#!/bin/bash
# darbs-setup.sh — full darbs setup on a fresh Kali install
# run as your regular user (not root), script will sudo when needed
# usage: bash darbs-setup.sh

GRN='\033[0;32m'; YLW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info() { echo -e "\n${GRN}==>${NC} $1"; }
ok()   { echo -e "  ${GRN}[OK]${NC}   $1"; }
skip() { echo -e "  ${YLW}[SKIP]${NC} $1 -- $2"; }
warn() { echo -e "  ${YLW}[!]${NC}   $1"; }
die()  { echo -e "${RED}[x]${NC} $1"; exit 1; }

try() {
    local desc="$1"; shift
    if "$@" 2>/dev/null; then ok "$desc"
    else skip "$desc" "failed, continuing"; fi
}

[ "$EUID" -eq 0 ] && die "Run as your regular user, not root."
command -v apt-get &>/dev/null || die "This script requires a Debian/Kali system."

WALL_DIR="/usr/share/backgrounds/darbs"
CONFIG="$HOME/.config"
THEMES_DIR="/usr/share/themes"
USER_THEMES="$HOME/.themes"

# ── 1. BASE PACKAGES ───────────────────────────────────────────────────────────
info "Installing base packages..."
sudo apt-get update -q
sudo apt-get install -y \
    xfce4-whiskermenu-plugin xfce4-genmon-plugin xfce4-battery-plugin \
    xfce4-pulseaudio-plugin xfce4-netload-plugin network-manager-gnome \
    tmux git curl wget imagemagick \
    fonts-jetbrains-mono fonts-unifont papirus-icon-theme \
    fastfetch plymouth plymouth-themes \
    python3-pip python3-venv ruby-full \
    jq fzf htop unzip p7zip-full bat ripgrep \
    squashfs-tools 2>/dev/null || warn "Some packages failed to install, continuing."

# ── 2. EVERFOREST GTK THEME ────────────────────────────────────────────────────
info "Installing Everforest GTK theme..."
mkdir -p "$USER_THEMES"
if [ ! -d "$USER_THEMES/Everforest-Dark-BL" ]; then
    if git clone --depth=1 https://github.com/Fausto-Korpsvart/Everforest-GTK-Theme /tmp/everforest-gtk 2>/dev/null; then
        cp -r /tmp/everforest-gtk/themes/Everforest-Dark-BL "$USER_THEMES/"
        sudo cp -r /tmp/everforest-gtk/themes/Everforest-Dark-BL "$THEMES_DIR/" 2>/dev/null || true
        rm -rf /tmp/everforest-gtk
        ok "Everforest GTK theme installed"
    else
        skip "Everforest GTK theme" "git clone failed"
    fi
else
    ok "Everforest GTK theme already present"
fi

# ── 3. PAPIRUS FOLDERS ─────────────────────────────────────────────────────────
info "Configuring Papirus icon theme..."
if command -v papirus-folders &>/dev/null; then
    try "papirus green folders" papirus-folders -C green --theme Papirus-Dark
else
    skip "papirus-folders" "not installed"
fi

# ── 4. WALLPAPERS ──────────────────────────────────────────────────────────────
info "Downloading wallpapers..."
sudo mkdir -p "$WALL_DIR"
sudo chmod 755 "$WALL_DIR"
BASE="https://raw.githubusercontent.com/cyberdiary2/dotfiles/main/wallpapers"
WALLS=(0001 0002 0003 0005 0006 0007 0008 0010 0014 0016 0017 0018 0019 0020
       0021 0022 0023 0024 0025 0026 0028 0031 0032 0036 0038 0039 0040 0041
       0042 0044 0045 0046 0051 0052 0054 0055 0057 0066 0067 0069 0070 0073
       0078 0112 0327)
DL=0
for w in "${WALLS[@]}"; do
    dest="$WALL_DIR/${w}.jpg"
    [ -f "$dest" ] && DL=$((DL+1)) && continue
    sudo curl -sL "$BASE/${w}.jpg" -o "$dest" 2>/dev/null && DL=$((DL+1)) || sudo rm -f "$dest" 2>/dev/null
