#!/usr/bin/env bash

# Some sensible settings for Mac OS X
# insipred by https://mths.be/osx

# Ensure that this script is running on OS X
if [ `uname` != "Darwin" ]; then
	echo "Run on Mac OS X !"; exit 1
fi

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until `.osx` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

set -x

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

configure_screen
configure_finder
configure_safari
