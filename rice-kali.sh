#!/bin/bash
# rice-kali.sh — Everforest moss rice for Kali XFCE4
# Dell E6410 optimized, no compositor

GRN='\033[0;32m'; YLW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info() { echo -e "${GRN}==>${NC} $1"; }
warn() { echo -e "${YLW}[!]${NC} $1"; }
die()  { echo -e "${RED}[x]${NC} $1"; exit 1; }

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
THEMES_DIR="$HOME/.themes"
FONTS_DIR="$HOME/.local/share/fonts"
CONFIG="$HOME/.config"

[ "$EUID" -eq 0 ] && die "Do not run as root. Script will sudo when needed."

# ─── 1. PACKAGES ───────────────────────────────────────────────────────────────
info "Installing packages..."
sudo apt update -q
sudo apt install -y \
    xfce4-whiskermenu-plugin \
    xfce4-genmon-plugin \
    xfce4-battery-plugin \
    xfce4-pulseaudio-plugin \
    xfce4-netload-plugin \
    network-manager-gnome \
    tmux \
    git \
    curl \
    wget \
    fonts-jetbrains-mono \
    papirus-icon-theme \
    fastfetch \
    imagemagick 2>/dev/null || warn "some packages failed, continuing"

# ─── 2. EVERFOREST GTK THEME ───────────────────────────────────────────────────
info "Installing Everforest GTK theme..."
mkdir -p "$THEMES_DIR"
if [ ! -d "$THEMES_DIR/Everforest-Dark-BL" ]; then
    git clone --depth=1 https://github.com/Fausto-Korpsvart/Everforest-GTK-Theme /tmp/everforest-gtk
    cp -r /tmp/everforest-gtk/themes/Everforest-Dark-BL     "$THEMES_DIR/"
    cp -r /tmp/everforest-gtk/themes/Everforest-Dark-BL-LB  "$THEMES_DIR/" 2>/dev/null || true
    rm -rf /tmp/everforest-gtk
    info "Everforest theme installed."
else
    warn "Everforest theme already exists, skipping."
fi

# ─── 3. PAPIRUS ICONS (green folders) ──────────────────────────────────────────
info "Configuring Papirus icons..."
if command -v papirus-folders &>/dev/null; then
    papirus-folders -C green --theme Papirus-Dark
else
    warn "papirus-folders not found, skipping folder color. Install manually with:"
    warn "  wget -qO- https://git.io/papirus-folders-install | sh"
fi

# ─── 4. FONTS ──────────────────────────────────────────────────────────────────
info "Refreshing font cache..."
mkdir -p "$FONTS_DIR"
fc-cache -fv > /dev/null 2>&1

# ─── 5. WALLPAPERS ─────────────────────────────────────────────────────────────
info "Downloading wallpapers from cyberdiary2/dotfiles..."
mkdir -p "$WALLPAPER_DIR"
BASE="https://raw.githubusercontent.com/cyberdiary2/dotfiles/main/wallpapers"
WALLS=(0001 0002 0003 0005 0006 0007 0008 0010 0014 0016 0017 0018 0019 0020
       0021 0022 0023 0024 0025 0026 0028 0031 0032 0036 0038 0039 0040 0041
       0042 0044 0045 0046 0051 0052 0054 0055 0057 0066 0067 0069 0070 0073
       0078 0112 0327)
for w in "${WALLS[@]}"; do
    dest="$WALLPAPER_DIR/${w}.jpg"
    [ -f "$dest" ] && continue
    wget -q "$BASE/${w}.jpg" -O "$dest" && echo "  downloaded ${w}.jpg" || warn "  failed: ${w}.jpg"
done
WALLPAPER="$WALLPAPER_DIR/0001.jpg"

# ─── 6. XFCE4-TERMINAL ─────────────────────────────────────────────────────────
info "Configuring xfce4-terminal (Everforest moss, 80% transparent)..."
mkdir -p "$CONFIG/xfce4/terminal"
cat > "$CONFIG/xfce4/terminal/terminalrc" << 'EOF'
[Configuration]
FontName=JetBrains Mono 11
MiscAlwaysShowTabs=FALSE
MiscBell=FALSE
MiscBellUrgent=FALSE
MiscBordersDefault=TRUE
MiscCursorBlinks=TRUE
MiscCursorShape=TERMINAL_CURSOR_SHAPE_BLOCK
MiscDefaultGeometry=100x30
MiscInheritGeometry=FALSE
MiscMenubarDefault=FALSE
MiscMouseAutohide=FALSE
MiscMouseWheelZoom=TRUE
MiscToolbarDefault=FALSE
MiscConfirmClose=TRUE
MiscCycleTabs=TRUE
MiscTabCloseButtons=TRUE
MiscTabCloseMiddleClick=TRUE
MiscTabPosition=GTK_POS_TOP
MiscHighlightUrls=TRUE
MiscMiddleClickOpensUri=FALSE
MiscCopyOnSelect=FALSE
MiscShowRelaunchDialog=TRUE
MiscRewrapOnResize=TRUE
MiscUseShiftArrowsToScroll=FALSE
MiscSlimTabs=FALSE
MiscNewTabAdjacent=FALSE
MiscSearchDialogOpacity=100
MiscShowUnsafePasteDialog=TRUE
BackgroundMode=TERMINAL_BACKGROUND_TRANSPARENT
BackgroundDarkness=0.80
ColorForeground=#a7c080
ColorBackground=#1b2421
ColorCursor=#a7c080
ColorCursorForeground=#1b2421
ColorBold=#d3c6aa
ColorPalette=#1b2421;#e67e80;#a7c080;#dbbc7f;#7fbbb3;#d699b6;#83c092;#d3c6aa;#475258;#e67e80;#a7c080;#dbbc7f;#7fbbb3;#d699b6;#83c092;#d3c6aa
TabActivityColor=#e67e80
EOF