done
ok "wallpapers: $DL / ${#WALLS[@]}"
WALLPAPER="$WALL_DIR/0001.jpg"
sudo chmod 644 "$WALL_DIR"/*.jpg 2>/dev/null || true

# greeter wallpaper
sudo mkdir -p /usr/share/backgrounds/everforest
[ -f "$WALLPAPER" ] && sudo cp "$WALLPAPER" /usr/share/backgrounds/everforest/greeter.jpg && \
    sudo chmod 644 /usr/share/backgrounds/everforest/greeter.jpg

# ── 5. XFCE4-TERMINAL ──────────────────────────────────────────────────────────
info "Configuring xfce4-terminal..."
mkdir -p "$CONFIG/xfce4/terminal"
cat > "$CONFIG/xfce4/terminal/terminalrc" << 'EOF'
[Configuration]
FontName=JetBrains Mono 11
MiscAlwaysShowTabs=FALSE
MiscBell=FALSE
MiscCursorBlinks=TRUE
MiscCursorShape=TERMINAL_CURSOR_SHAPE_BLOCK
MiscDefaultGeometry=100x30
MiscMenubarDefault=FALSE
BackgroundMode=TERMINAL_BACKGROUND_TRANSPARENT
BackgroundDarkness=0.80
ColorForeground=#a7c080
ColorBackground=#1b2421
ColorCursor=#a7c080
ColorCursorForeground=#1b2421
ColorBold=#d3c6aa
ColorPalette=#1b2421;#e67e80;#a7c080;#dbbc7f;#7fbbb3;#d699b6;#83c092;#d3c6aa;#475258;#e67e80;#a7c080;#dbbc7f;#7fbbb3;#d699b6;#83c092;#d3c6aa
EOF
ok "xfce4-terminal configured"

# ── 6. TMUX ────────────────────────────────────────────────────────────────────
info "Configuring tmux + TPM..."
mkdir -p "$HOME/.tmux/plugins"
[ ! -d "$HOME/.tmux/plugins/tpm" ] && \
    git clone --depth=1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" 2>/dev/null || true

cat > "$HOME/.tmux.conf" << 'EOF'
set -g default-terminal "tmux-256color"
set -as terminal-overrides ",xterm*:Tc"
set -g base-index 1
setw -g pane-base-index 1
set -g history-limit 10000
set -g mouse on
set -g escape-time 0
set -g renumber-windows on
unbind C-b
set -g prefix C-a
bind C-a send-prefix
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind r source-file ~/.tmux.conf \; display "config reloaded"
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R
set -g status on
set -g status-interval 5
set -g status-position bottom
set -g status-style "bg=#2d353b fg=#d3c6aa"
set -g status-left-length 50
set -g status-left "#[bg=#a7c080,fg=#2d353b,bold]  #S #[bg=#3d484d,fg=#a7c080]#[bg=#3d484d,fg=#859289] #(whoami) #[bg=#2d353b,fg=#3d484d] "
set -g status-right-length 140
set -g status-right "#[fg=#3d484d,bg=#2d353b]#[bg=#3d484d,fg=#83c092]  #{cpu_percentage} #[fg=#475258,bg=#3d484d]#[bg=#475258,fg=#dbbc7f] #{battery_percentage} #[fg=#a7c080,bg=#475258]#[bg=#a7c080,fg=#2d353b,bold]  %a %b %d  %H:%M "
set -g window-status-format "  #[fg=#859289]#I #W  "
set -g window-status-current-format "#[bg=#3d484d,fg=#2d353b]#[bg=#3d484d,fg=#a7c080,bold] #I #W #[bg=#2d353b,fg=#3d484d]"
set -g pane-border-style "fg=#3d484d"
set -g pane-active-border-style "fg=#a7c080"
set -g message-style "bg=#a7c080 fg=#2d353b bold"
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-cpu'
set -g @plugin 'tmux-plugins/tmux-battery'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-yank'
set -g @resurrect-capture-pane-contents 'on'
run '~/.tmux/plugins/tpm/tpm'
EOF

"$HOME/.tmux/plugins/tpm/bin/install_plugins" > /dev/null 2>&1 && ok "tmux plugins installed" || \
    skip "tmux plugins" "run prefix+I inside tmux manually"

# ── 7. GTK THEME ───────────────────────────────────────────────────────────────
info "Applying GTK theme..."
xfconf-query -c xsettings -p /Net/ThemeName      -s "Everforest-Dark-BL" 2>/dev/null || true
xfconf-query -c xsettings -p /Net/IconThemeName   -s "Papirus-Dark"       2>/dev/null || true
xfconf-query -c xsettings -p /Gtk/FontName        -s "Noto Sans 10"       2>/dev/null || true
xfconf-query -c xsettings -p /Gtk/CursorThemeName -s "Adwaita"            2>/dev/null || true

mkdir -p "$CONFIG/gtk-3.0" "$CONFIG/gtk-4.0"
cat > "$CONFIG/gtk-3.0/settings.ini" << 'EOF'
[Settings]
gtk-theme-name=Everforest-Dark-BL
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Noto Sans 10
gtk-cursor-theme-name=Adwaita
gtk-application-prefer-dark-theme=1
EOF
cp "$CONFIG/gtk-3.0/settings.ini" "$CONFIG/gtk-4.0/settings.ini"
cat > "$HOME/.gtkrc-2.0" << 'EOF'
gtk-theme-name="Everforest-Dark-BL"
gtk-icon-theme-name="Papirus-Dark"
gtk-font-name="Noto Sans 10"
EOF
ok "GTK theme applied"

# ── 8. WALLPAPER (XFCE4) ───────────────────────────────────────────────────────
info "Setting desktop wallpaper..."
for mon in LVDS1 LVDS-1 LVDS eDP1 eDP-1 VGA-1 VGA1; do
    xfconf-query -c xfce4-desktop \
        -p "/backdrop/screen0/monitor${mon}/workspace0/last-image" \
        -s "$WALLPAPER" 2>/dev/null && ok "wallpaper set on $mon" && break
done
xfconf-query -c xfce4-desktop -p /backdrop/single-workspace-mode -s true 2>/dev/null || true

# ── 9. PANEL ───────────────────────────────────────────────────────────────────
info "Configuring panel..."
xfconf-query -c xfce4-panel -p /panels/panel-1/position         -s "p=6;x=0;y=0" 2>/dev/null || true
xfconf-query -c xfce4-panel -p /panels/panel-1/size             -s 28             2>/dev/null || true
xfconf-query -c xfce4-panel -p /panels/panel-1/background-style -s 2              2>/dev/null || true
xfconf-query -c xfce4-panel -p /panels/panel-1/background-rgba \
    --create -t double -t double -t double -t double \
    -s 0.176 -s 0.212 -s 0.231 -s 0.85 2>/dev/null || \
xfconf-query -c xfce4-panel -p /panels/panel-1/background-rgba \
    -s 0.176 -s 0.212 -s 0.231 -s 0.85 2>/dev/null || true
ok "panel configured"

# ── 10. FASTFETCH ──────────────────────────────────────────────────────────────
info "Configuring fastfetch..."
mkdir -p "$CONFIG/fastfetch"
cat > "$CONFIG/fastfetch/config.jsonc" << 'EOF'
{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "display": { "color": { "keys": "green" }, "separator": " " },
    "modules": [
        "title", "separator",
        "os", "kernel", "uptime", "packages", "shell",
        "wm", "terminal", "font", "cpu", "memory"
    ]
}
EOF
grep -q "fastfetch" "$HOME/.bashrc" || echo -e "\nfastfetch" >> "$HOME/.bashrc"
ok "fastfetch configured"

# ── 11. LIGHTDM GREETER ────────────────────────────────────────────────────────
info "Configuring LightDM greeter..."
sudo rm -f /etc/lightdm/lightdm-gtk-greeter.conf.d/kali.conf 2>/dev/null || true
sudo bash -c 'cat > /etc/lightdm/lightdm-gtk-greeter.conf' << 'EOF'
[greeter]
background=/usr/share/backgrounds/everforest/greeter.jpg
theme-name=Everforest-Dark-BL
icon-theme-name=Papirus-Dark
font-name=JetBrains Mono 11
xft-antialias=true
xft-dpi=96
indicators=~clock;~spacer;~session;~power
clock-format=%A, %B %d    %H:%M
position=50%,center 50%,center
panel-position=top
EOF
ok "LightDM greeter configured"

# ── 12. PLYMOUTH ───────────────────────────────────────────────────────────────
info "Setting Plymouth to spinner (safe for LUKS encryption)..."
try "set plymouth spinner" sudo plymouth-set-default-theme spinner
try "update initramfs" sudo update-initramfs -u

# ── 13. GRUB ───────────────────────────────────────────────────────────────────
info "Configuring GRUB (black, terminal green)..."
sudo rm -f /boot/grub/kali-grub.png /boot/grub/kali_background.png 2>/dev/null || true
sudo rm -rf /boot/grub/themes/kali /usr/share/grub/themes/kali 2>/dev/null || true

sudo bash -c 'cat > /etc/default/grub' << 'EOF'
GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR=darbs
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
GRUB_CMDLINE_LINUX=""
GRUB_TERMINAL_OUTPUT=gfxterm
GRUB_GFXMODE=auto
GRUB_BACKGROUND=""
GRUB_COLOR_NORMAL="light-green/black"
GRUB_COLOR_HIGHLIGHT="black/light-green"
EOF
try "update-grub" sudo update-grub

# ── 14. REMOVE KALI BRANDING ───────────────────────────────────────────────────
info "Removing Kali branding..."
sudo apt-get remove -y \
    kali-wallpapers-legacy kali-wallpapers-2019 kali-wallpapers-2020 \
    kali-wallpapers-2021 kali-wallpapers-2022 kali-wallpapers-2023 \
    kali-wallpapers-2024 2>/dev/null || true
sudo apt-get autoremove -y 2>/dev/null || true
sudo rm -f /usr/share/kali-themes/kali-logo*.png \
           /usr/share/kali-themes/kali-dragon*.svg \
           /usr/share/pixmaps/kali-logo*.png 2>/dev/null || true
ok "Kali branding removed"

# ── 15. VSCODIUM ───────────────────────────────────────────────────────────────
info "Installing VSCodium..."
(
    wget -qO /usr/share/keyrings/vscodium.gpg \
        https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg
    echo "deb [ signed-by=/usr/share/keyrings/vscodium.gpg ] \
https://paulcarroty.gitlab.io/vscodium-deb-rpm-repo/debs vscodium main" \
        | sudo tee /etc/apt/sources.list.d/vscodium.list
    sudo apt-get update -q
    sudo apt-get install -y codium
    sudo rm -f /etc/apt/sources.list.d/vscodium.list
    sudo apt-get update -q
) 2>/dev/null && ok "VSCodium installed" || skip "VSCodium" "install failed"

# ── 16. ANONSURF ───────────────────────────────────────────────────────────────
info "Installing AnonSurf..."
sudo apt-get install -y tor iptables macchanger resolvconf 2>/dev/null || true
(
    git clone --depth=1 https://github.com/ParrotSec/anonsurf /tmp/anonsurf
    cd /tmp/anonsurf
    [ -f Makefile ] && sudo make install
) 2>/dev/null && ok "AnonSurf installed" || {
    [ -f /tmp/anonsurf/usr/bin/anonsurf ] && \
        sudo install -m755 /tmp/anonsurf/usr/bin/anonsurf /usr/bin/anonsurf && \
        ok "AnonSurf installed (manual)" || skip "AnonSurf" "install failed"
}
sudo rm -rf /tmp/anonsurf
sudo systemctl enable tor 2>/dev/null || true

# ── 17. GITHUB TOOL INSTALLS ───────────────────────────────────────────────────
info "Installing tools from GitHub releases..."

gh_latest() {
    curl -s "https://api.github.com/repos/$1/releases/latest" \
        | grep '"tag_name"' | head -1 | cut -d'"' -f4
}

# nuclei
(
    VER=$(gh_latest projectdiscovery/nuclei)
    curl -sL "https://github.com/projectdiscovery/nuclei/releases/download/${VER}/nuclei_${VER#v}_linux_amd64.zip" \
        -o /tmp/nuclei.zip
    unzip -q /tmp/nuclei.zip -d /tmp/nuclei
    sudo install -m755 /tmp/nuclei/nuclei /usr/local/bin/nuclei
    rm -rf /tmp/nuclei /tmp/nuclei.zip
) 2>/dev/null && ok "nuclei" || skip "nuclei" "download failed"

# chisel
(
    VER=$(gh_latest jpillora/chisel)
    curl -sL "https://github.com/jpillora/chisel/releases/download/${VER}/chisel_${VER#v}_linux_amd64.gz" \
        -o /tmp/chisel.gz
    gunzip /tmp/chisel.gz
    sudo install -m755 /tmp/chisel /usr/local/bin/chisel
    rm -f /tmp/chisel
) 2>/dev/null && ok "chisel" || skip "chisel" "download failed"

# ligolo-ng
(
    VER=$(gh_latest nicocha30/ligolo-ng)
    curl -sL "https://github.com/nicocha30/ligolo-ng/releases/download/${VER}/ligolo-ng_agent_${VER#v}_linux_amd64.tar.gz" \
        -o /tmp/ligolo-agent.tar.gz
    curl -sL "https://github.com/nicocha30/ligolo-ng/releases/download/${VER}/ligolo-ng_proxy_${VER#v}_linux_amd64.tar.gz" \
        -o /tmp/ligolo-proxy.tar.gz
    tar -xzf /tmp/ligolo-agent.tar.gz -C /tmp
    tar -xzf /tmp/ligolo-proxy.tar.gz -C /tmp
    sudo install -m755 /tmp/agent /usr/local/bin/ligolo-agent
    sudo install -m755 /tmp/proxy /usr/local/bin/ligolo-proxy
    rm -f /tmp/ligolo-*.tar.gz /tmp/agent /tmp/proxy
) 2>/dev/null && ok "ligolo-ng" || skip "ligolo-ng" "download failed"

# caido
(
    VER=$(gh_latest caido/caido)
    [ -z "$VER" ] && exit 1
    curl -sL "https://github.com/caido/caido/releases/download/${VER}/caido-cli-${VER#v}-linux-x86_64.tar.gz" \
        -o /tmp/caido.tar.gz
    tar -xzf /tmp/caido.tar.gz -C /tmp
    find /tmp -maxdepth 2 -name "caido*" -type f \
        -exec sudo install -m755 {} /usr/local/bin/caido \;
    rm -f /tmp/caido.tar.gz
) 2>/dev/null && ok "caido" || skip "caido" "download failed"

# obsidian
(
    VER=$(gh_latest obsidianmd/obsidian-releases)
    curl -sL "https://github.com/obsidianmd/obsidian-releases/releases/download/${VER}/obsidian_${VER#v}_amd64.deb" \
        -o /tmp/obsidian.deb
    sudo dpkg -i /tmp/obsidian.deb
    sudo apt-get install -f -y
    rm -f /tmp/obsidian.deb
) 2>/dev/null && ok "obsidian" || skip "obsidian" "download failed"

# joplin
(
    VER=$(gh_latest laurent22/joplin)
    curl -sL "https://github.com/laurent22/joplin/releases/download/${VER}/Joplin-${VER#v}.deb" \
        -o /tmp/joplin.deb 2>/dev/null
    [ ! -s /tmp/joplin.deb ] && \
        curl -sL "https://github.com/laurent22/joplin/releases/download/${VER}/joplin_${VER#v}_amd64.deb" \
            -o /tmp/joplin.deb 2>/dev/null
    if [ -s /tmp/joplin.deb ]; then
        sudo dpkg -i /tmp/joplin.deb
        sudo apt-get install -f -y
        rm -f /tmp/joplin.deb
    else
        sudo mkdir -p /opt/joplin
        curl -sL "https://github.com/laurent22/joplin/releases/download/${VER}/Joplin-${VER#v}.AppImage" \
            -o /opt/joplin/Joplin.AppImage
        sudo chmod +x /opt/joplin/Joplin.AppImage
        sudo ln -sf /opt/joplin/Joplin.AppImage /usr/local/bin/joplin-desktop
    fi
) 2>/dev/null && ok "joplin" || skip "joplin" "download failed"

# pwncat-cs
pip3 install pwncat-cs --quiet 2>/dev/null && ok "pwncat-cs" || skip "pwncat-cs" "pip failed"

# evil-winrm
gem install evil-winrm --quiet 2>/dev/null && ok "evil-winrm" || skip "evil-winrm" "gem failed"

# ── 18. EXTRA APT PACKAGES ─────────────────────────────────────────────────────
info "Installing extra packages..."
pkg() { sudo apt-get install -y "$1" 2>/dev/null && ok "$1" || skip "$1" "not available"; }

pkg wireshark
pkg burpsuite
pkg maltego
pkg ffuf
pkg gobuster
pkg sqlmap
pkg nikto
pkg hydra
pkg feroxbuster
pkg bloodhound
pkg crackmapexec
pkg impacket-scripts
pkg responder
pkg firejail
pkg bleachbit
pkg libreoffice
pkg gimp
pkg docker.io

# ── 19. WHISKER MENU ICON ──────────────────────────────────────────────────────
info "Cleaning up panel icons..."
WHISKER_ID=$(xfconf-query -c xfce4-panel -p /plugins -l 2>/dev/null | \
    grep "whiskermenu" | grep -oP 'plugin-\d+' | head -1 | grep -oP '\d+')
[ -n "$WHISKER_ID" ] && \
    xfconf-query -c xfce4-panel \
        -p "/plugins/plugin-${WHISKER_ID}/button-icon" \
        -s "start-here-symbolic" 2>/dev/null || true

# ── DONE ───────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GRN}════════════════════════════════════════════════${NC}"
echo -e "${GRN}  darbs setup complete${NC}"
echo -e "${GRN}════════════════════════════════════════════════${NC}"
echo ""
echo "  Reboot to apply Plymouth, GRUB, and LightDM changes."
echo "  Wallpapers are in: $WALL_DIR"
echo ""
