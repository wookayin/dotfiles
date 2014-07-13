# Custom Alias commands for ZSH

# Basic
alias cp='nocorrect cp -iv'
alias mv='nocorrect mv -iv'
alias rm='nocorrect rm -iv'

# Screen
alias scr='screen -rD'


# Tmux ========================================= {{{

# create a new session with name
alias tmuxnew='tmux new -s'
# list sessions
alias tmuxl='tmux list-sessions'
# tmuxa <session> : attach to <session> (force 256color and detach others)
alias tmuxa='tmux -2 attach-session -d -t'

# }}}


# More Git aliases
# (overrides przto's git/alias.zsh)

alias gh='git history'
alias gha='gh --all'
alias gd='git diff --no-prefix'
alias gdc='gd --cached --no-prefix'
alias gds='gd --staged --no-prefix'
alias gs='git status'
alias gsu='gs -u'

