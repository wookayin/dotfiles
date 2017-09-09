#!/bin/bash

# A collection of bash scripts for installing some libraries/packages in
# user namespaces (e.g. ~/.local/), without having root privileges.

install_zsh() {

    ZSH_VER="5.4.1"
    TMP_ZSH_DIR="/tmp/$USER/zsh/"

    mkdir -p $TMP_ZSH_DIR
    wget -O $TMP_ZSH_DIR/zsh.tar.gz "https://sourceforge.net/projects/zsh/files/zsh/${ZSH_VER}/zsh-${ZSH_VER}.tar.gz/download"
    tar -xvzf $TMP_ZSH_DIR/zsh.tar.gz -C $TMP_ZSH_DIR --strip-components 1
    cd $TMP_ZSH_DIR

    ./configure --prefix="$HOME/.local/"
    make -j8 && make install

    ~/.local/bin/zsh --version
}

# die immediately if error occurs
set -e

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
