#!/bin/bash
set -e

### VERIFICAÇÕES ###
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

echo "Usuário alvo: $SUDO_USER"
echo "Home: $USER_HOME"

---

### 1️⃣ COPIAR CONFIGURAÇÕES ###
echo "Copiando dotfiles para ~/.config..."

if [[ ! -d "./config" ]]; then
    echo "Pasta 'config/' não encontrada na raiz do repositório!"
    exit 1
fi

mkdir -p "$USER_CONFIG"

cp -rT ./config "$USER_CONFIG"

chown -R "$SUDO_USER:$SUDO_USER" "$USER_CONFIG"

---

### 2️⃣ INSTALAR PACOTES ###
PACKAGES=(
    base-devel
    git
    curl
    swaync
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
    gopls
    fastfetch
    nwg-look
    rofi
    zed
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

echo "Atualizando repositórios..."
pacman -Sy --noconfirm

echo "Instalando pacotes..."
pacman -S --needed --noconfirm "${PACKAGES[@]}"

echo "Dotfiles aplicados e pacotes instalados com sucesso!"
