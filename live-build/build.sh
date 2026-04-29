#!/bin/bash
# build.sh — build the darbs live ISO
# must be run as root on a Kali machine
# usage: sudo bash build.sh

set -e

GRN='\033[0;32m'; YLW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info() { echo -e "${GRN}==>${NC} $1"; }
warn() { echo -e "${YLW}[!]${NC} $1"; }
die()  { echo -e "${RED}[x]${NC} $1"; exit 1; }

[ "$EUID" -ne 0 ] && die "Run as root: sudo bash build.sh"

# dependencies
info "Checking dependencies..."
apt-get install -y live-build curl wget git > /dev/null 2>&1

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# copy auto/ and kali-config/ into build dir
cp -r "$SCRIPT_DIR/auto"        "$BUILD_DIR/"
cp -r "$SCRIPT_DIR/kali-config" "$BUILD_DIR/"

# make auto scripts executable
chmod +x "$BUILD_DIR/auto/"*

info "Running lb config..."
"$BUILD_DIR/auto/config"

info "Running lb build (this takes 30-60 minutes)..."
lb build 2>&1 | tee "$BUILD_DIR/build.log"

ISO=$(ls "$BUILD_DIR"/*.iso 2>/dev/null | head -1)
if [ -n "$ISO" ]; then
    info "ISO built: $ISO"
    sha256sum "$ISO" > "${ISO}.sha256"
    info "SHA256: $(cat "${ISO}.sha256")"
else
    die "Build failed -- check $BUILD_DIR/build.log"
fi
