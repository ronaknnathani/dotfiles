#!/usr/bin/env bash
# Capture personal Copilot CLI settings from the live ~/.copilot/settings.json
# into the tracked base (copilot/.copilot/settings.json) — the "push to repo"
# direction that install.sh's merge doesn't do.
#
# Only an allowlist of portable, leak-safe personal keys is captured. Keys that
# can carry machine-specific or enterprise-managed data (statusLine paths,
# allowedUrls, disabledSkills, extraKnownMarketplaces, enabledPlugins,
# companyAnnouncements, caches, trustedFolders) are NEVER captured; the base
# keeps its hand-maintained values for those. A safety net refuses to write if
# anything that looks machine/enterprise-specific slips through.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
live="${COPILOT_SETTINGS:-$HOME/.copilot/settings.json}"
base="$SCRIPT_DIR/.copilot/settings.json"

# Portable, personal, leak-safe keys only. Do NOT add keys that can contain
# paths, URLs, plugin names, marketplaces, or skill IDs.
ALLOWLIST=(model effortLevel contextTier colorMode theme)

if [[ ! -f "$live" ]]; then
  echo "No live settings at $live" >&2
  exit 1
fi
if [[ ! -f "$base" ]]; then
  echo "No tracked base at $base" >&2
  exit 1
fi

allow_json="$(printf '%s\n' "${ALLOWLIST[@]}" | jq -R . | jq -s .)"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

# base overlaid with the allowlisted keys pulled from the live settings
jq -s --argjson allow "$allow_json" '
  .[0] as $base | .[1] as $live
  | $base * ($live | with_entries(select(.key as $k | $allow | index($k) != null)))
' "$base" "$live" > "$tmp"

# Safety net: never let machine-specific or enterprise data into the tracked base.
forbidden='linkedin|/Users/|/home/|nimbus|foundry|corp|lva1|enterprise-security|li-plugin|li-agent|observe-agent|model-foundry|context-repo|unit-tests@'
if grep -Eiq "$forbidden" "$tmp"; then
  echo "Refusing to write: captured settings contain machine/enterprise-specific data:" >&2
  grep -Ein "$forbidden" "$tmp" >&2
  exit 1
fi

jq empty "$tmp"

if cmp -s "$tmp" "$base"; then
  echo "No change — tracked base already matches your personal settings."
  exit 0
fi

mv "$tmp" "$base"
trap - EXIT
echo "Captured personal settings into $base"
jq --argjson allow "$allow_json" 'with_entries(select(.key as $k | $allow | index($k) != null))' "$base"
