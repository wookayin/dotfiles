#!/usr/bin/env bash
# vim: set ts=2 sts=2 sw=2:

# Some sensible settings for macOS
# insipred by https://mths.be/osx

# Ensure that this script is running on macOS
if [ `uname` != "Darwin" ]; then
  echo "Run on macOS !"; exit 1
fi

# Ask for the administrator password upfront (when args are giveN)
if [ -n "$1" ]; then
  sudo -v --prompt "Administrator privilege required. Please type your local password: "

  # Keep-alive: update existing `sudo` time stamp until `.osx` has finished
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
fi

################################################################
# General settings
################################################################

_set_hostname() {
  local hostname="$1"

  if [[ -z "$hostname" ]]; then
    echo "Single argument required"
  fi
  sudo scutil --set ComputerName "$hostname"
  sudo scutil --set HostName "$hostname"
  sudo scutil --set LocalHostName "$hostname"
  sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$hostname"
}

configure_general() {
  # Faster key repeat
  defaults write NSGlobalDomain InitialKeyRepeat -int 20
  defaults write NSGlobalDomain KeyRepeat -int 1

  # Always show scrollbars (`WhenScrolling`, `Automatic` and `Always`)
  defaults write NSGlobalDomain AppleShowScrollBars -string "Always"
}

################################################################
# Dock
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

################################################################
# Screen
################################################################

configure_screen() {
  # Screen: enable HiDPI display resolution modes
  sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true
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
  defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true
}


################################################################
# Skim
################################################################

configure_skim() {
  # force skim to always autoupdate/autorefresh
  defaults write -app Skim SKAutoReloadFileUpdate -boolean true
}


################################################################
# VS Code
################################################################

configure_vscode() {
  # Enable key-repeating (https://github.com/VSCodeVim/Vim#mac)
  defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false
  defaults write com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled -bool false
  defaults delete -g ApplePressAndHoldEnabled || true
}


################################################################

all() {
  configure_general
  configure_dock
  configure_screen
  configure_finder
  configure_safari
  configure_skim
  configure_vscode
}

if [ -n "$1" ]; then
  cmd="$1"; shift;
  set -x
  $cmd "$@"
else
  echo "Usage: $0 [command], where command is one of the following:"
  declare -F | cut -d" " -f3 | grep -v '^_'
fi