# ─── 7. TMUX ───────────────────────────────────────────────────────────────────
info "Installing TPM and configuring tmux..."
mkdir -p "$HOME/.tmux/plugins"
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    git clone --depth=1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

cat > "$HOME/.tmux.conf" << 'EOF'
# ── Everforest tmux config ──────────────────────────────────────────────────────

set -g default-terminal "tmux-256color"
set -as terminal-overrides ",xterm*:Tc"
set -g base-index 1
setw -g pane-base-index 1
set -g history-limit 10000
set -g mouse on
set -g escape-time 0
set -g focus-events on
set -g renumber-windows on
set -g set-titles on
set -g set-titles-string "#S / #W"

# prefix: Ctrl+a
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# split
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %

# reload
bind r source-file ~/.tmux.conf \; display "  config reloaded"

# pane nav (vim keys)
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# pane resize
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# ── status bar ─────────────────────────────────────────────────────────────────
set -g status on
set -g status-interval 5
set -g status-position bottom
set -g status-style                 "bg=#2d353b fg=#d3c6aa"

# left: session block
set -g status-left-length 50
set -g status-left \
    "#[bg=#a7c080,fg=#2d353b,bold]  #S #[bg=#3d484d,fg=#a7c080]#[bg=#3d484d,fg=#859289] #(whoami) #[bg=#2d353b,fg=#3d484d] "

# right: cpu | battery | date/time
set -g status-right-length 140
set -g status-right \
    "#[fg=#3d484d,bg=#2d353b]#[bg=#3d484d,fg=#83c092]  #{cpu_percentage} #[fg=#475258,bg=#3d484d]#[bg=#475258,fg=#dbbc7f] #{battery_percentage} #{battery_icon} #[fg=#a7c080,bg=#475258]#[bg=#a7c080,fg=#2d353b,bold]  %a %b %d  %H:%M "

# window tabs
set -g window-status-separator ""
set -g window-status-format          "  #[fg=#859289]#I #W  "
set -g window-status-current-format  "#[bg=#3d484d,fg=#2d353b]#[bg=#3d484d,fg=#a7c080,bold] #I #W #[bg=#2d353b,fg=#3d484d]"

# pane borders
set -g pane-border-style        "fg=#3d484d"
set -g pane-active-border-style "fg=#a7c080"

# messages
set -g message-style        "bg=#a7c080 fg=#2d353b bold"
set -g message-command-style "bg=#dbbc7f fg=#2d353b bold"

# copy mode
setw -g mode-style "bg=#3d484d fg=#a7c080"

# ── battery icons ──────────────────────────────────────────────────────────────
set -g @battery_icon_charge_tier8  "█████"
set -g @battery_icon_charge_tier7  "████ "
set -g @battery_icon_charge_tier6  "███  "
set -g @battery_icon_charge_tier5  "███  "
set -g @battery_icon_charge_tier4  "██   "
set -g @battery_icon_charge_tier3  "█    "
set -g @battery_icon_charge_tier2  "▌    "
set -g @battery_icon_charge_tier1  "     "
set -g @battery_icon_status_charged  " "
set -g @battery_icon_status_charging " "
set -g @battery_icon_status_discharging " "

# ── plugins ────────────────────────────────────────────────────────────────────
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-cpu'
set -g @plugin 'tmux-plugins/tmux-battery'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-yank'

set -g @resurrect-capture-pane-contents 'on'

run '~/.tmux/plugins/tpm/tpm'
EOF

# Install plugins headlessly
info "Installing tmux plugins..."
"$HOME/.tmux/plugins/tpm/bin/install_plugins" > /dev/null 2>&1 || warn "TPM install failed — run prefix+I inside tmux manually."

