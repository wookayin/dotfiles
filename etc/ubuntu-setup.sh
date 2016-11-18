#!/bin/bash

_version_check() {
    curver="$1"; targetver="$2";
    [ "$targetver" = "$(echo -e "$curver\n$targetver" | sort -V | head -n1)" ]
}
install_essential_packages() {
    local -a packages; packages=( \
        build-essential \
        vim zsh curl \
        python-software-properties software-properties-common \
        cmake cmake-data ctags autoconf \
        terminator htop iotop iftop \
        silversearcher-ag \
        openssh-server mosh rdate \
        )

    sudo apt-get install -y ${packages[@]}
}

install_ppa_git() {
    # https://launchpad.net/~git-core/+archive/ubuntu/ppa
    sudo add-apt-repository -y ppa:git-core/ppa
    sudo apt-get update
    sudo apt-get install -y git-all git-extras
}

install_latest_tmux() {
    # tmux 2.3 is installed from source compilation,
    # as there is no tmux 2.3+ package that is compatible with ubuntu 14.04
    # For {libncurses,libevent >= 5}, we might use
    # https://launchpad.net/ubuntu/+archive/primary/+files/tmux_2.3-4_${archi}.deb
    # archi=$(dpkg --print-architecture)  # e.g. amd64
    set -e

    if _version_check "$(tmux -V | cut -d' ' -f2)" "2.3"; then
        echo "$(tmux -V) : $(which tmux)"
        echo "  Already installed, skipping installation"; return
    fi
    apt-get install -y libevent-dev libncurses5-dev libutempter-dev || exit 1;
    TMP_TMUX_DIR="/tmp/.tmux-src/"

    TMUX_TGZ_FILE="tmux-2.3.tar.gz"
    TMUX_DOWNLOAD_URL="https://github.com/tmux/tmux/releases/download/2.3/${TMUX_TGZ_FILE}"

    wget -nc ${TMUX_DOWNLOAD_URL} -P ${TMP_TMUX_DIR} || exit 1;
    cd ${TMP_TMUX_DIR} && tar -xvzf ${TMUX_TGZ_FILE} || exit 1;
    cd "tmux-2.3" && ./configure || exit 1;
    make clean && make -j2 && make install || exit 1;
    tmux -V
}

install_ppa_nginx() {
    # https://launchpad.net/~nginx/+archive/ubuntu/stable
    sudo add-apt-repository -y ppa:nginx/stable
    sudo apt-get update
    sudo apt-get install -y nginx
}

install_neovim() {
    # https://launchpad.net/~neovim-ppa/+archive/ubuntu/unstable
    sudo add-apt-repository -y ppa:neovim-ppa/unstable
    sudo apt-get update
    sudo apt-get install -y neovim

    command -v /usr/bin/pip3 2>&1 > /dev/null || sudo apt-get install python3-pip
    sudo /usr/bin/pip install neovim
    sudo /usr/bin/pip3 install neovim
}

install_all() {
    # TODO dependency management: duplicated 'apt-get update'?
    install_essential_packages
    install_ppa_tmux
    install_ppa_git
    install_ppa_nginx
}


# entrypoint script
if [ `uname` != "Linux" ]; then
    echo "Run on Linux (not on Mac OS X)"; exit 1
fi
if [ -n "$1" ]; then
    $1
else
    echo "Usage: $0 [command], where command is one of the following:"
    declare -F | cut -d" " -f3 | grep -v '^_'
fi
