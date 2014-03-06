#!/bin/bash -ex

emerge --sync

# to do: move package list into world, and include necessary masks/license/use/makeconf files

# Global make
cat >> /etc/portage/make.conf <<EOF
MAKEOPTS="-j9"
USE="static static-libs -doc"
EOF

# Core utilities

emerge -nNv dmidecode pciutils openipmi  ipmitool lshw lvm2

# Network stuff

emerge -nNv netcat tcpdump socat netio netperf
USE='ncat' emerge nmap 
USE='cdp edf fdp json snmp' emerge lldpd

emerge -nNv openssh

# Stress testing / burnin 

emerge -nNv stress stressapptest cpuburn 
emerge -nNv nbench tiobench 

set +e
emerge -nNv sci-mathematics/gimps --autounmask-write
echo "-5" | etc-update
emerge -nNv sci-mathematics/gimps 
set -e
emerge bonnie++

emerge -nNv lm_sensors memtester smartmontools ramspeed


cat > /init <<'EOF'
echo 'Dropping to rescue shell, good luck'
/bin/busybox sh

#export PATH=/bin:/sbin:/usr/bin:/usr/sbin
#
## Mount things needed by this script
#busybox mount -t proc proc /proc
#busybox mount -t sysfs sysfs /sys
#
## Disable kernel messages from popping onto the screen
#echo 0 > /proc/sys/kernel/printk
#
## Create all the symlinks to /bin/busybox
#busybox --install -s
#
## Create base device nodes
#mknod /dev/null c 1 3
#mknod /dev/tty c 5 0
#
## Run depmod to calculate module dependencies, so we can use modprobe
#depmod -a
#
## Start mdev to populate /dev
#echo /sbin/mdev > /proc/sys/kernel/hotplug
#mdev -s
#
## Allow mount command to work
#ln -s /proc/mounts /etc/mtab

EOF

#root=/dev/ram0 rdinit=/init 
