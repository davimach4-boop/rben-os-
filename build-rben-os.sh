#!/bin/bash
# RBEN OS - script de build (Debian testing + KDE Plasma + gaming)
# Executar num Debian/Ubuntu normal com internet e ~25 GB livres:
#   chmod +x build-rben-os.sh && ./build-rben-os.sh
# Em GitHub Actions/CI também funciona porque o script detecta se está em root.
set -euo pipefail

# Use sudo apenas quando necessário. Em execução em root (ex.: GitHub Actions), não exige sudo.
SUDO=""
if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
fi

if [ "$(id -u)" -eq 0 ]; then
  echo ">> A executar em root/CI; sem sudo necessário."
else
  echo ">> A executar como utilizador normal; usa sudo quando necessário."
fi

echo ">> A instalar ferramentas de build..."
$SUDO apt-get update
$SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  live-build debootstrap git xorriso squashfs-tools debian-archive-keyring ca-certificates wget

mkdir -p rben-os && cd rben-os
$SUDO lb clean --purge 2>/dev/null || true
rm -rf config auto

echo ">> A configurar o projeto..."
lb config \
  --distribution testing \
  --architectures amd64 \
  --archive-areas "main contrib non-free non-free-firmware" \
  --debian-installer none \
  --security false \
  --updates false \
  --binary-images iso-hybrid \
  --iso-application "RBEN OS" \
  --iso-volume "RBEN_OS" \
  --iso-publisher "RBEN OS" \
  --bootappend-live "boot=live components quiet splash locales=pt_PT.UTF-8 keyboard-layouts=pt"

mkdir -p config/package-lists config/hooks/normal config/includes.chroot/etc

# ---- Pacotes (64 bits) ----
cat > config/package-lists/rben.list.chroot <<'EOF'
task-kde-desktop
sddm
live-boot
live-config
firefox-esr
konsole
dolphin
mesa-vulkan-drivers
vulkan-tools
gamemode
mangohud
gamescope
wine
wine64
winetricks
lutris
nvidia-driver
firmware-misc-nonfree
firmware-amd-graphics
zram-tools
calamares
calamares-settings-debian
network-manager
pipewire-audio
EOF

# ---- Hook: multiarch (i386) + Steam e libs de 32 bits ----
cat > config/hooks/normal/0010-gaming-i386.hook.chroot <<'EOF'
#!/bin/sh
set -e
dpkg --add-architecture i386
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  steam-installer \
  mesa-vulkan-drivers:i386 \
  libgl1-mesa-dri:i386 \
  libglx-mesa0:i386
EOF
chmod +x config/hooks/normal/0010-gaming-i386.hook.chroot

# ---- Identidade do sistema ----
cat > config/includes.chroot/etc/os-release <<'EOF'
PRETTY_NAME="RBEN OS (Gaming Edition)"
NAME="RBEN OS"
ID=rben
ID_LIKE=debian
VERSION="1.0"
EOF

echo ">> A criar o tema azul do RBEN OS..."
echo "librsvg2-bin" >> config/package-lists/rben.list.chroot

mkdir -p config/includes.chroot/usr/share/color-schemes \
         config/includes.chroot/usr/share/backgrounds/rben \
         config/includes.chroot/usr/share/sddm/themes/breeze \
         config/includes.chroot/usr/local/bin \
         config/includes.chroot/etc/skel/.config/autostart

# ---- Fundo de ecrã: degradé azul ----
cat > config/includes.chroot/usr/share/backgrounds/rben/rben-blue.svg <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="3840" height="2160" viewBox="0 0 3840 2160">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#050b24"/>
      <stop offset="0.55" stop-color="#0b2a7a"/>
      <stop offset="1" stop-color="#1e6bff"/>
    </linearGradient>
    <radialGradient id="glow" cx="0.78" cy="0.25" r="0.5">
      <stop offset="0" stop-color="#4da3ff" stop-opacity="0.55"/>
      <stop offset="1" stop-color="#4da3ff" stop-opacity="0"/>
    </radialGradient>
  </defs>
  <rect width="3840" height="2160" fill="url(#bg)"/>
  <rect width="3840" height="2160" fill="url(#glow)"/>
  <text x="200" y="1900" font-family="sans-serif" font-size="150" font-weight="700"
        fill="#ffffff" fill-opacity="0.22" letter-spacing="14">RBEN OS</text>
  <text x="206" y="1990" font-family="sans-serif" font-size="70"
        fill="#ffffff" fill-opacity="0.30" letter-spacing="6">Baseado em Debian GNU/Linux</text>
