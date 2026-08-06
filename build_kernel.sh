#!/bin/bash

DPKG_BUILD='which dpkg-buildpackage'
# if [ -f $DPKG_BUILD ]; then
cp $PWD/cfg/buildroot_x86_64_glibc-systemd_2 $PWD/buildroot/.config
cd $PWD/buildroot; make linux-source; cd ../

echo $PWD 

if [ ! -L $PWD/linux ]; then
#mkdir -p $PWD/buildroot/output/build/linux-linux-rolling-stable
mkdir -p $PWD/buildroot/dl/linux/git/.git
mkdir -p $PWD/buildroot/output/build/linux-linux-next-master
#ln -s $PWD/buildroot/dl/linux/git/.git $PWD/buildroot/output/build/linux-linux-rolling-stable/.git
ln -s $PWD/buildroot/output/build/linux-linux-next-master $PWD/linux/
#ln -s $PWD/buildroot/dl/linux/git/.git $PWD/linux/.git

# buildroot/dl/linux/git/.git
#ln -s $PWD/buildroot/output/build/linux-linux-rolling-stable/.git $PWD/linux/.git
cd linux; git clone -b linux-next-master https://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git; git fetch; git reset --hard linux-next-master;
mv .git $PWD/buildroot/dl/linux/git/.git
# git gc --aggressive --prune=all
fi

#echo $PWD 

if [ ! -L $PWD/linux/debian ]; then
# mkdir $PWD/linux/
#echo $PWD 
ln -s $PWD/debian/debian/ $PWD/linux/debian
cd $PWD/linux/debian; git fetch; git reset --hard origin/debian/latest;
#echo $PWD
patch -p1 < $PWD/../../patches/0000_dont_clean_kernel_build_on_error.patch; cd ../../
# git gc --aggressive --prune=all
fi

# echo $PWD 
# Configure build for the current the running pc/perhapsials 
# cp /boot/config-$(uname -r) $PWD/linux/.config
#make localmodconfig;
#make oldconfig;
ARCH=$(uname -m)
# echo $PWD
$PWD/kernel-hardening-checker/bin/kernel-hardening-checker -g "${ARCH^^}" > $PWD/cfg/config_harden_fragment
cd $PWD/linux/ && yes "" | make localyesconfig && cd ../ && $PWD/linux/scripts/kconfig/merge_config.sh -m $PWD/linux/.config $PWD/cfg/config_harden_fragment && mv $PWD/.config $PWD/cfg/current_building_kernel_config;
# $PWD/kernel-hardening-checker/bin/kernel-hardening-checker -c $PWD/cfg/current_building_kernel_config
# make mrproper;

#ROOT_ARCH=`uname -m`
#if [ -f $DPKG_BUILD ]; then
# dpkg-buildpackage -us -ui -uc --no-sign --build=binary --no-post-clean
#fi

# Apply Debian patches regardless 
# echo $PWD
# make -f debian/rules source &&
# git add *; git commit -m "debian and friends";

# git clone https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/; cd linux-firmware; ./copy_packages.py -v /usr/lib/firmware; ../

cd linux/ && make -f debian/rules source; # &&  cp $PWD/../cfg/current_building_kernel_config .config # && make deb-pkg 
# yes ´´ | make localmodconfig && $PWD/../kernel-hardening-checker/bin/kernel-hardening-checker -c $PWD/.config > .config_hard  $PWD/scripts/kconfig/merge_config.sh $PWD/.config
cd ..

# build the buildroot 
cp $PWD/cfg/buildroot_x86_64_glibc-systemd_2 $PWD/buildroot/.config && cd $PWD/buildroot && make linux-build # ./build_buildroot.sh
