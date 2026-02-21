#!/bin/bash
set -e

# ==============================
# CONFIGURAÇÕES
# ==============================

INSTALL_YAY=true

AUR_PACKAGES=(
    waypaper
    google-chrome
    wf-recorder
    catppuccin-gtk-theme-mocha
    fastfetch
    swaync
    visual-studio-code-bin
)

PACMAN_PACKAGES=(
    base-devel
    git
    curl
    firefox
    waybar
    cava
    zsh
    fish
    grim
    slurp
    starship
    hyprlock
    nautilus
    libnotify
    pavucontrol
    swww
    zed
    rust
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

# ==============================
# VARIÁVEIS
# ==============================

CURRENT_USER=$(whoami)
USER_HOME="$HOME"
USER_CONFIG="$HOME/.config"
USER_BIN="$HOME/.local/bin"

declare -A INSTALL_STATUS

# ==============================
# FUNÇÕES
# ==============================

run_user() {
    "$@"
}

run_root() {
    sudo "$@"
}

install_pacman_pkg() {
    local pkg="$1"
    if sudo pacman -S --needed --noconfirm "$pkg"; then
        INSTALL_STATUS["$pkg"]="OK"
    else
        INSTALL_STATUS["$pkg"]="ERRO"
    fi
}

install_aur_pkg() {
    local pkg="$1"
    if yay -S --needed --noconfirm "$pkg"; then
        INSTALL_STATUS["$pkg (AUR)"]="OK"
    else
        INSTALL_STATUS["$pkg (AUR)"]="ERRO"
    fi
}

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
# CRIAR PASTAS DO USUÁRIO
# ==============================

echo "Criando diretórios do usuário..."

mkdir -p "$USER_CONFIG"
mkdir -p "$USER_BIN"

# ==============================
# COPIAR DOTFILES
# ==============================

echo "Copiando dotfiles..."

if [[ -d "./.config" ]]; then
    cp -rT "./.config" "$USER_CONFIG"
fi

if [[ -d "./.local/bin" ]]; then
    cp -rT "./.local/bin" "$USER_BIN"
    chmod +x "$USER_BIN"/* 2>/dev/null || true
fi

# ==============================
# ATUALIZAR SISTEMA
# ==============================

echo "Atualizando sistema..."
sudo pacman -Syu --noconfirm

# ==============================
# INSTALAR PACOTES OFICIAIS
# ==============================

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

    if ! grep -qx "$path" /etc/shells; then
        echo "$path" | sudo tee -a /etc/shells
    fi

    chsh -s "$path"
}

if [[ "$TARGET_SHELL" != "bash" ]]; then
    set_user_shell "$TARGET_SHELL"
fi

# ==============================
# CONFIGURAR STARSHIP
# ==============================

echo "Configurando Starship..."

if [[ "$TARGET_SHELL" == "bash" ]]; then

    grep -q "starship init bash" "$HOME/.bashrc" 2>/dev/null || \
        echo 'eval "$(starship init bash)"' >> "$HOME/.bashrc"

elif [[ "$TARGET_SHELL" == "zsh" ]]; then

    grep -q "starship init zsh" "$HOME/.zshrc" 2>/dev/null || \
        echo 'eval "$(starship init zsh)"' >> "$HOME/.zshrc"

elif [[ "$TARGET_SHELL" == "fish" ]]; then

    mkdir -p "$HOME/.config/fish"

    grep -q "starship init fish" "$HOME/.config/fish/config.fish" 2>/dev/null || \
        echo 'starship init fish | source' >> "$HOME/.config/fish/config.fish"

fi

# ==============================
# INSTALAR YAY
# ==============================

if [[ "$INSTALL_YAY" == true && ! $(command -v yay) ]]; then

    echo "Instalando yay..."

    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm

fi

# ==============================
# INSTALAR PACOTES AUR
# ==============================

if [[ "$INSTALL_YAY" == true ]]; then

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
echo "📦 CHECKLIST DE INSTALAÇÃO"

for pkg in "${!INSTALL_STATUS[@]}"; do

    if [[ "${INSTALL_STATUS[$pkg]}" == "OK" ]]; then
        echo "✔ $pkg"
    else
        echo "✖ $pkg"
    fi

done

echo
echo "✅ Instalação concluída com sucesso!"
echo
echo "ℹ️ Reinicie ou faça logout/login para aplicar tudo."
