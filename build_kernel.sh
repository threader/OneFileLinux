#!/bin/bash

DPKG_BUILD='which dpkg-buildpackage'
# if [ -f $DPKG_BUILD ]; then
#cp $PWD/cfg/buildroot_x86_64_glibc-systemd_2 $PWD/buildroot/.config
if [ ! -f $PWD/buildroot/.config ]; then
echo "no $PWD/buildroot/.config found, copy the corresponding $PWD/cfg/ and try again, bailing"
break
fi

cd $PWD/buildroot; make linux-source; cd ../

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

if [ ! -L $PWD/linux/debian ]; then
# mkdir $PWD/linux/
#echo $PWD
git rm debian
git remote add debian https://salsa.debian.org/kernel-team/linux.git
gif fetch debian
git merge debian/debian/latest --allow-unrelated-histories
#ln -s $PWD/debian/debian/ $PWD/linux/debian
#cd $PWD/linux/debian; git -f fetch; git reset --hard origin/debian/latest; cd../
patch -p1 < $PWD/../../patches/0000_dont_clean_kernel_build_on_error.patch; cd ../
#echo $PWD
# git gc --aggressive --prune=all
fi

# echo $PWD 
# Configure build for the current the running pc/perhapsials 
# cp /boot/config-$(uname -r) $PWD/linux/.config
#make localmodconfig;
#make oldconfig;
ARCH=$(uname -m)

$PWD/kernel-hardening-checker/bin/kernel-hardening-checker -g "${ARCH^^}" > $PWD/cfg/config_harden_fragment
cd $PWD/linux/ && yes "" | make localyesconfig && make menuconfig &&
echo "CONFIG_CMDLINE_BOOL=y" >> .config &&					
echo "CONFIG_CMDLINE="root=/dev/ram0"" >> .config &&
echo "CONFIG_FB_EFI="y"" >> .config &&
cd ../ && $PWD/linux/scripts/kconfig/merge_config.sh -m $PWD/linux/.config $PWD/cfg/config_harden_fragment && mv $PWD/linux/.config $PWD/cfg/current_building_kernel_config;
# $PWD/kernel-hardening-checker/bin/kernel-hardening-checker -c $PWD/cfg/current_building_kernel_config
# make mrproper;

#ROOT_ARCH=`uname -m`
#if [ -f $DPKG_BUILD ]; then
# quilt push -a -f 
# quilt refresh 
# quilt pop -a -f 
# quilt push -a -f 
# make localyesconfig 
# mv .config debian/config/${ARCH}"/yes-config
# cp debian/config/${ARCH}"/config debian/config/${ARCH}"/orig-config
# $PWD/../kernel-hardening-checker/bin/kernel-hardening-checker-g "${ARCH^^}" debian/config/"${ARCH}"/hard-config
# $PWD/linux/scripts/kconfig/merge_config.sh debian/config/${ARCH}"/hard-config debian/config/yes-config
# mv .config debian/config/${ARCH}"/config
## cp debian/config/"${ARCH}"/config debian/config/"${ARCH}"/orig-config
## $PWD/linux/scripts/kconfig/merge_config.sh  debian/config/"${ARCH}" $PWD/../cfg/config_harden_fragment
## mv debian debian.real
# make clean
## make bindeb-pkg
## make deb-pkg 
# MAKEFLAGS="-j$(nproc)" make -f debian/rules.gen binary-arch_amd64 #  binary-indep_none_headers-common binary-arch_amd64_none_amd64_binary
## MAKEFLAGS="-j$(nproc)" dpkg-buildpackage -b -uc
## dpkg-buildpackage -build=binary --no-post-clean
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
