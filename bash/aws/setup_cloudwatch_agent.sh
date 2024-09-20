#!/bin/bash

# Warning: This script will make significant changes to your system.

# Check for root privileges
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# Step 1: Download and install the Amazon CloudWatch Agent
echo "Creating /tmp/cloudwatch directory and downloading CloudWatch agent..."
sudo mkdir -p /tmp/cloudwatch
cd /tmp/cloudwatch
sudo wget https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb

echo "Installing the CloudWatch agent..."
sudo dpkg -i -E ./amazon-cloudwatch-agent.deb

# Step 2: Prompt the user for AWS credentials
echo "Now we will create the AWS credentials file."
read -p "Enter your AWS Access Key ID: " aws_access_key_id
read -sp "Enter your AWS Secret Access Key: " aws_secret_access_key
echo

# Create the AWS credentials file for the CloudWatch agent
aws_credentials_dir="$HOME/.aws"
aws_credentials_file="$aws_credentials_dir/credentials"

echo "Creating AWS credentials file in $aws_credentials_file..."
mkdir -p "$aws_credentials_dir"
cat > "$aws_credentials_file" <<EOL
[AmazonCloudWatchAgent]
aws_access_key_id = $aws_access_key_id
aws_secret_access_key = $aws_secret_access_key
EOL

echo "AWS credentials file created successfully."

# Step 3: Run the CloudWatch Agent configuration wizard
echo "Starting the CloudWatch agent configuration wizard..."
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard

# Step 4: Check if the user wants to store the configuration in AWS Systems Manager Parameter Store
read -p "Do you want to store the configuration file in AWS Systems Manager Parameter Store? (y/n): " store_in_ssm

if [[ "$store_in_ssm" == "y" || "$store_in_ssm" == "Y" ]]; then
    echo "Make sure the IAM role attached has the necessary permissions to store the file in Parameter Store."
fi

echo "CloudWatch agent installation and configuration complete. You may want to verify the status of the agent manually."
