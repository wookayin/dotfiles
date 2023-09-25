#!/bin/bash
# vim: set expandtab ts=2 sts=2 sw=2:

# A collection of bash scripts for installing some libraries/packages in
# user namespaces (e.g. ~/.local/), without having root privileges.

set -e   # fail when any command fails
set -o pipefail

PREFIX="$HOME/.local"

DOTFILES_TMPDIR="/tmp/$USER/linux-locals"

COLOR_NONE="\033[0m"
COLOR_RED="\033[0;31m"
COLOR_GREEN="\033[0;32m"
COLOR_YELLOW="\033[0;33m"
COLOR_WHITE="\033[1;37m"

#---------------------------------------------------------------------------------------------------

_glibc_version() {
  # https://stackoverflow.com/questions/71070969/how-to-extract-and-compare-the-libc-versions-at-runtime
  local libcfile="$(grep -azm1 '/libc.so.6$' /etc/ld.so.cache | tr -d '\0')"
  grep -aoP 'GNU C Library [^\n]* release version \K[0-9]*.[0-9]*' "$libcfile"
}

_version_check() {
  # _version_check {curver} {targetver}: exit code is 0 if curver >= targetver
  local curver="$1"; local targetver="$2";
  [ "$targetver" = "$(echo -e "$curver\n$targetver" | sort -V | head -n1)" ]
}

_template_github_latest() {
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

  local tmpdir="$DOTFILES_TMPDIR/$name"
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

  local GIT_LATEST_VERSION=$(\
    curl -L https://api.github.com/repos/git/git/tags 2>/dev/null | \
    python -c 'import json, sys; print(json.load(sys.stdin)[0]["name"])'\
  )  # e.g. "v2.38.1"
  test  -n "$GIT_LATEST_VERSION"

  local TMP_GIT_DIR="$DOTFILES_TMPDIR/git"; mkdir -p $TMP_GIT_DIR
  wget -N -O $TMP_GIT_DIR/git.tar.gz "https://github.com/git/git/archive/${GIT_LATEST_VERSION}.tar.gz"
  tar -xvzf $TMP_GIT_DIR/git.tar.gz -C $TMP_GIT_DIR --strip-components 1

  cd $TMP_GIT_DIR
  make configure
  ./configure --prefix="$PREFIX" --with-curl --with-expat

  # requires libcurl-dev (mandatory to make https:// work)
  if grep -q 'cannot find -lcurl' config.log; then
    echo -e "${COLOR_RED}Error: libcurl not found. Please install libcurl-dev and try again.${COLOR_NONE}"
    echo -e "${COLOR_YELLOW}e.g., sudo apt install libcurl4-openssl-dev${COLOR_NONE}"
    return 1;
  fi

  make clean
  make -j8 && make install
  ~/.local/bin/git --version

  if [[ ! -f "$(~/.local/bin/git --exec-path)/git-remote-https" ]]; then
    echo -e "${COLOR_YELLOW}Warning: $(~/.local/bin/git --exec-path)/git-remote-https not found. "
    echo -e "https:// git url will not work. Please install libcurl-dev and try again.${COLOR_NONE}"
    return 2;
  fi
}

install_gh() {
  # github CLI: https://github.com/cli/cli/releases

  local version="2.20.2"
  local url="https://github.com/cli/cli/releases/download/v$version/gh_${version}_linux_amd64.tar.gz"

  local tmpdir="$DOTFILES_TMPDIR/gh"; mkdir -p $tmpdir

  wget -N -O $tmpdir/gh.tar.gz "$url"
  tar -xvzf $tmpdir/gh.tar.gz -C $tmpdir --strip-components 1
  mv $tmpdir/bin/gh $HOME/.local/bin/gh

  $HOME/.local/bin/gh --version
}

install_ncurses() {
  # installs ncurses (shared libraries and headers) into local namespaces.

  TMP_NCURSES_DIR="$DOTFILES_TMPDIR/ncurses/"; mkdir -p $TMP_NCURSES_DIR
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

  ZSH_VER="5.8"
  TMP_ZSH_DIR="$DOTFILES_TMPDIR/zsh/"; mkdir -p $TMP_ZSH_DIR

  wget -nc -O $TMP_ZSH_DIR/zsh.tar.xz "https://sourceforge.net/projects/zsh/files/zsh/${ZSH_VER}/zsh-${ZSH_VER}.tar.xz/download"
  tar xvJf $TMP_ZSH_DIR/zsh.tar.xz -C $TMP_ZSH_DIR --strip-components 1
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

  local NODE_VERSION
  if [ -z "$NODE_VERSION" ]; then
    if _version_check $(_glibc_version) 2.28; then
      # Use LTS version if GLIBC >= 2.28 (Ubuntu 20.04+)
      NODE_VERSION="lts"
    else
      # Older distro (Ubuntu 18.04) have GLIBC < 2.28
      NODE_VERSION="v16"
    fi
  fi

  set -x
  curl -L "https://install-node.vercel.app/$NODE_VERSION" \
    | bash -s -- --prefix=$HOME/.local --verbose --yes

  echo -e "\n$(which node) : $(node --version)"
  node --version

  # install some useful nodejs based utility (~/.local/lib/node_modules)
  $HOME/.local/bin/npm install -g yarn
  which yarn && yarn --version
  $HOME/.local/bin/npm install -g http-server diff-so-fancy || true;
}

