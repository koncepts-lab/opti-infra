#!/bin/bash

# Update system
dnf update -y

# Install required utilities
dnf install -y \
    inotify-tools \
    ansible \
    xfsprogs

# Wait for data disk to be available
while [ ! -b /dev/sdc ]; do
    echo "Waiting for data disk to be attached..."
    sleep 1
done

# Create PostgreSQL data directory
mkdir -p /var/lib/pgsql

# Format the data disk (in Azure, typically /dev/sdc)
mkfs.xfs /dev/sdc

# Add entry to fstab for automatic mounting after reboot
echo "/dev/sdc /var/lib/pgsql xfs defaults 0 0" >> /etc/fstab

# Mount all filesystems
mount -a