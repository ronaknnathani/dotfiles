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

if OS.mac?
  cask "copilot-cli"
  cask "ghostty"
  cask "rectangle"
  cask "font-jetbrains-mono-nerd-font"
end

if OS.linux?
  # Linux distros default to bash; install zsh so we can exec into it
  brew "zsh"
  # On macOS, copilot-cli is a cask; on Linux the equivalent formula is just "copilot"
  brew "copilot"
end
