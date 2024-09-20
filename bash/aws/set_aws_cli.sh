#!/bin/bash

# Script to install and configure AWS CLI on Ubuntu

# Function to display error messages and exit
error_exit() {
    echo "Error: $1" 1>&2
    exit 1
}

# Check for root privileges
if [ "$(id -u)" != "0" ]; then
    error_exit "This script must be run as root. Use sudo."
fi

# Step 1: Update package lists
echo "Updating package lists..."
apt update -y || error_exit "Failed to update package lists."

# Step 2: Install AWS CLI
echo "Installing AWS CLI..."
apt install awscli -y || error_exit "Failed to install AWS CLI."

# Step 3: Configure AWS CLI
echo "Configuring AWS CLI..."
aws configure || error_exit "Failed to configure AWS CLI."

# Step 4: Set secure permissions on AWS credentials file
CREDENTIALS_FILE="/root/.aws/credentials"
CONFIG_FILE="/root/.aws/config"

if [ -f "$CREDENTIALS_FILE" ]; then
    echo "Setting permissions on $CREDENTIALS_FILE..."
    chmod 600 "$CREDENTIALS_FILE" || error_exit "Failed to set permissions on $CREDENTIALS_FILE."
    echo "Permissions set to 600 for $CREDENTIALS_FILE."
else
    error_exit "Credentials file $CREDENTIALS_FILE does not exist."
fi

if [ -f "$CONFIG_FILE" ]; then
    echo "Setting permissions on $CONFIG_FILE..."
    chmod 600 "$CONFIG_FILE" || error_exit "Failed to set permissions on $CONFIG_FILE."
    echo "Permissions set to 600 for $CONFIG_FILE."
else
    echo "Warning: Config file $CONFIG_FILE does not exist."
fi

echo "AWS CLI installation and configuration completed successfully."
exit 0
