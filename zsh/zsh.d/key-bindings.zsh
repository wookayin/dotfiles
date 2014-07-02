# Custom key bindings for ZSH

# In default settings, we use 'vi-mode' (bindkey -v)

# Bash-compatible (emacs style) key bindings
# ==========================================
# @see http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html
# @see http://www.gnu.org/software/bash/manual/html_node/Readline-Interaction.html

bindkey '^A' beginning-of-line
bindkey '^E' end-of-line

bindkey '^B' backward-char
bindkey '^F' forward-char

bindkey '^D' delete-char
bindkey '^H' backward-delete-char

bindkey '^N' down-history
bindkey '^P' up-history

bindkey '^R' history-incremental-search-backward

bindkey '\e.' insert-last-word # Alt-.
