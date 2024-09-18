#!/bin/bash

#This script is made to ping a service, and if you dont get a reply you can then run a command.
#The idea is to call this script from a cron job and check such as a NFS server is online
#If the server doesnt replay to the ping you can stop a docker conatiner.

SERVICE_TO_PING="google.com"
PING_COUNT=4



#Command that will be run of the service is unreachable

COMMAND_ON_FAILURE="this command will be runned"

ping -c $PING_COUNT $SERVICE_TO_PING > /dev/null

#Check for success.

if [ $? -ne 0 ]
then
    echo $COMMAND_ON_FAILURE
else
    echo "$SERVICE_TO_PING:- service is online!"
fi