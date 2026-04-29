#!/bin/bash
# build-slim.sh — build a minimal darbs ISO (~1.5GB target)
# usage: sudo bash build-slim.sh

set -e

GRN='\033[0;32m'; YLW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info() { echo -e "${GRN}==>${NC} $1"; }
die()  { echo -e "${RED}[x]${NC} $1"; exit 1; }

[ "$EUID" -ne 0 ] && die "Run as root: sudo bash build-slim.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

info "Checking dependencies..."
apt-get install -y live-build curl wget git > /dev/null 2>&1

info "Cleaning previous build state..."
lb clean --purge 2>/dev/null || true

info "Running lb config (slim)..."
lb config noauto \
    --apt-indices false \
    --apt-recommends false \
    --apt-secure false \
    --architectures amd64 \
    --archive-areas "main contrib non-free non-free-firmware" \
    --binary-images iso-hybrid \
    --bootappend-live "boot=live components username=darbs hostname=darbs i8042.reset i8042.nomux i8042.nopnp i8042.noloop" \
    --bootloaders grub-efi \
    --checksums sha256 \
    --debian-installer none \
    --debootstrap-options "--keyring=/usr/share/keyrings/kali-archive-keyring.gpg" \
    --distribution kali-rolling \
    --image-name "darbs-slim" \
    --iso-application "darbs-slim" \
    --iso-publisher "darbs" \
    --iso-volume "darbs-slim" \
    --mirror-bootstrap http://http.kali.org/kali \
    --mirror-chroot http://http.kali.org/kali \
    --mirror-binary http://http.kali.org/kali \
    --mirror-binary-security http://http.kali.org/kali \
    --parent-mirror-bootstrap http://http.kali.org/kali \
    --parent-mirror-chroot http://http.kali.org/kali \
    --parent-mirror-binary http://http.kali.org/kali \
    --parent-mirror-binary-security http://http.kali.org/kali \
    --security false \
    --updates false \
    --source false

info "Syncing config into live-build tree..."
cp -r kali-config/common/hooks/.          config/hooks/
cp -r kali-config/common/includes.chroot/. config/includes.chroot/
cp -r kali-config/slim/package-lists/.    config/package-lists/

info "Running lb build (slim — 20-40 min)..."
lb build noauto 2>&1 | tee build-slim.log

ISO=$(ls "$SCRIPT_DIR"/darbs-slim*.iso 2>/dev/null | head -1)
if [ -n "$ISO" ]; then
    info "ISO built: $ISO"
    sha256sum "$ISO" > "${ISO}.sha256"
else
    die "Build failed -- check $SCRIPT_DIR/build-slim.log"
fi
