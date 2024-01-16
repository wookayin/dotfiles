#!/bin/bash
# vim: set expandtab ts=2 sts=2 sw=2:

# A collection of bash scripts for installing some libraries/packages in
# user namespaces (e.g. ~/.local/), without having root privileges.

set -e   # fail when any command fails
set -o pipefail

PREFIX="$HOME/.local"
mkdir -p $PREFIX/share/zsh/site-functions

DOTFILES_TMPDIR="/tmp/$USER/linux-locals"

COLOR_NONE="\033[0m"
COLOR_RED="\033[0;31m"
COLOR_GREEN="\033[0;32m"
COLOR_YELLOW="\033[0;33m"
COLOR_CYAN="\033[0;36m"
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

_which() {
  which "$@" >/dev/null || { echo "$@ not found"; return 1; }
  echo -e "\n${COLOR_CYAN}$(which "$@")${COLOR_NONE}"
}

# _template_github_latest <name> <namespace/repo> <file *pattern* to match>
_template_github_latest() {
  local name="$1"
  local repo="$2"
  local filename="$3"
  if [[ -z "$name" ]] || [[ -z "$repo" ]] || [[ -z "$filename" ]]; then
    echo "Wrong usage"; return 1;
  fi

  echo -e "${COLOR_YELLOW}Installing $name from $repo ... ${COLOR_NONE}"
  local releases_url="https://api.github.com/repos/${repo}/releases"
  echo -e "${COLOR_YELLOW}Reading: ${COLOR_NONE}$releases_url"
  local download_url=$(\
    curl -fsSL "$releases_url" 2>/dev/null \
    | python3 -c "\
import json, sys, fnmatch;
I = sys.stdin.read()
try:
  J = json.loads(I)
except:
  sys.stderr.write(I)
  raise
for asset in J[0]['assets']:
  if fnmatch.fnmatch(asset['name'], '$filename'):
    print(asset['browser_download_url'])
    sys.exit(0)
sys.stderr.write('ERROR: Cannot find a download matching \'$filename\'.\n'); sys.exit(1)
")
  echo -e "${COLOR_YELLOW}download_url = ${COLOR_NONE}$download_url"
  test -n "$download_url"
  sleep 0.5

  local tmpdir="$DOTFILES_TMPDIR/$name"
  local filename="$(basename $download_url)"
  test -n "$filename"
  mkdir -p $tmpdir
  curl -fSL --progress-bar "$download_url" -o "$tmpdir/$filename"

  cd "$tmpdir"
  if [[ "$filename" == *.tar.gz ]]; then
    echo -e "${COLOR_YELLOW}Extracting to: $tmpdir${COLOR_NONE}"
    tar -xvzf "$filename" $TAR_OPTIONS
    local extracted_folder="${filename%.tar.gz}"
    if [ -d "$extracted_folder" ]; then
      cd "$extracted_folder"
    fi
  fi
  echo -e "\n${COLOR_YELLOW}PWD = $(pwd)${COLOR_NONE}"

  echo -e "${COLOR_YELLOW}Copying into $PREFIX ...${COLOR_NONE}"
}

#---------------------------------------------------------------------------------------------------

install_cmake() {
  local TMP_DIR="$DOTFILES_TMPDIR/cmake";
  mkdir -p "$TMP_DIR" && cd "$TMP_DIR"

  local CMAKE_VERSION="3.27.9"
  test -d "cmake-${CMAKE_VERSION}" && {\
    echo -e "${COLOR_RED}Error: $(pwd)/cmake-${CMAKE_VERSION} already exists.${COLOR_NONE}"; return 1; }

  wget -N  "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz"
  tar -xvzf "cmake-${CMAKE_VERSION}.tar.gz"
  cd "cmake-${CMAKE_VERSION}"

  ./configure --prefix="$PREFIX" --parallel=16
  make -j16 && make install

  "$PREFIX/bin/cmake" --version
}

install_git() {
  # installs a modern version of git locally.

  local GIT_LATEST_VERSION=$(\
    curl -fL https://api.github.com/repos/git/git/tags 2>/dev/null | \
    python3 -c 'import json, sys; print(json.load(sys.stdin)[0]["name"])'\
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

install_git_cliff() {
  # https://github.com/orhun/git-cliff/releases
  TAR_OPTIONS="--strip-components 1"
  _template_github_latest "git-cliff" "orhun/git-cliff" 'git-cliff-*-x86_64-*-linux-gnu.tar.gz'
  cp -v git-cliff "$PREFIX/bin/"
  cp -v man/git-cliff.1 "$PREFIX/share/man/man1/"
}

install_gh() {
  # github CLI: https://github.com/cli/cli/releases
  _template_github_latest "gh" "cli/cli" "gh_*_linux_amd64.tar.gz"

  cp -v ./bin/gh $HOME/.local/bin/gh
  _which gh
  $HOME/.local/bin/gh --version
}

install_ncurses() {
  # installs ncurses (shared libraries and headers) into local namespaces.

  local TMP_NCURSES_DIR="$DOTFILES_TMPDIR/ncurses/"; mkdir -p $TMP_NCURSES_DIR
  local NCURSES_DOWNLOAD_URL="https://invisible-mirror.net/archives/ncurses/ncurses-5.9.tar.gz";

  wget -nc -O $TMP_NCURSES_DIR/ncurses-5.9.tar.gz $NCURSES_DOWNLOAD_URL
  tar -xvzf $TMP_NCURSES_DIR/ncurses-5.9.tar.gz -C $TMP_NCURSES_DIR --strip-components 1
  cd $TMP_NCURSES_DIR

  # compile as shared library, at ~/.local/lib/libncurses.so (as well as static lib)
  export CPPFLAGS="-P"
  ./configure --prefix="$PREFIX" --with-shared

  make clean && make -j4 && make install
}

install_zsh() {
  local ZSH_VER="5.8"
  local TMP_ZSH_DIR="$DOTFILES_TMPDIR/zsh/"; mkdir -p "$TMP_ZSH_DIR"
  local ZSH_SRC_URL = "https://sourceforge.net/projects/zsh/files/zsh/${ZSH_VER}/zsh-${ZSH_VER}.tar.xz/download"

  wget -nc -O $TMP_ZSH_DIR/zsh.tar.xz "$ZSH_SRC_URL"
  tar xvJf "$TMP_ZSH_DIR/zsh.tar.xz" -C "$TMP_ZSH_DIR" --strip-components 1
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
  set +x

  _which node
  node --version

  # install some useful nodejs based utility (~/.local/lib/node_modules)
  $HOME/.local/bin/npm install -g yarn
  _which yarn && yarn --version
  $HOME/.local/bin/npm install -g http-server diff-so-fancy || true;
}

install_tmux() {
  # tmux: use tmux-appimage to avoid all the libevents/ncurses hassles
  # see https://github.com/nelsonenzo/tmux-appimage
  _template_github_latest "tmux" "nelsonenzo/tmux-appimage" "tmux.appimage"

  cp -v "./tmux.appimage" "$HOME/.local/bin/tmux"
  chmod +x $HOME/.local/bin/tmux

  ~/.local/bin/tmux -V
}

install_bazel() {

  # install the 'latest' stable release (no pre-releases.)
  local BAZEL_LATEST_VERSION=$(\
    curl -fL https://api.github.com/repos/bazelbuild/bazel/releases/latest 2>/dev/null | \
    python3 -c 'import json, sys; print(json.load(sys.stdin)["name"])'\
  )
  test -n $BAZEL_LATEST_VERSION
  local BAZEL_VER="${BAZEL_LATEST_VERSION}"
  echo -e "${COLOR_YELLOW}Installing Bazel ${BAZEL_VER} ...${COLOR_NONE}"

  local BAZEL_URL="https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VER}/bazel-${BAZEL_VER}-installer-linux-x86_64.sh"

  local TMP_BAZEL_DIR="$DOTFILES_TMPDIR/bazel/"
  mkdir -p $TMP_BAZEL_DIR
  wget -O $TMP_BAZEL_DIR/bazel-installer.sh $BAZEL_URL

  # zsh completion
  wget -O $PREFIX/share/zsh/site-functions/_bazel https://raw.githubusercontent.com/bazelbuild/bazel/master/scripts/zsh_completion/_bazel

  # install bazel
  bash $TMP_BAZEL_DIR/bazel-installer.sh \
      --bin=$PREFIX/bin \
      --base=$HOME/.bazel

  # print bazel version
  _which bazel
  bazel 2>/dev/null | grep release | xargs
  echo ""
}

install_mambaforge() {
  # Mambaforge.
  # https://conda-forge.org/miniforge/
  _template_github_latest "mambaforge" "conda-forge/miniforge" "Mambaforge-Linux-x86_64.sh"

  local MAMBAFORGE_PREFIX="$HOME/.mambaforge"
  bash "Mambaforge-Linux-x86_64.sh" -b -p "${MAMBAFORGE_PREFIX}"
  _which $MAMBAFORGE_PREFIX/bin/python3
  $MAMBAFORGE_PREFIX/bin/python3 --version
}

install_miniforge() {
  # Miniforge3.
  # https://github.com/conda-forge/miniforge
  _template_github_latest "mambaforge" "conda-forge/miniforge" "Miniforge3-Linux-x86_64.sh"

  local MINIFORGE_PREFIX="$HOME/.miniforge3"
  bash "Miniforge3-Linux-x86_64.sh" -b -p ${MINIFORGE_PREFIX}
  _which $MINIFORGE_PREFIX/bin/python3
  $MINIFORGE_PREFIX/bin/python3 --version
}

install_miniconda() {
  # installs Miniconda3. (Deprecated: Use miniforge3)
  # https://conda.io/miniconda.html
  local MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"

  local TMP_DIR="$DOTFILES_TMPDIR/miniconda/"; mkdir -p $TMP_DIR && cd ${TMP_DIR}
  wget -nc $MINICONDA_URL

  local MINICONDA_PREFIX="$HOME/.miniconda3/"
  bash "Miniconda3-latest-Linux-x86_64.sh" -b -p ${MINICONDA_PREFIX}

  # 3.9.5 as of Nov 2021
  $MINICONDA_PREFIX/bin/python3 --version

  echo -e "${COLOR_YELLOW}Warning: miniconda is deprecated, consider using miniforge3.${COLOR_NONE}"
}

install_vim() {
  # install latest vim

  # check python3-config
  local PYTHON3_CONFIGDIR=$(python3-config --configdir)
  echo -e "${COLOR_YELLOW} python3-config --configdir =${COLOR_NONE} $PYTHON3_CONFIGDIR"
  if [[ "$PYTHON3_CONFIGDIR" =~ (conda|virtualenv|venv) ]]; then
    echo -e "${COLOR_RED}Error: python3-config reports a conda/virtual environment. Deactivate and try again."
    return 1;
  fi

  # grab the lastest vim tarball and build it
  local TMP_VIM_DIR="$DOTFILES_TMPDIR/vim/"; mkdir -p $TMP_VIM_DIR
  local VIM_LATEST_VERSION=$(\
    curl -fL https://api.github.com/repos/vim/vim/tags 2>/dev/null | \
    python3 -c 'import json, sys; print(json.load(sys.stdin)[0]["name"])'\
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
    curl -fL https://api.github.com/repos/neovim/neovim/releases/latest 2>/dev/null | \
    python3 -c 'import json, sys; print(json.load(sys.stdin)["tag_name"])'\
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

install_just() {
  # https://github.com/casey/just/releases
  _template_github_latest "just" "casey/just" 'just-*-x86_64-*-linux-musl.tar.gz'

  cp -v just "$PREFIX/bin/just"
  cp -v just.1 "$PREFIX/share/man/man1/"
  _which just
  just --version
}

install_delta() {
  # https://github.com/dandavison/delta/releases
  _template_github_latest "delta" "dandavison/delta" 'delta-*-x86_64-*-linux-musl.tar.gz'

  cp -v "./delta" "$PREFIX/bin/delta"
  chmod +x "$PREFIX/bin/delta"
  _which delta
  delta --version
}

install_eza() {
  # https://github.com/eza-community/eza/releases
  _template_github_latest "eza" "eza-community/eza" 'eza_x86_64-*linux-gnu*'

  cp -v "./eza" "$PREFIX/bin/eza"
  curl -fL "https://raw.githubusercontent.com/eza-community/eza/main/completions/zsh/_eza" > \
    "$PREFIX/share/zsh/site-functions/_eza"
  _which eza
  eza --version
}

install_fd() {
  # https://github.com/sharkdp/fd/releases
  _template_github_latest "fd" "sharkdp/fd" "fd-*-x86_64-unknown-linux-musl.tar.gz"
  cp -v "./fd" $PREFIX/bin
  cp -v "./autocomplete/_fd" $PREFIX/share/zsh/site-functions

  _which fd
  $PREFIX/bin/fd --version
}

install_ripgrep() {
  # https://github.com/BurntSushi/ripgrep/releases
  _template_github_latest "ripgrep" "BurntSushi/ripgrep" "ripgrep-*-x86_64-unknown-linux-musl.tar.gz"
  cp -v "./rg" $PREFIX/bin/
  cp -v "./complete/_rg" $PREFIX/share/zsh/site-functions

  _which rg
  $PREFIX/bin/rg --version
}

install_xsv() {
  # https://github.com/BurntSushi/xsv/releases
  _template_github_latest "xsv" "BurntSushi/xsv" "xsv-*-x86_64-unknown-linux-musl.tar.gz"
  cp -v "./xsv" $PREFIX/bin/

  _which xsv
  $PREFIX/bin/xsv --version
}

install_bat() {
  # https://github.com/sharkdp/bat/releases
  _template_github_latest "bat" "sharkdp/bat" "bat-*-x86_64-unknown-linux-musl.tar.gz"
  cp -v "./bat" $PREFIX/bin/
  cp -v "./autocomplete/bat.zsh" $PREFIX/share/zsh/site-functions/_bat

  _which bat
  $PREFIX/bin/bat --version
}

install_go() {
  # install go lang into ~/.go
  # https://golang.org/dl/
  set -x
  if [ -d "$HOME/.go" ]; then
    echo -e "${COLOR_RED}Error: $HOME/.go already exists.${COLOR_NONE}"
    exit 1;
  fi
  mkdir -p "$HOME/.go"

  local GO_VERSION="1.21.4"
  local GO_DOWNLOAD_URL="https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz"
  TMP_GO_DIR="$DOTFILES_TMPDIR/go/"

  wget -nc ${GO_DOWNLOAD_URL} -P ${TMP_GO_DIR} || exit 1;
  cd ${TMP_GO_DIR} && tar -xvzf "go${GO_VERSION}.linux-amd64.tar.gz" || exit 1;
  mv go/* "$HOME/.go/"

  echo ""
  echo -e "${COLOR_GREEN}Installed at $HOME/.go${COLOR_NONE}"
  "$HOME/.go/bin/go" version
}

install_jq() {
  # https://github.com/jqlang/jq/releases
  _template_github_latest "jq" "jqlang/jq" "jq-linux-amd64"

  cp -v "./jq-linux-amd64" "$PREFIX/bin/jq"
  chmod +x "$PREFIX/bin/jq"
  _which jq
  $PREFIX/bin/jq --version
}

install_duf() {
  # https://github.com/muesli/duf/releases
  _template_github_latest "duf" "muesli/duf" "duf_*_linux_x86_64.tar.gz"
  cp -v "./duf" $PREFIX/bin

  _which duf
  $PREFIX/bin/duf --version
}

install_lazydocker() {
  _template_github_latest "lazydocker" "jesseduffield/lazydocker" "lazydocker_*_Linux_x86_64.tar.gz"
  cp -v "./lazydocker" $PREFIX/bin

  _which lazydocker
  $PREFIX/bin/lazydocker --version
}

install_lazygit() {
  _template_github_latest "lazygit" "jesseduffield/lazygit" "lazygit_*_Linux_x86_64.tar.gz"
  cp -v "./lazygit" $PREFIX/bin

  _which lazygit
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

install_ollama() {
  # https://github.com/jmorganca/ollama/releases
  curl -fSL --show-error --progress-bar -o "$HOME/.local/bin/ollama" "https://ollama.ai/download/ollama-linux-amd64"
  chmod +x "$HOME/.local/bin/ollama"
  _which ollama
  ollama --version
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
