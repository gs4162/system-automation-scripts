#!/bin/bash

# Warning: This script will make significant changes to your system.

# Function to display error messages
error_exit() {
    echo "Error: $1" 1>&2
    exit 1
}

# Check for root privileges
if [ "$(id -u)" != "0" ]; then
    error_exit "This script must be run as root."
fi

# Step 1: Download and install the Amazon CloudWatch Agent
echo "Creating /tmp/cloudwatch directory and downloading CloudWatch agent..."
mkdir -p /tmp/cloudwatch || error_exit "Failed to create /tmp/cloudwatch directory."
cd /tmp/cloudwatch || error_exit "Failed to navigate to /tmp/cloudwatch directory."

echo "Downloading the CloudWatch agent..."
wget https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb || error_exit "Failed to download CloudWatch agent."

echo "Installing the CloudWatch agent..."
dpkg -i -E ./amazon-cloudwatch-agent.deb || error_exit "Failed to install CloudWatch agent."

# Step 2: Create the cwagent user and add it to the adm group for log access
echo "Creating 'cwagent' user and adding to 'adm' group for log access..."
useradd -r -s /bin/false cwagent || echo "cwagent user already exists."
usermod -aG adm cwagent || error_exit "Failed to add 'cwagent' to 'adm' group."

# Step 3: Prompt the user for AWS credentials and region
echo "Now we will create the AWS credentials and config files for the cwagent user."

# Prompt for AWS Access Key and Secret Key
read -p "Enter your AWS Access Key ID: " aws_access_key_id
read -sp "Enter your AWS Secret Access Key: " aws_secret_access_key
echo

# Prompt for AWS Region (default to us-east-1 if no input)
read -p "Enter your AWS Region (default: us-east-1): " aws_region
aws_region=${aws_region:-us-east-1}

# Step 4: Create the AWS credentials and config file for the cwagent user
echo "Creating AWS credentials and config files for 'cwagent' user..."
mkdir -p /home/cwagent/.aws || error_exit "Failed to create /home/cwagent/.aws directory."

# Write credentials file
credentials_file="/home/cwagent/.aws/credentials"
cat > "$credentials_file" <<EOL
[AmazonCloudWatchAgent]
aws_access_key_id = $aws_access_key_id
aws_secret_access_key = $aws_secret_access_key
EOL

# Write config file for region
config_file="/home/cwagent/.aws/config"
cat > "$config_file" <<EOL
[AmazonCloudWatchAgent]
output = text
region = $aws_region
EOL

# Set appropriate permissions
chmod 600 "$credentials_file" "$config_file" || error_exit "Failed to set permissions for credentials and config files."
chown -R cwagent:cwagent /home/cwagent/.aws || error_exit "Failed to set ownership for /home/cwagent/.aws."

# Step 5: Configure CloudWatch Agent common-config.toml
echo "Configuring CloudWatch Agent common-config.toml..."

common_config_toml="/opt/aws/amazon-cloudwatch-agent/etc/common-config.toml"

cat > "$common_config_toml" <<EOL
[credentials]
profile = "AmazonCloudWatchAgent"
shared_credential_file = "/home/cwagent/.aws/credentials"

[region]
region = "$aws_region"
EOL

chmod 600 "$common_config_toml" || error_exit "Failed to set permissions for $common_config_toml."
chown root:root "$common_config_toml" || error_exit "Failed to set ownership for $common_config_toml."

echo "common-config.toml configured successfully."

# Step 6: Run the CloudWatch Agent configuration wizard
echo "Starting the CloudWatch agent configuration wizard..."
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard

# Step 7: Move the configuration file and rename it
mv /opt/aws/amazon-cloudwatch-agent/bin/config.json /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json || error_exit "Failed to move and rename the configuration file."

# Step 8: Start and enable the CloudWatch Agent service
echo "Starting the CloudWatch Agent service..."
systemctl enable amazon-cloudwatch-agent || error_exit "Failed to enable CloudWatch Agent service."
systemctl start amazon-cloudwatch-agent || error_exit "Failed to start CloudWatch Agent service."

# Step 9: Verify the CloudWatch Agent status
echo "Verifying the CloudWatch Agent service status..."
systemctl status amazon-cloudwatch-agent --no-pager

# Step 10: Install collectd if not installed (optional, required for some metrics)
echo "Checking if collectd is installed..."
if ! dpkg -l | grep -q collectd; then
    echo "Installing collectd..."
    apt-get update && apt-get install -y collectd || error_exit "Failed to install collectd."
else
    echo "collectd is already installed."
fi

# Step 11: Provide final instructions
echo "CloudWatch agent installation and configuration complete."
echo "You may want to verify the status of the agent manually using:"
echo "  sudo systemctl status amazon-cloudwatch-agent"
echo "And check the log files at /var/log/amazon/amazon-cloudwatch-agent/amazon-cloudwatch-agent.log"

exit 0
