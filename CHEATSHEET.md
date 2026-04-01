# Cheatsheet

## Fuzzy Finding (fzf + fd + bat)

Everything is themed with Catppuccin Mocha. fd respects `.gitignore` automatically.

| Binding | What it does |
|---------|-------------|
| `Ctrl-T` | Search files with syntax-highlighted preview. Start typing to filter. |
| `Alt-C` | Jump to a directory. Shows listing preview. |
| `Ctrl-Y` | Copy current fzf selection to clipboard |
| `Ctrl-D / Ctrl-U` | Scroll half-page down/up in fzf results |
| `**<TAB>` | Trigger fzf completion inline (e.g., `cd **<TAB>`, `vim **<TAB>`) |

**fd standalone:**
```bash
fd pattern           # find files matching pattern (recursive, respects .gitignore)
fd -t d              # find directories only
fd -e yaml           # find by extension
fd -H                # include hidden files
```

**bat standalone:**
```bash
bat file.py          # cat with syntax highlighting and line numbers
bat -l yaml file     # force a specific language
bat --diff file      # show git diff for file
```

## Shell History (atuin)

| Binding | What it does |
|---------|-------------|
| `Ctrl-R` | Open full-screen fuzzy history search |
| Up arrow | Normal zsh history (atuin doesn't override this) |

In the atuin search UI:
- Type to fuzzy-filter across all history
- `Enter` to execute the selected command
- `Tab` to paste it into the prompt for editing
- `Ctrl-D` to delete an entry

Atuin automatically filters secrets (commands containing SECRET, TOKEN, PASSWORD) and noise (`ls`, `clear`) from being recorded.

## Directory Jumping (zoxide)

zoxide learns directories as you `cd` into them. The more you visit, the higher they rank.

```bash
z dotfiles           # jump to best match for "dotfiles"
z nim                # jump to best match for "nim" (e.g., ~/code/nimbus)
z go src             # match multiple words
zi                   # interactive picker with fzf
```

`z` replaces `cd` for frequent directories. For new directories you haven't visited yet, use `cd` normally -- zoxide learns it for next time.

## Git Aliases (OMZP::git)

197 aliases. The most useful ones:

**Status and diff:**
```bash
gst                  # git status
gd                   # git diff
gds                  # git diff --staged
glog                 # git log --oneline --decorate --graph
gloga                # git log --oneline --decorate --graph --all
```

**Branching:**
```bash
gb                   # git branch
gba                  # git branch --all
gcb feature-name     # git checkout -b feature-name
gco branch-name      # git checkout branch-name
gcm                  # git checkout main (auto-detects main vs master)
gcd                  # git checkout develop
```

**Committing:**
```bash
ga file              # git add file
gaa                  # git add --all
gc                   # git commit
gcam "message"       # git commit --all --message "message"
gc!                  # git commit --amend
```

**Push and pull:**
```bash
gl                   # git pull
gp                   # git push
gpf                  # git push --force-with-lease (safe force push)
gpsup                # git push --set-upstream origin $(current_branch)
```

**Rebase and merge:**
```bash
grb                  # git rebase
grbm                 # git rebase $(main_branch)
grba                 # git rebase --abort
grbc                 # git rebase --continue
gm branch            # git merge branch
```

**Stash:**
```bash
gsta                 # git stash push
gstp                 # git stash pop
gstl                 # git stash list
gstd                 # git stash drop
```

## Interactive Git (forgit)

All forgit commands open an fzf-powered interactive view.

```bash
forgit::log          # browse git log with preview (also: glo)
forgit::diff         # browse changed files with diff preview (also: gd)
forgit::add          # stage files interactively with diff preview (also: ga)
forgit::reset::head  # unstage files interactively
forgit::stash::show  # browse stash entries with preview
forgit::checkout::branch  # switch branches with preview
forgit::clean        # interactively clean untracked files
```

## Kubectl Aliases (OMZP::kubectl)

Pattern: `k` + action + resource. Actions: `g`=get, `d`=describe, `del`=delete, `e`=edit. Resources: `p`=pods, `d`=deployment, `s`=svc, `ns`=namespaces, `no`=nodes.

**Pods:**
```bash
kgp                  # kubectl get pods
kgpa                 # kubectl get pods --all-namespaces
kgpwide              # kubectl get pods -o wide
kdp                  # kubectl describe pods
kdelp                # kubectl delete pods
kgpw                 # kubectl get pods --watch
```

**Deployments:**
```bash
kgd                  # kubectl get deployment
kdd                  # kubectl describe deployment
ked                  # kubectl edit deployment
ksd                  # kubectl scale deployment
krsd                 # kubectl rollout status deployment
krrd                 # kubectl rollout restart deployment
```

**Services and ingress:**
```bash
kgs                  # kubectl get svc
kds                  # kubectl describe svc
kgi                  # kubectl get ingress
```

**Logs:**
```bash
kl                   # kubectl logs
klf                  # kubectl logs -f (follow)
kl1h                 # kubectl logs --since 1h
kl1m                 # kubectl logs --since 1m
```

**Context and namespace:**
```bash
kcuc context-name    # kubectl config use-context
kcgc                 # kubectl config get-contexts
kccc                 # kubectl config current-context
kcn namespace        # set namespace for current context
```

**Other:**
```bash
kaf file.yaml        # kubectl apply -f
keti pod-name        # kubectl exec -ti (interactive shell)
kgno                 # kubectl get nodes
kge                  # kubectl get events (sorted by time)
kga                  # kubectl get all
kj get pods          # output as JSON piped to jq
```

## Tab Completion (fzf-tab)

fzf-tab replaces the default zsh tab completion with fzf. Just use `TAB` as normal -- it now shows a fuzzy-searchable list with previews.

```bash
cd <TAB>             # fuzzy directory picker
git checkout <TAB>   # fuzzy branch picker
kubectl get pods <TAB>  # fuzzy pod picker
kill <TAB>           # fuzzy process picker
ssh <TAB>            # fuzzy host picker
```

## Watch (viddy)

`watch` is aliased to `viddy`, which adds diff highlighting and time-machine.

```bash
watch kubectl get pods       # refresh every 2s with diff highlighting
watch -n 5 curl http://...   # custom interval
```

In viddy:
- `d` toggle diff highlighting
- `t` toggle time-machine mode (scroll through past outputs with arrow keys)
- `q` quit

## Better Git Diffs (diff-so-fancy + delta)

These work automatically -- no extra commands needed.

- `git diff` and `git log -p` use diff-so-fancy for readable output
- `git add -p` (interactive staging) uses delta for syntax-highlighted diffs

## Helix Editor

Modal editor (vim-like but selection-first). The binary is `hx`.

```bash
hx                   # open helix
hx file.yaml         # open a file
hx --health          # check language servers
```

**Navigation:**
```
h/j/k/l              move left/down/up/right
w/b                   word forward/backward
gg / G                top / bottom of file
Ctrl-D / Ctrl-U       half-page down/up
f<char>               find char forward
```

**Selection (select first, then act):**
```
v                     toggle select mode
x                     select entire line
%                     select entire file
s                     search within selection
```

**Editing:**
```
i / a                 insert before / after cursor
o / O                 new line below / above
d                     delete selection
c                     change (delete + insert)
y / p                 yank (copy) / paste
u / U                 undo / redo
> / <                 indent / dedent
```

**Commands (press `:`):**
```
:w                    save
:q                    quit
:wq                   save and quit
:o file               open file
:theme name           switch theme
```

**File picker:** `Space-f` opens fuzzy file finder. `Space-b` opens buffer picker.

Your config: Catppuccin Mocha theme, relative line numbers (great for `10j` jumps), auto-save on focus loss, YAML with Kubernetes schema validation.

## Ghostty Terminal

| Binding | Action |
|---------|--------|
| `Cmd+T` | New tab |
| `Cmd+Left/Right` | Switch tabs |
| `Cmd+D` | Split pane |
| `Cmd+Shift+,` | Reload config |
| Select text | Auto-copies to clipboard |

## Oh-My-Posh Prompt

Your prompt shows (left to right):
1. Kubernetes context + namespace (teal)
2. Directory path (pink)
3. Git branch + status (lavender/peach/sky depending on state)
4. Execution time for commands >2s (peach)
5. Date and time (right side, muted)
6. Second line: `>` green = last command succeeded, red = failed

## Machine-Specific Config

Add anything private to `~/.zshrc.local` -- it's sourced at the end of `.zshrc` and not tracked by git.

```bash
# Example ~/.zshrc.local
source ~/.azurerc
alias deploy="kubectl apply -f deploy/"
export GITHUB_TOKEN="..."
```

## After Upgrading Tools

Zinit plugins update automatically. For brew tools:

```bash
brew upgrade
```

No cache to refresh -- everything re-evaluates on shell startup.
