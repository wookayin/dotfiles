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

bindkey '^F' forward-word
bindkey '^B' backward-word

if [[ $(bindkey '^R') == *"undefined"* ]]; then
  bindkey '^R' history-incremental-search-backward
fi

bindkey '\e.' insert-last-word # Alt-.

# zsh-history-substring-search 키바인딩
# 화살표 키로 부분 문자열 히스토리 검색
if [[ -n "$terminfo[kcuu1]" ]]; then
  bindkey "$terminfo[kcuu1]" history-substring-search-up      # Up arrow
fi
if [[ -n "$terminfo[kcud1]" ]]; then
  bindkey "$terminfo[kcud1]" history-substring-search-down    # Down arrow
fi

# 다양한 터미널에서 호환성을 위한 추가 바인딩
bindkey '^[[A' history-substring-search-up      # Up arrow
bindkey '^[[B' history-substring-search-down    # Down arrow
bindkey '^[OA' history-substring-search-up      # Up arrow (alternative)
bindkey '^[OB' history-substring-search-down    # Down arrow (alternative)

# Vi mode에서도 작동하도록 설정
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# Vi mode key bindings
# CTRL-X CTRL-E: Edit command in an external editor (even in insert mode)
bindkey -M viins "$key_info[Control]X$key_info[Control]E" edit-command-line

# Note: see ~/.zsh/zsh.d/fzf-widgets.zsh
# for more zsh widgets and their keybindings.
