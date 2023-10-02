#!/usr/bin/env bash
# vim: set ts=2 sts=2 sw=2:

# Some sensible settings for macOS
# insipred by https://mths.be/osx
# See also for what's possible: https://macos-defaults.com/

# Ensure that this script is running on macOS
if [ `uname` != "Darwin" ]; then
  echo "Run on macOS !"; exit 1
fi

set -e

# Ask for the administrator password upfront (when args are given)
require-sudo() {
  if [ -n "$1" ]; then
    sudo -v --prompt "Administrator privilege required. Please type your local password: "

    # Keep-alive: update existing `sudo` time stamp until `.osx` has finished
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
  fi
}

ignore-error() { return 0; }
warning() {
  { set +x; } 2>/dev/null; echo -e "\033[1;33mWarning: $1\033[0m\n"; set -x;
}
warning-permission() {
  { set +x; } 2>/dev/null; warning "Full disk access is needed. See: System Preferences > Privacy & Security > Full Disk Access."; set -x;
}
has-sonoma() {
  # return code: 0[true] if macos version >= 14.0; 1[false] if version < 14.0
  { set +x; } 2>/dev/null;
  printf "14.0\n$(sw_vers -productVersion)" | sort -V -C
  local ret=$?; set -x; return $ret;
}

################################################################
# General settings
################################################################

_set_hostname() {
  local hostname="$1"

  if [[ -z "$hostname" ]]; then
    echo "Single argument required"
  fi
  require-sudo
  sudo scutil --set ComputerName "$hostname"
  sudo scutil --set HostName "$hostname"
  sudo scutil --set LocalHostName "$hostname"
  sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$hostname"
}

configure_general() {
  # Faster key repeat
  defaults write NSGlobalDomain InitialKeyRepeat -int 20
  defaults write NSGlobalDomain KeyRepeat -int 1

  # Use key repeat instead of the accents menu when holding a key
  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

  # Always show scrollbars (`WhenScrolling`, `Automatic` and `Always`)
  defaults write NSGlobalDomain AppleShowScrollBars -string "Always"

  # Do not use OSX credential store for git
  git config --system --unset credential.helper || ignore-error;
}

################################################################
# Desktop & Dock
################################################################

configure_dock() {
  # Make dock auto-hide/show instantly (no animation!)
  # https://apple.stackexchange.com/questions/33600/how-can-i-make-auto-hide-show-for-the-dock-faster
  defaults write com.apple.dock autohide -int 1
  defaults write com.apple.dock autohide-delay -float 0.0
  defaults write com.apple.dock autohide-time-modifier -float 0.0

  #defaults write com.apple.dock magnification -int 1
  killall Dock
}

configure_desktop() {
  # "Desktop & Dock" > "Click wallpaper to reveal desktop" = "Only in Stage Manager"
  if has-sonoma; then
    defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false
  fi
}


################################################################
# Screen
################################################################

configure_screen() {
  # Screen: enable HiDPI display resolution modes
  defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true
}

################################################################
# Finder
################################################################

configure_finder() {
  # Finder: show status bar
  defaults write com.apple.finder ShowStatusBar -bool true

  # Finder: show path bar
  defaults write com.apple.finder ShowPathbar -bool true

  # Always show file extensions
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true

  # Disable the warning when changing a file extension
  defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
}

################################################################
# Safari
################################################################

configure_safari() {
  # Safari: show the full URL in the address bar (note: this still hides the scheme)
  defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true || warning-permission
}


################################################################
# Skim
################################################################

configure_skim() {
  # force skim to always autoupdate/autorefresh
  defaults write -app Skim SKAutoReloadFileUpdate -boolean true
}


################################################################

all() {
  configure_general
  configure_dock
  configure_desktop
  configure_screen
  configure_finder
  configure_safari
  configure_skim
}

if [ -n "$1" ]; then
  cmd="$1"; shift;
  PS4="\033[1;33m>>>\033[0m "
  set -x
  $cmd "$@"
else
  echo "Usage: $0 [command], where command is one of the following:"
  declare -F | cut -d" " -f3 | grep -v '^_'
fi
