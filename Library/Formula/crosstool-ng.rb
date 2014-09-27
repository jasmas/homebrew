require 'formula'

class CrosstoolNg < Formula
  homepage 'http://crosstool-ng.org'
  url 'http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-1.19.0.tar.bz2'
  sha1 'b7ae3e90756b499ff5362064b7d80f8a45d09bfb'

  depends_on :autoconf
  depends_on :automake
  depends_on :libtool
  depends_on 'coreutils' => :build
  depends_on 'wget'
  depends_on 'gnu-sed'
  depends_on 'gawk'
  depends_on 'binutils'
  depends_on 'libelf'
  depends_on 'grep'

  # Avoid superenv to prevent https://github.com/mxcl/homebrew/pull/10552#issuecomment-9736248
  env :std

  # Fixes clang offsetof compatability. Took better patch from #14547
  patch :DATA

  def install
    system "./configure", "--prefix=#{prefix}",
                          "--exec-prefix=#{prefix}",
                          "--with-objcopy=gobjcopy",
                          "--with-objdump=gobjdump",
                          "--with-readelf=greadelf",
                          "--with-libtool=glibtool",
                          "--with-libtoolize=glibtoolize",
                          "--with-install=ginstall",
                          "--with-sed=gsed",
                          "--with-awk=gawk",
                          "--with-grep=ggrep",
                          "CFLAGS=-std=gnu89"
    # Must be done in two steps
    system "make"
    system "make install"
  end

  def caveats; <<-EOS.undent
    You will need to install modern gcc compiler in order to use this tool.
    EOS
  end

  test do
    system "#{bin}/ct-ng", "version"
  end
end

__END__
diff --git a/kconfig/zconf.gperf b/kconfig/zconf.gperf
index c9e690e..21e79e4 100644
--- a/kconfig/zconf.gperf
+++ b/kconfig/zconf.gperf
@@ -7,6 +7,10 @@
 %pic
 %struct-type

+%{
+#include <stddef.h>
+%}
+
 struct kconf_id;

 static struct kconf_id *kconf_id_lookup(register const char *str, register unsigned int len);

 diff -r fcdf7fc7fd1c -r 0926f7ff958a patches/eglibc/2_17/osx_do_not_redefine_types_sunrpc.patch
--- /dev/null Thu Jan 01 00:00:00 1970 +0000
+++ b/patches/eglibc/2_17/osx_do_not_redefine_types_sunrpc.patch  Tue Mar 26 14:28:49 2013 +0200
@@ -0,0 +1,39 @@
+Apple already defines the u_char, u_short, etc. types in <sys/types.h>.
+However, those are defined directly, without using the __u_char types.
+
+diff -Naur eglibc-2_17-old/sunrpc/rpc/types.h eglibc-2_17-new/sunrpc/rpc/types.h
+--- eglibc-2_17-old/sunrpc/rpc/types.h 2010-08-19 23:32:31.000000000 +0300
++++ eglibc-2_17-new/sunrpc/rpc/types.h 2013-03-26 01:16:16.000000000 +0200
+@@ -69,7 +69,11 @@
+ #include <sys/types.h>
+ #endif
+ 
+-#ifndef __u_char_defined
++/*
++ * OS X already has these <sys/types.h>
++ */
++#ifndef __APPLE__
++# ifndef __u_char_defined
+ typedef __u_char u_char;
+ typedef __u_short u_short;
+ typedef __u_int u_int;
+@@ -77,13 +81,14 @@
+ typedef __quad_t quad_t;
+ typedef __u_quad_t u_quad_t;
+ typedef __fsid_t fsid_t;
+-# define __u_char_defined
+-#endif
+-#ifndef __daddr_t_defined
++#  define __u_char_defined
++# endif
++# ifndef __daddr_t_defined
+ typedef __daddr_t daddr_t;
+ typedef __caddr_t caddr_t;
+-# define __daddr_t_defined
+-#endif
++#  define __daddr_t_defined
++# endif
++#endif /* __APPLE__ */
+ 
+ #include <sys/time.h>
+ #include <sys/param.h>

