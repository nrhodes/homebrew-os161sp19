class Qemu < Formula
  desc "X86 emulator (with changes for running xv6)"
  homepage "https://github.com/geofft/qemu"
  url "https://github.com/geofft/qemu.git", :branch => "6.828-1.7.0"
  # sha256 "7751098f7af62d8997b1798b816fffbdc18aba147512cd09c5477a44f440aa14"
  version "6.828-1.70"
  head "https://github.com/geofft/qemu.git"

  depends_on "libtool" => :build
  depends_on "pkg-config" => :build
  depends_on "glib"
  depends_on "gnutls"
  depends_on "jpeg"
  depends_on :macos => :snow_leopard
  depends_on "ncurses"
  depends_on "pixman"
  depends_on "libpng" => :recommended
  depends_on "libssh2" => :optional
  depends_on "libusb" => :optional

  if OS.mac?
    fails_with :gcc_4_0 do
      cause "qemu requires a compiler with support for the __thread specifier"
    end

    fails_with :gcc do
      cause "qemu requires a compiler with support for the __thread specifier"
    end
  end

  # 820KB floppy disk image file of FreeDOS 1.2, used to test QEMU
  resource "test-image" do
    url "https://dl.bintray.com/homebrew/mirror/FD12FLOPPY.zip"
    sha256 "81237c7b42dc0ffc8b32a2f5734e3480a3f9a470c50c14a9c4576a2561a35807"
  end

  def install
    ENV["LIBTOOL"] = "glibtool"
    ENV["CFLAGS"] = "-fno-common"

    args = %W[
      --prefix=#{prefix}
      --cc=#{ENV.cc}
      --host-cc=#{ENV.cc}
      --disable-bsd-user
      --disable-guest-agent
      --enable-curses
      --extra-cflags=-DNCURSES_WIDECHAR=1
    ]

    if OS.mac?
      args << "--enable-cocoa"

      # Sharing Samba directories in QEMU requires the samba.org smbd which is
      # incompatible with the macOS-provided version. This will lead to
      # silent runtime failures, so we set it to a Homebrew path in order to
      # obtain sensible runtime errors. This will also be compatible with
      # Samba installations from external taps.
      args << "--smbd=#{HOMEBREW_PREFIX}/sbin/samba-dot-org-smbd"
      args << "--disable-sdl"
    end

    args << "--disable-vde"
    args << "--disable-gtk"
    args << "--disable-libssh2"

    system "./configure", *args
    system "make", "V=1", "install"
  end

  test do
    expected = build.stable? ? version.to_s : "QEMU Project"
    assert_match expected, shell_output("#{bin}/qemu-system-i386 --version")
    resource("test-image").stage testpath
    assert_match "file format: raw", shell_output("#{bin}/qemu-img info FLOPPY.img")
  end
end
