# Custom key bindings for ZSH
# TODO: change to keymap.zsh, use zsh(keymap): convention

# In default settings, we use 'vi-mode' (bindkey -v)

# Bash-compatible (emacs style) key bindings
# ==========================================
# @see http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html
# @see http://www.gnu.org/software/bash/manual/html_node/Readline-Interaction.html

bindkey '^A' beginning-of-line
bindkey '^E' end-of-line

# For Home and End key support
bindkey "\033[1~" beginning-of-line
bindkey "\033[4~" end-of-line
bindkey "\033[7~" beginning-of-line
bindkey "\033[8~" end-of-line
bindkey "\033[H" beginning-of-line
bindkey "\033[F" end-of-line
bindkey "\033OH" beginning-of-line
bindkey "\033OF" end-of-line

bindkey '^D' delete-char
bindkey '^H' backward-delete-char

bindkey '^N' down-history
bindkey '^P' up-history

bindkey '^F' forward-word
bindkey '^B' backward-word

if [[ $(bindkey '^R') == *"undefined"* ]]; then
  bindkey '^R' history-incremental-search-backward
fi

bindkey '\e.' insert-last-word # Alt-.

# Alt-{h,j,k,l}: navigate tmux panes, vim-tmux-navigator style
# @see tmux.conf's C-{h,j,k,l} pane, vim keymap for M-{h,j,k,l}
if [[ -n "$TMUX" ]]; then
  _tmux-select-pane-left()  { tmux select-pane -L }
  _tmux-select-pane-down()  { tmux select-pane -D }
  _tmux-select-pane-up()    { tmux select-pane -U }
  _tmux-select-pane-right() { tmux select-pane -R }
  zle -N _tmux-select-pane-left
  zle -N _tmux-select-pane-down
  zle -N _tmux-select-pane-up
  zle -N _tmux-select-pane-right

  bindkey '\eh' _tmux-select-pane-left
  bindkey '\ej' _tmux-select-pane-down
  bindkey '\ek' _tmux-select-pane-up
  bindkey '\el' _tmux-select-pane-right
fi


# vi normal mode
# ==============

# CTRL-g, CTRL-v: Edit in an external editor
bindkey -M vicmd '^g' edit-command-line
bindkey -M vicmd '^v' edit-command-line

# vi insert mode
# ==============

# zsh-vi-mode eats CTRL-g which is a prefix of all fzf-git-* keybindings,
# so we have to explicitly remove it. jeffreytse/zsh-vi-mode#24
bindkey -M viins -r '^g'

# Shift-Enter: line break (add newline)
line-break() { LBUFFER+=$'\n' }
zle -N line-break
bindkey -M viins $'\e[13;2u' line-break
bindkey -M viins $'\e[27;2;13~' line-break

# CTRL-x CTRL-e: Edit command in an external editor
bindkey -M viins "$key_info[Control]X$key_info[Control]E" edit-command-line


# Note: see ~/.zsh/zsh.d/fzf-widgets.zsh
# for more zsh widgets and their keybindings.
