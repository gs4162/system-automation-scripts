import os
import shutil
from datetime import datetime
import re

# Source and backup location
source_dir = '/opt/k3s'
backup_dir = '/mnt/state-less-hhd/backups/python-backups-location'

# Get the current script's name dynamically
script_name = os.path.basename(__file__)

# Get current timestamp
timestamp = datetime.now().strftime("%Y-%m-%d-%H%M")

# File name to include the script name
backup_subdir = f"{script_name}-{re.sub(r'/', '-', source_dir)}-{timestamp}"

# Full backup path
backup_full_path = os.path.join(backup_dir, backup_subdir)

# Check for directory and create if not exists
os.makedirs(backup_dir, exist_ok=True)

# Function to do the backup (entire directory)
def backup_files(source, backup):
    # Copy the entire directory tree
    shutil.copytree(source, backup)
    print(f'Copied {source} to {backup}')

# Call the backup function
backup_files(source_dir, backup_full_path)
