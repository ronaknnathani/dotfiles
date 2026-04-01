#!/bin/bash
set -e

if [[ "$(uname)" != "Linux" ]]; then
  echo "This script is for Linux. Use install.sh for macOS."
  exit 1
fi

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
STOW_PACKAGES=(zsh git ghostty oh-my-posh atuin helix)

# Homebrew (Linuxbrew)
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

echo "Installing packages..."
# Install formulae (casks not supported on Linux)
brew install zinit oh-my-posh fzf fd bat ripgrep zoxide atuin viddy helix diff-so-fancy git-delta stow direnv

# Ghostty (build from source or install via package manager)
if ! command -v ghostty &>/dev/null; then
  echo ""
  echo "NOTE: Ghostty must be installed separately on Linux."
  echo "  See: https://ghostty.org/docs/install/linux"
fi

# JetBrainsMono Nerd Font
if ! fc-list | grep -qi "JetBrainsMono.*Nerd"; then
  echo "Installing JetBrainsMono Nerd Font..."
  mkdir -p ~/.local/share/fonts
  curl -fLo /tmp/JetBrainsMono.tar.xz \
    "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
  tar -xf /tmp/JetBrainsMono.tar.xz -C ~/.local/share/fonts/
  fc-cache -fv ~/.local/share/fonts/ >/dev/null 2>&1
  rm /tmp/JetBrainsMono.tar.xz
fi

# Backup conflicting files
echo "Backing up existing configs to $BACKUP_DIR..."
mkdir -p "$BACKUP_DIR"
for pkg in "${STOW_PACKAGES[@]}"; do
  find "$DOTFILES_DIR/$pkg" -type f | while read -r src; do
    rel="${src#$DOTFILES_DIR/$pkg/}"
    target="$HOME/$rel"
    if [[ -f "$target" && ! -L "$target" ]]; then
      mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
      cp "$target" "$BACKUP_DIR/$rel"
      echo "  Backed up: ~/$rel"
    fi
  done
done

# Stow packages
echo "Linking dotfiles..."
cd "$DOTFILES_DIR"
for pkg in "${STOW_PACKAGES[@]}"; do
  stow --adopt -t "$HOME" "$pkg"
  git checkout -- "$pkg"
done

# Import shell history into atuin
if command -v atuin &>/dev/null; then
  echo "Importing shell history into atuin..."
  atuin import zsh 2>/dev/null || true
fi

echo ""
echo "Done! Open a new terminal tab to see the changes."
echo ""
echo "Post-install:"
echo "  1. Update email in ~/.gitconfig"
echo "  2. Add machine-specific config to ~/.zshrc.local"
