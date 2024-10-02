#!/bin/bash

# This script is designed to be run by a cron job and send a single notification to a service like ntfy after completing system updates.

# Configuration
LOG_DIR='/opt/ntfy/logs'
LOG_FILE="$LOG_DIR/test.log"
LOG_FILE_ERROR="$LOG_DIR/test_error.log"
HOSTNAME=$(hostname)  # Get the hostname for notifications
NTFY_URL="https://ntfy.stillautomate.lan/update"  # Ntfy topic URL

# Function to send notifications
send_notification() {
    local title="$1"
    local message="$2"
    local priority="$3"  # Priority levels: 1 (low) to 5 (high)

    curl -s -X POST "$NTFY_URL" \
         -H "Title: $title" \
         -H "Priority: $priority" \
         -d "$message"
}

# Ensure the log directory exists
if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
fi

# Initialize variables
STATUS="Success"
MESSAGE=""
PRIORITY=2  # Default priority for success notifications

# Capture system information
DISK_SPACE=$(df -h / | awk 'NR==2 {print $4}')  # Available space on root partition
UPTIME=$(uptime -p)  # Human-readable uptime

# Start the update process and log output/errors
echo "$(date): Starting update...." | tee -a "$LOG_FILE"

# Run apt update and log output
sudo apt update >> "$LOG_FILE" 2>> "$LOG_FILE_ERROR"
if [ $? -ne 0 ]; then
    STATUS="Failure"
    MESSAGE+="Error during 'apt update'.\n"
    PRIORITY=5  # High priority for critical errors
fi

# Check for upgradable packages
UPGRADABLE=$(apt list --upgradable 2>> "$LOG_FILE_ERROR" | grep -v "Listing...")
if [ -n "$UPGRADABLE" ]; then
    echo "Packages available for upgrade:" | tee -a "$LOG_FILE"
    echo "$UPGRADABLE" | tee -a "$LOG_FILE"

    # Run apt upgrade and log output
    sudo apt upgrade -y >> "$LOG_FILE" 2>> "$LOG_FILE_ERROR"
    if [ $? -ne 0 ]; then
        STATUS="Failure"
        MESSAGE+="Error during 'apt upgrade'.\n"
        PRIORITY=5  # High priority for critical errors
    else
        # Check if upgrades were deferred due to phasing
        if grep -q "The following upgrades have been deferred due to phasing" "$LOG_FILE"; then
            MESSAGE+="Updates were deferred due to phasing. No packages were upgraded.\n"
            PRIORITY=3  # Medium priority for deferred updates
        else
            MESSAGE+="Packages were successfully upgraded.\n"
            PRIORITY=4  # High priority for successful upgrades
        fi
    fi
else
    echo "All packages are up to date." | tee -a "$LOG_FILE"
    MESSAGE+="No upgrades available. The system is up to date.\n"
    PRIORITY=1  # Very low priority for informational messages
fi

# Check if a reboot is required
if [ -f /var/run/reboot-required ]; then
    MESSAGE+="A system reboot is required to complete the updates.\n"
    PRIORITY=4  # High priority for reboot notifications
fi

# Append system information to the message
MESSAGE+="\nSystem Information:\n"
MESSAGE+="Hostname: $HOSTNAME\n"
MESSAGE+="Available Disk Space: $DISK_SPACE\n"
MESSAGE+="System Uptime: $UPTIME"

# Determine the title based on the status
if [ "$STATUS" = "Success" ]; then
    TITLE="System Update Successful on $HOSTNAME"
else
    TITLE="System Update Failed on $HOSTNAME"
fi

# Send the notification
send_notification "$TITLE" "$MESSAGE" "$PRIORITY"

# Exit with the appropriate status
if [ "$STATUS" = "Failure" ]; then
    exit 1
else
    exit 0
fi