diff -Naur /dev/null patches/gcc/linaro-4.8-2013.06-1/parallel.patch
--- /dev/null	2014-01-20 22:55:35.000000000 -0500
+++ b/patches/gcc/linaro-4.8-2013.06-1/parallel.patch	2014-01-20 20:15:15.000000000 -0500
@@ -0,0 +1,13 @@
+--- a/gcc/Makefile.in	2013-05-22 02:00:49.000000000 +1000
++++ b/gcc/Makefile.in	2013-06-23 19:00:25.000000000 +1000
+@@ -3801,8 +3801,8 @@ s-gtype: build/gengtype$(build_exeext) $
+ 	$(STAMP) s-gtype
+ 
+ generated_files = config.h tm.h $(TM_P_H) $(TM_H) multilib.h \
+-       $(simple_generated_h) specs.h \
+-       tree-check.h genrtl.h insn-modes.h tm-preds.h tm-constrs.h \
++       $(simple_generated_h) specs.h tree-check.h insn-opinit.h \
++       genrtl.h insn-modes.h tm-preds.h tm-constrs.h \
+        $(ALL_GTFILES_H) gtype-desc.c gtype-desc.h gcov-iov.h
+ 
+ # In order for parallel make to really start compiling the expensive

diff -Naur a/samples/armv6-rpi-linux-gnueabihf/crosstool.config b/samples/armv6-rpi-linux-gnueabihf/crosstool.config
--- a/samples/armv6-rpi-linux-gnueabihf/crosstool.config	1969-12-31 19:00:00.000000000 -0500
+++ b/samples/armv6-rpi-linux-gnueabihf/crosstool.config	2014-01-22 10:24:21.000000000 -0500
@@ -0,0 +1,30 @@
+CT_EXPERIMENTAL=y
+CT_LOCAL_TARBALLS_DIR="${HOME}/src"
+CT_SAVE_TARBALLS=y
+CT_LOG_EXTRA=y
+CT_ARCH_ARCH="armv6zk"
+CT_ARCH_CPU="arm1176jzf-s"
+CT_ARCH_TUNE="arm1176jzf-s"
+CT_ARCH_FPU="vfp"
+CT_ARCH_arm=y
+CT_ARCH_SUFFIX="v6"
+CT_ARCH_ARM_TUPLE_USE_EABIHF=y
+CT_TARGET_VENDOR="rpi"
+CT_KERNEL_linux=y
+CT_BINUTILS_CUSTOM=y
+CT_BINUTILS_CUSTOM_LOCATION="/Users/jasmas/src/binutils-2.24.tar.bz2"
+CT_BINUTILS_LINKER_LD_GOLD=y
+CT_BINUTILS_GOLD_THREADS=y
+CT_BINUTILS_LD_WRAPPER=y
+CT_BINUTILS_PLUGINS=y
+CT_BINUTILS_EXTRA_CONFIG_ARRAY="'CC=gcc-4.8' 'CXX=g++-4.8'"
+CT_CC_GCC_SHOW_LINARO=y
+CT_CC_LANG_CXX=y
+# CT_CC_STATIC_LIBSTDCXX is not set
+CT_CC_GCC_DISABLE_PCH=y
+CT_CC_GCC_BUILD_ID=y
+CT_CC_GCC_LNK_HASH_STYLE_BOTH=y
+CT_EGLIBC_OPT_SIZE=y
+CT_LIBC_GLIBC_KERNEL_VERSION_CHOSEN=y
+CT_LIBC_GLIBC_MIN_KERNEL_VERSION="3.2.27"
+CT_COMPLIBS_CHECK=y
diff -Naur a/samples/armv6-rpi-linux-gnueabihf/reported.by b/samples/armv6-rpi-linux-gnueabihf/reported.by
--- a/samples/armv6-rpi-linux-gnueabihf/reported.by	1969-12-31 19:00:00.000000000 -0500
+++ b/samples/armv6-rpi-linux-gnueabihf/reported.by	2014-01-22 10:25:06.000000000 -0500
@@ -0,0 +1,3 @@
+reporter_name="Jason Masker"
+reporter_url="http://masker.net"
+reporter_comment="custom rpi"
