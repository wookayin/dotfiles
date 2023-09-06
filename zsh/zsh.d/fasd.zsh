# Aliases for FASD
#
# @see https://github.com/clvv/fasd

alias a='fasd -a'        # any
alias s='fasd -si'       # show / search / select
alias d='fasd -d'        # directory
alias f='fasd -f'        # file
alias sd='fasd -sid'     # interactive directory selection
alias sf='fasd -sif'     # interactive file selection
alias zz='fasd_cd -d -i' # cd with interactive selection

function z() {
    # cd, same functionality as j in autojump
    # need to strip trailing '/' or recognize the existing path as-is
    # because fasd_cd won't accept absolute path
    local arg=${@%$'/'}
    fasd_cd -d "$arg"

    # rename tmux window after jump (unless manually set)
    if [[ -n "$TMUX" ]]; then
        tmux rename-window "${PWD##*/}"
    fi
}
