#!/bin/bash
# Install terminfo for kitty, wezterm, alacritty, etc.
# $ infocmp <TERM name>

set -e

CSI="\x1b["

test() {
  echo -e "TERM = $TERM"
  echo -e "TMUX = $TMUX"
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
  echo "Installing terminfo ..."
  infocmp wezterm >/dev/null && echo -e "wezterm: ${CSI}32mOK${CSI}0m" || wezterm
  echo ""
}

# https://wezfurlong.org/wezterm/faq.html#how-do-i-enable-undercurl-curly-underlines
wezterm() {
  set -x
  tempfile=$(mktemp) \
    && curl -fsSL -o $tempfile https://raw.githubusercontent.com/wez/wezterm/master/termwiz/data/wezterm.terminfo \
    && tic -x -o ~/.terminfo $tempfile \
    && rm $tempfile
  infocmp wezterm > /dev/null && echo "wezterm: Installed."
  set +x
}

# https://sw.kovidgoyal.net/kitty/kittens/ssh/
kitty() {
  echo 'Run the following command to copy terminfo to a remote server:'
  echo 'infocmp -a xterm-kitty | ssh myserver tic -x -o \~/.terminfo /dev/stdin'
}

if [[ -n "$1" && "$1" != "--help" ]] && declare -f "$1" >/dev/null; then
  $@
elif [[ -z "$@" ]]; then
  install
  test
else
  ( echo "invalid command" )
  exit 1;
fi
