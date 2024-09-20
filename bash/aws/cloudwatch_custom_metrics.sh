#!/bin/bash

# Function to display error messages and exit
error_exit() {
    echo "Error: $1" 1>&2
    exit 1
}

# Log file paths
LOG_FILE="/var/log/custom_metrics.log"
ERROR_LOG_FILE="/var/log/custom_metrics_error.log"

# Ensure log files exist and are writable
touch $LOG_FILE $ERROR_LOG_FILE || error_exit "Failed to create or access log files."

# Get the system's hostname
HOSTNAME=$(hostname) || error_exit "Failed to get hostname."

# Use /proc/uptime to extract total uptime in seconds
UPTIME_SECONDS=$(awk '{print $1}' /proc/uptime | cut -d. -f1) || error_exit "Failed to get uptime."

# Convert seconds to days
UPTIME_DAYS=$(echo "$UPTIME_SECONDS" | awk '{print int($1 / 86400)}') || error_exit "Failed to convert uptime to days."

# Print the output to verify
echo "$(date): Hostname: $HOSTNAME, Uptime Days: $UPTIME_DAYS" >> $LOG_FILE

# Send the data to AWS CloudWatch as a custom metric
aws cloudwatch put-metric-data \
    --namespace "Custom/SystemUptime" \
    --metric-name "UptimeDays" \
    --dimensions Hostname="$HOSTNAME" \
    --value "$UPTIME_DAYS" \
    --unit Count \
    --region us-east-1

# Check if the command was successful
if [ $? -eq 0 ]; then
    echo "$(date): Successfully sent uptime to CloudWatch." >> $LOG_FILE
else
    echo "$(date): Failed to send uptime to CloudWatch." >> $ERROR_LOG_FILE
fi