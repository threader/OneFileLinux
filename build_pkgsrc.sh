#!/bin/bash
# Do i even remember any of this!?
#
BUILDROOT_OUT=$PWD/buildroot/output/staging/

# 
export PKGSRC_COMPILER=cchache clang
export HAVE_LLVM=yes

export HAVE_X11=yes
export X_CFLAGS="-I$BUILDROOT_OUT/usr/include -D_REENTRANT"
export X_LIBS="-Wl,-R$BUILDROOT_OUT/usr/lib -lX11"

cd bootstrap && 
./bootstrap \
--cwrappers=no \
--unprivileged \
--prefix=$BUILDROOT_OUT/usr/pkg \
--pkgdbdir=$BUILDROOT_OUT/usr/pkg/pkgdb \ 
--sysconfdir=$BUILDROOT_OUT/usr/pkg/etc \
--varbase=$BUILDROOT_OUT/usr/var 
