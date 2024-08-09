#!/usr/bin/env zsh
# Doc: https://getantidote.github.io/options

set -eu
set -o pipefail
autoload -Uz is-at-least

local -a bundles=()
function plugin() {
  bundles+="$@"
}

# ----------------------------------------------------------------------------

# TODO: Get rid of prezto, a legacy.
# see ~/.zpreztorc for prezto config
plugin 'sorin-ionescu/prezto'

# zsh theme: powerlevel10k + customization
plugin 'romkatv/powerlevel10k'

# zsh syntax: FSH (fast-syntax-highlighting)
# theme file (XDG:wook) is at ~/.dotfiles/config/f-sy-h
plugin 'z-shell/F-Sy-H'

# More completion support
plugin 'esc/conda-zsh-completion'

# see ~/.zsh/zsh.d/envs.zsh for fzf configs
plugin 'wookayin/fzf-fasd'
plugin 'junegunn/fzf-git.sh' kind:clone

plugin 'zsh-users/zsh-autosuggestions'

# conda support: Use my own fork for a while, to support autoswitch into anaconda envs
plugin 'wookayin/zsh-autoswitch-virtualenv'

if [[ "`uname`" == "Darwin" ]]; then
  plugin 'wookayin/anybar-zsh'
fi


# ----------------------------------------------------------------------------

print -rC1 -- "${bundles[@]}"
exit 0;

# vim: set sts=2 ts=2 sw=2:
