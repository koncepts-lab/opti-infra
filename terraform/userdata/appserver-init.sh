#!/bin/bash
yum install -y inotify-tools ansible
mkdir -p /var/lib/pgsql
until [[ -b /dev/sdh ]]; do sleep 1 ; done
mkfs -t xfs /dev/sdh
echo '/dev/sdh /var/lib/pgsql xfs defaults 0 0' >> /etc/fstab
mount -a