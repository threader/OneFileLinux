#!/bin/bash
DPKG_BUILD=´which dpkg-buildpackage´
# if [ -f $DPKG_BUILD ]; then
ln -s $PWD/debian/debian/ $PWD/linux/debian
# fi

ROOT_ARCH=´uname -m´
cd linux; git fetch; git reset --hard remotes/origin/linux-rolling-stable
# git gc --aggressive --prune=all

#if [ -f $DPKG_BUILD ]; then
cd debian; git fetch; git reset --hard debian/latest
patch -p1 < ../../patches/0000_dont_clean_kernel_build_on_error.patch; 
# git gc --aggressive --prune=all
cd ..
#fi

# Apply Debian patches regardless 
make -f debian/rules source;
# Configure build for the current the running pc/perhapsials 
make localmodconfig
../kernel-hardening-checker/bin/kernel-hardening-checker -g ${ROOT_ARCH^^} > .config-harden-stub
./scripts/kconfig/merge_config.sh .config .config-harden-stub
../kernel-hardening-checker/bin/kernel-hardening-checker -c .config
cp .config ../cfg/current_building_kernel_config
yes ´´ | make menuconfig

if [ -f $DPKG_BUILD ]; then
# dpkg-buildpackage -us -ui -uc --no-sign --build=binary --no-post-clean
fi

