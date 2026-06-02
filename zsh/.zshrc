# ── PATH ─────────────────────────────────────────────────────
if [[ -d /opt/homebrew ]]; then
  export PATH="/opt/homebrew/bin:$PATH"
elif [[ -d /home/linuxbrew/.linuxbrew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
export GOPATH="$HOME/code/go"
export PATH="$HOME/.local/go/bin:$PATH"
export PATH="$PATH:$GOPATH/bin"
export PATH="$PATH:$HOME/.local/bin"
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# ── Environment ──────────────────────────────────────────────
if command -v cursor &>/dev/null; then
  export EDITOR="cursor -w"
elif command -v hx &>/dev/null; then
  export EDITOR="hx"
else
  export EDITOR="vim"
fi

# ── SSH session indicator: distinct bg, cursor, and tab title ───
# Helps tell SSH'd-into Linux VMs apart from local macOS terminals at a glance.
# Only the outer (non-tmux) shell touches the terminal: inside tmux each pane
# spawns a fresh interactive shell, and re-emitting these escapes per pane
# corrupts the display. Inside tmux the tab title is handled by set-titles in
# ~/.tmux.conf instead.
if [[ "$OSTYPE" == linux* ]] && [[ -o interactive ]] && [[ -n "$SSH_CONNECTION" ]] && [[ -z "$TMUX" ]]; then
  autoload -Uz add-zsh-hook
  printf '\e]11;#1a1f3a\a'                          # OSC 11: dark navy background
  printf '\e]2;🖥 VM: %s\a' "$(hostname -s)"        # OSC 2:  window/tab title

  # Re-assert the orange cursor on every prompt. tmux resets the cursor color
  # when you attach/detach, so a one-time OSC 12 at startup doesn't survive
  # returning to this outer shell. (Inside tmux, cursor-colour in ~/.tmux.conf
  # keeps it orange.)
  _ssh_cursor() { printf '\e]12;#ff9e3b\a'; }       # OSC 12: orange cursor
  _ssh_cursor
  add-zsh-hook precmd _ssh_cursor

  # Restore the terminal when the SSH shell exits, so the local macOS terminal
  # isn't left with the navy background, orange cursor, an invisible cursor, or
  # a shifted charset (the "random characters / no cursor" garbling on logout).
  _ssh_term_restore() {
    printf '\e]111;\a'   # OSC 111: reset background to default
    printf '\e]112;\a'   # OSC 112: reset cursor color to default
    printf '\e[0m'       # reset text attributes (SGR)
    printf '\e(B'        # restore ASCII charset (fixes garbled characters)
    printf '\e[?25h'     # ensure the cursor is visible
  }
  add-zsh-hook zshexit _ssh_term_restore
fi

# ── History ──────────────────────────────────────────────────
setopt SHARE_HISTORY
setopt HIST_IGNORE_SPACE
setopt BANG_HIST
bindkey ' ' magic-space

# ── Zinit ────────────────────────────────────────────────────
source "$(brew --prefix)/opt/zinit/zinit.zsh"
export ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
mkdir -p "$ZSH_CACHE_DIR/completions"
fpath=("$ZSH_CACHE_DIR/completions" $fpath)

# OMZ git helper functions (needed by OMZP::git aliases)
function git_current_branch() {
  local ref
  ref=$(git symbolic-ref --quiet HEAD 2>/dev/null)
  [[ $? != 0 ]] && ref=$(git rev-parse --short HEAD 2>/dev/null) || ref=${ref#refs/heads/}
  echo "$ref"
}
function git_main_branch() {
  local ref
  for ref in main master trunk; do
    if git show-ref -q --verify "refs/heads/$ref" 2>/dev/null; then
      echo "$ref"
      return
    fi
  done
  echo "main"
}

# Turbo-loaded plugins (deferred — prompt renders first)
zinit wait lucid for \
  OMZP::git \
  OMZP::kubectl \
  light-mode zsh-users/zsh-autosuggestions \
  light-mode hlissner/zsh-autopair \
  light-mode wfxr/forgit \
  light-mode trapd00r/LS_COLORS \
  light-mode Aloxaf/fzf-tab

# Option+Backspace deletes subword (stops at - / $ # . _ etc), Ctrl+W deletes whole word
WORDCHARS=''
_kill_whole_word() {
  local WORDCHARS='*?_-.[]~=/&;!#$%^(){}<>'
  zle backward-kill-word
}
zle -N _kill_whole_word
bindkey '^W' _kill_whole_word

# Loaded synchronously (must hook into zle before Ghostty's shell integration)
zinit lucid for \
  light-mode atload"zicompinit; zicdreplay" zdharma-continuum/fast-syntax-highlighting


# ── Tool inits ───────────────────────────────────────────────
eval "$(oh-my-posh init zsh --config $HOME/.config/oh-my-posh/theme.omp.json)"
eval "$(fzf --zsh)"
eval "$(atuin init zsh --disable-up-arrow)"
eval "$(zoxide init zsh)"

# ── FZF + fd + bat ───────────────────────────────────────────
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

# Catppuccin Mocha theme + layout
export FZF_DEFAULT_OPTS=" \
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
  --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
  --color=selected-bg:#45475a \
  --color=border:#6c7086,label:#cdd6f4 \
  --height=60% --layout=reverse --border=rounded \
  --prompt='  ' --pointer='▎' --marker='✓ ' \
  --preview-window='right:50%:border-left' \
  --bind='ctrl-d:half-page-down,ctrl-u:half-page-up' \
  --bind='ctrl-y:execute-silent(echo -n {+} | clip)+abort' \
"
export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :300 {} 2>/dev/null || cat {}'"
export FZF_ALT_C_OPTS="--preview 'ls -la --color=always {} | head -50'"

# ── Aliases ──────────────────────────────────────────────────
alias ll="ls -la"
alias k="kubectl"
alias gpom='git pull --rebase origin $(git_main_branch)'
alias watch='viddy'
alias gdu='gdu-go'
# Recover a terminal left in a bad state (e.g. after an SSH session that didn't
# reset colors/cursor/charset): restore line discipline + full reset (RIS).
alias fixterm='stty sane; printf "\033c"'

# ── Functions ────────────────────────────────────────────────
function digall {
  for t in AAAA A; do
    dig +noall +answer "$1" "${t}"
  done
}

# yazi: `y` opens yazi and cd's to the last visited directory on exit
function y() {
  local tmp cwd
  tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# ── Lazy-loaded tools ────────────────────────────────────────
(( $+commands[direnv] )) && eval "$(direnv hook zsh)"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Lazy-load NVM
export NVM_DIR="$HOME/.nvm"
_load_nvm() { unset -f nvm node npm npx; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; }
nvm()  { _load_nvm; nvm  "$@"; }
node() { _load_nvm; node "$@"; }
npm()  { _load_nvm; npm  "$@"; }
npx()  { _load_nvm; npx  "$@"; }

# ── Machine-specific overrides ───────────────────────────────
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
