#!/usr/bin/env bash
# A part of tmux config, see ~/.tmux/tmux.conf
# Configures tmux status bar in the bottom with some batteries included

set -e
set -o pipefail

cwd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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
";
#[fg=#303030,bg=#1c1c1c,nobold,nounderscore,noitalics]\
#[fg=#9e9e9e,bg=#303030] %Y-%m-%d  %H:%M \
#[fg=#ffffff,bg=#303030,nobold,nounderscore,noitalics]\
#";

  # [right status] CPU Usage
  tmux set -ga status-right "#($cwd/statusbar.tmux component-cpu)"
  # [right status] Memory Usage
  tmux set -ga status-right "#($cwd/statusbar.tmux component-ram)"

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

component-cpu() {
  # see ~/.dotfiles/bin/cpu-usage
  local cpu_percentage
  if [ `uname` == "Darwin" ]; then
    # https://stackoverflow.com/questions/30855440/how-to-get-cpu-utilization-in-in-terminal-mac
    # Sum of user + sys CPU usage
    cpu_percentage=$(\
      top -l 2 -s 0 | grep -E "^CPU" | tail -1 | awk '{ printf "%.2f", $3 + $5 }')
  else
    # https://unix.stackexchange.com/questions/69185/getting-cpu-usage-same-every-time/
    cpu_percentage=$(\
      cat <(grep 'cpu ' /proc/stat) <(sleep 1 && grep 'cpu ' /proc/stat) | \
      awk -v RS="" '{printf "%.2f", ($13-$2+$15-$4)*100/($13-$2+$15-$4+$16-$5) "%"}'
    )
  fi
  if [ ! $? -eq 0 ]; then return; fi

  # https://coolors.co/gradient-palette/2c1d1d-aa2626?number=10
  local reds=("#2c1d1d" "#3a1e1e" "#481f1f" "#562020" "#642121"
              "#722222" "#802323" "#8e2424" "#9c2525" "#aa2626")
  local colors=(${reds[1]} ${reds[2]} ${reds[3]} ${reds[4]} ${reds[7]})  # not linear
  local bgcolor="#${colors[$(echo "$cpu_percentage/20" | bc)]:-${colors[-1]}}"
  local colorfmt="bg=$bgcolor,fg=white"

  printf "#[bg=#1c1c1c,fg=$bgcolor,nobold,nounderscore,noitalics]"
  printf "#[$colorfmt] 󰻠 %2.0f %% #[default]" $cpu_percentage
}

component-ram() {
  local mem_used mem_total mem_percentage
  case $(uname -s) in
    Linux)
      if ! command -v free 2>&1 > /dev/null; then return 1; fi
      IFS=" " read -r mem_used mem_total mem_percentage <<<"$(free -m | awk '/^Mem/ { print ($3/1024), ($2/1024), ($3/$2*100) }')"
    ;;
    Darwin)
      if ! command -v vm_stat 2>&1 > /dev/null; then return 1; fi
      mem_used=$(vm_stat | grep ' active\|wired ' | sed 's/[^0-9]//g' | paste -sd ' ' - | \
          awk -v pagesize=$(pagesize) '{ printf "%.2f\n", ($1 + $2) * pagesize / 1024^3 }')
      mem_total=$(system_profiler SPHardwareDataType | grep "Memory:" | awk '{ print $2 }')
      mem_percentage=$(echo "$mem_used $mem_total" | awk '{ printf "%.0f", 100 * $1 / $2 }')
    ;;
    *) return 1;;
  esac
  if [ ! $? -eq 0 ]; then return; fi
  sleep 0.9;  # do not query too frequently

  local bgcolor fgcolor
  if   (( $(echo "$mem_percentage >= 90" | bc -l) )); then bgcolor='#e67700'; fgcolor='black';
  elif (( $(echo "$mem_percentage >= 75" | bc -l) )); then bgcolor='#B57A0A'; fgcolor='black';
  elif (( $(echo "$mem_percentage >= 50" | bc -l) )); then bgcolor='#755515'; fgcolor='white';
  else                                                     bgcolor='#35301F'; fgcolor='white';
  fi
  local colorfmt="bg=$bgcolor,fg=$fgcolor"
  printf "#[$colorfmt] 󰍛 %.1f/%.0f GB #[default]" $mem_used $mem_total
}

if [[ -z "$1" ]]; then
  main
elif declare -f "$1" > /dev/null; then
  $@
else
  echo "Unknown command"
  exit 1;
fi