# ─── 8. GTK / ICON THEME ───────────────────────────────────────────────────────
info "Applying GTK theme and icons via xfconf..."

# GTK theme
xfconf-query -c xsettings -p /Net/ThemeName       -s "Everforest-Dark-BL"  2>/dev/null || true
xfconf-query -c xsettings -p /Net/IconThemeName    -s "Papirus-Dark"        2>/dev/null || true
xfconf-query -c xsettings -p /Gtk/FontName         -s "Noto Sans 10"        2>/dev/null || true
xfconf-query -c xsettings -p /Gtk/CursorThemeName  -s "Adwaita"             2>/dev/null || true

# Also write GTK3 settings file as fallback
mkdir -p "$CONFIG/gtk-3.0"
cat > "$CONFIG/gtk-3.0/settings.ini" << 'EOF'
[Settings]
gtk-theme-name=Everforest-Dark-BL
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Noto Sans 10
gtk-cursor-theme-name=Adwaita
gtk-application-prefer-dark-theme=1
EOF

mkdir -p "$HOME/.config/gtk-4.0"
cp "$CONFIG/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"

# GTK2 fallback
cat > "$HOME/.gtkrc-2.0" << 'EOF'
gtk-theme-name="Everforest-Dark-BL"
gtk-icon-theme-name="Papirus-Dark"
gtk-font-name="Noto Sans 10"
gtk-cursor-theme-name="Adwaita"
EOF

# ─── 9. WALLPAPER ──────────────────────────────────────────────────────────────
info "Setting wallpaper..."

# Try common monitor names on Dell E6410
set_wallpaper() {
    local monitor="$1"
    xfconf-query -c xfce4-desktop \
        -p "/backdrop/screen0/monitor${monitor}/workspace0/last-image" \
        -s "$WALLPAPER" 2>/dev/null && return 0
    xfconf-query -c xfce4-desktop \
        -p "/backdrop/screen0/monitor${monitor}/workspace0/last-image" \
        --create -t string -s "$WALLPAPER" 2>/dev/null && return 0
    return 1
}

for mon in LVDS1 LVDS-1 LVDS eDP1 eDP-1 VGA-1 VGA1; do
    set_wallpaper "$mon" && info "  wallpaper set on $mon" && break
done

xfconf-query -c xfce4-desktop -p /backdrop/single-workspace-mode -s true 2>/dev/null || true

# ─── 10. PANEL ─────────────────────────────────────────────────────────────────
info "Configuring panel (transparent top bar)..."

# Set panel to transparent with dark everforest tint
xfconf-query -c xfce4-panel -p /panels/panel-1/position         -s "p=6;x=0;y=0" 2>/dev/null || true
xfconf-query -c xfce4-panel -p /panels/panel-1/size             -s 28             2>/dev/null || true
xfconf-query -c xfce4-panel -p /panels/panel-1/background-style -s 2              2>/dev/null || true
# RGBA: #2d353b at ~85% opacity
xfconf-query -c xfce4-panel -p /panels/panel-1/background-rgba \
    --create -t double -t double -t double -t double \
    -s 0.176 -s 0.212 -s 0.231 -s 0.85 2>/dev/null || \
xfconf-query -c xfce4-panel -p /panels/panel-1/background-rgba \
    -s 0.176 -s 0.212 -s 0.231 -s 0.85 2>/dev/null || true

# ─── 11. FASTFETCH ─────────────────────────────────────────────────────────────
info "Configuring fastfetch..."
mkdir -p "$CONFIG/fastfetch"
cat > "$CONFIG/fastfetch/config.jsonc" << 'EOF'
{
    "modules": [
        "title", "separator",
        {"type": "os",       "key": "OS      "},
        {"type": "kernel",   "key": "Kernel  "},
        {"type": "uptime",   "key": "Uptime  "},
        {"type": "packages", "key": "Packages"},
        {"type": "shell",    "key": "Shell   "},
        {"type": "wm",       "key": "WM      "},
        {"type": "terminal", "key": "Term    "},
        {"type": "cpu",      "key": "CPU     "},
        {"type": "memory",   "key": "Memory  "}
    ]
}
EOF

grep -q "fastfetch" "$HOME/.bashrc" || echo -e "\nfastfetch" >> "$HOME/.bashrc"

# ─── 12. LIGHTDM GREETER ───────────────────────────────────────────────────────
info "Ricing LightDM greeter..."

# Copy a wallpaper to a system path the greeter can read before login
sudo mkdir -p /usr/share/backgrounds/everforest
sudo cp "$WALLPAPER" /usr/share/backgrounds/everforest/greeter.jpg
sudo chmod 644 /usr/share/backgrounds/everforest/greeter.jpg

# Copy GTK theme and icons to system dirs so greeter can use them
if [ -d "$THEMES_DIR/Everforest-Dark-BL" ]; then
    sudo cp -r "$THEMES_DIR/Everforest-Dark-BL" /usr/share/themes/ 2>/dev/null || true
