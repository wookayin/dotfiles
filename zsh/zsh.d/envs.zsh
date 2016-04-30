# Environment Variables and Shell Options for ZSH
# (overrides prezto's default settings or zshenv)


# fzf-powered CTRL-R: launch fzf with sort enabled
# @see https://github.com/junegunn/fzf/issues/526
export FZF_CTRL_R_OPTS='--sort'

# Save more history entries
# @see history/init.zsh
export HISTSIZE=100000
export SAVEHIST=100000

# No, I don't want share command history.
unsetopt SHARE_HISTORY
setopt NO_SHARE_HISTORY
