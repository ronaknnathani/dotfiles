#!/usr/bin/env bash
# Stow every package in this dotfiles repo into $HOME, then apply config that
# can't be symlinked (Copilot settings are merged into the live file).
# Idempotent: re-running picks up new packages and new files in existing packages.
# Pass --adopt for first-run adoption of pre-existing files (used by install.sh).
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DOTFILES_DIR"

if ! command -v stow &>/dev/null; then
  echo "stow not found on PATH" >&2
  exit 1
fi

adopt=0
[[ "${1:-}" == "--adopt" ]] && adopt=1

for pkg in */; do
  pkg="${pkg%/}"
  echo "Stowing $pkg..."
  if [[ "$adopt" == 1 ]]; then
    # --adopt pulls any pre-existing real file into the repo, then we revert it
    # so the tracked version wins and the target becomes a symlink.
    stow --adopt --no-folding -t "$HOME" "$pkg"
    git checkout -- "$pkg"
  else
    stow -t "$HOME" "$pkg"
  fi
done

# Apply non-stowed Copilot settings (merged into the live ~/.copilot/settings.json).
"$DOTFILES_DIR/copilot/apply-settings.sh"

echo "Done."