fi

sudo bash -c 'cat > /etc/lightdm/lightdm-gtk-greeter.conf' << 'EOF'
[greeter]
background=/usr/share/backgrounds/everforest/greeter.jpg
theme-name=Everforest-Dark-BL
icon-theme-name=Papirus-Dark
font-name=JetBrains Mono 11
xft-antialias=true
xft-dpi=96
xft-hintstyle=slight
xft-rgba=rgb
indicators=~clock;~spacer;~session;~power
clock-format=%A, %B %d    %H:%M
position=50%,center 50%,center
panel-position=top
hide-user-image=false
default-user-image=/usr/share/pixmaps/faces/stock_person.png
cursor-theme-name=Adwaita
EOF

# Remove Kali-specific greeter config if it exists
sudo rm -f /etc/lightdm/lightdm-gtk-greeter.conf.d/kali.conf 2>/dev/null || true

# ─── 13. PLYMOUTH (boot splash) ────────────────────────────────────────────────
info "Replacing Kali plymouth theme with minimal spinner..."
if dpkg -l plymouth &>/dev/null; then
    sudo apt install -yq plymouth-themes 2>/dev/null || true
    # Use 'spinner' - minimal, no distro branding
    sudo plymouth-set-default-theme spinner 2>/dev/null || \
    sudo plymouth-set-default-theme text    2>/dev/null || \
    warn "Could not set plymouth theme, skipping."
    sudo update-initramfs -u 2>/dev/null || true
else
    warn "Plymouth not installed, skipping."
fi

# ─── 14. GRUB ──────────────────────────────────────────────────────────────────
info "Cleaning up GRUB branding..."
# Remove Kali background image from grub
sudo rm -f /boot/grub/kali-grub.png /boot/grub/kali_background.png 2>/dev/null || true

# Set clean GRUB config (no splash, just text, short timeout)
sudo sed -i 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=3/'           /etc/default/grub 2>/dev/null || true
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/' \
    /etc/default/grub 2>/dev/null || true

# Remove Kali background from grub
if grep -q "GRUB_BACKGROUND" /etc/default/grub 2>/dev/null; then
    sudo sed -i '/GRUB_BACKGROUND/d' /etc/default/grub
fi

sudo update-grub 2>/dev/null || warn "update-grub failed, skipping."

# ─── 15. STRIP KALI BRANDING ───────────────────────────────────────────────────
info "Removing Kali logos and branding assets..."

# Remove Kali wallpapers (keep custom ones)
sudo apt remove -y kali-wallpapers-legacy kali-wallpapers-2019 \
    kali-wallpapers-2020 kali-wallpapers-2021 kali-wallpapers-2022 \
    kali-wallpapers-2023 kali-wallpapers-2024 2>/dev/null || true
sudo apt autoremove -y 2>/dev/null || true

# Remove Kali desktop logo/watermark files
sudo rm -f /usr/share/kali-themes/kali-logo*.png 2>/dev/null || true
sudo rm -f /usr/share/kali-themes/kali-dragon*.svg 2>/dev/null || true

# Remove Kali logo from whisker menu (set to a neutral system icon)
WHISKER_ID=$(xfconf-query -c xfce4-panel -p /plugins -l 2>/dev/null | \
    grep "whiskermenu" | grep -oP 'plugin-\d+' | head -1 | grep -oP '\d+')
if [ -n "$WHISKER_ID" ]; then
    xfconf-query -c xfce4-panel -p "/plugins/plugin-${WHISKER_ID}/button-icon" \
        -s "start-here-symbolic" 2>/dev/null || \
    xfconf-query -c xfce4-panel -p "/plugins/plugin-${WHISKER_ID}/button-icon" \
        -s "applications-other" 2>/dev/null || true
    info "  Whisker menu icon set to neutral."
else
    warn "  Whisker menu plugin not found in panel, set icon manually."
fi

# ─── DONE ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GRN}════════════════════════════════════════${NC}"
echo -e "${GRN}  Rice complete!${NC}"
echo -e "${GRN}════════════════════════════════════════${NC}"
echo ""
echo "  Next steps:"
echo "  1. Reboot to apply greeter, GRUB, and Plymouth changes"
echo "  2. Open tmux and press Ctrl+a then I to install plugins"
echo "  3. Wallpapers are in: $WALLPAPER_DIR"
echo "  4. Right-click desktop > Desktop Settings to change wallpaper"
echo ""
warn "If GTK theme is missing after reboot, open Appearance > Style and select Everforest-Dark-BL."
warn "If greeter wallpaper is wrong, edit /etc/lightdm/lightdm-gtk-greeter.conf and point background= to any wallpaper in /usr/share/backgrounds/everforest/"
