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

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

info "Checking dependencies..."
apt-get install -y live-build curl wget git > /dev/null 2>&1

info "Cleaning previous build state..."
lb clean --purge 2>/dev/null || true

info "Running lb config..."
bash auto/config

info "Running lb build (this takes 30-60 minutes)..."
lb build noauto 2>&1 | tee build.log

ISO=$(ls "$SCRIPT_DIR"/*.iso 2>/dev/null | head -1)
if [ -n "$ISO" ]; then
    info "ISO built: $ISO"
    sha256sum "$ISO" > "${ISO}.sha256"
    info "SHA256: $(cat "${ISO}.sha256")"
else
    die "Build failed -- check $SCRIPT_DIR/build.log"
fi
