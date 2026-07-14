#!/bin/bash
set -e

OS="$(uname)"
case "$OS" in
  Darwin|Linux) ;;
  *) echo "Unsupported OS: $OS"; exit 1 ;;
esac

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
STOW_PACKAGES=(zsh bash git ghostty oh-my-posh atuin helix yazi tmux claude copilot agents)

# Homebrew
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ "$OS" == "Darwin" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
fi

echo "Installing packages..."
brew bundle --file="$DOTFILES_DIR/Brewfile"

# stow is required below; reinstall if brew bundle left it missing for any reason
if ! command -v stow &>/dev/null; then
  echo "stow not on PATH — installing explicitly..."
  brew install stow
fi

# GitHub Copilot CLI — use the official installer on both macOS and Linux
if command -v copilot &>/dev/null; then
  echo "GitHub Copilot CLI already installed"
else
  echo "Installing GitHub Copilot CLI..."
  curl -fsSL https://gh.io/copilot-install | bash
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
    KOS="$(uname | tr '[:upper:]' '[:lower:]')" &&
    ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
    KREW="krew-${KOS}_${ARCH}" &&
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

# kind (Kubernetes in Docker) — pinned release downloaded to ~/.local/bin (already on PATH)
if [[ -x "$HOME/.local/bin/kind" ]] || command -v kind &>/dev/null; then
  echo "kind already installed"
else
  KIND_VERSION="v0.32.0"
  case "$OS-$(uname -m)" in
    Darwin-arm64)  KIND_ASSET="kind-darwin-arm64" ;;
    Darwin-x86_64) KIND_ASSET="kind-darwin-amd64" ;;
    Linux-aarch64) KIND_ASSET="kind-linux-arm64" ;;
    Linux-x86_64)  KIND_ASSET="kind-linux-amd64" ;;
    *) KIND_ASSET="" ;;
  esac
  if [[ -z "$KIND_ASSET" ]]; then
    echo "  warn: no kind build for $OS-$(uname -m); skipping"
  else
    echo "Installing kind ${KIND_VERSION}..."
    mkdir -p "$HOME/.local/bin"
    curl -fsSL -o "$HOME/.local/bin/kind" "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/${KIND_ASSET}"
    chmod +x "$HOME/.local/bin/kind"
  fi
fi

# Go — install latest stable from go.dev (override any brew/system go via PATH)
install_go() {
  local version="$1" goos goarch
  case "$OS" in
    Darwin) goos="darwin" ;;
    Linux)  goos="linux" ;;
  esac
  case "$(uname -m)" in
    arm64|aarch64) goarch="arm64" ;;
    x86_64)        goarch="amd64" ;;
    *) echo "  unsupported arch: $(uname -m)"; return 1 ;;
  esac
  local tarball="${version}.${goos}-${goarch}.tar.gz"
  echo "  Downloading https://go.dev/dl/${tarball}..."
  local tmpdir
  tmpdir=$(mktemp -d)
  curl -fsSL -o "${tmpdir}/${tarball}" "https://go.dev/dl/${tarball}"
  rm -rf "$HOME/.local/go"
  mkdir -p "$HOME/.local"
  tar -xzf "${tmpdir}/${tarball}" -C "$HOME/.local"
  rm -rf "$tmpdir"
  export PATH="$HOME/.local/go/bin:$PATH"
  echo "  Go ${version} installed to $HOME/.local/go"
}

echo "Checking Go..."
export PATH="$HOME/.local/go/bin:$PATH"
GO_LATEST=$(curl -fsSL "https://go.dev/dl/?mode=json" 2>/dev/null \
  | jq -r '[.[] | select(.stable == true)][0].version' 2>/dev/null || true)
if [[ -z "$GO_LATEST" || "$GO_LATEST" == "null" ]]; then
  echo "  warn: could not determine latest Go version; skipping"
elif command -v go &>/dev/null; then
  GO_CURRENT=$(go version | awk '{print $3}')
  if [[ "$GO_CURRENT" == "$GO_LATEST" ]]; then
    echo "  $GO_CURRENT already installed (latest)"
  else
    echo "  $GO_CURRENT installed; latest is $GO_LATEST"
    read -p "  Upgrade? [y/N] " -n 1 -r REPLY || REPLY=""
    echo
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
      install_go "$GO_LATEST"
    fi
  fi
else
  echo "  Go not installed; installing $GO_LATEST..."
  install_go "$GO_LATEST"
fi

# Claude Code — use the official native installer on both macOS and Linux
if command -v claude &>/dev/null; then
  echo "Claude Code already installed"
else
  echo "Installing Claude Code..."
  curl -fsSL https://claude.ai/install.sh | bash
fi

# Codex — use the official non-interactive installer on both macOS and Linux
if command -v codex &>/dev/null; then
  echo "Codex already installed"
else
  echo "Installing Codex..."
  curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh
fi

# Linux-only extras
if [[ "$OS" == "Linux" ]]; then
  if ! command -v ghostty &>/dev/null; then
    echo ""
    echo "NOTE: Ghostty must be installed separately on Linux."
    echo "  See: https://ghostty.org/docs/install/linux"
  fi

  # JetBrainsMono Nerd Font (skip on headless systems without fontconfig)
  if ! command -v fc-cache &>/dev/null; then
    echo "Skipping JetBrainsMono Nerd Font install — fontconfig not present (headless system)."
  elif ! fc-list | grep -qi "JetBrainsMono.*Nerd"; then
    echo "Installing JetBrainsMono Nerd Font..."
    mkdir -p ~/.local/share/fonts
    curl -fLo /tmp/JetBrainsMono.tar.xz \
      "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
    tar -xf /tmp/JetBrainsMono.tar.xz -C ~/.local/share/fonts/
    fc-cache -fv ~/.local/share/fonts/ >/dev/null 2>&1
    rm /tmp/JetBrainsMono.tar.xz
  fi
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

# Stow packages (adopting any pre-existing files) and apply non-stowed config
# (Copilot settings). Delegated to sync.sh so the stow/apply logic lives in one
# place; --adopt makes the tracked versions win over existing dotfiles.
echo "Linking dotfiles..."
"$DOTFILES_DIR/sync.sh" --adopt

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
if [[ "$OS" == "Darwin" ]]; then
  echo "  2. Reload Ghostty: Cmd+Shift+,"
  echo "  3. Add machine-specific shell config to ~/.zshrc.local"
else
  echo "  2. Add machine-specific shell config to ~/.zshrc.local"
fi
