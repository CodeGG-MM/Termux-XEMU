#!/data/data/com.termux/files/usr/bin/bash

set -e

clear 2>/dev/null || true

apt update -y && \
yes | apt upgrade -y && \
yes | apt install -y x11-repo tur-repo && \
yes | apt install -y git build-essential sdl2 libepoxy libpixman gtk3 libsamplerate libpcap ninja python-pip libslirp binutils pkg-config cmake xorgproto vulkan-headers libglvnd-dev wget ca-certificates termux-x11-nightly bsdtar xz-utils termux-create-package && \
pip install pyyaml

set -ux

mkdir -p build-xemu

cd build-xemu

CURRENT_DIR="$(pwd)"

rm -rf termux-packages xemu _lib

[ -f .termux-packages.backup ] || { git clone https://github.com/termux/termux-packages termux-packages.backup || { rm -rf termux-packages.backup && exit 1; }; }

touch .termux-packages.backup

(cd termux-packages.backup; git pull || true)

cp -rf termux-packages.backup termux-packages

[ -f .xemu.backup ] || { git clone --recursive https://github.com/xemu-project/xemu xemu.backup || { rm -rf xemu.backup && exit 1; }; }

touch .xemu.backup

cp -rf xemu.backup xemu

#(cd xemu; git reset --hard 98a03e944c5d4c9f3f4973a51bf3b707819d1a89)

# Patch 1
patch -p1 -d xemu <<< '
--- xemu/util/async-teardown.c	2024-12-25 03:20:11.561540567 +0530
+++ xemu.mod/util/async-teardown.c	2024-12-25 12:14:32.785528336 +0530
@@ -39,13 +39,13 @@
     int fd, dfd;
     DIR *dir;
 
-#ifdef CONFIG_CLOSE_RANGE
-    int r = close_range(0, ~0U, 0);
-    if (!r) {
-        /* Success, no need to try other ways. */
-        return;
-    }
-#endif
+//#ifdef CONFIG_CLOSE_RANGE
+//    int r = close_range(0, ~0U, 0);
+//    if (!r) {
+//        /* Success, no need to try other ways. */
+//        return;
+//    }
+//#endif
 
     dir = opendir("/proc/self/fd");
     if (!dir) {
'

# Patch 2
patch -p1 -d xemu <<< '
--- xemu/crypto/random-platform.c	2024-12-25 03:20:10.865540567 +0530
+++ xemu.mod/crypto/random-platform.c	2024-12-25 12:11:03.397528416 +0530
@@ -44,14 +44,14 @@
         return -1;
     }
 #else
-# ifdef CONFIG_GETRANDOM
-    if (getrandom(NULL, 0, 0) == 0) {
-        /* Use getrandom() */
-        fd = -1;
-        return 0;
-    }
-    /* Fall through to /dev/urandom case.  */
-# endif
+//# ifdef CONFIG_GETRANDOM
+//    if (getrandom(NULL, 0, 0) == 0) {
+//        /* Use getrandom() */
+//        fd = -1;
+//        return 0;
+//    }
+//    /* Fall through to /dev/urandom case.  */
+//# endif
     fd = open("/dev/urandom", O_RDONLY | O_CLOEXEC);
     if (fd == -1 && errno == ENOENT) {
         fd = open("/dev/random", O_RDONLY | O_CLOEXEC);
@@ -75,24 +75,24 @@
         return -1;
     }
 #else
-# ifdef CONFIG_GETRANDOM
-    if (likely(fd < 0)) {
-        while (1) {
-            ssize_t got = getrandom(buf, buflen, 0);
-            if (likely(got == buflen)) {
-                return 0;
-            }
-            if (got >= 0) {
-                buflen -= got;
-                buf += got;
-            } else if (errno != EINTR) {
-                error_setg_errno(errp, errno, "getrandom");
-                return -1;
-            }
-        }
-    }
-    /* Fall through to /dev/urandom case.  */
-# endif
+//# ifdef CONFIG_GETRANDOM
+//    if (likely(fd < 0)) {
+//        while (1) {
+//            ssize_t got = getrandom(buf, buflen, 0);
+//            if (likely(got == buflen)) {
+//                return 0;
+//            }
+//            if (got >= 0) {
+//                buflen -= got;
+//                buf += got;
+//            } else if (errno != EINTR) {
+//                error_setg_errno(errp, errno, "getrandom");
+//                return -1;
+//            }
+//        }
+//    }
+//    /* Fall through to /dev/urandom case.  */
+//# endif
     while (1) {
         ssize_t got = read(fd, buf, buflen);
         if (likely(got == buflen)) {
'

# Patch 3
patch -p1 -d xemu <<< '
--- xemu/block/file-posix.c	2024-12-25 03:20:10.825540567 +0530
+++ xemu.mod/block/file-posix.c	2024-12-25 19:47:19.981517973 +0530
@@ -1792,37 +1792,76 @@
 }
 #endif
 
+//static int handle_aiocb_copy_range(void *opaque)
+//{
+//    RawPosixAIOData *aiocb = opaque;
+//    uint64_t bytes = aiocb->aio_nbytes;
+//    off_t in_off = aiocb->aio_offset;
+//    off_t out_off = aiocb->copy_range.aio_offset2;
+//
+//    while (bytes) {
+//        ssize_t ret = copy_file_range(aiocb->aio_fildes, &in_off,
+//                                      aiocb->copy_range.aio_fd2, &out_off,
+//                                      bytes, 0);
+//        trace_file_copy_file_range(aiocb->bs, aiocb->aio_fildes, in_off,
+//                                   aiocb->copy_range.aio_fd2, out_off, bytes,
+//                                   0, ret);
+//        if (ret == 0) {
+//            /* No progress (e.g. when beyond EOF), let the caller fall back to
+//             * buffer I/O. */
+//            return -ENOSPC;
+//        }
+//        if (ret < 0) {
+//            switch (errno) {
+//            case ENOSYS:
+//                return -ENOTSUP;
+//            case EINTR:
+//                continue;
+//            default:
+//                return -errno;
+//            }
+//        }
+//        bytes -= ret;
+//    }
+//    return 0;
+//}
+
 static int handle_aiocb_copy_range(void *opaque)
 {
     RawPosixAIOData *aiocb = opaque;
     uint64_t bytes = aiocb->aio_nbytes;
     off_t in_off = aiocb->aio_offset;
     off_t out_off = aiocb->copy_range.aio_offset2;
+    char buffer[8192]; // Use a buffer for data transfer.
+
+    while (bytes > 0) {
+        size_t to_read = bytes > sizeof(buffer) ? sizeof(buffer) : bytes;
 
-    while (bytes) {
-        ssize_t ret = copy_file_range(aiocb->aio_fildes, &in_off,
-                                      aiocb->copy_range.aio_fd2, &out_off,
-                                      bytes, 0);
-        trace_file_copy_file_range(aiocb->bs, aiocb->aio_fildes, in_off,
-                                   aiocb->copy_range.aio_fd2, out_off, bytes,
-                                   0, ret);
-        if (ret == 0) {
-            /* No progress (e.g. when beyond EOF), let the caller fall back to
-             * buffer I/O. */
+        ssize_t read_bytes = pread(aiocb->aio_fildes, buffer, to_read, in_off);
+        if (read_bytes < 0) {
+            if (errno == EINTR) {
+                continue; // Retry on interrupted system call.
+            }
+            return -errno; // Return negative errno for other errors.
+        }
+        if (read_bytes == 0) {
+            // Reached EOF, let the caller fall back to buffer I/O.
             return -ENOSPC;
         }
-        if (ret < 0) {
-            switch (errno) {
-            case ENOSYS:
-                return -ENOTSUP;
-            case EINTR:
-                continue;
-            default:
-                return -errno;
+
+        ssize_t written_bytes = pwrite(aiocb->copy_range.aio_fd2, buffer, read_bytes, out_off);
+        if (written_bytes < 0) {
+            if (errno == EINTR) {
+                continue; // Retry on interrupted system call.
             }
+            return -errno; // Return negative errno for other errors.
         }
-        bytes -= ret;
+
+        in_off += written_bytes;
+        out_off += written_bytes;
+        bytes -= written_bytes;
     }
+
     return 0;
 }
'

find termux-packages/x11-packages/qemu-system-x86-64 -type f -name "*.patch" -exec sed -i 's#@TERMUX_PREFIX@#/data/data/com.termux/files/usr#g' {} \;

(cd termux-packages/x11-packages/qemu-system-x86-64/setjmp-aarch64; mkdir -p private; for s in $(find . -name "private-*\.h"); do cp ${s} ./$(basename ${s} | sed "s/-/\//g"); done; clang -I. setjmp.S -c; ar cru libandroid-setjmp.a setjmp.o)

_LIB_DIR="$(pwd)/_lib"

mkdir -p "$_LIB_DIR"

mv termux-packages/x11-packages/qemu-system-x86-64/setjmp-aarch64/libandroid-setjmp.a "$_LIB_DIR"

find $(pwd)/termux-packages/x11-packages/qemu-system-x86-64 -type f -name "*.patch" -exec patch -p1 -f -d xemu -i {} \;

(cd termux-packages; git reset --hard a35ea9f5c40e9613cc91af56cc6a15ad9a0cf868)

find $(pwd)/termux-packages/x11-packages/qemu-system-x86-64 -type f -name "*.patch" -exec sed -i 's#@TERMUX_PREFIX@#/data/data/com.termux/files/usr#g' {} \;

patch -p1 -d xemu -i $(pwd)/termux-packages/x11-packages/qemu-system-x86-64/qemu-7.1.0-linux-user-mmap.c.patch

patch -p1 -d xemu -i $(pwd)/termux-packages/x11-packages/qemu-system-x86-64/qemu-7.2.0-linux-user-syscall.c.patch

set +ux

(cd xemu; LDFLAGS=" -landroid-shmem -llog -L$_LIB_DIR -l:libandroid-setjmp.a" ./build.sh)

rm -rf "$CURRENT_DIR/xemu.deb"

TMP_DIR="$(mktemp -d)"; \
( \
cd "$TMP_DIR" && \
wget -O mcpx_1.0.bin "https://archive.org/download/xemustarter/XEMU%20FILES.zip/XEMU%20FILES%2FBoot%20ROM%20Image%2Fmcpx_1.0.bin" && \
wget -O 4627v1.03.bin "https://archive.org/download/xemustarter/XEMU%20FILES.zip/XEMU%20FILES%2FBIOS%2FComplex_4627v1.03.bin" && \
wget -O- https://github.com/xemu-project/xemu-hdd-image/releases/latest/download/xbox_hdd.qcow2.zip | bsdtar -xOf - > xbox_hdd.qcow2 && \
XEMU_VERSION="$("$CURRENT_DIR/xemu/scripts/xemu-version.sh" "$CURRENT_DIR/xemu" | grep " XEMU_VERSION " | sed "s/\"//g" | awk "{print \$NF}")" && \
echo '
{
    "control": {
        "Package": "xemu",
        "Version": "'$(cut -d- -f1<<<$XEMU_VERSION)-$(cut -d- -f2<<<$XEMU_VERSION)~$(cut -d- -f3<<<$XEMU_VERSION)'",
        "Architecture": "aarch64",
        "Maintainer": "George-Seven",
        "Pre-Depends": "x11-repo",
        "Depends": "libpixman, libepoxy, sdl2, libsamplerate, gtk3, zlib, glib, openssl, libslirp, libpcap, libc++, libiconv, libx11, libxext, libxcursor, libxi, libxfixes, libxrandr, libxss, libwayland, libxkbcommon, libdecor, libxcb, libandroid-support, libxau, libxdmcp, libxrender, libffi, pango, harfbuzz, libcairo, fontconfig, fribidi, gdk-pixbuf, at-spi2-core, libxdamage, libxcomposite, libxinerama, libpng, libjpeg-turbo, pcre2, libandroid-shmem, freetype, libexpat, libbz2, brotli, libgraphite, termux-x11-nightly",
        "Homepage": "https://github.com/George-Seven/Termux-XEMU",
        "Description": [
            "A free and open-source emulator for the original Xbox console.",
            " Supports connecting up to 4 controllers for local play, networking for multiplayer, resolution scaling, and more.",
            " Note: Controllers do not work directly on Termux:X11 yet. Try keyboards."
            ]
    },
    "data_files": {
        "bin/xemu": { "source": "'$CURRENT_DIR'/xemu/dist/xemu" },
        "bin/iso2xiso": { "source": "iso2xiso" },
        "share/doc/xemu/LICENSE.txt": { "source": "'$CURRENT_DIR'/xemu/dist/LICENSE.txt" },
        "share/xemu/mcpx_1.0.bin": { "source": "mcpx_1.0.bin" },
        "share/xemu/4627v1.03.bin": { "source": "4627v1.03.bin" },
        "share/xemu/xbox_hdd.qcow2": { "source": "xbox_hdd.qcow2" }
    },
    "deb_name": "xemu.deb"
}
' > manifest.json && \
echo '
mkdir -p "$HOME/.local/share/xemu/xemu"
echo "
[general]
show_welcome = false

[display.debug.video]
x_pos = 1100
y_pos = 30
x_winsize = 180
y_winsize = 60

[sys.files]
bootrom_path = '\''$PREFIX/share/xemu/mcpx_1.0.bin'\''
flashrom_path = '\''$PREFIX/share/xemu/4627v1.03.bin'\''
hdd_path = '\''$PREFIX/share/xemu/xbox_hdd.qcow2'\''
" > "$HOME/.local/share/xemu/xemu/xemu.toml"
' > postinst && \
echo '#!/data/data/com.termux/files/usr/bin/sh

help_text(){
echo " Usage -"
echo
echo "  $(basename "$0") \"/path/to/game.iso\""
echo
}

[ -z "$1" ] && help_text && exit 1

ISO_PATH="$(readlink -f "$1")"

set -e

[ -f "$ISO_PATH" ] || { echo && echo "Error: File not found" && echo && help_text && exit 1; }

ISO_NAME="$(basename "$ISO_PATH")"

if ! echo "$ISO_NAME" | grep -Eq "\.x\.iso$"; then
  dd if="$ISO_PATH" of="$(dirname "$ISO_PATH")/$(echo "$ISO_NAME" | sed -E "s/\.iso$//").x.iso" skip=387 bs=1M
  echo
  echo "Saved to -"
  echo " \"$(dirname "$ISO_PATH")/$(echo "$ISO_NAME" | sed -E "s/\.iso$//").x.iso\""
  echo
else
  echo
  echo "File seems to be XISO"
  echo
fi
' > iso2xiso && \
chmod 755 iso2xiso && \
termux-create-package manifest.json && \
mv xemu.deb "$CURRENT_DIR" \
); \
rm -rf "$TMP_DIR"

cd "$CURRENT_DIR"

apt install -y "$CURRENT_DIR/xemu.deb"

echo
echo "Output debian package -"
echo
echo " \"$CURRENT_DIR/xemu.deb\""
echo
