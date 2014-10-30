#!/bin/bash -ex
DIR=$(cd "$(dirname "$0")"; pwd)

source $DIR/methods

procs=`nproc`
sed -i "s:CORES:$procs:g" /etc/portage/make.conf

# Setup the admin user
/bin/bash $DIR/adminuser

# Create world file
cat $DIR/packages/* > /var/lib/portage/world

emerge --sync

mkdir -p /usr/portage/distfiles
mkdir -p /usr/portage/packages
[ -e /distfiles ] && cp -r /distfiles/* /usr/portage/distfiles
[ -e /packages ] && cp -r /packages/* /usr/portage/packages && emaint binhost --fix

emerge_world

# Come on, who uses anything else?
eselect editor set vi

# IMPORTANT: Enable serial console so we can login via IPMI
# Uncomment s0
sed -i 's/^#\(s0.*$\)/\1/'g /etc/inittab

# Force it to ttyS1 (which is passed as boot argument to kernel)
sed -i 's/\(s0.*\)ttyS0\(.*$\)/\1ttyS1\2/g' /etc/inittab

# Allow passwordless sudo
sed -i "/%wheel ALL=(ALL) NOPASSWD/ s/# *//" /etc/sudoers

rc-update add lldpd default
#rc-update add lm_sensors default

set +e
rc-update delete hwclock boot
rc-update delete swap boot
rc-update delete swapfiles boot
rc-update delete keymaps boot
rc-update delete netmount default

rm /etc/init.d/hwclock
rm /etc/init.d/swap
rm /etc/init.d/swapfiles
rm /etc/init.d/keymaps
rm /etc/init.d/netmount
set -e


# Prepare /init
ln -sf /bin/busybox /bin/sht 
cp $DIR/init /
chmod +x /init
