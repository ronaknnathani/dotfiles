brew "zinit"
brew "oh-my-posh"
brew "fzf"
brew "fd"
brew "bat"
brew "ripgrep"
brew "zoxide"
brew "atuin"
brew "viddy"
brew "helix"
brew "yazi"
brew "diff-so-fancy"
brew "git-delta"
brew "stow"
brew "direnv"
brew "tmux"
brew "jq"
brew "gh"
brew "kubectx"
brew "hugo"
brew "netlify-cli"

# GitHub Copilot CLI — distributed only as a cask (a single `copilot` binary), but
# `brew install copilot-cli` installs it on both macOS and Linux. Not the `copilot`
# formula, which is the unrelated AWS ECS/Fargate CLI.
cask "copilot-cli"

if OS.mac?
  cask "ghostty"
  cask "rectangle"
  cask "font-jetbrains-mono-nerd-font"
end

if OS.linux?
  # Linux distros default to bash; install zsh so we can exec into it
  brew "zsh"
end
