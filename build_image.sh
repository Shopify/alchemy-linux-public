#!/bin/bash -e


OUTPUT_DIR=/tmp
CHROOT_DIR=/tmp/image_chroot
BIND_MOUNTS="proc sys dev"

# Attempt to unmount bind-mounts first, just in case
for i in $BIND_MOUNTS; do
	umount $CHROOT_DIR/$i &>/dev/null
done

# Clean previous contents of chroot
rm -rf $CHROOT_DIR 2>/dev/null
mkdir -p $CHROOT_DIR


# Bind-mount various directories inside the chroot
for i in $BIND_MOUNTS; do
	mkdir -p $CHROOT_DIR/$i
	mount -o bind /$i $CHROOT_DIR/$i
done

# Init chroot
rpm --root=$CHROOT_DIR --initdb
yum_install sl-release busybox

# Use our repos
rm $CHROOT_DIR/etc/yum.repos.d/sl.repo
cp /etc/yum.repos.d/{sl,packages}-*.repo $CHROOT_DIR/etc/yum.repos.d/
yum --installroot=$CHROOT_DIR clean all

# Kernel
yum_install --downloadonly --downloaddir=$CHROOT_DIR/tmp kernel
rpm --root=$CHROOT_DIR -Uhv --nodeps --noscripts $CHROOT_DIR/tmp/kernel-2*rpm

# Additional packages
yum_install dmidecode pciutils OpenIPMI nc ipmitool lshw

# Non-standard packages
yum_install MegaCli

# Drop init script
cat > $CHROOT_DIR/init <<'EOF'
#!/bin/bash

export PATH=/bin:/sbin:/usr/bin:/usr/sbin

# Mount things needed by this script
busybox mount -t proc proc /proc
busybox mount -t sysfs sysfs /sys

# Disable kernel messages from popping onto the screen
echo 0 > /proc/sys/kernel/printk

# Create all the symlinks to /bin/busybox
busybox --install -s

# Create base device nodes
mknod /dev/null c 1 3
mknod /dev/tty c 5 0

# Run depmod to calculate module dependencies, so we can use modprobe
depmod -a

# Start mdev to populate /dev
echo /sbin/mdev > /proc/sys/kernel/hotplug
mdev -s

# Allow mount command to work
ln -s /proc/mounts /etc/mtab

# Load some modules
modprobe vmxnet3
modprobe igb
modprobe bnx2
modprobe ixgbe
modprobe e1000
modprobe ahci
modprobe megaraid_sas
modprobe sd_mod

# Start IPMI stuff
modprobe ipmi_devintf
modprobe ipmi_si
/etc/init.d/ipmi start

# Try to get an IP address
cd /sys/class/net
for i in eth*; do
  ifconfig $i up
done
echo "Sleeping for a bit to allow the interfaces to initialize..."
sleep 5s
for i in eth*; do
  if [ "$(<$i/carrier)" = "1" ]; then
    udhcpc -i $i -s /usr/bin/udhcpc.script
	if ifconfig $i | grep -q 'inet addr'; then
      echo "Got an address on interface $i"
      break
    fi
  else
    echo "No link detected on $i...skipping"
  fi
done

wget http://kickstart3001.lv7.box.net/cblr/svc/op/ks/system/default -O - | bash

exec setsid sh -c 'exec sh </dev/tty1 >/dev/tty1 2>&1'

EOF
chmod a+x $CHROOT_DIR/init

# Drop udhcpc script so DHCP client will work
cat > $CHROOT_DIR/usr/bin/udhcpc.script <<'EOF'
#!/bin/sh

# udhcpc script edited by Tim Riker <Tim@Rikers.org>

[ -z "$1" ] && echo "Error: should be called from udhcpc" && exit 1

RESOLV_CONF="/etc/resolv.conf"
[ -n "$broadcast" ] && BROADCAST="broadcast $broadcast"
[ -n "$subnet" ] && NETMASK="netmask $subnet"

case "$1" in
	deconfig)
		/sbin/ifconfig $interface 0.0.0.0
		;;
	renew|bound)
		/sbin/ifconfig $interface $ip $BROADCAST $NETMASK
		if [ -n "$router" ] ; then
			while route del default gw 0.0.0.0 dev $interface 2>/dev/null ; do
				:
			done
			metric=0
			for i in $router ; do
				route add default gw $i dev $interface metric $((metric++))
			done
		fi
		echo -n > $RESOLV_CONF
		[ -n "$domain" ] && echo search $domain >> $RESOLV_CONF
		for i in $dns ; do
			echo adding dns $i
			echo nameserver $i >> $RESOLV_CONF
		done
		;;
esac

exit 0
EOF
chmod a+x $CHROOT_DIR/usr/bin/udhcpc.script

# Script to clean up locale archive
cat > $CHROOT_DIR/tmp/cleanup_locales <<EOF
#!/bin/bash

cd /usr/lib/locale
/usr/bin/localedef --list-archive | /bin/grep -v -i ^en_US | /sbin/busybox xargs /usr/bin/localedef --delete-from-archive
rm locale-archive.tmpl
mv locale-archive locale-archive.tmpl
/usr/sbin/build-locale-archive
EOF
chmod a+x $CHROOT_DIR/tmp/cleanup_locales
chroot $CHROOT_DIR /tmp/cleanup_locales

# Clean up unneeded stuff
rm -rf $CHROOT_DIR/usr/share/doc
rm -rf $CHROOT_DIR/usr/share/man
rm -rf $CHROOT_DIR/var/cache/yum/*
rm -rf $CHROOT_DIR/tmp/*
find $CHROOT_DIR/usr/share/locale -mindepth 1 -maxdepth 1 -type d | grep -v 'en_US' | xargs rm -rf

# Unmount bind mounts
for i in $BIND_MOUNTS; do
	umount $CHROOT_DIR/$i
done

# Build initramfs
cd $CHROOT_DIR
find . | cpio -H newc -o > $OUTPUT_DIR/initramfs.cpio
cd $OUTPUT_DIR
gzip > netboot.initramfs < initramfs.cpio
rm initramfs.cpio


# Display space usage
du -hcs $CHROOT_DIR
ls -lh $OUTPUT_DIR/netboot.{initramfs,kernel}

echo "Image build completed in $CHROOT_DIR"
