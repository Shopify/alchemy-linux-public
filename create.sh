#!/bin/bash -e
DIR=$(cd "$(dirname "$0")"; pwd)
OUTPUT_DIR=/tmp
CHROOT_DIR=/$OUTPUT_DIR/image_chroot
KERNEL_DIR=/$OUTPUT_DIR/kernel
KERNEL_CONF_DIR=$DIR/kernels
OUTFILE=$DIR/bin/alchemist.img
BIND_MOUNTS="proc sys dev"
STAGE3_URL=http://ftp.osuosl.org/pub/funtoo/funtoo-current/x86-64bit/generic_64/stage3-latest.tar.xz 

[ $# -le 0 ] && echo "Must specify parameters" && exit 1
[ "`whoami`" != 'root' ] &&  echo "Must be run as root, rerunning as sudo" && sudo $0 $@ 
[ "`whoami`" == 'root' ] || exit $?
while getopts "k:d" opt; do
    case "$opt" in
    k)  kernel=$OPTARG
        kernel_conf_path=$DIR/kernels/$kernel
        [ ! -e $kernel_conf_path ] && echo "Specified kernel '$kernel' doesn't exist at $kernel_conf_path" && exit 1
        ;;
    r)  ramfs=1
        ;;
    d)  debug=1
        set -x
        ;;
    esac
done

if [ $ramfs ];then

# Get the image
  if [ ! -f "$OUTPUT_DIR/stage3-latest.tar.xz" ]; then
    echo "Downloading Image"
    wget $STAGE3_URL -P $OUTPUT_DIR
  fi

# Extract it
  if [ ! -f $CHROOT_DIR/extracted ];then
    echo "Extracting image"
    
    [ ! -d $CHROOT_DIR ] && mkdir $CHROOT_DIR
    tar -xpf $OUTPUT_DIR/stage3-latest.tar.xz -C $CHROOT_DIR
    touch $CHROOT_DIR/extracted
  fi

  echo "Preparing chroot"

# Attempt to unmount bind-mounts first, just in case
  for i in $BIND_MOUNTS; do
    if [ -n "`grep $CHROOT_DIR/$i /proc/mounts`" ];then
      umount $CHROOT_DIR/$i &>/dev/null
    fi
  done

# Clean previous contents of chroot
#rm -rf $CHROOT_DIR 2>/dev/null
  mkdir -p $CHROOT_DIR

  echo "Bind mounting"
# Bind-mount various directories inside the chroot
  for i in $BIND_MOUNTS; do
    mkdir -p $CHROOT_DIR/$i
    mount -o bind /$i $CHROOT_DIR/$i
  done


  echo "Entering chroot"
  cp chroot_script.sh $CHROOT_DIR
  cp /etc/resolv.conf $CHROOT_DIR/etc
  chmod +x $CHROOT_DIR/chroot_script.sh
  chroot $CHROOT_DIR /chroot_script.sh 

  echo "Leaving chroot"
  echo "Cleaning chroot"
# Unmount bind mounts
  for i in $BIND_MOUNTS; do
    umount $CHROOT_DIR/$i
  done
fi

## Build initramfs
#cd $CHROOT_DIR
#find . | cpio -H newc -o > $OUTPUT_DIR/initramfs.cpio
#cd $OUTPUT_DIR
#gzip > netboot.initramfs < initramfs.cpio
#rm initramfs.cpio
#
## Grab kernel
#mv $CHROOT_DIR/boot/vmlinuz* $OUTPUT_DIR/netboot.kernel
#
## Display space usage
#du -hcs $CHROOT_DIR
#ls -lh $OUTPUT_DIR/netboot.{initramfs,kernel}

if [ -n "$kernel" ];then

  if [ ! -e /usr/src/linux/.git ];then
    echo "Please clone linux to /usr/src linux to continue"
    exit

  else
    echo "building kernel using $kernel_conf_path"
 
    rm -rf $CHROOT_DIR/usr/share/doc
    rm -rf $CHROOT_DIR/usr/share/gtk-doc
    rm -rf $CHROOT_DIR/usr/share/man
    rm -rf $CHROOT_DIR/tmp/*
    rm -rf $CHROOT_DIR/var/tmp/*
    rm -rf $CHROOT_DIR/var/db/pkg
    rm -rf $CHROOT_DIR/usr/portage
    find $CHROOT_DIR | grep include | xargs rm -rf

    cd /usr/src/linux
    cp $kernel_conf_path .config
    sed -i "s:CHROOT_DIR:$CHROOT_DIR:g" .config
    echo 'y' | make oldconfig
    make -j`nproc` modules
    INSTALL_MOD_PATH=$CHROOT_DIR make modules_install
    make -j`nproc`
   
    [ ! -d $DIR/bin ] && mkdir $DIR/bin 
    mv arch/x86/boot/bzImage  $OUTFILE
    echo "Image build completed in $CHROOT_DIR"
  fi

fi


echo "Image build completed in $CHROOT_DIR"
