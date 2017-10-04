#!/usr/bin/env bash

# Some sensible settings for macOS
# insipred by https://mths.be/osx

# Ensure that this script is running on macOS
if [ `uname` != "Darwin" ]; then
    echo "Run on macOS !"; exit 1
fi

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until `.osx` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

################################################################
# General settings
################################################################

configure_general() {
    # Faster key repeat
    defaults write NSGlobalDomain InitialKeyRepeat -int 20
    defaults write NSGlobalDomain KeyRepeat -int 2
}


################################################################
# Screen
################################################################

configure_screen() {
    # Screen: enable HiDPI display resolution modes
    sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true
}

################################################################
# Screen
################################################################

configure_finder() {
    # Finder: show status bar
    defaults write com.apple.finder ShowStatusBar -bool true

    # Finder: show path bar
    defaults write com.apple.finder ShowPathbar -bool true
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

all() {
    configure_general
    configure_screen
    configure_finder
    configure_safari
    configure_skim
}

if [ -n "$1" ]; then
    set -x
    $1
else
    echo "Usage: $0 [command], where command is one of the following:"
    declare -F | cut -d" " -f3 | grep -v '^_'
fi
