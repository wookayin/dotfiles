#!/usr/bin/env bash
# A part of tmux config, see ~/.tmux/tmux.conf
# Configures tmux status bar in the bottom with some batteries included

set -e
set -o pipefail

cwd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

main() {
  tmux set-hook -g client-resized "run-shell '~/.tmux/statusbar.tmux'"

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

  # [right status]
  # Set a limit on width to suppress an excessive message '... is not ready' until the first execution is done
  local STATUS_RIGHT_LENGTH=40
  if [ $(tmux display-message -p '#{client_width}') -lt 100 ]; then
    STATUS_RIGHT_LENGTH=4
  fi

  tmux set -g status-right-length $STATUS_RIGHT_LENGTH
  tmux set-hook -g client-attached "set -g status-right-length 1; run-shell 'sleep 1.1'; set -g status-right-length $STATUS_RIGHT_LENGTH;"

  # [right status] prefix, datetime, etc.
  tmux set -g status-right "\
#[fg=#ffffff,bg=#005fd7]#{s/^(.+)$/ \\1 :#{s/root//:client_key_table}}\
#[default]\
";
#[fg=#303030,bg=#1c1c1c,nobold,nounderscore,noitalics]\
#[fg=#9e9e9e,bg=#303030] %Y-%m-%d  %H:%M \
#[fg=#ffffff,bg=#303030,nobold,nounderscore,noitalics]\
#";

  local session_name=$(tmux display-message -p '#S')

  # [right status] CPU Usage
  tmux set -ga status-right "#($cwd/statusbar.tmux component-cpu -S $session_name)"
  # [right status] Memory Usage
  tmux set -ga status-right "#($cwd/statusbar.tmux component-ram -S $session_name)"
  # [right status] GPU Usage
  if command -v gpustat &> /dev/null && command -v nvidia-smi &> /dev/null; then
    tmux set -ga status-right "#($cwd/statusbar.tmux component-gpu -S $session_name)"
  fi

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

cpu-usage() {
  if [ `uname` == "Darwin" ]; then
    # Sum of user + sys CPU usage
    # https://stackoverflow.com/questions/30855440/how-to-get-cpu-utilization-in-in-terminal-mac
    # On MacOS: top is CPU-greedy in the first run,
    # so we stream in a loop (so that component-cpu can print line-by-line)
    top -l 60 -s 2 | grep --line-buffered -E "^CPU" | while read line; do
        echo "$line" | awk '{ printf "%.2f\n", $3 + $5 }'
    done
  else
    # https://unix.stackexchange.com/questions/69185/getting-cpu-usage-same-every-time/
    cat <(grep 'cpu ' /proc/stat) <(sleep 1 && grep 'cpu ' /proc/stat) | \
      awk -v RS="" '{printf "%.2f\n", ($13-$2+$15-$4)*100/($13-$2+$15-$4+$16-$5) "%"}'
  fi
}

component-cpu() {
  # see ~/.dotfiles/bin/cpu-usage
  # https://coolors.co/gradient-palette/2c1d1d-aa2626?number=10
  local reds=("#2c1d1d" "#3a1e1e" "#481f1f" "#562020" "#642121"
              "#722222" "#802323" "#8e2424" "#9c2525" "#aa2626")
  local colors=(${reds[1]} ${reds[2]} ${reds[3]} ${reds[4]} ${reds[7]})  # not linear

  cpu-usage | while IFS= read -r cpu_percentage; do
    local bgcolor="${colors[$(echo "$cpu_percentage/20" | bc)]:-${colors[-1]}}"
    local colorfmt="bg=$bgcolor,fg=white"

    printf "#[bg=#1c1c1c,fg=$bgcolor,nobold,nounderscore,noitalics]"
    printf "#[$colorfmt] 󰻠 %2.0f %% #[default]" $cpu_percentage
    echo ""
  done
}

component-gpu() {
  local gpu_utilization=$( \
    python -c 'import gpustat; G = gpustat.new_query(); \
      print("%.1f" % (sum(c.utilization for c in G) / len(G)))' \
  )  # average gpu utilization. range: 0~100
  if [ -n "$gpu_utilization" ]; then
    if   (( $(echo "$gpu_utilization >= 90" | bc -l) )); then bgcolor='#40C057'; fgcolor='black';
    elif (( $(echo "$gpu_utilization >= 75" | bc -l) )); then bgcolor='#3EAE51'; fgcolor='black';
    elif (( $(echo "$gpu_utilization >= 50" | bc -l) )); then bgcolor='#398A44'; fgcolor='black';
    elif (( $(echo "$gpu_utilization >= 25" | bc -l) )); then bgcolor='#356537'; fgcolor='white';
    else                                                      bgcolor='#30412A'; fgcolor='white';
    fi
  fi
  local colorfmt="bg=$bgcolor,fg=$fgcolor"
  if [ -z "$gpu_utilization" ]; then
    echo "  ERR"
    sleep 1; return 1;
  else
    printf "#[$colorfmt] %3.0f %% #[default]" "$gpu_utilization"
    sleep 1;
  fi
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
