#!/bin/bash
set -e

# ==============================
# CONFIGURAÇÕES
# ==============================
INSTALL_YAY=true

AUR_PACKAGES=(
    zed-bin
    waypaper
    google-chrome
    catppuccin-gtk-theme-mocha
    fastfetch
    swaync
)

# ==============================
# CHECKLIST
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
    echo "Use sudo:"
    echo "  sudo $0"
    exit 1
fi

if [[ -z "$SUDO_USER" ]]; then
    echo "Execute via sudo por um usuário normal."
    exit 1
fi

USER_HOME=$(eval echo "~$SUDO_USER")
USER_CONFIG="$USER_HOME/.config"
USER_BIN="$USER_HOME/.local/bin"

# ==============================
# ESCOLHA DO SHELL
# ==============================
echo
echo "🐚 Escolha o shell padrão"
echo "1) Bash (padrão)"
echo "2) Zsh"
echo "3) Fish"
read -rp "Digite [1-3]: " SHELL_CHOICE

case "$SHELL_CHOICE" in
    2) TARGET_SHELL="zsh" ;;
    3) TARGET_SHELL="fish" ;;
    *) TARGET_SHELL="bash" ;;
esac

echo "Shell escolhido: $TARGET_SHELL"

# ==============================
# COPIAR DOTFILES
# ==============================
mkdir -p "$USER_CONFIG" "$USER_BIN"
cp -rT ./.config "$USER_CONFIG" 2>/dev/null || true
cp -rT ./.local/bin "$USER_BIN" 2>/dev/null || true
chmod +x "$USER_BIN"/* 2>/dev/null || true
chown -R "$SUDO_USER:$SUDO_USER" "$USER_CONFIG" "$USER_BIN"

# ==============================
# PACOTES OFICIAIS
# ==============================
PACMAN_PACKAGES=(
    base-devel
    git
    curl
    firefox
    waybar
    cava
    zsh
    fish
    starship
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
    nwg-look
    rofi
    ttf-jetbrains-mono
    ttf-jetbrains-mono-nerd
    kitty
    mpv
    imagemagick
)

echo "Atualizando sistema..."
pacman -Syu --noconfirm

echo "Instalando pacotes oficiais..."
set +e
for pkg in "${PACMAN_PACKAGES[@]}"; do
    install_pacman_pkg "$pkg"
done
set -e

# ==============================
# DEFINIR SHELL PADRÃO
# ==============================
set_user_shell() {
    local shell="$1"
    local path
    path=$(command -v "$shell") || return

    grep -qx "$path" /etc/shells || echo "$path" >> /etc/shells
    chsh -s "$path" "$SUDO_USER"
}

if [[ "$TARGET_SHELL" != "bash" ]]; then
    set_user_shell "$TARGET_SHELL"
fi

# ==============================
# CONFIGURAR STARSHIP
# ==============================
echo "Configurando Starship..."

if [[ "$TARGET_SHELL" == "bash" ]]; then
    BASHRC="$USER_HOME/.bashrc"
    grep -q "starship init bash" "$BASHRC" 2>/dev/null || \
        echo 'eval "$(starship init bash)"' >> "$BASHRC"

elif [[ "$TARGET_SHELL" == "zsh" ]]; then
    ZSHRC="$USER_HOME/.zshrc"
    grep -q "starship init zsh" "$ZSHRC" 2>/dev/null || \
        echo 'eval "$(starship init zsh)"' >> "$ZSHRC"

elif [[ "$TARGET_SHELL" == "fish" ]]; then
    FISHCFG="$USER_HOME/.config/fish/config.fish"
    mkdir -p "$(dirname "$FISHCFG")"
    grep -q "starship init fish" "$FISHCFG" 2>/dev/null || \
        echo 'starship init fish | source' >> "$FISHCFG"
fi

chown "$SUDO_USER:$SUDO_USER" \
    "$USER_HOME/.bashrc" \
    "$USER_HOME/.zshrc" \
    "$USER_HOME/.config/fish/config.fish" 2>/dev/null || true

# ==============================
# INSTALAR YAY
# ==============================
if [[ "$INSTALL_YAY" == true && ! $(command -v yay) ]]; then
    sudo -u "$SUDO_USER" bash <<EOF
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
EOF
fi

# ==============================
# INSTALAR AUR
# ==============================
if [[ "$INSTALL_YAY" == true ]]; then
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
echo "📦 CHECKLIST DE INSTALAÇÃO"
for pkg in "${!INSTALL_STATUS[@]}"; do
    [[ "${INSTALL_STATUS[$pkg]}" == "OK" ]] && echo "✔ $pkg" || echo "✖ $pkg"
done

echo
echo "ℹ️ Faça logout/login para aplicar o shell e o Starship."
echo "✅ Script finalizado com sucesso."
