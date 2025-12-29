#!/usr/bin/env bash
set -euo pipefail

# ========================================
# CONFIGURATION
# ========================================
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
ALIAS_FILE="$ZSH_CUSTOM/aliases.zsh"
MACRO_FILE="$ZSH_CUSTOM/macros.zsh"
PACKAGES=(
    git
    curl
    wget
    neovim
    fzf
    zsh
    btop
    unzip
    tar
    hyfetch
    build-essential
    python3.13-venv

)

# ========================================
# FUNCTION DEFINITIONS
# ========================================

install_packages() {
    echo "Installing packages..."
    sudo apt update
    sudo apt install -y "${PACKAGES[@]}"
}

install_zsh() {
    echo "Installing Zsh and making it default..."
    sudo apt install -y zsh
    chsh -s "$(which zsh)"
}

install_oh_my_zsh() {
    echo "Installing Oh My Zsh..."
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
}

install_powerlevel10k() {
    echo "Installing Powerlevel10k theme..."
    if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
    fi
}

setup_aliases() {
    echo "Creating aliases file..."
    cat > "$ALIAS_FILE" <<'EOF'
alias zshcfg="nvim ~/.zshrc"
alias nv="nvim"
alias rm='rm -Iv'
alias cp='cp -iv'
alias mv='mv -iv'
alias mkdir='mkdir -pv'
alias mem='free -h'
alias path='print -l ${PATH//:/ }'
alias hist='history | tail -50'
alias reload='source ~/.zshrc'
alias omzsh='nvim ~/.oh-my-zsh'
alias nvcfg='nvim ~/.config/nvim/init.lua'
alias nvplug='nvim ~/.config/nvim/lua'
EOF
}

setup_macros() {
    echo "Creating macros file..."
    cat > "$MACRO_FILE" <<'EOF'
nv() { nvim "${@:-.}"; }
mkcd() {
    [[ -n "$1" ]] || { echo "mkcd: missing directory name"; return 1; }
    mkdir -p "$1" && cd "$1"
}
codeprj() {
    local dir=~/Documents/code/"$1"
    [[ -d "$dir" ]] || { echo "codeprj: not found: $dir"; return 1; }
    cd "$dir"
}
extract() {
    [[ -f "$1" ]] || { echo "extract: file not found"; return 1; }
    case "$1" in
        *.tar.gz|*.tgz) tar xzf "$1" ;;
        *.tar.xz)       tar xJf "$1" ;;
        *.zip)          unzip "$1" ;;
        *) echo "extract: unknown format: $1" ;;
    esac
}
up() {
    local n=${1:-1}
    cd $(printf '%0.s../' $(seq 1 $n))
}
EOF
}

update_zshrc() {
    echo "Linking aliases and macros in .zshrc..."
    grep -qxF 'ZSH_THEME="powerlevel10k/powerlevel10k"' ~/.zshrc || sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
}

# ========================================
# MAIN SCRIPT
# ========================================

main() {
    install_packages
    install_zsh
    install_oh_my_zsh
    install_powerlevel10k
    setup_aliases
    setup_macros
    update_zshrc
    echo "Setup complete! Restart your terminal or run 'source ~/.zshrc'"
}

main "$@"
