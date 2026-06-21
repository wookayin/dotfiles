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

function highlight_last_path_segment() {
  local color="$(tput setaf 3)"  # color_yellow
  local reset="$(tput sgr0)"  # reset, i.e. \033[0m
  sed -e "s#\(.*\)/\(.*\)#\1/${color}\2${reset}#"
}

function z() {
  # cd, same functionality as j in autojump

  # When no argument is provided, launch fzf to select interactively
  if [[ -z "$@" ]]; then
    # TODO consolidate with fzf-cd-widget (FZF_ALT_C_COMMAND)
    local dir=$(
      fasd -d -R \
        | sed -E 's/^([0-9.]+)[[:space:]]+/\1\t/' \
        | highlight_last_path_segment \
        | fzf --ansi --scheme=path --no-sort --height='50%' --reverse \
          --delimiter='\t' --nth 2 --accept-nth 2 --color "fg:dim,nth:regular" \
          "${(@Q)${(z)FZF_ALT_C_OPTS:-}}"
    ) && echo "$dir" && cd "$dir"
    return $?
  fi

  # Need to strip trailing '/' or recognize the existing path as-is
  # because fasd_cd won't accept absolute path
  local arg=${@%$'/'}
  fasd_cd -d "$arg"

  # Auto-rename tmux window after jump
  # if it's the only pane for the current window and not manually set (distinguished by prefix)
  local autotitle_prefix="󰉋 "
  if [[ -n "$TMUX" ]]; then
    local num_panes=$(tmux display-message -p '#{window_panes}')
    if [[ $num_panes -eq 1 ]]; then
      local current_pane_name=$(tmux display-message -p '#W')
      # auto-renamed tmux window names should have a prefix
      if [[ "$current_pane_name" == "zsh" || "$current_pane_name" == "$autotitle_prefix"* ]]; then
        tmux rename-window "$autotitle_prefix${PWD##*/}"
      fi
    fi
  fi
}
