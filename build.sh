#!/bin/bash

set -e

# RootFS variables
#ROOTFS="alpine-minirootfs"
BUILDROOT="$PWD/buildroot"
ROOTFS="$PWD/buildroot/output/images/rootfs"
CACHEPATH="$ROOTFS/var/cache/apk/"
SHELLHISTORY="$ROOTFS/root/.ash_history"
DEVCONSOLE="$ROOTFS/dev/console"
MODULESPATH="$ROOTFS/lib/modules/"
DEVURANDOM="$ROOTFS/dev/urandom"

# Kernel variables
KERNELVERSION="mainline-onefile"
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
# run the lk-reducer
# run kernel-hardening-checker if needed.
# build

#
if [ ! -e $BUILDROOT/.config ]; then
    echo -e "ERROR: no buildroot/.config found, check $PWD/cfg or run 'make manuconfig'"
    exit 1
 else
cd $BUILDROOT; make -j$THREADS
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
