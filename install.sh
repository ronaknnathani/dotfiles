#!/bin/bash
set -e

if [[ "$(uname)" != "Darwin" ]]; then
  echo "This script is for macOS. Use install-linux.sh for Linux."
  exit 1
fi

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
STOW_PACKAGES=(zsh git ghostty oh-my-posh atuin helix yazi tmux claude)

# Homebrew
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo "Installing packages..."
brew bundle --file="$DOTFILES_DIR/Brewfile"

# stow is required below; reinstall if brew bundle left it missing for any reason
if ! command -v stow &>/dev/null; then
  echo "stow not on PATH — installing explicitly..."
  brew install stow
fi

# gh-dash extension (skip if already installed)
if command -v gh &>/dev/null && ! gh extension list 2>/dev/null | grep -q "dlvhdr/gh-dash"; then
  echo "Installing gh-dash extension..."
  gh extension install dlvhdr/gh-dash
fi

# krew (kubectl plugin manager) — bootstrap with the official installer
if [[ ! -x "$HOME/.krew/bin/kubectl-krew" ]]; then
  echo "Installing krew..."
  (
    cd "$(mktemp -d)" &&
    OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
    ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
    KREW="krew-${OS}_${ARCH}" &&
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
    tar zxf "${KREW}.tar.gz" &&
    ./"${KREW}" install krew
  )
fi

# kubectl plugins via krew
export PATH="$HOME/.krew/bin:$PATH"
if command -v kubectl-krew &>/dev/null; then
  echo "Updating krew plugin index..."
  kubectl krew update >/dev/null 2>&1 || true
  echo "Installing kubectl plugins via krew..."
  KREW_PLUGINS=(
    blame cond get-all images klock mc neat
    node-resource pods-on resource-capacity status stern tail tree
    view-allocations whoami
  )
  installed_plugins=$(kubectl krew list 2>/dev/null || true)
  for plugin in "${KREW_PLUGINS[@]}"; do
    if echo "$installed_plugins" | grep -qx "$plugin"; then
      continue
    fi
    kubectl krew install "$plugin" || echo "  warn: failed to install $plugin"
  done
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
echo "  1. Create ~/.gitconfig.local with your email and any per-machine git config"
echo "     (the tracked ~/.gitconfig already [include]s it)"
echo "  2. Reload Ghostty: Cmd+Shift+,"
echo "  3. Add machine-specific shell config to ~/.zshrc.local"
