#!/bin/bash

PROJ="tfgha"
POETRY="/usr/local/bin"
WORKDIR="/home/ubuntu"

# Update package lists
if ! sudo apt-get update; then
  echo "Failed to update package lists"
  exit 1
fi

# Install necessary packages
if ! sudo apt-get install -y python3 python3-pip git curl; then
  echo "Failed to install packages"
  exit 1
fi

# Change to the working directory
cd "$WORKDIR" || { echo "Failed to change directory to $WORKDIR"; exit 1; }

# Clone the project
if ! git clone "https://github.com/proquickly/$PROJ.git"; then
  echo "Failed to clone the repository"
  exit 1
fi

# Change ownership
if ! sudo chown -R ubuntu:ubuntu "$WORKDIR"; then
  echo "Failed to change ownership"
  exit 1
fi

# Run as the ubuntu user
sudo -u ubuntu bash
  set -e
  python3 -m pip install -U poetry
  cd "$WORKDIR/$PROJ"
  [ -f poetry.lock ] && rm poetry.lock
  $POETRY/poetry install
  cd "$WORKDIR/$PROJ/src/$PROJ"
  nohup $POETRY/poetry run python app.py &
