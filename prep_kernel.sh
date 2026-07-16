#!/bin/bash
DPKG_BUILD=´which dpkg-buildpackage´
if [ -f $DPKG_BUILD ]; then
ln -s $PWD/debian/debian/ $PWD/linux/debian
fi
ROOT_ARCH=´uname -m´
cd linux; git fetch; git reset --hard remotes/origin/linux-rolling-stable
git gc --aggressive --prune=all
if [ -f $DPKG_BUILD ]; then
cd debian; patch -p1 < ../../patches/0000_dont_clean_kernel_build_on_error.patch; cd ..
make -f debian/rules source; 
fi
make localmodconfig
../kernel-hardening-checker/bin/kernel-hardening-checker -g ${ROOT_ARCH^^} > .config-harden-stub
./scripts/kconfig/merge_config.sh .config .config-harden-stub
../kernel-hardening-checker/bin/kernel-hardening-checker -c .config
if [ -f $DPKG_BUILD ]; then
# dpkg-buildpackage -us -ui -uc --no-sign --build=binary --no-post-clean
fi
