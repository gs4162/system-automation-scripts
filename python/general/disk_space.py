import shutil
import os

# Location and threshold
check_location = "/"
threshold = 80

#convert bytes to human readable gb
def bytes_to_gb(bytes):
    return bytes / (1024 ** 3) 


def check_disk_usage(location, threshold):
    disk_usage_stat = {}
    disk_stats = shutil.disk_usage(location)

    total_gb = bytes_to_gb(disk_stats[0])
    used_gb = bytes_to_gb(disk_stats[1])
    free_gb = bytes_to_gb(disk_stats[2])
    usage_percent = (disk_stats[1] / disk_stats[0]) * 100
    

    # Format the values to dict to have 2 decimal places
    disk_usage_stat['total_gb'] = f"{total_gb:.2f}"
    disk_usage_stat['used_gb'] = f"{used_gb:.2f}"
    disk_usage_stat['free_gb'] = f"{free_gb:.2f}"
    disk_usage_stat['usage_percent'] = f"{usage_percent:.2f}"

    return(disk_usage_stat)
    #testing
    #print(f"Disk Check Location: {location}")
    #print(f"Total Space: {total_gb:.2f} GB")
    #print(f"Used Space: {used_gb:.2f} GB ({usage_percent:.2f}%)")
    #print(f"Free Space: {free_gb:.2f} GB")





print(check_disk_usage(check_location,threshold))