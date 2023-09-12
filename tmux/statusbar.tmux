#!/usr/bin/env bash
# A part of tmux config, see ~/.tmux/tmux.conf
# Configures tmux status bar in the bottom with some batteries included


main() {
  # Left status: background color w.r.t per-host prompt color
  if [[ -z "$PROMPT_HOST_COLOR" ]]; then
      TMUX_STATUS_BG="#0087af"   # default
  elif [[ "$PROMPT_HOST_COLOR" =~ ^\#[0-9A-Za-z]{6}$ ]]; then
      TMUX_STATUS_BG="$PROMPT_HOST_COLOR"
  else
      TMUX_STATUS_BG="colour$PROMPT_HOST_COLOR"
  fi

  # [left status] session name (#S), hostname (#h)
  tmux set -g status-left "\
#[fg=#000000,bg=$TMUX_STATUS_BG,bold] #S \
#[fg=#1c1c1c,bg=$TMUX_STATUS_BG,nobold,nounderscore,noitalics]\
#[fg=$TMUX_STATUS_BG,bg=#1c1c1c] #h \
";

  # [right status] prefix, datetime, etc.
  tmux set -g status-right "\
#[fg=#ffffff,bg=#005fd7]#{s/^(.+)$/ \\1 :#{s/root//:client_key_table}}\
#[default]\
#[fg=#303030,bg=#1c1c1c,nobold,nounderscore,noitalics]\
#[fg=#9e9e9e,bg=#303030] %Y-%m-%d  %H:%M \
#[fg=#ffffff,bg=#303030,nobold,nounderscore,noitalics]\
";

  # [window] number (#I), window flag (#F), window name (#W)
  #   - #F: e.g., Marked or Zoomed. If marked (i.e. #F contains 'M'), highlight it.
  tmux setw -g window-status-format "\
#[fg=#0087af,bg=#1c1c1c] #{?#{m:*M*,#F},#[fg=#121212]#[bg=#5faf5f],}#I#F\
#[fg=#bcbcbc,bg=#1c1c1c] #W\
#[bg=#1c1c1c] \
";

  # [active window]
  #   - #W: use blue-ish color.
  #   - If panes are synchronized, display the information (SYNC).
  tmux setw -g window-status-current-format "\
#[fg=#1c1c1c,bg=#0087af,nobold,nounderscore,noitalics]\
#[fg=#5fffff,bg=#0087af] #{?#{m:*M*,#F},#[fg=#121212]#[bg=#5faf5f],}#I#F\
#[fg=#ffffff,bg=#0087af,bold] #W\
#{?pane_synchronized,#[fg=#d7ff00] (SYNC),} \
#[fg=#0087af,bg=#1c1c1c,nobold,nounderscore,noitalics]\
";
}

main
