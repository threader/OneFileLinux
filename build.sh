#!/bin/bash

set -e

# RootFS variables
#ROOTFS="alpine-minirootfs"
OFL_ROOT="$PWD"
BUILDROOT="$PWD/buildroot"
PKGSRC_DIR="$PWD/pkgsrc"
LLVM_DELUGE_DIR="$PWD/llvm-project-deluge"
ROOTFS="$PWD/$BUILDROOT/output/target"
CACHEPATH="$ROOTFS/var/cache/apk/"
SHELLHISTORY="$ROOTFS/root/.ash_history"
DEVCONSOLE="$ROOTFS/dev/console"
MODULESPATH="$ROOTFS/lib/modules/"
DEVURANDOM="$ROOTFS/dev/urandom"

# Kernel variables
KERNELVERSION="mainline_hardened_ofl"
KERNELPATH="linux"
export INSTALL_MOD_PATH="../$ROOTFS/"

# Macbook 2015-2017 SPI keyboard driver
#MACBOOKSPI="macbook12-spi-driver"

# Build threads equall CPU cores
THREADS=$(getconf _NPROCESSORS_ONLN)

echo "      ____________  "
echo "    /|------------| "
echo "   /_|  .---.     | "
echo "  |    /     \    | "
echo "  |    \.6-6./    | "
echo "  |    /\`\_/\`\    | "
echo "  |   //  _  \\\   | "
echo "  |  | \     / |  | "
echo "  | /\`\_\`>  <_/\`\ | "
echo "  | \__/'---'\__/ | "
echo "  |_______________| "
echo "                    "
echo "   OneFileLinux.efi "


# buildroot/linux
# Use 'Make menuconfig' to configure buildroot and linux to your liking or select a .config in cfg/
# cd buildroot; make -j$THREADS
# run kernel-hardening-checker if needed.
#./kernel-hardening-checker/bin/kernel-hardening-checker -c cfg/linux_x86_64 -l /proc/cmdline -s kernel-hardening-checker/kernel_hardening_checker/config_files/distros/example_sysctls.txt
# configure and hopefully run - well that was the plan anyway.

#
if [ ! -e $BUILDROOT/.config ]; then
    echo -e "ERROR: no buildroot/.config found, copy "$(PWD)"/cfg/buildroot_x86_64 or run 'make manuconfig' in buildroot to create your own!"
    exit 1
 else
# this was supposed to be a setup file
. setup.sh

# I guess this is where it get's interesting
#
# Build memory safe llvm musl and friends
if  [ $USE_FILC != 'false' ]; then
cd $LLVM_DELUGE_DIR
./setup_gits.sh
#./build_all.sh
./build_all_fast.sh
./build_zlib.sh
./build_bzip2.sh
./build_xz.sh
./build_jpeg-6b.sh
./build_openssl.sh
./build_curl.sh
./build_openssh.sh
./build_cpython.sh
./build_zsh.sh
fi
# Buildroot - Still to figure out conifg
cd $BUILDROOT; make -j$THREADS
# pkgsrc - uuhm, chroot to buildroot output dir and build?
# cd $OFL_ROOT
# ./build_pkgsrc.sh
fi

#
#

##########################
# Checking root filesystem
##########################

echo "----------------------------------------------------"
echo -e "Checking root filesystem\n"

# Clearing apk cache 
if [ "$(ls -A $CACHEPATH)" ]; then 
    echo -e "Apk cache folder is not empty: $CACHEPATH \nRemoving cache...\n"
    rm $CACHEPATH*
fi

# Remove shell history
if [ -f $SHELLHISTORY ]; then
    echo -e "Shell history found: $SHELLHISTORY \nRemoving history file...\n"
    rm $SHELLHISTORY
fi

# Clearing kernel modules folder 
if [ "$(ls -A $MODULESPATH)" ]; then 
    echo -e "Kernel modules folder is not empty: $MODULESPATH \nRemoving modules...\n"
    rm -r $MODULESPATH*
fi

# Removing dev bindings
if [ -e $DEVURANDOM ]; then
    echo -e "/dev/ bindings found: $DEVURANDOM. Unmounting...\n"
    umount $DEVURANDOM || echo -e "Not mounted. \n"
    rm $DEVURANDOM
fi


# Check if console character file exist
if [ ! -e $DEVCONSOLE ]; then
    echo -e "ERROR: Console device does not exist: $DEVCONSOLE \nPlease create device file:  mknod -m 600 $DEVCONSOLE c 5 1"
    exit 1
else
    if [ -d $DEVCONSOLE ]; then # Check that console device is not a folder 
        echo -e  "ERROR: Console device is a folder: $DEVCONSOLE \nPlease create device file:  mknod -m 600 $DEVCONSOLE c 5 1"
        exit 1
    fi

    if [ -f $DEVCONSOLE ]; then # Check that console device is not a regular file
        echo -e "ERROR: Console device is a regular: $DEVCONSOLE \nPlease create device file:  mknod -m 600 $DEVCONSOLE c 5 1"
    fi
fi

# Print version from /etc/issue
echo -n "Version in banner: " 
grep -Eo "v[0-9\.]+" $ROOTFS/etc/issue

# Print rootfs uncompressed size
echo -e "Uncompressed root filesystem size WITHOUT kernel modules: $(du -sh $ROOTFS | cut -f1)\n"


##########################
# Bulding kernel modules
##########################

echo "----------------------------------------------------"
echo -e "Building kernel mobules using $THREADS threads...\n"
cd $KERNELPATH 
make modules -j$THREADS

# Building macbook SPI keybaord driver
#echo -e "\nBuilding Macbook SPI keybaord driver...\n"
#cd ../$MACBOOKSPI
#make clean
#make KDIR=../$KERNELPATH
#cd ../$KERNELPATH

# Copying kernel modules in root filesystem
echo "----------------------------------------------------"
echo -e "Copying kernel modules in root filesystem\n"
make modules_install
# macbook spi keyboard driver
#cd ../$MACBOOKSPI
#make KDIR=../$KERNELPATH install
#cd ../$KERNELPATH

echo -e "Uncompressed root filesystem size WITH kernel modules: $(du -sh ../$ROOTFS | cut -f1)\n"


# Creating modules.dep
echo "----------------------------------------------------"
echo -e "Copying modules.dep\n"
depmod -b ../$ROOTFS -F System.map $KERNELVERSION

##########################
# Bulding kernel
##########################

echo "----------------------------------------------------"
echo -e "Building kernel with initrams using $THREADS threads...\n"
make -j$THREADS


##########################
# Get builded file
##########################

cp arch/x86/boot/bzImage ../OneFileLinux.efi
cd ..

echo "----------------------------------------------------"
echo -e "\nBuilded successfully: $(pwd)/OneFileLinux.efi\n"
echo -e "File size: $(du -sh OneFileLinux.efi | cut -f1)\n"
