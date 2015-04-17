#!/bin/bash

install_essential_packages() {
	local -a packages; packages=( \
		build-essential \
		vim zsh curl \
		python-software-properties software-properties-common \
		cmake cmake-data \
		terminator htop \
		silversearcher-ag \
		openssh-server mosh \
		)

	sudo apt-get install -y ${packages[@]}
}

install_ppa_git() {
	# https://launchpad.net/~git-core/+archive/ubuntu/ppa
	sudo add-apt-repository -y ppa:git-core/ppa
	sudo apt-get update
	sudo apt-get install -y git-all
}

install_ppa_tmux() {
	# https://launchpad.net/~pi-rho/+archive/ubuntu/dev
	sudo add-apt-repository -y ppa:pi-rho/dev
	sudo apt-get update
	sudo apt-get install -y tmux
}


# entrypoint script
if [ -n "$1" ]; then
	$1
else
	echo "Usage: $0 [command], where command is one of the following:"
	declare -F | cut -d" " -f3
fi
