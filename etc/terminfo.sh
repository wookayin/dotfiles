#!/bin/bash
# Install terminfo for kitty, wezterm, alacritty, etc.
# $ infocmp <TERM name>

set -eu -o pipefail

SCRIPT="$(readlink -f $0)"
SCRIPTPATH="$(dirname $SCRIPT)"

CSI="\x1b["

test() {
  echo -e "TERM = $TERM"
  echo -e "TMUX = ${TMUX:-(no tmux)}"
  echo ""

  # CSI escape sequences
  # https://wezfurlong.org/wezterm/escape-sequences.html#csi-control-sequence-introducer-sequences
  echo -e "\t${CSI}0m"normal"${CSI}0m"
  echo -e "\t${CSI}1m"bold"${CSI}0m"
  echo -e "\t${CSI}2m"light dim/faint"${CSI}0m"
  echo -e "\t${CSI}3m"italic"${CSI}0m"
  echo -e "\t${CSI}1m${CSI}3m"bold italic"${CSI}0m"
  echo -e "\t${CSI}4m"underline"${CSI}0m"
  echo -e "\t${CSI}5m"blink"${CSI}0m"
  echo -e "\t${CSI}6m"rapid blink"${CSI}0m"
  echo -e "\t${CSI}7m"inverse"${CSI}0m"
  echo -e "\t${CSI}8m"invisible"${CSI}0m"
  echo -e "\t${CSI}9m"strikethrough"${CSI}0m"
  echo -e ""

  # CSI 4: Underline
  echo -en "${CSI}58:2:0:255:0:0m"  # CSI 58:2 underline color (RGB) palette
  echo -e "\t${CSI}4:1m"single underline
  echo -e "\t${CSI}4:2m"double underline
  echo -e "\t${CSI}4:3m"curly underline
  echo -e "\t${CSI}4:4m"dotted underline
  echo -e "\t${CSI}4:5m"dashed underline
  echo -e "\t${CSI}4:0m"no underline
  echo -e "\t${CSI}9m"strikethrough with color"${CSI}0m"
  echo -e "${CSI}0m"

  # (wezterm only)
  echo -e "\t${CSI}53m"overline"${CSI}0m"
  echo -e "\t"normal text"${CSI}73m"superscript"${CSI}0m"
  echo -e "\t"normal text"${CSI}74m"subscript"${CSI}0m"
  echo -e "\t"normal text"${CSI}75m"baseline"${CSI}0m"

  echo ""
  echo -e "\t${CSI}31m"foreground red"${CSI}0m"
  echo -e "\t${CSI}42m${CSI}30m"background green"${CSI}0m"
  echo -e "\t${CSI}32m${CSI}7m"foreground green inverse"${CSI}0m"
}

install() {
  echo -e "Installing terminfo for some TERMs (into ~/.terminfo) ...\n"
  _check() {
    local termname="$1"
    local required="${2:-}"
    local ok=true
    echo -en "$termname: "
    if ! infocmp "$termname" >/dev/null 2>&1; then
      ok=false
    elif [[ -n "$required" ]]; then
      local feature missing=()
      IFS='|' read -ra features <<< "$required"
      for feature in "${features[@]}"; do
        if ! infocmp -x1 "$termname" | grep -qE "$feature"; then
          missing+=("$feature")
        fi
      done
      if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${CSI}33m""missing features: ${missing[*]}""${CSI}0m"
        ok=false
      fi
    fi

    if $ok; then
      echo -e "${CSI}32m"'OK'"${CSI}0m"
      echo -en "${CSI}2m"  # faint
      infocmp $termname | head -n1
      echo -en "${CSI}0m"
    else
      "$SCRIPT" $termname
    fi
    echo ""
  }
  _check wezterm
  _check tmux-256color 'smxx|rmxx|Smulx|Setulc'
}

# tmux-256color: Patch terminfo for tmux so that it can support modern features.
# The built-in terminfo database for tmux-256color in macOS is outdated, it does not support SGR!
# See `./terminfo/tmux-256color.terminfo` for more details
tmux-256color() {
  set -x
  tic -x -o ~/.terminfo "$SCRIPTPATH/terminfo/tmux-256color.terminfo"
  { set +x; } 2>/dev/null
  infocmp tmux-256color | head -n1 && echo "tmux-256color (patched): Installed."
}

# https://wezfurlong.org/wezterm/faq.html#how-do-i-enable-undercurl-curly-underlines
wezterm() {
  set -x
  tempfile=$(mktemp) \
    && curl -fsSL -o $tempfile https://raw.githubusercontent.com/wez/wezterm/master/termwiz/data/wezterm.terminfo \
    && tic -x -o ~/.terminfo $tempfile \
    && rm $tempfile
  { set +x; } 2>/dev/null
  infocmp wezterm | head -n1 && echo "wezterm: Installed."
}

# https://sw.kovidgoyal.net/kitty/kittens/ssh/
xterm-kitty() {
  echo 'Run the following command to copy terminfo to a remote server:'
  echo 'infocmp -a xterm-kitty | ssh myserver tic -x -o \~/.terminfo /dev/stdin'
}

arg="${1:-}"
if [[ -n "$arg" && "$arg" != "--help" ]] && declare -f "$arg" >/dev/null; then
  "$@"
elif [[ -z "$@" ]]; then
  install
  test
else
  ( echo "invalid command" )
  exit 1;
fi
