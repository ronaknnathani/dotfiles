# Exec into zsh on interactive shells when zsh is available.
# Needed for accounts whose login shell can't be changed via chsh
# (e.g. LDAP/NSS-managed corporate users where chsh refuses with
# "user does not exist in /etc/passwd").
if [[ -z "$ZSH_VERSION" ]] && [[ $- == *i* ]] && command -v zsh &>/dev/null; then
  exec zsh
fi
