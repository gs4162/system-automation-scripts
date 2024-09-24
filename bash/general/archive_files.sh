#!/bin/bash

# This script is to archive and compress files in the current directory
# or allows the user to input a different path.

# Prompt for input with a default action
read -p "This script will archive and compress the current directory [Press Enter], unless you insert a path here: " input_path

# Check if input_path is empty
if [[ -n $input_path ]]
then
    echo "Input path: $input_path"
    # List files to be archived, excluding certain file types
    files=$(ls --ignore='*.sh' --ignore='*.gz' --ignore='*tar.gz' "$input_path")
else
    echo "No path provided, defaulting to current directory."
    # List files in the current directory, excluding certain file types
    files=$(ls --ignore='*.sh' --ignore='*.gz' --ignore='*tar.gz')
fi

# Display the selected files
echo "The following files will be archived:"
for file in $files
do
    echo "$file"
done

# Prompt the user to continue or cancel
read -p "This is your last chance to cancel. Press Ctrl + C to quit, or press Enter to continue."

# Archive and compress the selected files
tar czf "archive-$(date +%F).tar.gz" $files

# Check for success in archiving
if [ $? -ne 0 ]
then
    echo "Error occurred during archiving."
    exit 1
else
    echo "Success! The following files have been archived: $files"
fi

# Prompt for cleanup of the original files
read -p "Would you like to delete the files we just archived? Press Ctrl + C to quit, or press Enter to continue."

# Delete the original files
rm -v $files
