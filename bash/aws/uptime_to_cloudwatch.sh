#!/bin/bash

#Sytems hostname
HOSTNAME=$(hostname)

#AWK the uptime command and get the part which shows days
UPTIME_DAYS=$(uptime | awk '{print "days:"$3}')

# Print the output to verify
echo "Hostname: $HOSTNAME"
echo "Uptime: $UPTIME_DAYS"

# Send the data to AWS CloudWatch agent
aws cloudwatch put-metric-data \
    --namespace "Custom/SystemUptime" \
    --metric-name "UptimeDays" \
    --dimensions "Hostname=$HOSTNAME" \
    --value "${UPTIME_DAYS//days:/}" \
    --unit None

# check for non zero return indicating error or success
if [ $? -eq 0 ]; then
    echo "Successfully sent uptime to CloudWatch."
else
    echo "Failed to send uptime to CloudWatch."
fi
