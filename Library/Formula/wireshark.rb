require "formula"

class Wireshark < Formula
  homepage "https://www.wireshark.org"

  stable do
    url "https://www.wireshark.org/download/src/all-versions/wireshark-1.12.2.tar.bz2"
    mirror "https://1.eu.dl.wireshark.org/src/wireshark-1.12.2.tar.bz2"
    sha1 "0598fe285725f97045d7d08e6bde04686044b335"

    # Removes SDK checks that prevent the build from working on CLT-only systems
    # Reported upstream: https://bugs.wireshark.org/bugzilla/show_bug.cgi?id=9290
    patch :DATA
  end

  bottle do
    revision 2
    sha1 "6f7662eeef5a2827e65717725dcfc6f035104d27" => :yosemite
    sha1 "4132e4ced51696ff52513ec55d5be79754f58d95" => :mavericks
    sha1 "d9dee8926b364e76420aef082c17370fd65f72ac" => :mountain_lion
  end

  head do
    url "https://code.wireshark.org/review/wireshark", :using => :git

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  devel do
    url "https://www.wireshark.org/download/src/all-versions/wireshark-1.99.0.tar.bz2"
    mirror "https://1.eu.dl.wireshark.org/src/wireshark-1.99.0.tar.bz2"
    sha1 "2e5cf3209104b98251350b3a5e52401866916aec"
  end

  option "with-gtk+3", "Build the wireshark command with gtk+3"
  option "with-gtk+", "Build the wireshark command with gtk+"
  option "with-qt", "Build the wireshark-qt command (can be used with or without either GTK option)"
  option "with-headers", "Install Wireshark library headers for plug-in development"
  option "with-app", "Build a .app bundle"

  depends_on "pkg-config" => :build

  depends_on "glib"
  depends_on "gnutls"
  depends_on "libgcrypt"
  depends_on "d-bus"

  depends_on "geoip" => :recommended
  depends_on "c-ares" => :recommended

  depends_on "libsmi" => :optional
  depends_on "lua" => :optional
  depends_on "portaudio" => :optional
  depends_on "qt" => :optional
  depends_on "gtk+3" => :optional
  depends_on "gtk+" => :optional
  depends_on "homebrew/dupes/libpcap" => :optional
  depends_on "gnome-icon-theme" if build.with? "gtk+3"
  depends_on "platypus" => :build if build.with? "app"

  def install
    args = ["--disable-dependency-tracking",
            "--disable-silent-rules",
            "--prefix=#{prefix}",
            "--with-gnutls"]

    args << "--disable-wireshark" if build.without?("gtk+3") && build.without?("qt") && build.without?("gtk+")
    args << "--disable-gtktest" if build.without?("gtk+3") && build.without?("gtk+")
    args << "--with-qt" if build.with? "qt"
    args << "--with-gtk3" if build.with? "gtk+3"
    args << "--with-gtk2" if build.with? "gtk+"
    args << "--with-libcap=#{Formula["libpcap"].opt_prefix}" if build.with? "libpcap"

    if build.head?
      args << "--disable-warnings-as-errors"
      system "./autogen.sh"
    end

    system "./configure", *args
    system "make"
    ENV.deparallelize # parallel install fails
    system "make", "install"

    if build.with? "headers"
      (include/"wireshark").install Dir["*.h"]
      (include/"wireshark/epan").install Dir["epan/*.h"]
      (include/"wireshark/epan/crypt").install Dir["epan/crypt/*.h"]
      (include/"wireshark/epan/dfilter").install Dir["epan/dfilter/*.h"]
      (include/"wireshark/epan/dissectors").install Dir["epan/dissectors/*.h"]
      (include/"wireshark/epan/ftypes").install Dir["epan/ftypes/*.h"]
      (include/"wireshark/epan/wmem").install Dir["epan/wmem/*.h"]
      (include/"wireshark/wiretap").install Dir["wiretap/*.h"]
      (include/"wireshark/wsutil").install Dir["wsutil/*.h"]
    end

    if build.with? "app"
      inreplace "packaging/macosx/Resources/script", "$CWD/bin/wireshark", "#{bin}/wireshark"
      inreplace "packaging/macosx/Resources/script", "test", "#test"
      system "platypus",
        "-a", "Wireshark",
        "-o", "None",
        "-i", "packaging/macosx/Resources/Wireshark.icns",
        "-Q", "packaging/macosx/Resources/Wiresharkdoc.icns",
        "-p", "/bin/sh",
        "-V", "version",
        "-u", "Copyright 1998-2014 Wireshark Development Team",
        "-I", "org.wireshark.Wireshark",
        "-X", "pcap|pcapng|ntar",
        "-G", "-l", "-x", "-R", "-D",
        "packaging/macosx/Resources/script",
        "#{prefix}/Wireshark.app"
    end
  end

  def caveats; <<-EOS.undent
    If your list of available capture interfaces is empty
    (default OS X behavior), try the following commands:

      curl https://bugs.wireshark.org/bugzilla/attachment.cgi?id=3373 -o ChmodBPF.tar.gz
      tar zxvf ChmodBPF.tar.gz
      open ChmodBPF/Install\\ ChmodBPF.app

    This adds a launch daemon that changes the permissions of your BPF
    devices so that all users in the 'admin' group - all users with
    'Allow user to administer this computer' turned on - have both read
    and write access to those devices.

    See bug report:
      https://bugs.wireshark.org/bugzilla/show_bug.cgi?id=3760
    EOS
  end

  test do
    system "#{bin}/randpkt", "-b", "100", "-c", "2", "capture.pcap"
    output = shell_output("#{bin}/capinfos -Tmc capture.pcap")
    assert_equal "File name,Number of packets\ncapture.pcap,2\n", output
  end
end

__END__
diff --git a/configure b/configure
index cd41b63..c473fe7 100755
--- a/configure
+++ b/configure
@@ -16703,42 +16703,12 @@ $as_echo "yes" >&6; }
 				break
 			fi
 		done
-		if test -z "$SDKPATH"
-		then
-			{ $as_echo "$as_me:${as_lineno-$LINENO}: result: no" >&5
-$as_echo "no" >&6; }
-			as_fn_error $? "We couldn't find the SDK for OS X $deploy_target" "$LINENO" 5
-		fi
 		{ $as_echo "$as_me:${as_lineno-$LINENO}: result: yes" >&5
 $as_echo "yes" >&6; }
 		;;
 	esac

 	#
-	# Add a -mmacosx-version-min flag to force tests that
-	# use the compiler, as well as the build itself, not to,
-	# for example, use compiler or linker features not supported
-	# by the minimum targeted version of the OS.
-	#
-	# Add an -isysroot flag to use the SDK.
-	#
-	CFLAGS="-mmacosx-version-min=$deploy_target -isysroot $SDKPATH $CFLAGS"
-	CXXFLAGS="-mmacosx-version-min=$deploy_target -isysroot $SDKPATH $CXXFLAGS"
-	LDFLAGS="-mmacosx-version-min=$deploy_target -isysroot $SDKPATH $LDFLAGS"
-
-	#
-	# Add a -sdkroot flag to use with osx-app.sh.
-	#
-	OSX_APP_FLAGS="-sdkroot $SDKPATH"
-
-	#
-	# XXX - do we need this to build the Wireshark wrapper?
-	# XXX - is this still necessary with the -mmacosx-version-min
-	# flag being set?
-	#
-	OSX_DEPLOY_TARGET="MACOSX_DEPLOYMENT_TARGET=$deploy_target"
-
-	#
 	# In the installer package XML file, give the deployment target
 	# as the minimum version.
 	#

