# Dotfiles

Personal dotfiles managed with GNU Stow. Catppuccin Mocha theme throughout.

## Structure

Each top-level directory is a Stow package that symlinks into `$HOME`:

- `zsh/` - Shell config (zinit, plugins, fzf, aliases)
- `git/` - Git config (diff-so-fancy, delta, global gitignore)
- `ghostty/` - Ghostty terminal config
- `oh-my-posh/` - Shell prompt theme + Claude Code status line theme
- `atuin/` - Shell history config
- `helix/` - Editor config

## Key decisions

- **Zinit over oh-my-zsh** for speed (~300ms startup). All plugins turbo-loaded except fast-syntax-highlighting which must load synchronously to avoid Ghostty zle conflicts.
- **OMZP::git and OMZP::kubectl** provide aliases and completions. Don't add manual aliases that shadow them (e.g., `gcm`, `k`, `gst` are already defined by the plugins). `gcm` auto-detects `main` vs `master`.
- **No LinkedIn-specific content.** Machine-specific config goes in `~/.zshrc.local` which is sourced at the end of `.zshrc`.
- **NVM is lazy-loaded** to avoid 2s startup penalty. Only triggers on first `nvm`/`node`/`npm`/`npx` call.
- **`ZSH_CACHE_DIR` must be set and on `fpath`** before OMZP::kubectl loads, or kubectl completions break.

## Conventions

- Commits to this repo should use the noreply email: `7279934+ronaknnathani@users.noreply.github.com`
- The `.gitconfig` in the repo has a placeholder email -- users update it after install.
- Two install scripts: `install.sh` (macOS), `install-linux.sh` (Linux). Both use Homebrew.
- The portable `.zshrc` uses `$(brew --prefix)` for zinit path to support both macOS and Linux brew locations.

## Files not in this repo

- `~/.zshrc.local` - Machine-specific overrides (work aliases, credentials, proxies)
- `~/.config/oh-my-posh/theme-original.omp.json` - Backup of original prompt theme with icons
- `~/.claude/statusline-command.sh.bak` - Backup of old bash-based Claude status line
