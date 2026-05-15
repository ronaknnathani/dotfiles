#!/usr/bin/env bash
# Stow every package in this dotfiles repo into $HOME.
# Idempotent: re-running picks up new packages and new files in existing packages.
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DOTFILES_DIR"

if ! command -v stow &>/dev/null; then
  echo "stow not found on PATH" >&2
  exit 1
fi

for pkg in */; do
  pkg="${pkg%/}"
  echo "Stowing $pkg..."
  stow -t "$HOME" "$pkg"
done

echo "Done."
