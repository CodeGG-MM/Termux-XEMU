#!/data/data/com.termux/files/usr/bin/bash

set -e

cd "$(dirname "${BASH_SOURCE[0]}")"

clear 2>/dev/null || true

apt update -y && \
yes | apt upgrade -y && \
yes | apt install -y git jq termux-exec

set -ux

CURRENT_DIR="$(pwd)"

TMP_DIR="$(mktemp -d)"

cd "$TMP_DIR"

git clone --depth 1 https://github.com/George-Seven/termux-packages

cd termux-packages

./scripts/setup-termux.sh

if [ -z "$LD_PRELOAD" ]; then
    LD_PRELOAD=/data/data/com.termux/files/usr/lib/libtermux-exec.so ./build-package.sh -f -I xemu
else
    ./build-package.sh -f -I xemu
fi

cd "$CURRENT_DIR"

rm -rf "$CURRENT_DIR/xemu.deb"

mv output/*.deb "$CURRENT_DIR/xemu.deb"

cd "$CURRENT_DIR"

rm -rf "$TMP_DIR"

#apt install -y "$CURRENT_DIR/xemu.deb"

echo
echo "Output debian package -"
echo
echo " \"$CURRENT_DIR/xemu.deb\""
echo
