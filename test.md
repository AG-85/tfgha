# HOW TO

This is the simplest possible workflow to deploy to aws using terraform and gha.

Before you can use this workflow, you need to set up these GitHub Secrets:

	▪	AWS_ACCESS_KEY_ID
	▪	AWS_SECRET_ACCESS_KEY
To use this example:
Get an instance id:
```aiignore
aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=al2023-ami-*" "Name=architecture,Values=x86_64" \
    --query "sort_by(Images, &CreationDate)[-1].ImageId" \
    --output text
```
	1.	Create a new GitHub repository
	1.	Add the files as shown above
    1.  Add this to gha yml files:
                ```
                - name: Terraform Plan
                run: terraform plan
                working-directory: terraform
                ```
	1.	Add your AWS credentials as GitHub Secrets
    1. run `aws sts get-caller-identity`
	1.	Push the code to the main branch
The workflow will:

	1.	Trigger when you push to the main branch
	2.	Initialize Terraform
	3.	Check the formatting
	4.	Create a plan
	5.	Apply the infrastructure changes

# IMPORTANT
To destroy the infrastructure when deploying manually (not via action), run terraform destroy locally.

Steps to be defined later in a video. now works remote and autodeletes

CARE WHERE YOU PUT SECRETS - MUST BE IN GitHub REPO settings (not env)

eg: https://github.com/proquickly/<your-repo-name>/settings/secrets/actions

get your aws keys from your account:
https://us-east-1.console.aws.amazon.com/iam/home?region=<your-region>#/users/details/<your-user-name>?section=permissions

this now runs locally - updated aws config


Add your PUBLIC ssh key ONLY to the terraform directory and the main.tf will use it to login to the EC2 instance interactively from local laptop. ss ubuntu@ipaddress
as usual.

Now that poetry is used for python this will deploy any python project that
is setup correctly with poetry.

TODO: install the project as a module with poetry build and pip or poetry 
install from the dist dir whl file. Put the .whl in a registry,

Also note that the delay in deployment during the time the EC2 instance is up is caused by the time it takes to clone the github repo.


# More info
## ssh keys

Here's a complete guide for setting up SSH keys for EC2 instances with Terraform and GitHub Actions:
	1.	Generate SSH Keys Locally

```# Generate key pair
ssh-keygen -t rsa -b 4096 -f id_rsa -N ""

# This creates:
# - id_rsa (private key)
# - id_rsa.pub (public key)
	2.	Add to GitHub Secrets
Add these secrets in your GitHub repository (Settings > Secrets and variables > Actions):

SSH_PRIVATE_KEY: (contents of id_rsa)
SSH_PUBLIC_KEY:  (contents of id_rsa.pub)
	3.	Update Terraform Configuration

# main.tf
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = var.ssh_public_key  # Use variable instead of file()
}

variable "ssh_public_key" {
  description = "Public key for SSH access"
  type        = string
}
	4.	GitHub Actions Workflow

name: Terraform AWS Deployment

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  terraform:
    runs-on: ubuntu-latest
    
    env:
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      AWS_REGION: us-west-2

    steps:
    - name: Checkout repository
      uses: actions/checkout@v3
      
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2
      
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}

    - name: Create terraform.tfvars
      run: |
        cat > terraform.tfvars <<EOF
        ssh_public_key = "${{ secrets.SSH_PUBLIC_KEY }}"
        EOF

    - name: Terraform Init
      run: terraform init

    - name: Terraform Plan
      run: terraform plan

    - name: Terraform Apply
      if: github.ref == 'refs/heads/main'
      run: terraform apply -auto-approve
	5.	Complete Terraform Configuration

# main.tf
provider "aws" {
  region = "us-west-2"
}

# Variables
variable "ssh_public_key" {
  description = "Public key for SSH access"
  type        = string
}

# Key pair
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = var.ssh_public_key
}

# Security group
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
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
}

# EC2 instance
resource "aws_instance" "example" {
  ami           = "ami-06946f6c9b153d494"  # Ubuntu 22.04
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name

  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "ExampleInstance"
  }
}

# Output
output "instance_public_ip" {
  value = aws_instance.example.public_ip
}
```
# Terminating ec2 instance

```aiignore

import sys
import boto3
import time
import requests

def run_job():
    try:
        # Your job logic here
        print("Starting job...")
        time.sleep(60)  # Your actual work here
        print("Job completed successfully")
        return True
    except Exception as e:
        print(f"Job failed: {e}")
        return False

def terminate_instance():
    try:
        # Get instance ID
        instance_id = requests.get(
            'http://169.254.169.254/latest/meta-data/instance-id'
        ).text
        
        # Initialize boto3 client
        ec2 = boto3.client('ec2')
        
        # Terminate instance
        ec2.terminate_instances(InstanceIds=[instance_id])
        print(f"Instance {instance_id} termination initiated")
    except Exception as e:
        print(f"Failed to terminate instance: {e}")
        sys.exit(1)

if __name__ == "__main__":
    success = run_job()
    if success:
        terminate_instance()
    else:
        sys.exit(1)
```
# eof
