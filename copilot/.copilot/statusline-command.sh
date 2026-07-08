#!/bin/bash
set -euo pipefail

input=$(cat)

color() {
  printf '\033[%sm%s\033[0m' "$1" "$2"
}

teal='38;2;148;226;213'
pink='38;2;245;194;231'
lavender='38;2;180;190;254'
blue='38;2;137;180;250'
green='38;2;166;227;161'
peach='38;2;250;179;135'
yellow='38;2;249;226;175'
red='38;2;243;139;168'

jq_value() {
  jq -er "$1 // empty" <<<"$input" 2>/dev/null || true
}

format_tokens() {
  local tokens=$1

  awk -v tokens="$tokens" '
    function trim(value) {
      sub(/\.0$/, "", value)
      return value
    }
    BEGIN {
      if (tokens >= 1000000) {
        printf "%sM", trim(sprintf("%.1f", tokens / 1000000))
      } else if (tokens >= 1000) {
        printf "%sK", trim(sprintf("%.1f", tokens / 1000))
      } else {
        printf "%d", tokens
      }
    }
  '
}

cwd=$(jq_value '.workspace.current_dir // .cwd')
[ -z "$cwd" ] && cwd="$PWD"

kube_info=""
if command -v kubectl >/dev/null 2>&1; then
  context=$(kubectl config current-context 2>/dev/null || true)
  namespace=$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null || true)
  [ -n "$context" ] && kube_info="$(color "$teal" "$context:$namespace")"
fi

path_info="$(color "$pink" "$(basename "$cwd")")"
[ "$cwd" = "$HOME" ] && path_info="$(color "$pink" '~')"

git_info=""
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null || true)
  [ -n "$branch" ] && git_info=" | $(color "$blue" " $branch")"
fi

model=$(jq_value '.model.display_name // .model.id // .model')
effort=$(jq_value '.effort // .effort_level // .reasoning_effort // .model.effort // .model.effort_level')
context_limit=$(jq_value '.context_window.displayed_context_limit // .context_window.context_window_size')
used_pct=$(jq_value '.context_window.current_context_used_percentage // .context_window.used_percentage')
ai_used=$(jq_value '.ai_used.formatted')
premium_requests=$(jq_value '.cost.total_premium_requests')

model_parts=()
[ -n "$model" ] && model_parts+=("$model")
if [ -n "$effort" ] && [[ "$model" != *"$effort"* ]]; then
  model_parts+=("$effort")
fi
if [ -n "$context_limit" ]; then
  context_label="$(format_tokens "$context_limit") context"
  if [[ "$model" != *"$context_label"* ]] && [[ "$model" != *" context"* ]]; then
    model_parts+=("$context_label")
  fi
fi

model_info=""
if [ ${#model_parts[@]} -gt 0 ]; then
  model_info="${model_parts[0]}"
  for part in "${model_parts[@]:1}"; do
    model_info="$model_info · $part"
  done
fi

usage_info=""
if [ -n "$used_pct" ]; then
  used_pct=$(printf '%.0f' "$used_pct")
  pct_color="$yellow"
  [ "$used_pct" -ge 70 ] && pct_color="$peach"
  [ "$used_pct" -ge 85 ] && pct_color="$red"
  usage_info="$(color "$pct_color" "$used_pct%")"
fi

cost_info=""
if [ -n "$ai_used" ] && [ "$ai_used" != "0" ] && [ "$ai_used" != "0.00" ]; then
  cost_info="$(color "$green" "${ai_used} AIC")"
elif [ -n "$premium_requests" ]; then
  cost_info="$(color "$green" "$(printf '$%.4f' "$premium_requests")")"
fi

printf '%s' "$kube_info"
[ -n "$kube_info" ] && printf ' | '
printf '%s%s' "$path_info" "$git_info"
[ -n "$model_info" ] && printf ' | %s' "$(color "$lavender" "$model_info")"
[ -n "$usage_info" ] && printf ' | %s' "$usage_info"
[ -n "$cost_info" ] && printf ' | %s' "$cost_info"
