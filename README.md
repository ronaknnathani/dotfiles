# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/). Unified Catppuccin Mocha theme across all tools. Shell startup is ~300ms with zinit turbo mode deferring plugin loading until after the prompt renders.

## Install

**macOS:**
```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/code/dotfiles
cd ~/code/dotfiles
./install.sh
```

**Linux:**
```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/code/dotfiles
cd ~/code/dotfiles
./install-linux.sh
```

Both scripts install Homebrew (if missing), all dependencies, back up any conflicting configs to `~/dotfiles_backup/`, and symlink everything via Stow. Zinit auto-downloads all zsh plugins on first shell startup.

## Post-install

1. Update your email in `~/.gitconfig`
2. Open a new terminal tab
3. Reload Ghostty config: `Cmd+Shift+,`
4. Add machine-specific config (work aliases, credentials, etc.) to `~/.zshrc.local`

## What's included

### Shell (zsh + zinit)

The shell is configured with [zinit](https://github.com/zdharma-continuum/zinit) as the plugin manager, replacing oh-my-zsh. All plugins load asynchronously via turbo mode so the prompt appears instantly.

**Plugins:**
- [OMZP::git](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git) -- 197 git aliases (`gst`, `gco`, `gcm`, `gp`, `gl`, etc.). `gcm` auto-detects `main` vs `master`.
- [OMZP::kubectl](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/kubectl) -- ~80 kubectl aliases (`kgp`, `kgd`, `kl`, `klf`, etc.) plus tab completion.
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) -- ghost-text completions from history (accept with right-arrow).
- [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting) -- real-time command highlighting with per-command awareness. Valid commands are green, invalid are red.
- [fzf-tab](https://github.com/Aloxaf/fzf-tab) -- replaces default tab completion with fzf-powered fuzzy matching and previews.
- [forgit](https://github.com/wfxr/forgit) -- interactive git commands with fzf (`forgit::log`, `forgit::diff`, `forgit::add`).
- [zsh-autopair](https://github.com/hlissner/zsh-autopair) -- auto-closes brackets, quotes, and parens.
- [LS_COLORS](https://github.com/trapd00r/LS_COLORS) -- improved directory/file colors for `ls` output.

**NVM** is lazy-loaded (only sourced when you first call `nvm`, `node`, `npm`, or `npx`), saving ~2s on every shell startup.

### Prompt (oh-my-posh)

[Oh-My-Posh](https://ohmyposh.dev/) with a custom Catppuccin Mocha theme showing:
- Kubernetes context and namespace (teal, with color-coding for prod/staging)
- Current directory with repo-relative path (pink)
- Git branch and status -- clean (lavender), staged changes (sky), working changes (peach), both (mauve)
- Command execution time for slow commands >2s (peach)
- Date and time (right-aligned)
- Status indicator: green `>` on success, red on error

### Fuzzy finding (fzf + fd + bat)

[fzf](https://github.com/junegunn/fzf) configured with [fd](https://github.com/sharkdp/fd) as the backend and [bat](https://github.com/sharkdp/bat) for previews, themed with Catppuccin Mocha colors.

- `Ctrl-T` -- fuzzy file search with syntax-highlighted preview
- `Alt-C` -- fuzzy directory jump with listing preview
- `Ctrl-R` -- handled by atuin (see below)
- `Ctrl-Y` -- copy selected item to clipboard
- `Ctrl-D/U` -- half-page scroll in results

### Shell history (atuin)

[Atuin](https://github.com/atuinsh/atuin) replaces `Ctrl-R` with full-screen fuzzy history search. SQLite-backed, cross-session, deduplicated. Filters secrets (tokens, passwords) from being recorded. Local-only sync.

### Directory jumping (zoxide)

[zoxide](https://github.com/ajeetdsouza/zoxide) learns your most-used directories. `z dotfiles` jumps to `~/code/dotfiles`, `zi` opens an interactive picker.

### Terminal (Ghostty)

[Ghostty](https://ghostty.org/) configured with:
- Theme: Catppuccin Mocha
- Font: JetBrainsMono Nerd Font, 18pt bold
- Copy-on-select to clipboard
- Mouse hides while typing
- 10px window padding
- 50% opacity for unfocused splits
- `Cmd+Left/Right` to switch tabs

### Editor (Helix)

[Helix](https://helix-editor.com/) configured with:
- Theme: Catppuccin Mocha
- Relative line numbers
- Auto-save on focus loss and after 1s delay
- Soft-wrap enabled
- Inline diagnostics (warnings on cursor line, hints at end of line)
- YAML language server with Kubernetes schema validation

### Git

- [diff-so-fancy](https://github.com/so-fancy/diff-so-fancy) as the pager for readable diffs
- [delta](https://github.com/dandavison/delta) for interactive rebase diffs
- Global gitignore for `.claude/settings.local.json`, `.DS_Store`, `.env`

### Other tools

- [viddy](https://github.com/sachaos/viddy) -- modern `watch` replacement with diff highlighting (aliased as `watch`)
- [direnv](https://direnv.net/) -- auto-loads `.envrc` when entering a directory
- [ripgrep](https://github.com/BurntSushi/ripgrep) -- fast recursive grep

## Stow packages

```
dotfiles/
├── install.sh              # macOS installer
├── install-linux.sh        # Linux installer
├── Brewfile                # Homebrew dependencies
├── zsh/.zshrc              # Shell config (zinit, plugins, fzf, aliases)
├── git/.gitconfig          # Git user config, diff-so-fancy, delta
├── git/.config/git/ignore  # Global gitignore
├── ghostty/.config/ghostty/config
├── oh-my-posh/.config/oh-my-posh/theme.omp.json
├── atuin/.config/atuin/config.toml
├── helix/.config/helix/config.toml
└── helix/.config/helix/languages.toml
```

## Machine-specific config

The `.zshrc` sources `~/.zshrc.local` at the end if it exists. Use this for work-specific aliases, credentials, proxy settings, or anything that shouldn't be in a public repo.

## Key bindings cheat sheet

| Binding | Action |
|---------|--------|
| `Ctrl-T` | Fuzzy file search (fzf + fd + bat preview) |
| `Ctrl-R` | Fuzzy history search (atuin) |
| `Alt-C` | Fuzzy directory jump (fzf + fd) |
| `Ctrl-Y` | Copy fzf selection to clipboard |
| `z <partial>` | Jump to frequent directory (zoxide) |
| `zi` | Interactive directory picker (zoxide) |
| `Cmd+Left/Right` | Switch Ghostty tabs |
| `Cmd+Shift+,` | Reload Ghostty config |
