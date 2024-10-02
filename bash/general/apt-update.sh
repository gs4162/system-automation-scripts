#!/bin/bash

# This script is designed to be run by a cron job and output a message to a service like notify.

LOG_DIR='./logs'
LOG_FILE="$LOG_DIR/test.log"
LOG_FILE_ERROR="$LOG_DIR/test_error.log"

if [ ! -d "$LOG_DIR" ]
then
    mkdir -p $LOG_DIR
fi

# Start the update process and log output/errors
echo "$(date): Starting update...." | tee -a $LOG_FILE
sudo apt update 2>> $LOG_FILE_ERROR | tee -a $LOG_FILE

echo "Listing packages that can be upgraded..." | tee -a $LOG_FILE

# Capture upgradable packages, exclude headers and log errors
UPGRADABLE=$(apt list --upgradable 2>> $LOG_FILE_ERROR | grep -v "Listing...")

# Output the list of upgradable packages (if any)
echo "$UPGRADABLE" | tee -a $LOG_FILE

# Check if any packages need to be upgraded
if [ -n "$UPGRADABLE" ]; then
    echo 'About to update' | tee -a $LOG_FILE

    # Run apt upgrade and capture the output
    UPGRADE_RESULT=$(sudo apt upgrade -y 2>> $LOG_FILE_ERROR | tee -a $LOG_FILE)

    # Check if upgrades were deferred due to phasing
    if echo "$UPGRADE_RESULT" | grep -q "The following upgrades have been deferred due to phasing"; then
        echo '--------------'
        echo 'Updates are deferred due to phasing, no packages upgraded.' | tee -a $LOG_FILE
        echo '--------------'
    else
        echo '--------------'
        echo 'Packages upgraded successfully.' | tee -a $LOG_FILE
        echo '--------------'
    fi
else
    echo '--------------'
    echo 'All up to date' | tee -a $LOG_FILE
    echo '--------------'
fi
