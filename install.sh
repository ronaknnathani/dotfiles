#!/bin/bash
set -e

if [[ "$(uname)" != "Darwin" ]]; then
  echo "This script is for macOS. Use install-linux.sh for Linux."
  exit 1
fi

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
STOW_PACKAGES=(zsh git ghostty oh-my-posh atuin helix)

# Homebrew
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo "Installing packages..."
brew bundle --file="$DOTFILES_DIR/Brewfile"

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
echo "  2. Reload Ghostty: Cmd+Shift+,"
echo "  3. Add machine-specific config to ~/.zshrc.local"
