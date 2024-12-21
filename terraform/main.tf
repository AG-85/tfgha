terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

provider "random" {}

data "aws_security_groups" "all" {
  filter {
    name   = "group-name"
    values = ["*"]
  }
}

resource "null_resource" "cleanup_security_groups" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<EOF
      for sg in $(aws ec2 describe-security-groups \
        --filters "Name=group-name,Values=*" \
        --query 'SecurityGroups[?GroupName!=`default`].GroupId' \
        --output text); do

        # Check if SG is attached to running instances
        INSTANCES=$(aws ec2 describe-instances \
          --filters "Name=instance.group-id,Values=$sg" \
          --query 'Reservations[].Instances[?State.Name==`running`].InstanceId' \
          --output text)

        if [ -z "$INSTANCES" ]; then
          echo "Deleting security group: $sg"
          aws ec2 delete-security-group --group-id $sg || true
        else
          echo "Security group $sg is attached to running instances, skipping"
        fi
      done
    EOF
  }
}

# Add random suffix to avoid conflicts
resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key-${random_id.suffix.hex}"
  public_key = file("id_rsa.pub")
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh_${random_id.suffix.hex}"
  description = "Allow SSH inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http_flask_${random_id.suffix.hex}"
  description = "Allow inbound HTTP traffic"

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "py_server" {
  ami           = "ami-06946f6c9b153d494"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name

  user_data = file("setup.sh")

  tags = {
    Name = "FlaskAppInstance"
  }

  vpc_security_group_ids = [
    aws_security_group.allow_http.id, aws_security_group.allow_ssh.id
  ]

  depends_on = [
    aws_security_group.allow_http,
    aws_security_group.allow_ssh
  ]
}

