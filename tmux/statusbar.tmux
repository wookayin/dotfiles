#!/usr/bin/env bash
# A part of tmux config, see ~/.tmux/tmux.conf
# Configures tmux status bar in the bottom with some batteries included

set -e
set -o pipefail

cwd="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

theme_color_base="$(tmux show-options -gqv @theme_color_base)"
theme_color_base="${theme_color_base:-"#0087af"}"

main_debounced() {
  # Call `main`, but with some debouncing because the script will be called many times successively on resizing.
  local current_tick=$(tmux show-option -gqv @statusbar_debounce_tick 2>/dev/null)
  local new_tick=$(( ( ${current_tick:-0} + 1 ) % 10000 ))
  tmux set-option -g @statusbar_debounce_tick "$new_tick"
  sleep 0.2
  # Only the last one will have the counter value unmodified, so call main() only if it's the case.
  # (Actually, the above increment of counter is not fully atomic; however, it will be fine despite the race condition
  # because it's okay to call `main()` to update statusbar settings, which is basically idempotent.)
  local now_tick=$(tmux show-option -gqv @statusbar_debounce_tick 2>/dev/null)
  if [ "$now_tick" = "$new_tick" ]; then
    main
  fi
}

main() {
  # This will be called once on startup and when the statusbar is resized, run shortly (not as a daemon).
  # NOTE: upon resizing, call the script (`main_debounced`) in the background: multiple concurrent invocations.
  tmux set-hook -g client-resized "run-shell -b '~/.tmux/statusbar.tmux main_debounced'"

  # Left status: background color w.r.t per-host prompt color
  local TMUX_STATUS_BG
  if [[ -z "$PROMPT_HOST_COLOR" ]]; then
      TMUX_STATUS_BG="$theme_color_base"   # default
  elif [[ "$PROMPT_HOST_COLOR" =~ ^\#[0-9A-Za-z]{6}$ ]]; then
      TMUX_STATUS_BG="$PROMPT_HOST_COLOR"
  elif [[ "$PROMPT_HOST_COLOR" =~ ^[0-9]+$ ]]; then
      TMUX_STATUS_BG="colour$PROMPT_HOST_COLOR"
  else
      TMUX_STATUS_BG="$PROMPT_HOST_COLOR"
  fi
  local TMUX_STATUS_HOST_BG="#0a0a0a"

  # [left status] session name (#S)
  local status_left=""
  status_left+="#[fg=#000000,bg=$TMUX_STATUS_BG,bold] #S "
  status_left+="#[bg=$TMUX_STATUS_HOST_BG,fg=$TMUX_STATUS_BG,nobold,nounderscore,noitalics]"

  # [left status] hostname (#h)
  # hostname is displayed only on remote machines (e.g. SSH)
  status_left+="#[fg=$TMUX_STATUS_BG,bg=$TMUX_STATUS_HOST_BG,bold]"
  if [[ -n "${SSH_CONNECTION:-}" ]]; then
    status_left+=" #h "
  else  # localhost
    status_left+=" 💻 "
  fi
  status_left+="#[fg=$TMUX_STATUS_HOST_BG,bg=#1c1c1c,nobold]"

  tmux set -g status-left "$status_left"

  # [right status]
  # Set a limit on width to suppress an excessive message '... is not ready' until the first execution is done
  local STATUS_RIGHT_LENGTH=40
  if [ $(tmux display-message -p '#{client_width}') -lt 100 ]; then
    STATUS_RIGHT_LENGTH=4
  fi

  tmux set -g status-right-length $STATUS_RIGHT_LENGTH
  tmux set-hook -g client-attached "set -g status-right-length 1; run-shell 'sleep 1.1'; set -g status-right-length $STATUS_RIGHT_LENGTH;"

  # Window colors (@status_window_color): defaults to the tmux theme's base color.
  # Per-window customization is allowed, use 'tmux-window-color <color> [num-color]'
  tmux set -g @status_window_color "${theme_color_base}"
  tmux set -g @status_window_num_color "#5fffff"

  # [right status] prefix, datetime
  local status_right=""
  status_right+="#[fg=#ffffff,bg=#005fd7]#{s/^(.+)$/ \\1 :#{s/root//:client_key_table}}"
  status_right+="#[default]"
#[fg=#303030,bg=#1c1c1c,nobold,nounderscore,noitalics]\
#[fg=#9e9e9e,bg=#303030] %Y-%m-%d  %H:%M \
#[fg=#ffffff,bg=#303030,nobold,nounderscore,noitalics]\
#";
  local session_name=$(tmux display-message -p '#S')

  # [right status] CPU Usage
  status_right+="#($cwd/statusbar.tmux component-cpu -S $session_name)"
  # [right status] Memory Usage
  status_right+="#($cwd/statusbar.tmux component-ram -S $session_name)"
  # [right status] GPU Usage
  if [ -d /sys/module/nvidia ] && command -v gpustat &> /dev/null; then
    status_right+="#($cwd/statusbar.tmux component-gpu -S $session_name)"
  fi

  tmux set -g status-right "$status_right"

  # [window] number (#I), window flag (#F), window name (#W)
  #   - #F: e.g., Marked or Zoomed. If marked (i.e. #F contains 'M'), highlight it.
  local -a _window_status_format=(
    "#[fg=#{@status_window_color},bg=#1c1c1c] #{?#{m:*M*,#F},#[fg=#121212]#[bg=#5faf5f],}#I#F"
    "#[fg=#bcbcbc,bg=#1c1c1c] #W"
    "#[bg=#1c1c1c] "
  )
  tmux setw -g window-status-format "$(printf "%s" "${_window_status_format[@]}")"

  # [active window]
  #   - #W: use blue-ish color.
  #   - If panes are synchronized, display the information (SYNC).
  local -a _window_status_current_format=(
    "#[fg=#1c1c1c,bg=#{@status_window_color},nobold,nounderscore,noitalics]"
    "#[fg=#{@status_window_num_color},bg=#{@status_window_color}] #{?#{m:*M*,#F},#[fg=#121212]#[bg=#5faf5f],}#I#F"
    "#[fg=#ffffff,bg=#{@status_window_color},bold] #W"
    "#{?pane_synchronized,#[fg=#d7ff00] (SYNC),} "
    "#[fg=#{@status_window_color},bg=#1c1c1c,nobold,nounderscore,noitalics]"
  )
  tmux setw -g window-status-current-format "$(printf "%s" "${_window_status_current_format[@]}")"

}

cpu-usage() {
  if [ `uname` == "Darwin" ]; then
    # Sum of user + sys CPU usage via iostat (much lighter than top)
    # (old w/ top: https://stackoverflow.com/questions/30855440/how-to-get-cpu-utilization-in-in-terminal-mac)
    # iostat -w 2 streams samples every 2s; parse column headers dynamically
    # since column positions shift depending on the number of disks present.
    # skip=1 after finding the header row to discard the boot-average sample.
    iostat -c 60 -w 2 | awk '
      /us/ && us==0 { for(i=1;i<=NF;i++) { if($i=="us") us=i; if($i=="sy") sy=i }; skip=1; next }
      skip { skip=0; next }
      us>0 { printf "%.2f\n", $us + $sy; fflush() }
    '
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
    local bgcolor="${colors[$(( ${cpu_percentage%.*} / 20 ))]:-${colors[-1]}}"
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
    local gpu_int="${gpu_utilization%.*}"  # integer part, for bc-less comparison
    if   (( gpu_int >= 90 )); then bgcolor='#40C057'; fgcolor='black';
    elif (( gpu_int >= 75 )); then bgcolor='#3EAE51'; fgcolor='black';
    elif (( gpu_int >= 50 )); then bgcolor='#398A44'; fgcolor='black';
    elif (( gpu_int >= 25 )); then bgcolor='#356537'; fgcolor='white';
    else                           bgcolor='#30412A'; fgcolor='white';
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
      # mem_used includes shared memory usage: `free` reports total($2), used($3), free, shared($5), buff/cache, available.
      IFS=" " read -r mem_used mem_total mem_percentage <<<"$(free -m | awk '/^Mem/ { print (($3+$5)/1024), ($2/1024), (($3+$5)/$2*100) }')"
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
