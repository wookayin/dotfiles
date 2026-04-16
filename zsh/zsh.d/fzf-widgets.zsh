# More fzf widgets
# ================

# This script should be sourced AFTER fzf.zsh
# @seealso ~/.fzf/shell/key-bindings.zsh for fzf mappings (Ctrl-T, Alt-C, Ctrl-R, etc.)

# More Shortcuts
bindkey '^ ' fzf-file-widget          # Ctrl-SPACE, Ctrl-T

# ctrl-z (as well as alt-c): fzf for 'z' (recent directories).
# See ~/.zsh/zsh.d/envs.zsh for ALT-C configurations.
bindkey '^z' fzf-cd-widget


# Advanced, customized <TAB> (^I) completion through fzf widgets
# This overrides fzf's default tab binding widget (fzf-completion): see ~/.fzf/shell/completion.zsh
zle -A 'fzf-completion' _orig_fzf-complete 2>/dev/null ||
  zle -A 'expand-or-complete' _orig_fzf-complete

fzf-complete-custom() {
  # {v,vim,nvim} <TAB>: use fzf file finder (like Ctrl-T), with the trailing word as initial query
  # TODO: This is too experimental, apply to `v` only, we can apply to `vim` later
  if [[ "$LBUFFER" =~ ^[[:space:]]*(v)[[:space:]] && ! "$LBUFFER" =~ -[a-zA-Z0-9]*$ ]]; then
    # TODO: detect if the current completion (for fallback) is 'file' completion, and invoke fzf widget only when it's the case?
    # e.g. vim +<TAB>, vim -c 'lua<TAB>' should not invoke fzf completion
    local query="${LBUFFER##* }"   # Extract the last word as query
    LBUFFER="${LBUFFER%$query}"    # Strip the query from LBUFFER
    local FZF_CTRL_T_OPTS="$FZF_CTRL_T_OPTS --query='${query:-}'"
    zle fzf-file-widget

  # kill <TAB>
  elif [[ "$LBUFFER" =~ ^[[:space:]]*kill[[:space:]] && ! "$LBUFFER" =~ -[a-zA-Z0-9]*$ ]]; then
    # Like _fzf_complete_kill, but using ~/.dotfiles/bin/pid.fzf
    local query="${LBUFFER##* }"  # Extract the last word as query
    LBUFFER="${LBUFFER%$query}"   # Strip the query from LBUFFER
    local pid
    pid=$("pid.fzf" --no-tmux --no-border --no-footer --prompt="Pick process to kill> " --query="$query" < /dev/tty 2>/dev/tty)
    if [[ -n "$pid" ]]; then
      LBUFFER="${LBUFFER}${pid//$'\n'/ }"
    fi

    zle reset-prompt

  # Fallback to the default <Tab> completion (fzf -> expand-or-complete)
  else
    zle _orig_fzf-complete
  fi
}

zle -N fzf-complete-custom
bindkey '^I' fzf-complete-custom
