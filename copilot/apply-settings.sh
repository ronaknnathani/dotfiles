#!/usr/bin/env bash
# Apply the tracked Copilot base settings to the live ~/.copilot/settings.json
# (repo -> machine). Deep-merges the base over the live file so curated personal
# defaults win, while machine-specific or enterprise-managed keys already present
# locally (plugins, marketplaces, caches, trusted folders, company announcements)
# are preserved. Counterpart to capture-settings.sh (machine -> repo).
#
# Called by sync.sh; the base is merged, not symlinked, because the live file is
# co-owned by you, enterprise tooling, and the CLI runtime.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base="$SCRIPT_DIR/.copilot/settings.json"
live="${COPILOT_SETTINGS:-$HOME/.copilot/settings.json}"

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
chmod 600 "$live"
echo "Applied Copilot base settings to $live"
