#!/bin/bash

DPKG_BUILD='which dpkg-buildpackage'
# if [ -f $DPKG_BUILD ]; then
cp $PWD/cfg/buildroot_x86_64_glibc-systemd $PWD/buildroot/.config
cd $PWD/buildroot; make linux-source; cd ../

echo $PWD 

if [ ! -L $PWD/linux ]; then
#mkdir -p $PWD/buildroot/output/build/linux-linux-rolling-stable
mkdir -p $PWD/buildroot/dl/linux/git/
#ln -s $PWD/buildroot/dl/linux/git/.git $PWD/buildroot/output/build/linux-linux-rolling-stable/.git
ln -s $PWD/buildroot/dl/linux/git $PWD/linux
# buildroot/dl/linux/git/.git
#ln -s $PWD/buildroot/output/build/linux-linux-rolling-stable/.git $PWD/linux/.git
cd linux; git fetch; git reset --hard origin/linux-rolling-stable;
# git gc --aggressive --prune=all
fi

echo $PWD 

if [ ! -L $PWD/linux/debian ]; then
# mkdir $PWD/linux/
echo $PWD 
ln -s $PWD/debian/debian/ $PWD/linux/debian
cd $PWD/linux/debian; git fetch; git reset --hard origin/debian/7.1/forky; cd ../../ # debian/latest
echo $PWD
cd $PWD/linux/debian; patch -p1 < $PWD/../../patches/0000_dont_clean_kernel_build_on_error.patch; cd ../../
# git gc --aggressive --prune=all
fi

echo $PWD 
# Configure build for the current the running pc/perhapsials 
cp /boot/config-$(uname -r) $PWD/linux/.config
#make localmodconfig;
#make oldconfig;
ARCH=$(uname -m)
echo $PWD
$PWD/kernel-hardening-checker/bin/kernel-hardening-checker -g "${ARCH^^}" > $PWD/cfg/config_harden_fragment
$PWD/linux/scripts/kconfig/merge_config.sh $PWD/linux/.config $PWD/cfg/config_harden_fragment
$PWD/kernel-hardening-checker/bin/kernel-hardening-checker -c $PWD/linux/.config
cd $PWD/linux/ && yes ´´ | make localmodconfig && echo "CONFIG_PROFILING=n" >> $PWD/.config && cp $PWD/.config $PWD/../cfg/current_building_kernel_config && make mrproper;

#ROOT_ARCH=`uname -m`
#if [ -f $DPKG_BUILD ]; then
# dpkg-buildpackage -us -ui -uc --no-sign --build=binary --no-post-clean
#fi

# Apply Debian patches regardless 
echo $PWD
make -f debian/rules source &&
git add *; git commit -m "debian and friends";
cp $PWD/../cfg/buildroot_x86_64_glibc-systemd $PWD/../buildroot/.config; cp $PWD/../cfg/current_building_kernel_config $PWD/.confg; make linux-build # ./build_buildroot.sh
