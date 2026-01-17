#!/bin/bash
set -e

# ==============================
# CONFIGURAÇÕES (EDITE AQUI)
# ==============================

# Instalar yay e pacotes AUR?
INSTALL_YAY=true

AUR_PACKAGES=(
    zed-bin
    waypaper
    catppuccin-gtk-theme-mocha
    swaync
)

# ==============================
# CHECKLIST DE INSTALAÇÃO
# ==============================
declare -A INSTALL_STATUS

install_pacman_pkg() {
    local pkg="$1"

    if pacman -S --needed --noconfirm "$pkg"; then
        INSTALL_STATUS["$pkg"]="OK"
    else
        INSTALL_STATUS["$pkg"]="ERRO"
    fi
}

install_aur_pkg() {
    local pkg="$1"

    if sudo -u "$SUDO_USER" yay -S --needed --noconfirm "$pkg"; then
        INSTALL_STATUS["$pkg (AUR)"]="OK"
    else
        INSTALL_STATUS["$pkg (AUR)"]="ERRO"
    fi
}

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
    chmod +x "$USER_BIN"/* || true
fi

chown -R "$SUDO_USER:$SUDO_USER" "$USER_CONFIG" "$USER_BIN"

# ==============================
# PACOTES OFICIAIS
# ==============================
PACMAN_PACKAGES=(
    base-devel
    git
    curl
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
# ATUALIZAR SISTEMA
# ==============================
echo "Atualizando sistema..."
pacman -Syu --noconfirm

echo "Instalando pacotes oficiais..."
set +e
for pkg in "${PACMAN_PACKAGES[@]}"; do
    install_pacman_pkg "$pkg"
done
set -e

# ==============================
# DEFINIR ZSH COMO SHELL PADRÃO
# ==============================
echo "Configurando ZSH como shell padrão..."

ZSH_PATH=$(command -v zsh)

if [[ -n "$ZSH_PATH" ]]; then
    if ! grep -qx "$ZSH_PATH" /etc/shells; then
        echo "$ZSH_PATH" >> /etc/shells
    fi

    chsh -s "$ZSH_PATH" "$SUDO_USER"
    echo "ZSH definido como shell padrão para $SUDO_USER"
else
    echo "❌ ZSH não encontrado, pulando configuração."
fi

# ==============================
# INSTALAR YAY (OPCIONAL)
# ==============================
if [[ "$INSTALL_YAY" == true ]]; then
    if ! command -v yay &> /dev/null; then
        echo "Instalando yay (AUR helper)..."
        sudo -u "$SUDO_USER" bash << EOF
set -e
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
EOF
    else
        echo "yay já está instalado."
    fi
else
    echo "Instalação de AUR desativada."
fi

# ==============================
# INSTALAR PACOTES AUR
# ==============================
if [[ "$INSTALL_YAY" == true && ${#AUR_PACKAGES[@]} -gt 0 ]]; then
    echo "Instalando pacotes AUR..."
    set +e
    for pkg in "${AUR_PACKAGES[@]}"; do
        install_aur_pkg "$pkg"
    done
    set -e
fi

# ==============================
# CHECKLIST FINAL
# ==============================
echo
echo "=============================="
echo "📦 CHECKLIST DE INSTALAÇÃO"
echo "=============================="

for pkg in "${!INSTALL_STATUS[@]}"; do
    if [[ "${INSTALL_STATUS[$pkg]}" == "OK" ]]; then
        echo "✔ $pkg"
    else
        echo "✖ $pkg"
    fi
done

echo
echo "ℹ️ Faça logout/login para o ZSH entrar em efeito."
echo "✅ Script finalizado."
