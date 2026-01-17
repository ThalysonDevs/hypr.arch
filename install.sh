#!/bin/bash
set -e

# ==============================
# VERIFICAÇÕES
# ==============================
if [[ $EUID -ne 0 ]]; then
    echo "Execute com sudo:"
    echo "  sudo $0"
    exit 1
fi

if [[ -z "$SUDO_USER" ]]; then
    echo "Este script deve ser executado via sudo por um usuário normal."
    exit 1
fi

USER_HOME=$(eval echo "~$SUDO_USER")
USER_CONFIG="$USER_HOME/.config"
USER_BIN="$USER_HOME/.local/bin"

echo "Usuário alvo: $SUDO_USER"
echo "Home: $USER_HOME"

# ==============================
# COPIAR DOTFILES
# ==============================
echo "Copiando dotfiles..."

if [[ ! -d "./.config" ]]; then
    echo "Pasta '.config/' não encontrada na raiz do repositório!"
    exit 1
fi

mkdir -p "$USER_CONFIG" "$USER_BIN"

cp -rT ./.config "$USER_CONFIG"

if [[ -d "./.local/bin" ]]; then
    cp -rT ./.local/bin "$USER_BIN"
    chmod +x "$USER_BIN"/*
fi

chown -R "$SUDO_USER:$SUDO_USER" "$USER_CONFIG" "$USER_BIN"

# ==============================
# PACOTES OFICIAIS
# ==============================
PACMAN_PACKAGES=(
    base-devel
    git
    curl
    swaync
    waybar
    cava
    zsh
    hyprlock
    nautilus
    pavucontrol
    swww
    python-lsp-server
    pyright
    shfmt
    shellcheck
    typescript-language-server
    bash-language-server
    rust-analyzer
    clang
    catppuccin-gtk-theme-mocha
    gopls
    fastfetch
    nwg-look
    rofi
    ttf-jetbrains-mono
    ttf-jetbrains-mono-nerd
    wf-recorder
    wlogout
    kitty
    wireless_tools
    pamixer
    mpv
    imagemagick
)
# ==============================
# DEFINIR ZSH COMO SHELL PADRÃO
# ==============================
echo "Configurando ZSH como shell padrão..."

ZSH_PATH=$(command -v zsh)

if ! grep -q "$ZSH_PATH" /etc/shells; then
    echo "$ZSH_PATH" >> /etc/shells
fi

chsh -s "$ZSH_PATH" "$SUDO_USER"

echo "ZSH definido como shell padrão para $SUDO_USER"

# ==============================
# PACOTES AUR
# ==============================
AUR_PACKAGES=(
    zed-bin
    waypaper
)

# ==============================
# ATUALIZA SISTEMA
# ==============================
echo "Atualizando sistema..."
pacman -Syu --noconfirm

echo "Instalando pacotes oficiais..."
pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"

# ==============================
# INSTALAR YAY
# ==============================
if ! command -v yay &>/dev/null; then
    echo "Instalando yay (AUR helper)..."
    sudo -u "$SUDO_USER" bash <<EOF
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
EOF
fi

# ==============================
# INSTALAR PACOTES AUR
# ==============================
echo "Instalando pacotes AUR..."
sudo -u "$SUDO_USER" yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"

echo "✅ Dotfiles aplicados e pacotes (pacman + AUR) instalados com sucesso!"
