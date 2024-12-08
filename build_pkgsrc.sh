#!/bin/bash
# Do i even remember any of this!?
#
BUILDROOT_OUT="$PWD/buildroot/output/staging/"
CFG_DIR="$PWD/cfg/"

echo "PKGSRC_COMPILER=ccache clang" > $(CFG_DIR)/mk_ofl.mk
echo "HAVE_LLVM=yes" >> $(CFG_DIR)/mk_ofl.mk

echo "CFLAGS="$CFLAGS -march=native -mcpu=native -mtune=native -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3 -D_GLIBCXX_ASSERTIONS -D_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_EXTENSIVE -fstack-clash-protection -param stack-clash-protection-guard-size= 20 -fcf-protection=full -Wl,-z,nodlopen-Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now -fPIE -pie -fPIC -shared -fno-delete-null-pointer-checks -ftrivial-auto-var-init=zero -fexceptions -fhardened -Whardened -Wl,--as-needed -Wl,--no-copy-dt-needed-entries -fsanitize=address -fsanitize=thread -fsanitize=leak -fsanitize=undefined -fsanitize=address -fsanitize=thread --enable-default-pie --enable-default-ssp --enable-host-pie --enable-host-bind-now" "   >> $(CFG_DIR)/mk_ofl.mk
echo "LDFLAGS="$LDFLAGS --disable-default-execstack --enable-warn-execstack --enable-error-execstack --enable-warn-rwx-segments --enable-error-rwx-segments --enable-relro --enable-textrel-check=error" "  >> $(CFG_DIR)/mk_ofl.mk

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