install_tmux() {
  # tmux: we can do static compile, or use tmux-appimage (include libevents/ncurses)
  # see https://github.com/nelsonenzo/tmux-appimage
  TMUX_VER="3.2a"

  TMUX_APPIMAGE_URL="https://github.com/nelsonenzo/tmux-appimage/releases/download/${TMUX_VER}/tmux.appimage"
  wget -O $HOME/.local/bin/tmux $TMUX_APPIMAGE_URL
  chmod +x $HOME/.local/bin/tmux

  ~/.local/bin/tmux -V
}

install_bazel() {

  # install the 'latest' stable release (no pre-releases.)
  BAZEL_LATEST_VERSION=$(\
    curl -L https://api.github.com/repos/bazelbuild/bazel/releases/latest 2>/dev/null | \
    python -c 'import json, sys; print(json.load(sys.stdin)["name"])'\
  )
  test -n $BAZEL_LATEST_VERSION
  BAZEL_VER="${BAZEL_LATEST_VERSION}"
  echo -e "${COLOR_YELLOW}Installing Bazel ${BAZEL_VER} ...${COLOR_NONE}"

  BAZEL_URL="https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VER}/bazel-${BAZEL_VER}-installer-linux-x86_64.sh"

  TMP_BAZEL_DIR="$DOTFILES_TMPDIR/bazel/"
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

install_miniforge() {
  # Miniforge3.
  # https://github.com/conda-forge/miniforge
  local URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh"

  local TMP_DIR="$DOTFILES_TMPDIR/miniforge/"; mkdir -p $TMP_DIR && cd ${TMP_DIR}
  wget -nc "$URL"

  local MINIFORGE_PREFIX="$HOME/.miniforge3"
  bash "Miniforge3-Linux-x86_64.sh" -b -p ${MINIFORGE_PREFIX}
  $MINIFORGE_PREFIX/bin/python3 --version
}

install_miniconda() {
  # installs Miniconda3. (Deprecated: Use miniforge3)
  # https://conda.io/miniconda.html
  MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"

  TMP_DIR="$DOTFILES_TMPDIR/miniconda/"; mkdir -p $TMP_DIR && cd ${TMP_DIR}
  wget -nc $MINICONDA_URL

  MINICONDA_PREFIX="$HOME/.miniconda3/"
  bash "Miniconda3-latest-Linux-x86_64.sh" -b -p ${MINICONDA_PREFIX}

  # 3.9.5 as of Nov 2021
  $MINICONDA_PREFIX/bin/python --version
  echo -e "${COLOR_GREEN}All set!${COLOR_NONE}"

  echo -e "${COLOR_YELLOW}Warning: miniconda is deprecated, consider using miniforge3.${COLOR_NONE}"
}

install_vim() {
  # install latest vim

  # check python3-config
  local PYTHON3_CONFIGDIR=$(python3-config --configdir)
  echo -e "${COLOR_YELLOW}$ python3-config --configdir =${COLOR_NONE} $PYTHON3_CONFIGDIR"
  if [[ "$PYTHON3_CONFIGDIR" =~ (conda|virtualenv|venv) ]]; then
    echo -e "${COLOR_RED}Error: python3-config reports a conda/virtual environment. Deactivate and try again."
    return 1;
  fi

  # grab the lastest vim tarball and build it
  local TMP_VIM_DIR="$DOTFILES_TMPDIR/vim/"; mkdir -p $TMP_VIM_DIR
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
  # [NEOVIM_VERSION=...] dotfiles install neovim

  # Otherwise, use the latest stable version.
  local NEOVIM_LATEST_VERSION=$(\
    curl -L https://api.github.com/repos/neovim/neovim/releases/latest 2>/dev/null | \
    python -c 'import json, sys; print(json.load(sys.stdin)["tag_name"])'\
  )   # usually "stable"
  : "${NEOVIM_VERSION:=$NEOVIM_LATEST_VERSION}"

  if [[ $NEOVIM_VERSION != "stable" ]] && [[ $NEOVIM_VERSION != v* ]]; then
    NEOVIM_VERSION="v$NEOVIM_VERSION"  # e.g. "0.7.0" -> "v0.7.0"
  fi
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

  local TMP_NVIM_DIR="$DOTFILES_TMPDIR/neovim"; mkdir -p $TMP_NVIM_DIR
  local NVIM_DOWNLOAD_URL="https://github.com/neovim/neovim/releases/download/${NEOVIM_VERSION}/nvim.appimage"

  set -x
  cd $TMP_NVIM_DIR
  wget --backups=1 $NVIM_DOWNLOAD_URL      # always overwrite, having only one backup

  chmod +x nvim.appimage
  rm -rf "$TMP_NVIM_DIR/squashfs-root"
  ./nvim.appimage --appimage-extract >/dev/null   # into ./squashfs-root

  # Install into ~/.local/neovim/ and put a symlink into ~/.local/bin
  local NEOVIM_DEST="$HOME/.local/neovim"
  echo -e "${COLOR_GREEN}[*] Copying neovim files to $NEOVIM_DEST ... ${COLOR_NONE}"
  mkdir -p $NEOVIM_DEST/bin/
  cp -f squashfs-root/usr/bin/nvim "$NEOVIM_DEST/bin/nvim" \
    || (echo -e "${COLOR_RED}Copy failed, please kill all nvim instances. (killall nvim)${COLOR_NONE}"; exit 1)
  rm -rf "$NEOVIM_DEST"
  cp -r squashfs-root/usr "$NEOVIM_DEST"
  rm -f "$PREFIX/bin/nvim"
  ln -sf "$NEOVIM_DEST/bin/nvim" "$PREFIX/bin/nvim"

  $PREFIX/bin/nvim --version | head -n3
}

install_exa() {
  # https://github.com/ogham/exa/releases
  EXA_VERSION="0.10.1"
  EXA_BINARY_SHA1SUM="7bbd4be0bf44a0302970e7596f5753a0f31e85ac"
  EXA_DOWNLOAD_URL="https://github.com/ogham/exa/releases/download/v$EXA_VERSION/exa-linux-x86_64-v$EXA_VERSION.zip"
  TMP_EXA_DIR="$DOTFILES_TMPDIR/exa/"

  wget -nc ${EXA_DOWNLOAD_URL} -P ${TMP_EXA_DIR} || exit 1;
  cd ${TMP_EXA_DIR} && unzip -o "exa-linux-x86_64-v$EXA_VERSION.zip" || exit 1;
  if [[ "$EXA_BINARY_SHA1SUM" != "$(sha1sum bin/exa | cut -d' ' -f1)" ]]; then
      echo -e "${COLOR_RED}SHA1 checksum mismatch, aborting!${COLOR_NONE}"
      exit 1;
  fi
  cp "bin/exa" "$PREFIX/bin/exa" || exit 1;
  cp "completions/exa.zsh" "$PREFIX/share/zsh/site-functions/_exa" || exit 1;
  echo "$(which exa) : $(exa --version)"
}

install_fd() {
  # install fd
  # https://github.com/sharkdp/fd/releases
  local FD_VERSION="v8.5.3"

  TMP_FD_DIR="$DOTFILES_TMPDIR/fd"; mkdir -p $TMP_FD_DIR
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
  RIPGREP_LATEST_VERSION=$(\
      curl -L https://api.github.com/repos/BurntSushi/ripgrep/releases 2>/dev/null | \
      python -c 'import json, sys; J = json.load(sys.stdin); assert J[0]["assets"][0]["name"].startswith("ripgrep"); print(J[0]["name"])'\
  )
  test -n $RIPGREP_LATEST_VERSION
  echo -e "${COLOR_YELLOW}Installing ripgrep ${RIPGREP_LATEST_VERSION} ...${COLOR_NONE}"
  RIPGREP_VERSION="${RIPGREP_LATEST_VERSION}"

  TMP_RIPGREP_DIR="$DOTFILES_TMPDIR/ripgrep"; mkdir -p $TMP_RIPGREP_DIR
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

  set -x
  mkdir -p $PREFIX/bin && cd $PREFIX/bin
  curl -L "https://github.com/BurntSushi/xsv/releases/download/${XSV_VERSION}/xsv-${XSV_VERSION}-x86_64-unknown-linux-musl.tar.gz" | tar zxf -
  $PREFIX/bin/xsv
}

install_bat() {
  # https://github.com/sharkdp/bat/releases
  local BAT_VERSION="0.22.1"

  set -x
  mkdir -p $PREFIX/bin && cd $PREFIX/bin
  curl -L "https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat-v${BAT_VERSION}-x86_64-unknown-linux-musl.tar.gz" \
    | tar zxf - --strip-components 1 --wildcards --no-anchored 'bat*'     # bat, bat.1

  $PREFIX/bin/bat --version
}

install_go() {
  # install go lang into ~/.go
  # https://golang.org/dl/
  if [[ -d $HOME/.go ]]; then
    echo -e "${COLOR_RED}Error: $HOME/.go already exists.${COLOR_NONE}"
    exit 1;
  fi

  GO_DOWNLOAD_URL="https://dl.google.com/go/go1.9.3.linux-amd64.tar.gz"
  TMP_GO_DIR="$DOTFILES_TMPDIR/go/"

  wget -nc ${GO_DOWNLOAD_URL} -P ${TMP_GO_DIR} || exit 1;
  cd ${TMP_GO_DIR} && tar -xvzf "go1.9.3.linux-amd64.tar.gz" || exit 1;
  mv go $HOME/.go

  echo ""
  echo -e "${COLOR_GREEN}Installed at $HOME/.go${COLOR_NONE}"
  $HOME/.go/bin/go version
}

install_duf() {
  # https://github.com/muesli/duf/releases
  _template_github_latest "duf" "muesli/duf" "duf_*_linux_x86_64.tar.gz"
  [[ $(pwd) =~ ^"$DOTFILES_TMPDIR/" ]]

  cp -v "./duf" $PREFIX/bin

  echo -e "\n\n${COLOR_WHITE}$(which duf)${COLOR_NONE}"
  $PREFIX/bin/duf --version
}

install_lazydocker() {
  _template_github_latest "lazydocker" "jesseduffield/lazydocker" "lazydocker_*_Linux_x86_64.tar.gz"
  [[ $(pwd) =~ ^$DOTFILES_TMPDIR/ ]]

  cp -v "./lazydocker" $PREFIX/bin

  echo -e "\n\n${COLOR_WHITE}$(which lazydocker)${COLOR_NONE}"
  $PREFIX/bin/lazydocker --version
}

install_lazygit() {
  _template_github_latest "lazygit" "jesseduffield/lazygit" "lazygit_*_Linux_x86_64.tar.gz"
  [[ $(pwd) =~ ^$DOTFILES_TMPDIR/ ]]

  cp -v "./lazygit" $PREFIX/bin

  echo -e "\n\n${COLOR_WHITE}$(which lazydocker)${COLOR_NONE}"
  $PREFIX/bin/lazygit --version
}

install_rsync() {

  local URL="https://www.samba.org/ftp/rsync/src/rsync-3.2.4.tar.gz"
  local TMP_DIR="$DOTFILES_TMPDIR/rsync"; mkdir -p $TMP_DIR

  wget -N -O $TMP_DIR/rsync.tar.gz "$URL"
  tar -xvzf $TMP_DIR/rsync.tar.gz -C $TMP_DIR --strip-components 1
  cd $TMP_DIR

  ./configure --prefix="$PREFIX"
  make install
  $PREFIX/bin/rsync --version
}

install_mosh() {
  set -x
  rm -rf mosh || true

  local URL="https://github.com/mobile-shell/mosh/archive/refs/tags/mosh-1.4.0.zip"
  local TMP_DIR="$DOTFILES_TMPDIR/mosh"; mkdir -p $TMP_DIR
  rm -rf mosh || true
  cd "$TMP_DIR"

  wget -N -O "mosh.tar.gz" "$URL"
  unzip -o "mosh.tar.gz"   # It's actually a zip file, not a tar.gz ....
  cd "mosh-mosh-1.4.0/"

  ./autogen.sh
  ./configure --prefix="$PREFIX"
  make -j4
  make install
  $PREFIX/bin/mosh-server --version
}

install_mujoco() {
  # https://github.com/deepmind/mujoco/
  # Note: If pre-built wheel is available, just do `pip install mujoco` and it's done
  set -x
  local mujoco_version="2.3.0"

  local MUJOCO_ROOT=$HOME/.mujoco/mujoco-$mujoco_version
  if [[ -d "$MUJOCO_ROOT" ]]; then
    echo -e "${COLOR_YELLOW}Error: $MUJOCO_ROOT already exists.${COLOR_NONE}"
    return 1;
  fi

  local tmpdir="$DOTFILES_TMPDIR/mujoco"
  mkdir -p $tmpdir && cd $tmpdir
  mkdir -p $HOME/.mujoco

  local download_url="https://github.com/deepmind/mujoco/releases/download/${mujoco_version}/mujoco-${mujoco_version}-linux-x86_64.tar.gz"
  local filename="$(basename $download_url)"
  wget -N -O $tmpdir/$filename "$download_url"
  tar -xvzf "$filename" -C $tmpdir

  mv $tmpdir/mujoco-$mujoco_version $HOME/.mujoco/
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
