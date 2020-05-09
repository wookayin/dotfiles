# Custom key bindings for ZSH

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

if [[ $(bindkey '^R') == *"undefined"* ]]; then
  bindkey '^R' history-incremental-search-backward
fi

bindkey '\e.' insert-last-word # Alt-.


# Vi mode key bindings
# CTRL-X CTRL-E: Edit command in an external editor (even in insert mode)
bindkey -M viins "$key_info[Control]X$key_info[Control]E" edit-command-line


# Note: see ~/.zsh/zsh.d/fzf-widgets.zsh
# for more zsh widgets and their keybindings.
