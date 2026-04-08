# More fzf widgets
# ================

# This script should be sourced AFTER fzf.zsh
# @seealso ~/.fzf/shell/key-bindings.zsh for fzf mappings (Ctrl-T, Alt-C, Ctrl-R, etc.)

# More Shortcuts
bindkey '^ ' fzf-file-widget          # Ctrl-SPACE, Ctrl-T

# ctrl-z (as well as alt-c): fzf for 'z' (recent directories).
# See ~/.zsh/zsh.d/envs.zsh for ALT-C configurations.
bindkey '^z' fzf-cd-widget
