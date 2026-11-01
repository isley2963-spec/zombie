# ============================================================================
# Zombie OS - Fedora-based live spin (Red Hat family: RPM + dnf + systemd)
# Desktops: GNOME, KDE Plasma, Hyprland (pick one at the GDM login screen)
# Target: installed system comfortable on 1 GB RAM (zram swap, earlyoom, trimmed services)
# Build with: sudo ./build.sh
# ============================================================================

lang en_US.UTF-8
keyboard us
timezone UTC --utc
selinux --enforcing
firewall --enabled --service=mdns
xconfig --startxonboot
zerombr
clearpart --all
part / --size=12288 --fstype=ext4
rootpw --lock --iscrypted locked
network --bootproto=dhcp --device=link --activate --hostname=zombie

services --enabled=NetworkManager,gdm,earlyoom,systemd-oomd,livesys,livesys-late --disabled=sshd,cups,cups-browsed,ModemManager,abrtd,abrt-journal-core,abrt-oops,abrt-vmcore,abrt-xorg,bluetooth

# Fedora repositories (the release is chosen at build time with --releasever)
url --metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch
repo --name=updates --metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-f$releasever&arch=$basearch
# Hyprland comes from this COPR when it is not in the Fedora repos for your release
repo --name=hyprland --baseurl=https://download.copr.fedorainfracloud.org/results/solopasha/hyprland/fedora-$releasever-$basearch/

%packages
# ---- Base system and stock Fedora Linux kernel ----
@core
kernel
kernel-modules
kernel-modules-extra
dracut-live
grub2-efi-x64
grub2-efi-x64-cdboot
shim-x64
syslinux
memtest86+
livesys-scripts
glibc-all-langpacks
NetworkManager-wifi
firefox
nano
vim-minimal
git
curl
fastfetch
htop

# ---- Installer ----
anaconda
anaconda-install-env-deps
anaconda-live
@anaconda-tools

# ---- Memory tuning ----
earlyoom
zram-generator-defaults
systemd-oomd-defaults

# ---- Login screen (starts GNOME, Plasma or Hyprland sessions) ----
gdm

# ---- GNOME ----
gnome-shell
gnome-session-wayland-session
gnome-control-center
gnome-text-editor
nautilus
ptyxis
adwaita-icon-theme

# ---- KDE Plasma ----
plasma-desktop
plasma-workspace-wayland
plasma-nm
plasma-pa
kscreen
dolphin
konsole
kate
breeze-icon-theme

# ---- Hyprland ----
hyprland
xdg-desktop-portal-hyprland
waybar
wofi
foot
mako
hyprpaper
hyprlock
grim
slurp
wl-clipboard
brightnessctl
pavucontrol
polkit-gnome

# ---- Fonts ----
google-noto-sans-fonts
google-noto-sans-mono-fonts
google-noto-color-emoji-fonts

# ---- Things a 1 GB machine does not need ----
-gnome-software
-abrt*
-cups
-localsearch
-gnome-tour
-gnome-initial-setup
%end

%post
set -x

# ---------------------------------------------------------------------------
# Branding (keep ID=fedora so dnf and release tooling keep working)
# ---------------------------------------------------------------------------
sed -i -e 's/^NAME=.*/NAME="Zombie OS"/' \
       -e 's/^PRETTY_NAME=.*/PRETTY_NAME="Zombie OS (Fedora based)"/' \
       /usr/lib/os-release
echo 'VARIANT="Frostbite"' >> /usr/lib/os-release
echo 'zombie' > /etc/hostname
echo 'Zombie OS \S{VERSION_ID}  \n  \l' > /etc/issue

# ---------------------------------------------------------------------------
# 1 GB RAM tuning
# ---------------------------------------------------------------------------
cat > /etc/systemd/zram-generator.conf <<'EOF'
[zram0]
zram-size = ram
compression-algorithm = zstd
swap-priority = 100
EOF

cat > /etc/sysctl.d/90-zombie-memory.conf <<'EOF'
vm.swappiness = 180
vm.page-cluster = 0
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.vfs_cache_pressure = 100
EOF

mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/zombie.conf <<'EOF'
[Journal]
Storage=volatile
RuntimeMaxUse=24M
EOF

mkdir -p /etc/default
cat > /etc/default/earlyoom <<'EOF'
EARLYOOM_ARGS="-r 60 -m 5 -s 5 --avoid '(^|/)(gnome-shell|plasmashell|Hyprland|Xwayland|gdm)$'"
EOF

# ---------------------------------------------------------------------------
# Network and kernel hygiene that costs no memory and does not get in the way
# ---------------------------------------------------------------------------
cat > /etc/sysctl.d/91-zombie-hardening.conf <<'EOF'
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.unprivileged_bpf_disabled = 1
net.core.bpf_jit_harden = 2
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.tcp_syncookies = 1
fs.protected_symlinks = 1
fs.protected_hardlinks = 1
EOF

# ---------------------------------------------------------------------------
# Dark frosted glass defaults for every desktop
# ---------------------------------------------------------------------------

# GNOME: dark style by default
mkdir -p /etc/dconf/profile /etc/dconf/db/local.d
cat > /etc/dconf/profile/user <<'EOF'
user-db:user
system-db:local
EOF
cat > /etc/dconf/db/local.d/00-zombie <<'EOF'
[org/gnome/desktop/interface]
color-scheme='prefer-dark'
enable-animations=true