</svg>
EOF

# ---- Esquema de cores KDE: RBEN Blue ----
cat > config/includes.chroot/usr/share/color-schemes/RbenBlue.colors <<'EOF'
[General]
ColorScheme=RbenBlue
Name=RBEN Blue

[ColorEffects:Disabled]
Color=56,56,56
ColorAmount=0
ColorEffect=0
ContrastAmount=0.65
ContrastEffect=1
IntensityAmount=0.1
IntensityEffect=2

[ColorEffects:Inactive]
ChangeSelectionColor=true
Color=112,111,110
ColorAmount=0.025
ColorEffect=2
ContrastAmount=0.1
ContrastEffect=2
Enable=false
IntensityAmount=0
IntensityEffect=0

[Colors:Window]
BackgroundAlternate=14,26,58
BackgroundNormal=10,20,46
DecorationFocus=30,120,255
DecorationHover=77,163,255
ForegroundActive=77,163,255
ForegroundInactive=140,160,200
ForegroundLink=100,170,255
ForegroundNegative=255,90,90
ForegroundNeutral=255,190,70
ForegroundNormal=232,240,255
ForegroundPositive=70,220,150
ForegroundVisited=160,140,255

[Colors:View]
BackgroundAlternate=12,24,54
BackgroundNormal=7,15,36
DecorationFocus=30,120,255
DecorationHover=77,163,255
ForegroundActive=77,163,255
ForegroundInactive=140,160,200
ForegroundLink=100,170,255
ForegroundNegative=255,90,90
ForegroundNeutral=255,190,70
ForegroundNormal=232,240,255
ForegroundPositive=70,220,150
ForegroundVisited=160,140,255

[Colors:Button]
BackgroundAlternate=22,44,98
BackgroundNormal=20,40,92
DecorationFocus=30,120,255
DecorationHover=77,163,255
ForegroundActive=77,163,255
ForegroundInactive=140,160,200
ForegroundLink=100,170,255
ForegroundNegative=255,90,90
ForegroundNeutral=255,190,70
ForegroundNormal=232,240,255
ForegroundPositive=70,220,150
ForegroundVisited=160,140,255

[Colors:Selection]
BackgroundAlternate=20,100,240
BackgroundNormal=30,120,255
DecorationFocus=30,120,255
DecorationHover=77,163,255
ForegroundActive=255,255,255
ForegroundInactive=210,225,255
ForegroundLink=255,255,255
ForegroundNegative=255,200,200
ForegroundNeutral=255,230,170
ForegroundNormal=255,255,255
ForegroundPositive=200,255,225
ForegroundVisited=220,210,255

[Colors:Tooltip]
BackgroundAlternate=14,26,58
BackgroundNormal=10,20,46
DecorationFocus=30,120,255
DecorationHover=77,163,255
ForegroundActive=77,163,255
ForegroundInactive=140,160,200
ForegroundLink=100,170,255
ForegroundNegative=255,90,90
ForegroundNeutral=255,190,70
ForegroundNormal=232,240,255
ForegroundPositive=70,220,150
ForegroundVisited=160,140,255

[Colors:Complementary]
BackgroundAlternate=8,16,40
BackgroundNormal=6,12,32
DecorationFocus=30,120,255
DecorationHover=77,163,255
ForegroundActive=77,163,255
ForegroundInactive=140,160,200
ForegroundLink=100,170,255
ForegroundNegative=255,90,90
ForegroundNeutral=255,190,70
ForegroundNormal=232,240,255
ForegroundPositive=70,220,150
ForegroundVisited=160,140,255

[WM]
activeBackground=8,18,48
activeForeground=232,240,255
inactiveBackground=10,20,46
inactiveForeground=140,160,200
EOF

# ---- Aplicar tema por defeito no primeiro login ----
cat > config/includes.chroot/etc/skel/.config/kdeglobals <<'EOF'
[General]
ColorScheme=RbenBlue
AccentColor=30,120,255
EOF

cat > config/includes.chroot/usr/local/bin/rben-apply-theme <<'EOF'
#!/bin/sh
# Corre uma vez por utilizador
MARK="$HOME/.config/rben-theme-applied"
[ -f "$MARK" ] && exit 0
sleep 5
IMG=/usr/share/backgrounds/rben/rben-blue.png
[ -f "$IMG" ] || IMG=/usr/share/backgrounds/rben/rben-blue.svg
plasma-apply-colorscheme RbenBlue 2>/dev/null
plasma-apply-wallpaperimage "$IMG" 2>/dev/null
touch "$MARK"
EOF
chmod +x config/includes.chroot/usr/local/bin/rben-apply-theme

