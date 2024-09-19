#!/bin/bash

# Warning: This script will make significant changes to your system.

# Check for root privileges
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# Source the environment variables from the .env file
source .env
if [ $? -ne 0 ]; then
    echo "Failed to source .env file. Ensure the file exists in the correct location and your permissions are correct."
    exit 1
fi

# Use SSM Code and ID directly from the environment
ssm_code=$SSM_CODE
ssm_id=$SSM_ID

read -p "SSM configuration loaded. Press Enter to continue and disable the SSH service..."

echo "Disabling SSH service..."
sudo systemctl disable ssh
sudo systemctl stop ssh
read -p "SSH service has been disabled. Press Enter to continue and download the AWS SSM Agent setup files..."

echo "Downloading and setting up the AWS SSM Agent..."
sudo snap stop amazon-ssm-agent
sudo snap remove amazon-ssm-agent
sudo mkdir -p /tmp/ssm
sudo wget -O /tmp/ssm/ssm-setup-cli https://s3.us-east-1.amazonaws.com/amazon-ssm-us-east-1/latest/debian_amd64/ssm-setup-cli

sudo chmod +x /tmp/ssm/ssm-setup-cli
read -p "AWS SSM Agent setup files downloaded and ready. Press Enter to continue and attempt to register with SSM using the provided code and ID..."

# Attempt to register with SSM using the provided code and ID
if ! sudo /tmp/ssm/ssm-setup-cli -register -activation-code "$ssm_code" -activation-id "$ssm_id" -region "us-east-1" -override; then
    echo "Error: The activation token may already be used. Please contact support as this token has been taken."
    exit 1
fi

echo "Registering the instance with AWS Systems Manager..."
read -p "AWS Systems Manager registration in progress. Press Enter to wait for 20 seconds and complete the setup..."

echo "Waiting for 20 seconds for the system to complete the setup..."
sleep 20

# Delete the .env file after the installation is complete
echo "Deleting the .env file for security purposes..."
if [ -f ".env" ]; then
    sudo rm .env
    if [ $? -eq 0 ]; then
        echo ".env file deleted successfully."
    else
        echo "Failed to delete the .env file."
    fi
else
    echo ".env file not found."
fi

read -p "Press Enter to complete the installation and review the status of AWS SSM Agent manually if needed..."

echo "Installation complete. You may want to verify the status of AWS SSM Agent manually."