[org/gnome/desktop/wm/preferences]
button-layout='close,minimize,maximize:'
EOF
dconf update || true

# KDE Plasma: Breeze Dark with the blur and translucency effects turned on
mkdir -p /etc/xdg
cat > /etc/xdg/kdeglobals <<'EOF'
[KDE]
LookAndFeelPackage=org.kde.breezedark.desktop
EOF
cat > /etc/xdg/kwinrc <<'EOF'
[Plugins]
blurEnabled=true
translucencyEnabled=true
contrastEnabled=true

[Effect-blur]
BlurStrength=12
NoiseStrength=3
EOF

# Hyprland: glass windows, translucent bar, no animations (saves GPU and RAM)
mkdir -p /etc/skel/.config/hypr /etc/skel/.config/waybar /etc/skel/.config/foot /etc/skel/.config/mako

cat > /etc/skel/.config/hypr/hyprland.conf <<'EOF'
monitor=,preferred,auto,1

$terminal = foot
$menu = wofi --show drun
$lock = hyprlock

exec-once = waybar
exec-once = mako
exec-once = hyprpaper
exec-once = /usr/libexec/polkit-gnome-authentication-agent-1

general {
    gaps_in = 5
    gaps_out = 12
    border_size = 1
    col.active_border = rgba(9fe3c4cc)
    col.inactive_border = rgba(ffffff22)
    layout = dwindle
}

decoration {
    rounding = 14
    active_opacity = 0.92
    inactive_opacity = 0.82
    blur {
        enabled = true
        size = 8
        passes = 3
        noise = 0.02
        brightness = 0.9
        vibrancy = 0.2
    }
    shadow {
        enabled = false
    }
}

animations {
    enabled = false
}

misc {
    disable_hyprland_logo = true
    disable_splash_rendering = true
}

layerrule = blur, waybar
layerrule = blur, wofi
layerrule = blur, notifications

input {
    kb_layout = us
    follow_mouse = 1
    touchpad {
        natural_scroll = true
    }
}

$mod = SUPER

bind = $mod, Return, exec, $terminal
bind = $mod, D, exec, $menu
bind = $mod, Q, killactive
bind = $mod, F, fullscreen
bind = $mod, V, togglefloating
bind = $mod, L, exec, $lock
bind = $mod SHIFT, M, exit
bind = , Print, exec, grim -g "$(slurp)" - | wl-copy

bind = $mod, left, movefocus, l
bind = $mod, right, movefocus, r
bind = $mod, up, movefocus, u
bind = $mod, down, movefocus, d

bind = $mod, 1, workspace, 1
bind = $mod, 2, workspace, 2
bind = $mod, 3, workspace, 3
bind = $mod, 4, workspace, 4
bind = $mod, 5, workspace, 5
bind = $mod SHIFT, 1, movetoworkspace, 1
bind = $mod SHIFT, 2, movetoworkspace, 2
bind = $mod SHIFT, 3, movetoworkspace, 3
bind = $mod SHIFT, 4, movetoworkspace, 4
bind = $mod SHIFT, 5, movetoworkspace, 5

bindm = $mod, mouse:272, movewindow
bindm = $mod, mouse:273, resizewindow
EOF

cat > /etc/skel/.config/waybar/config.jsonc <<'EOF'
{
  "layer": "top",
  "height": 32,
  "margin-top": 8,
  "margin-left": 12,
  "margin-right": 12,
  "modules-left": ["hyprland/workspaces"],
  "modules-center": ["clock"],
  "modules-right": ["memory", "network", "pulseaudio", "battery"],
  "clock": { "format": "{:%a %d %b  %H:%M}" },
  "memory": { "format": "RAM {used:0.2f} GiB" },
  "network": { "format-wifi": "{essid}", "format-ethernet": "wired", "format-disconnected": "offline" },
  "pulseaudio": { "format": "vol {volume}%" },
  "battery": { "format": "bat {capacity}%" }
}
EOF

cat > /etc/skel/.config/waybar/style.css <<'EOF'
* { font-family: "Noto Sans", sans-serif; font-size: 13px; border: none; }
window#waybar { background: rgba(14, 20, 18, 0.55); border: 1px solid rgba(255,255,255,0.14); border-radius: 14px; color: #e8efec; }
#workspaces button { padding: 0 10px; color: #9fb0aa; background: transparent; }
#workspaces button.active { color: #9fe3c4; }
#clock, #memory, #network, #pulseaudio, #battery { padding: 0 12px; }
EOF

cat > /etc/skel/.config/foot/foot.ini <<'EOF'
[main]
font=Noto Sans Mono:size=11
pad=12x12

[colors]
alpha=0.82
background=0b100f
foreground=e8efec
EOF

cat > /etc/skel/.config/mako/config <<'EOF'
background-color=#0e1412cc
text-color=#e8efec
border-color=#ffffff22
border-radius=12
default-timeout=6000
EOF

# ---------------------------------------------------------------------------
# Clean up
# ---------------------------------------------------------------------------
dnf clean all || true
rm -rf /var/cache/dnf/* /var/log/dnf*.log 2>/dev/null || true
%end
