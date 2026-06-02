# SSH login shells start as bash and source .bash_profile (not .bashrc).
# Forward to .bashrc so the zsh-exec rule there fires.
[ -f ~/.bashrc ] && . ~/.bashrc
