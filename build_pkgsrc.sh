#!/bin/bash
# Do i even remember any of this!?
#
BUILDROOT_OUT="$PWD/buildroot/output/staging/"
CFG_DIR="$PWD/cfg/"

echo "PKGSRC_COMPILER=ccache clang" > $(CFG_DIR)/mk_ofl.mk
echo "HAVE_LLVM=yes" >> $(CFG_DIR)/mk_ofl.mk

echo "HAVE_X11=yes" >> $(CFG_DIR)/mk_ofl.mk
echo "X_CFLAGS="-I$(BUILDROOT_OUT)/usr/include -D_REENTRANT"" >> $(CFG_DIR)/mk_ofl.mk
echo "X_LIBS="-Wl,-R$(BUILDROOT_OUT)/usr/lib -lX11"" >> $(CFG_DIR)/mk_ofl.mk

cd pkgsrc/bootstrap && 
./bootstrap \
--cwrappers=no \
--mk-fragment=$(CFG_DIR)/mk_ofl.mk \
--unprivileged \
--prefix=$(BUILDROOT_OUT)/usr/pkg \
--pkgdbdir=$(BUILDROOT_OUT)/usr/pkg/pkgdb \ 
--sysconfdir=$(BUILDROOT_OUT)/usr/pkg/etc \
--varbase=$(BUILDROOT_OUT)/usr/var 
