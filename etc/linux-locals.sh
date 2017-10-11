#!/bin/bash

# A collection of bash scripts for installing some libraries/packages in
# user namespaces (e.g. ~/.local/), without having root privileges.

PREFIX="$HOME/.local/"

install_zsh() {
    set -e

    ZSH_VER="5.4.1"
    TMP_ZSH_DIR="/tmp/$USER/zsh/"; mkdir -p $TMP_ZSH_DIR

    wget -nc -O $TMP_ZSH_DIR/zsh.tar.gz "https://sourceforge.net/projects/zsh/files/zsh/${ZSH_VER}/zsh-${ZSH_VER}.tar.gz/download"
    tar -xvzf $TMP_ZSH_DIR/zsh.tar.gz -C $TMP_ZSH_DIR --strip-components 1
    cd $TMP_ZSH_DIR

    ./configure --prefix="$PREFIX"
    make clean && make -j8 && make install

    ~/.local/bin/zsh --version
}

install_tmux() {
    # install tmux (and its dependencies such as libevent) locally
    set -e
    TMP_TMUX_DIR="/tmp/$USER/tmux/"; mkdir -p $TMP_TMUX_DIR

    # libevent
    if [[ -f "/usr/include/libevent.a" ]]; then
        echo "Using system libevent"
    elif [[ ! -f "$PREFIX/lib/libevent.a" ]]; then
        wget -nc -O $TMP_TMUX_DIR/libevent.tar.gz "https://github.com/libevent/libevent/releases/download/release-2.1.8-stable/libevent-2.1.8-stable.tar.gz" || true;
        tar -xvzf $TMP_TMUX_DIR/libevent.tar.gz -C $TMP_TMUX_DIR
        cd ${TMP_TMUX_DIR}/libevent-*
        ./configure --prefix="$PREFIX" --disable-shared
        make clean && make -j4 && make install
    fi

    # TODO: assuming that ncurses is available?

    # tmux
    TMUX_TGZ_FILE="tmux-2.5.tar.gz"
    TMUX_DOWNLOAD_URL="https://github.com/tmux/tmux/releases/download/2.5/${TMUX_TGZ_FILE}"

    wget -nc ${TMUX_DOWNLOAD_URL} -P ${TMP_TMUX_DIR}
    cd ${TMP_TMUX_DIR} && tar -xvzf ${TMUX_TGZ_FILE}
    cd "tmux-2.5"

    ./configure --prefix="$PREFIX" \
        CFLAGS="-I$PREFIX/include/" \
        LDFLAGS="-L$PREFIX/lib/" \
        PKG_CONFIG="/bin/false"

    make clean && make -j4 && make install
    ~/.local/bin/tmux -V
}


install_bazel() {
    set -e

    BAZEL_VER="0.5.4"
    BAZEL_URL="https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VER}/bazel-${BAZEL_VER}-installer-linux-x86_64.sh"

    TMP_BAZEL_DIR="/tmp/$USER/bazel/"
    mkdir -p $TMP_BAZEL_DIR
    wget -O $TMP_BAZEL_DIR/bazel-installer.sh $BAZEL_URL

    bash $TMP_BAZEL_DIR/bazel-installer.sh \
        --bin=$HOME/.local/bin \
        --base=$HOME/.bazel
}


install_anaconda3() {
    # installs Anaconda-python3.
    # https://www.anaconda.com/download/#linux
    set -e

    # https://www.anaconda.com/download/
    TMP_DIR="/tmp/$USER/anaconda/"; mkdir -p $TMP_DIR && cd ${TMP_DIR}
    wget -nc "https://repo.continuum.io/archive/Anaconda3-5.0.0.1-Linux-x86_64.sh"

    # will install at $HOME/.anaconda3 (see zsh config for PATH)
    ANACONDA_PREFIX="$HOME/.anaconda3/"
    bash "Anaconda3-5.0.0.1-Linux-x86_64.sh" -b -p ${ANACONDA_PREFIX}

    $ANACONDA_PREFIX/bin/python --version
}


install_vim() {
    # install latest vim
    set -e

    TMP_VIM_DIR="/tmp/$USER/vim/"; mkdir -p $TMP_VIM_DIR
    VIM_LATEST_VERSION=$(\
        curl -L https://api.github.com/repos/vim/vim/tags 2>/dev/null | \
        python -c 'import json, sys; print(json.load(sys.stdin)[0]["name"])'\
    )
    test -n $VIM_LATEST_VERSION
    VIM_LATEST_VERSION=${VIM_LATEST_VERSION/v/}    # (e.g) 8.0.1234

    VIM_DOWNLOAD_URL="https://github.com/vim/vim/archive/v${VIM_LATEST_VERSION}.tar.gz"

    wget -nc ${VIM_DOWNLOAD_URL} -P ${TMP_VIM_DIR} || true;
    cd ${TMP_VIM_DIR} && tar -xvzf v${VIM_LATEST_VERSION}.tar.gz
    cd "vim-${VIM_LATEST_VERSION}/src"

    ./configure --prefix="$PREFIX" \
        --with-features=huge \
        --enable-pythoninterp

    make clean && make -j8 && make install
    ~/.local/bin/vim --version | head -n2

    # make sure that all necessary features are shipped
    if ! (vim --version | grep -q '+python'); then
        echo "vim: python is not enabled"
        exit 1;
    fi
}

install_neovim() {
    # install neovim nightly
    set -e

    TMP_NVIM_DIR="/tmp/$USER/neovim"; mkdir -p $TMP_NVIM_DIR
    NVIM_DOWNLOAD_URL="https://github.com/neovim/neovim/releases/download/nightly/nvim-linux64.tar.gz"

    cd $TMP_NVIM_DIR
    wget -nc $NVIM_DOWNLOAD_URL || true;
    tar -xvzf "nvim-linux64.tar.gz"

    # copy and merge into ~/.local/bin
    cp -RTv "nvim-linux64/" "$PREFIX"

    $PREFIX/bin/nvim --version
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
