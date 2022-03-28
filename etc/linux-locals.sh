#!/bin/bash

# A collection of bash scripts for installing some libraries/packages in
# user namespaces (e.g. ~/.local/), without having root privileges.

PREFIX="$HOME/.local/"

COLOR_NONE="\033[0m"
COLOR_RED="\033[0;31m"
COLOR_GREEN="\033[0;32m"
COLOR_YELLOW="\033[0;33m"
COLOR_WHITE="\033[1;37m"


#---------------------------------------------------------------------------------------------------

_template_github_latest() {
  set -e
  local name="$1"
  local repo="$2"
  local filename="$3"
  if [[ -z "$name" ]] || [[ -z "$repo" ]] || [[ -z "$filename" ]]; then
    echo "Wrong usage"; return 1;
  fi

  echo -e "${COLOR_YELLOW}Installing $name from $repo ... ${COLOR_NONE}"
  local download_url=$(\
    curl -L https://api.github.com/repos/${repo}/releases 2>/dev/null | \
    python -c "\
import json, sys, fnmatch;
J = json.load(sys.stdin);
for asset in J[0]['assets']:
  if fnmatch.fnmatch(asset['name'], '$filename'):
    print(asset['browser_download_url'])
")
  echo -e "${COLOR_YELLOW}download_url = ${COLOR_NONE}$download_url"
  test -n $download_url
  sleep 0.5

  local tmpdir="/tmp/$USER/$name"
  local filename="$(basename $download_url)"
  mkdir -p $tmpdir
  wget -O "$tmpdir/$filename" "$download_url"

  echo -e "${COLOR_YELLOW}Extracting to: $tmpdir${COLOR_NONE}"
  cd $tmpdir && tar -xvzf $filename

  echo -e "${COLOR_YELLOW}Copying ...${COLOR_NONE}"
}

#---------------------------------------------------------------------------------------------------

install_git() {
    # installs a modern version of git locally.
    set -e

    GIT_VER="2.30.0"
    TMP_GIT_DIR="/tmp/$USER/git"; mkdir -p $TMP_GIT_DIR

    wget -N -O $TMP_GIT_DIR/git.tar.gz "https://github.com/git/git/archive/v${GIT_VER}.tar.gz"
    tar -xvzf $TMP_GIT_DIR/git.tar.gz -C $TMP_GIT_DIR --strip-components 1
    cd $TMP_GIT_DIR

    make configure
    ./configure --prefix="$PREFIX" --with-curl --with-expat
    make clean
    make -j8 && make install

    ~/.local/bin/git --version

    if [[ ! -f "$(~/.local/bin/git --exec-path)/git-remote-https" ]]; then
        echo -e "${COLOR_YELLOW}Warning: $(~/.local/bin/git --exec-path)/git-remote-https not found. "
        echo -e "https:// git url will not work. Please install libcurl-dev and try again.${COLOR_NONE}"
        false;
    fi
}

install_ncurses() {
    # installs ncurses (shared libraries and headers) into local namespaces.
    set -e

    TMP_NCURSES_DIR="/tmp/$USER/ncurses/"; mkdir -p $TMP_NCURSES_DIR
    NCURSES_DOWNLOAD_URL="https://invisible-mirror.net/archives/ncurses/ncurses-5.9.tar.gz";

    wget -nc -O $TMP_NCURSES_DIR/ncurses-5.9.tar.gz $NCURSES_DOWNLOAD_URL
    tar -xvzf $TMP_NCURSES_DIR/ncurses-5.9.tar.gz -C $TMP_NCURSES_DIR --strip-components 1
    cd $TMP_NCURSES_DIR

    # compile as shared library, at ~/.local/lib/libncurses.so (as well as static lib)
    export CPPFLAGS="-P"
    ./configure --prefix="$PREFIX" --with-shared

    make clean && make -j4 && make install
}

install_zsh() {
    set -e

    ZSH_VER="5.4.1"
    TMP_ZSH_DIR="/tmp/$USER/zsh/"; mkdir -p $TMP_ZSH_DIR

    wget -nc -O $TMP_ZSH_DIR/zsh.tar.gz "https://sourceforge.net/projects/zsh/files/zsh/${ZSH_VER}/zsh-${ZSH_VER}.tar.gz/download"
    tar -xvzf $TMP_ZSH_DIR/zsh.tar.gz -C $TMP_ZSH_DIR --strip-components 1
    cd $TMP_ZSH_DIR

    if [[ -d "$PREFIX/include/ncurses" ]]; then
        export CFLAGS="-I$PREFIX/include -I$PREFIX/include/ncurses"
        export LDFLAGS="-L$PREFIX/lib/"
    fi

    ./configure --prefix="$PREFIX"
    make clean && make -j8 && make install

    ~/.local/bin/zsh --version
}

install_node() {
    # Install node.js LTS at ~/.local
    set -e
    curl -sL install-node.now.sh | bash -s -- --prefix=$HOME/.local --verbose --yes

    echo -e "\n$(which node) : $(node --version)"
    node --version

    # install some useful nodejs based utility (~/.local/lib/node_modules)
    $HOME/.local/bin/npm install -g yarn
    which yarn && yarn --version
    $HOME/.local/bin/npm install -g http-server diff-so-fancy || true;
}

install_tmux() {
    # install tmux (and its dependencies such as libevent) locally
    set -e
    TMUX_VER="3.2a"

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
    TMUX_TGZ_FILE="tmux-${TMUX_VER}.tar.gz"
    TMUX_DOWNLOAD_URL="https://github.com/tmux/tmux/releases/download/${TMUX_VER}/${TMUX_TGZ_FILE}"

    wget -nc ${TMUX_DOWNLOAD_URL} -P ${TMP_TMUX_DIR}
    cd ${TMP_TMUX_DIR} && tar -xvzf ${TMUX_TGZ_FILE}
    cd "tmux-${TMUX_VER}"

    ./configure --prefix="$PREFIX" \
        CFLAGS="-I$PREFIX/include/ -I$PREFIX/include/ncurses/" \
        LDFLAGS="-L$PREFIX/lib/" \
        PKG_CONFIG="/bin/false"

    make clean && make -j4 && make install
    ~/.local/bin/tmux -V
}

install_bazel() {
    set -e

    # install the 'latest' stable release (no pre-releases.)
    BAZEL_LATEST_VERSION=$(\
        curl -L https://api.github.com/repos/bazelbuild/bazel/releases/latest 2>/dev/null | \
        python -c 'import json, sys; print(json.load(sys.stdin)["name"])'\
    )
    test -n $BAZEL_LATEST_VERSION
    BAZEL_VER="${BAZEL_LATEST_VERSION}"
    echo -e "${COLOR_YELLOW}Installing Bazel ${BAZEL_VER} ...${COLOR_NONE}"

    BAZEL_URL="https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VER}/bazel-${BAZEL_VER}-installer-linux-x86_64.sh"

    TMP_BAZEL_DIR="/tmp/$USER/bazel/"
    mkdir -p $TMP_BAZEL_DIR
    wget -O $TMP_BAZEL_DIR/bazel-installer.sh $BAZEL_URL

    # zsh completion
    mkdir -p $HOME/.local/share/zsh/site-functions
    wget -O $HOME/.local/share/zsh/site-functions/_bazel https://raw.githubusercontent.com/bazelbuild/bazel/master/scripts/zsh_completion/_bazel

    # install bazel
    bash $TMP_BAZEL_DIR/bazel-installer.sh \
        --bin=$HOME/.local/bin \
        --base=$HOME/.bazel

    # print bazel version
    echo -e "\n\n${COLOR_YELLOW}Bazel at $(which bazel): ${COLOR_NONE}"
    bazel 2>/dev/null | grep release | xargs
    echo ""
}

install_anaconda() {
    # installs Anaconda-python3. (Deprecated: Use miniconda)
    # https://www.anaconda.com/products/individual
    # https://repo.anaconda.com/archive/Anaconda3-2021.05-Linux-x86_64.sh
    set -e
    ANACONDA_VERSION="2021.05"

    if [ "$1" != "--force" ]; then
        echo "Please use miniconda instead. Use --force option to proceed." && exit 1;
    fi

    # https://www.anaconda.com/download/
    TMP_DIR="/tmp/$USER/anaconda/"; mkdir -p $TMP_DIR && cd ${TMP_DIR}
    wget -nc "https://repo.anaconda.com/archive/Anaconda3-${ANACONDA_VERSION}-Linux-x86_64.sh"

    # will install at $HOME/.anaconda3 (see zsh config for PATH)
    ANACONDA_PREFIX="$HOME/.anaconda3/"
    bash "Anaconda3-${ANACONDA_VERSION}-Linux-x86_64.sh" -b -p ${ANACONDA_PREFIX}

    $ANACONDA_PREFIX/bin/python --version
}

install_miniconda() {
    # installs Miniconda3
    # https://conda.io/miniconda.html
    set -e
    MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"

    TMP_DIR="/tmp/$USER/miniconda/"; mkdir -p $TMP_DIR && cd ${TMP_DIR}
    wget -nc $MINICONDA_URL

    MINICONDA_PREFIX="$HOME/.miniconda3/"
    bash "Miniconda3-latest-Linux-x86_64.sh" -b -p ${MINICONDA_PREFIX}

    # 3.9.5 as of Nov 2021
    $MINICONDA_PREFIX/bin/python --version
    echo -e "${COLOR_GREEN}All set!${COLOR_NONE}"
}

install_vim() {
    # install latest vim
    set -e

    # check python3-config
    local PYTHON3_CONFIGDIR=$(python3-config --configdir)
    echo -e "${COLOR_YELLOW}$ python3-config --configdir =${COLOR_NONE} $PYTHON3_CONFIGDIR"
    if [[ "$PYTHON3_CONFIGDIR" =~ (conda|virtualenv|venv) ]]; then
      echo -e "${COLOR_RED}Error: python3-config reports a conda/virtual environment. Deactivate and try again."
      return 1;
    fi

    # grab the lastest vim tarball and build it
    local TMP_VIM_DIR="/tmp/$USER/vim/"; mkdir -p $TMP_VIM_DIR
    local VIM_LATEST_VERSION=$(\
        curl -L https://api.github.com/repos/vim/vim/tags 2>/dev/null | \
        python -c 'import json, sys; print(json.load(sys.stdin)[0]["name"])'\
    )
    test -n $VIM_LATEST_VERSION
    local VIM_LATEST_VERSION=${VIM_LATEST_VERSION/v/}    # (e.g) 8.0.1234
    echo -e "${COLOR_GREEN}Installing vim $VIM_LATEST_VERSION ...${COLOR_NONE}"
    sleep 1

    local VIM_DOWNLOAD_URL="https://github.com/vim/vim/archive/v${VIM_LATEST_VERSION}.tar.gz"

    wget -nc ${VIM_DOWNLOAD_URL} -P ${TMP_VIM_DIR} || true;
    cd ${TMP_VIM_DIR} && tar -xvzf v${VIM_LATEST_VERSION}.tar.gz
    cd "vim-${VIM_LATEST_VERSION}/src"

    ./configure --prefix="$PREFIX" \
        --with-features=huge \
        --enable-python3interp \
        --with-python3-config-dir="$PYTHON3_CONFIGDIR"

    make clean && make -j8 && make install
    ~/.local/bin/vim --version | head -n2

    # make sure that all necessary features are shipped
    if ! (vim --version | grep -q '+python3'); then
        echo "vim: python is not enabled"
        exit 1;
    fi
}

install_neovim() {
    # install neovim stable or nightly
    set -e

    local NEOVIM_VERSION=$(\
        curl -L https://api.github.com/repos/neovim/neovim/releases/latest 2>/dev/null | \
        python -c 'import json, sys; print(json.load(sys.stdin)["tag_name"])'\
    )   # starts with "v", e.g. "v0.6.1"
    test -n "$NEOVIM_VERSION"

    local VERBOSE=""
    for arg in "$@"; do
      if [ "$arg" == "--nightly" ]; then
        NEOVIM_VERSION="nightly";
      elif [ "$arg" == "-v" ] || [ "$arg" == "--verbose" ]; then
        VERBOSE="--verbose"
      fi
    done

    if [ "${NEOVIM_VERSION}" == "nightly" ]; then
      echo -e "${COLOR_YELLOW}Installing neovim nightly. ${COLOR_NONE}"
    else
      echo -e "${COLOR_YELLOW}Installing neovim stable ${NEOVIM_VERSION}. ${COLOR_NONE}"
      echo -e "${COLOR_YELLOW}To install a nightly version, add flag: --nightly ${COLOR_NONE}"
    fi
    sleep 1;  # allow users to read above comments

    local TMP_NVIM_DIR="/tmp/$USER/neovim"; mkdir -p $TMP_NVIM_DIR
    local NVIM_DOWNLOAD_URL="https://github.com/neovim/neovim/releases/download/${NEOVIM_VERSION}/nvim-linux64.tar.gz"

    cd $TMP_NVIM_DIR
    wget --backups=1 $NVIM_DOWNLOAD_URL      # always overwrite, having only one backup
    tar $VERBOSE -xzf "nvim-linux64.tar.gz"
    ls --color -d $TMP_NVIM_DIR/nvim-linux64

    # copy and merge into ~/.local/bin
    echo -e "${COLOR_GREEN}[*] Copying to $PREFIX ... ${COLOR_NONE}"
    cp -RT $VERBOSE "nvim-linux64/" "$PREFIX" >/dev/null \
        || (echo -e "${COLOR_RED}Copy failed, please kill all nvim instances.${COLOR_NONE}"; exit 1)

    $PREFIX/bin/nvim --version
}

install_exa() {
    # https://github.com/ogham/exa/releases
    EXA_VERSION="0.9.0"
    EXA_BINARY_SHA1SUM="744e3fdff6581bf84b95cecb00258df8c993dc74"  # exa-linux-x86_64 v0.9.0
    EXA_DOWNLOAD_URL="https://github.com/ogham/exa/releases/download/v$EXA_VERSION/exa-linux-x86_64-$EXA_VERSION.zip"
    TMP_EXA_DIR="/tmp/$USER/exa/"

    wget -nc ${EXA_DOWNLOAD_URL} -P ${TMP_EXA_DIR} || exit 1;
    cd ${TMP_EXA_DIR} && unzip -o "exa-linux-x86_64-$EXA_VERSION.zip" || exit 1;
    if [[ "$EXA_BINARY_SHA1SUM" != "$(sha1sum exa-linux-x86_64 | cut -d' ' -f1)" ]]; then
        echo -e "${COLOR_RED}SHA1 checksum mismatch, aborting!${COLOR_NONE}"
        exit 1;
    fi
    cp "exa-linux-x86_64" "$PREFIX/bin/exa" || exit 1;
    echo "$(which exa) : $(exa --version)"
}

install_fd() {
    # install fd
    set -e

    local FD_VERSION="v8.3.2"

    TMP_FD_DIR="/tmp/$USER/fd"; mkdir -p $TMP_FD_DIR
    FD_DOWNLOAD_URL="https://github.com/sharkdp/fd/releases/download/${FD_VERSION}/fd-${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz"
    echo $FD_DOWNLOAD_URL

    cd $TMP_FD_DIR
    curl -L $FD_DOWNLOAD_URL | tar -xvzf - --strip-components 1
    cp "./fd" $PREFIX/bin
    mkdir -p $HOME/.local/share/zsh/site-functions
    cp "./autocomplete/_fd" $PREFIX/share/zsh/site-functions

    $PREFIX/bin/fd --version
    echo "$(which fd) : $(fd --version)"
}

install_ripgrep() {
    # install ripgrep
    set -e
    RIPGREP_LATEST_VERSION=$(\
        curl -L https://api.github.com/repos/BurntSushi/ripgrep/releases 2>/dev/null | \
        python -c 'import json, sys; J = json.load(sys.stdin); assert J[0]["assets"][0]["name"].startswith("ripgrep"); print(J[0]["name"])'\
    )
    test -n $RIPGREP_LATEST_VERSION
    echo -e "${COLOR_YELLOW}Installing ripgrep ${RIPGREP_LATEST_VERSION} ...${COLOR_NONE}"
    RIPGREP_VERSION="${RIPGREP_LATEST_VERSION}"

    TMP_RIPGREP_DIR="/tmp/$USER/ripgrep"; mkdir -p $TMP_RIPGREP_DIR
    RIPGREP_DOWNLOAD_URL="https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl.tar.gz"
    echo $RIPGREP_DOWNLOAD_URL

    cd $TMP_RIPGREP_DIR
    curl -L $RIPGREP_DOWNLOAD_URL | tar -xvzf - --strip-components 1
    cp "./rg" $PREFIX/bin

    mkdir -p $HOME/.local/share/zsh/site-functions
    cp "./complete/_rg" $PREFIX/share/zsh/site-functions

    $PREFIX/bin/rg --version
    echo "$(which rg) : $(rg --version)"
}

install_xsv() {
    XSV_VERSION="0.13.0"

    set -e; set -x
    mkdir -p $PREFIX/bin && cd $PREFIX/bin
    curl -L "https://github.com/BurntSushi/xsv/releases/download/${XSV_VERSION}/xsv-${XSV_VERSION}-x86_64-unknown-linux-musl.tar.gz" | tar zxf -
    $PREFIX/bin/xsv
}

install_bat() {
    BAT_VERSION="0.12.1"

    set -e; set -x
    mkdir -p $PREFIX/bin && cd $PREFIX/bin
    curl -L "https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat-v${BAT_VERSION}-x86_64-unknown-linux-musl.tar.gz" \
        | tar zxf - --strip-components 1 --wildcards --no-anchored 'bat*'     # bat, bat.1

    $PREFIX/bin/bat --version
}

install_go() {
    # install go lang into ~/.go
    # https://golang.org/dl/
    set -e
    if [[ -d $HOME/.go ]]; then
        echo -e "${COLOR_RED}Error: $HOME/.go already exists.${COLOR_NONE}"
        exit 1;
    fi

    GO_DOWNLOAD_URL="https://dl.google.com/go/go1.9.3.linux-amd64.tar.gz"
    TMP_GO_DIR="/tmp/$USER/go/"

    wget -nc ${GO_DOWNLOAD_URL} -P ${TMP_GO_DIR} || exit 1;
    cd ${TMP_GO_DIR} && tar -xvzf "go1.9.3.linux-amd64.tar.gz" || exit 1;
    mv go $HOME/.go

    echo ""
    echo -e "${COLOR_GREEN}Installed at $HOME/.go${COLOR_NONE}"
    $HOME/.go/bin/go version
}

install_lazydocker() {
  set -e
  _template_github_latest "lazydocker" "jesseduffield/lazydocker" "lazydocker_*_Linux_x86_64.tar.gz"
  [[ $(pwd) =~ ^/tmp/$USER/ ]]

  cp -v "./lazydocker" $PREFIX/bin

  echo -e "\n\n${COLOR_WHITE}$(which lazydocker)${COLOR_NONE}"
  $PREFIX/bin/lazydocker --version
}

install_lazygit() {
  set -e
  _template_github_latest "lazygit" "jesseduffield/lazygit" "lazygit_*_Linux_x86_64.tar.gz"
  [[ $(pwd) =~ ^/tmp/$USER/ ]]

  cp -v "./lazygit" $PREFIX/bin

  echo -e "\n\n${COLOR_WHITE}$(which lazydocker)${COLOR_NONE}"
  $PREFIX/bin/lazygit --version
}

install_rsync() {
  set -e

  local URL="https://rsync.samba.org/ftp/rsync/rsync-3.2.3.tar.gz"
  local TMP_DIR="/tmp/$USER/rsync"; mkdir -p $TMP_DIR

  wget -N -O $TMP_DIR/rsync.tar.gz "$URL"
  tar -xvzf $TMP_DIR/rsync.tar.gz -C $TMP_DIR --strip-components 1
  cd $TMP_DIR

  ./configure --prefix="$PREFIX"
  make install
  $PREFIX/bin/rsync --version
}

install_mosh() {
  set -e; set -x
  mkdir -p /tmp/$USER && cd /tmp/$USER/
  rm -rf mosh || true
  git clone https://github.com/mobile-shell/mosh --depth=1
  cd mosh

  # bump up mosh version to indicate this is a HEAD version
  sed -i -e 's/1\.3\.2/1.4.0/g' configure.ac

  ./autogen.sh
  ./configure --prefix="$PREFIX"
  make install
  $PREFIX/bin/mosh-server --version
}

install_mujoco() {
  # https://mujoco.org/download
  set -e; set -x
  local mujoco_version="mujoco210"

  local MUJOCO_ROOT=$HOME/.mujoco/$mujoco_version
  if [[ -d "$MUJOCO_ROOT" ]]; then
    echo -e "${COLOR_YELLOW}Error: $MUJOCO_ROOT already exists.${COLOR_NONE}"
    return 1;
  fi

  local tmpdir="/tmp/$USER/mujoco"
  mkdir -p $tmpdir && cd $tmpdir
  mkdir -p $HOME/.mujoco

  local download_url="https://mujoco.org/download/${mujoco_version}-linux-x86_64.tar.gz"
  local filename="$(basename $download_url)"
  wget -N -O $tmpdir/$filename "$download_url"
  tar -xvzf "$filename" -C $tmpdir

  mv $tmpdir/$mujoco_version $HOME/.mujoco/
  test -d $MUJOCO_ROOT

  $MUJOCO_ROOT/bin/testspeed $MUJOCO_ROOT/model/scene.xml 1000
  set +x

  echo -e "${COLOR_GREEN}MUJOCO_ROOT = $MUJOCO_ROOT${COLOR_NONE}"
  echo -e "${COLOR_WHITE}Done. Please don't forget to set LD_LIBRARY_PATH \
   (should include $MUJOCO_ROOT/bin).${COLOR_NONE}\n"
}


# entrypoint script
if [ `uname` != "Linux" ]; then
    echo "Run on Linux (not on Mac OS X)"; exit 1
fi
if [[ -n "$1" && "$1" != "--help" ]] && declare -f "$1"; then
    $@
else
    echo "Usage: $0 [command], where command is one of the following:"
    declare -F | cut -d" " -f3 | grep -v '^_'
    exit 1;
fi
