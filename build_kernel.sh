#!/bin/bash
OLD_PWD=$PWD
DPKG_BUILD='which dpkg-buildpackage'
# if [ -f $DPKG_BUILD ]; then

if [ ! -d $PWD/linux/debian ]; then
ln -s $PWD/debian/debian $PWD/linux/debian
fi

if [ ! -d $PWD/linux/.git ]; then
ln -s $PWD/buildroot/dl/linux/git/.git $PWD/linux/.git
fi

#ROOT_ARCH=`uname -m`
cd linux; git fetch; git reset --hard remotes/origin/linux-rolling-stable
# git gc --aggressive --prune=all

#if [ -f $DPKG_BUILD ]; then
cd linux/debian; git fetch; git reset --hard debian/latest
patch -p1 < $PWD/patches/0000_dont_clean_kernel_build_on_error.patch; 
# git gc --aggressive --prune=all
cd ..
#fi

# Apply Debian patches regardless 
make -f debian/rules source;
# Configure build for the current the running pc/perhapsials 
#make localmodconfig; 
make oldconfig
$PWD/kernel-hardening-checker/bin/kernel-hardening-checker -g X86_64 > $PWD/cfg/config-harden-stub
$PWD/linux/scripts/kconfig/merge_config.sh $PWD/.config $PWD/cfg/config-harden-stub
$PWD/kernel-hardening-checker/bin/kernel-hardening-checker -c $PWD/linux/.config
cp $PWD/linux/.config $PWD/cfg/current_building_kernel_config
# yes ´´ | make menuconfig

#if [ -f $DPKG_BUILD ]; then
# dpkg-buildpackage -us -ui -uc --no-sign --build=binary --no-post-clean
#fi

cd $OLD_PWD/buildroot; make # ./build_buildroot.sh
