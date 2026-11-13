#!/bin/bash

# This script will expand the Publisher partition to use all available space AFTER the physical hard drive 
# space has been increased on the Virtual Machine HyperVisor
# The below commands will grow the partition AFTER the physical hard drive has been increased

# Check if the script is run as root
if [ "$(id -u)" != 0 ]; then
  echo "Please run this script as root or using sudo."
  exit 1
fi

# Print out the block devices
lsblk
echo ""

# Print out the  file systems
df "$HOME" -H
echo ""

availSpace=$(df "$HOME" -H | awk 'NR==2 {gsub("G","",$4); print $4}')
echo "Current publisher partition available size is ${availSpace}G"
if [ "$availSpace" -gt 30 ]; then
    echo "Available space is sufficient: ${availSpace}G. No need further expansion."
    exit 0
fi

read -r -p "This script should be executed AFTER the physical hard drive has been increased [y/N] " response
case "$response" in
    [yY][eE][sS]|[yY])
        ;;
    *)
        exit 1
        ;;
esac

# Check if required commands are available
command -v growpart >/dev/null 2>&1 || { echo "growpart is not installed. Aborting." >&2; exit 1; }
command -v pvresize >/dev/null 2>&1 || { echo "pvresize is not installed. Aborting." >&2; exit 1; }
command -v lvresize >/dev/null 2>&1 || { echo "lvresize is not installed. Aborting." >&2; exit 1; }

# # The below 3 commands will grow the partition AFTER the physical hard drive has been increased
sudo growpart /dev/sda 3 || { echo "growpart failed. Aborting." >&2; exit 1; }
sudo pvresize /dev/sda3 || { echo "pvresize failed. Aborting." >&2; exit 1; }
sudo lvresize -l+100%FREE --resizefs /dev/mapper/ubuntu--vg-ubuntu--lv || { echo "lvresize failed. Aborting." >&2; exit 1; }

availSpace=$(df "$HOME" -H | awk 'NR==2 { print $4 }')
echo "Successfully expand the partition, current publisher partition available size is" $availSpace
exit 0