cat > config/includes.chroot/etc/skel/.config/autostart/rben-theme.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=RBEN Theme
Exec=/usr/local/bin/rben-apply-theme
X-KDE-autostart-phase=2
EOF

# ---- Ecrã de login (SDDM) azul ----
cat > config/includes.chroot/usr/share/sddm/themes/breeze/theme.conf.user <<'EOF'
[General]
background=/usr/share/backgrounds/rben/rben-blue.png
type=image
EOF

# ---- Converter o SVG para PNG durante o build ----
cat > config/hooks/normal/0020-wallpaper.hook.chroot <<'EOF'
#!/bin/sh
rsvg-convert -w 3840 -h 2160 \
  /usr/share/backgrounds/rben/rben-blue.svg \
  -o /usr/share/backgrounds/rben/rben-blue.png || true
EOF
chmod +x config/hooks/normal/0020-wallpaper.hook.chroot

echo ">> A configurar os atalhos de teclado..."
# Padrões do KDE que já funcionam sem configuração:
#   Super (menu iniciar), Super+D (área de trabalho), Super+L (bloquear),
#   Super+setas (encaixar), Alt+Tab, Alt+F4
# Abaixo ficam os que precisam de ser definidos ou confirmados.
cat > config/includes.chroot/etc/skel/.config/kglobalshortcutsrc <<'EOF'
[org.kde.dolphin.desktop]
_k_friendly_name=Dolphin
_launch=Meta+E,none,Dolphin

[org.kde.krunner.desktop]
_k_friendly_name=KRunner
_launch=Meta+R\tAlt+Space\tAlt+F2,Alt+Space\tAlt+F2\tSearch,KRunner

[systemsettings.desktop]
_k_friendly_name=System Settings
_launch=Meta+I,none,System Settings

[org.kde.plasma-systemmonitor.desktop]
_k_friendly_name=System Monitor
_launch=Ctrl+Shift+Esc,Ctrl+Shift+Esc,System Monitor

[org.kde.spectacle.desktop]
_k_friendly_name=Spectacle
_launch=Print,Print,Launch Spectacle
RectangularRegionScreenShot=Meta+Shift+S,Meta+Shift+Print,Capture Rectangular Region
EOF

echo ">> A adicionar OnlyOffice, OBS e captura de ecrã..."
cat >> config/package-lists/rben.list.chroot <<'EOF'
obs-studio
wget
ca-certificates
wl-clipboard
EOF

# ---- OnlyOffice (não existe nos repositórios do Debian: descarrega o .deb oficial) ----
cat > config/hooks/normal/0030-onlyoffice.hook.chroot <<'EOF'
#!/bin/sh
cd /tmp
if wget -q -O onlyoffice.deb \
  https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors_amd64.deb; then
  DEBIAN_FRONTEND=noninteractive apt-get install -y ./onlyoffice.deb || echo "OnlyOffice: falhou a instalacao"
else
  echo "OnlyOffice: falhou o download (o build continua sem ele)"
fi
rm -f onlyoffice.deb
EOF
chmod +x config/hooks/normal/0030-onlyoffice.hook.chroot

# ---- Captura de ecrã estilo Windows+Shift+S: recorte + copiar ----
# Super+Shift+S (definido acima) abre o recorte de região no Spectacle.
# Aqui o Spectacle é configurado para copiar a imagem para a área de transferência.
cat > config/includes.chroot/etc/skel/.config/spectaclerc <<'EOF'
[General]
clipboardGroup=PostScreenshotCopyImage
launchAction=TakeRectangularRegion
showCaptureInstructions=false
rememberSelectionRect=Never

[GuiConfig]
quitAfterSaveCopyExport=true
EOF

echo ">> A construir a ISO (demora bastante)..."
$SUDO lb build 2>&1 | tee build.log

SRC=$(ls -1 *.iso | head -n1 || true)
if [ -n "${SRC:-}" ] && [ "${SRC}" != "rben-amd64.iso" ]; then
  mv "$SRC" rben-amd64.iso
fi

ISO=rben-amd64.iso
if [ ! -f "$ISO" ]; then
  echo "ERRO: não foi encontrada a ISO final: $ISO" >&2
  exit 1
fi

echo

echo "================================================"
echo " ISO criada: $(pwd)/$ISO"
echo " Grava num USB com Ventoy ou balenaEtcher."
echo "================================================"
