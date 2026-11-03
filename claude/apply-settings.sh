#!/usr/bin/env bash
# Apply the tracked Claude Code base settings to the live ~/.claude/settings.json
# (repo -> machine). Deep-merges the base over the live file so curated personal
# defaults win, while machine-specific keys already present locally (hooks,
# marketplaces, model settings) are preserved.
#
# Called by sync.sh; the base is merged, not symlinked, because the live file is
# also written by Claude Code itself (/config, plugin installs).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base="$SCRIPT_DIR/.claude/settings.json"
live="${CLAUDE_SETTINGS:-$HOME/.claude/settings.json}"

if [[ ! -f "$base" ]]; then
  echo "No tracked base at $base" >&2
  exit 1
fi

mkdir -p "$(dirname "$live")"
[[ -f "$live" ]] || printf '{}\n' > "$live"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
jq -s '.[0] * .[1]' "$live" "$base" > "$tmp"
jq empty "$tmp"
mv "$tmp" "$live"
trap - EXIT
echo "Applied Claude base settings to $live"
