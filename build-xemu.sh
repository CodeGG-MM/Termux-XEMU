#!/data/data/com.termux/files/usr/bin/bash

set -e

cd "${BASH_SOURCE[0]}"

clear 2>/dev/null || true

apt update -y && \
yes | apt upgrade -y && \
yes | apt install -y git jq

set -ux

CURRENT_DIR="$(pwd)"

TMP_DIR="$(mktemp -d)"

cd "$TMP_DIR"

git clone --depth 1 https://github.com/George-Seven/termux-packages

cd termux-packages

./scripts/setup-termux.sh

./build-package.sh -f -I xemu

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
