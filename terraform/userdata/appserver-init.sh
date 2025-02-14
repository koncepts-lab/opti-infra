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

# Create .ssh directory if it doesn't exist
mkdir -p /home/${app_server_admin_username}/.ssh

# Set correct permissions and ownership
chmod 700 /home/${app_server_admin_username}/.ssh
chown -R ${app_server_admin_username}:${app_server_admin_username} /home/${app_server_admin_username}/.ssh