# Custom alias and functions for ZSH

# -------- Utilities ----------
_version_check() {
    # _version_check curver targetver: returns true (zero exit code) if $curver >= $targetver
    curver="$1"; targetver="$2";
    [ "$targetver" = "$(echo -e "$curver\n$targetver" | sort -V | head -n1)" ]
}
# -----------------------------

# Basic
alias reload!="command -v antidote 2>&1 > /dev/null && antidote reset; exec zsh --login"
alias c='command'
alias ZQ='exit'
alias QQ='exit'

alias cp='nocorrect cp -ivp'
alias mv='nocorrect mv -iv'
alias rm='nocorrect rm -iv'

# sudo, but inherits $PATH from the current shell
alias sudoenv='sudo env PATH=$PATH'

alias path='printf "%s\n" $path'
function fpath() {
  if [ $# == 0 ]; then
    printf "%s\n" $fpath
  else  # fpath _something: find _something within all $fpath's
    local f; for f in `fpath`; do find -L $f -maxdepth 1 -type f -name "$@" | xargs exa; done
  fi
}

if (( $+commands[htop] )); then
    alias top='htop'
    alias topc='htop -s PERCENT_CPU'
    alias topm='htop -s PERCENT_MEM'
fi

# list
if command -v exa 2>&1 >/dev/null; then
    # exa is our friend :)
    alias ls='exa'
    alias l='exa --long --group --git'
else
    # fallback to normal ls
    alias l='ls'
fi

# Screen
alias scr='screen -rD'

# vim: Defaults to Neovim if exists
if command -v nvim 2>&1 >/dev/null; then
    alias vim='nvim'
fi
alias vi='vim'
alias v='vim'

# Just open ~/.vimrc, ~/.zshrc, etc.
alias vimrc='vim +"cd ~/.dotfiles" +Vimrc +tabclose\ 1'
alias plugs='vim +"cd ~/.dotfiles" ~/.dotfiles/vim/plugins.vim'

alias zshrc='vim +cd\ ~/.zsh -O ~/.zsh/zshrc ~/.zsh/zsh.d/alias.zsh'

function plugged() {
    [ -z "$1" ] && { echo "plugged: args required"; return 1; }
    cd "$HOME/.vim/plugged/$1"
}

# Running lua tests for neovim in the command line
function plenary-busted() {
    if [ $# == 0 ]; then
        plenary-busted . || return 1;
    else
        for f in "$@"; do
            nvim --headless --clean -u ~/.dotfiles/nvim/init.testing.lua -c "PlenaryBustedDirectory $f" || return 1;
        done
    fi
}

# Tmux ========================================= {{{

function tmux-wrapper() {
    if [ $# -lt 1 ]; then
        command tmux -V || return 2;
        echo 'tmux: Using tmux with no arguments is discouraged, try some aliases:\n' >&2
        echo '  tmuxnew SESSION_NAME : Create a new session with the name' >&2
        echo '  tmuxa   SESSION_NAME : Attach to an existing session' >&2
        echo '  tmuxl                : List all the existing sessions' >&2
        echo '' >&2

        tmux --help || true;
        return 1;
    fi
    command tmux "$@"
}
compdef '_tmux' tmux-wrapper
alias tmux='tmux-wrapper'

# create a new session with name
alias tmuxnew='tmux new -s'
alias tnew='tmuxnew'
# list sessions
alias tmuxl='tmux list-sessions'
# tmuxa <session> : attach to <session> (force 256color and detach others)
alias tmuxa='tmux -2 attach-session -d -t'
# tmux kill-session -t
alias tmuxkill='tmux kill-session -t'

# t <session>: attach to <session> (if exists) or create a new session with the name
alias t='tmux new-session -AD -s'
alias T='TMUX= tmuxa'

# tmuxp
function tmuxp {
    tmuxpfile="$1"
    if [ -z "$tmuxpfile" ] && [[ -s ".tmuxp.yaml" ]]; then
        tmuxpfile=".tmuxp.yaml"
    fi

    if [[ -s "$tmuxpfile" ]]; then
        # (load) e.g. $ tmuxp [.tmuxp.yaml]
        command tmuxp load $tmuxpfile
    else
        # (normal commands)
        command tmuxp $@;
    fi
}

alias set-pane-title='set-window-title'
alias tmux-pane-title='set-window-title'
alias tmux-window-title='tmux rename-window'

# }}}
# SSH ========================================= {{{

if [[ "$(uname)" == "Darwin" ]] && (( $+commands[iterm-tab-color] )); then
  ssh() {
    command ssh $@
    iterm-tab-color reset 2>/dev/null
  }
fi

function ssh-tmuxa {
    local host="$1"
    if [[ -z "$2" ]]; then
       ssh $host -t tmux attach -d
    else;
       ssh $host -t tmux attach -d -t "$2"
    fi
}
alias sshta='ssh-tmuxa'
alias ssh-ta='ssh-tmuxa'
compdef '_hosts' ssh-tmuxa
# }}}

# More Git aliases ============================= {{{
# (overrides prezto's default git/alias.zsh)

GIT_VERSION=$(git --version | awk '{print $3}')

alias github='\gh'

function ghn() {
    # git history, but truncate w.r.t the terminal size. Assumes not headless.
    # A few lines to subtract from the height: previous prompt (2) + blank (1) + current prompt (2)
    local num_lines=$(($(stty size | cut -d" " -f1) - 5))
    if [[ $num_lines -gt 25 ]]; then num_lines=$((num_lines - 5)); fi  # more margin
    git history --color=always -n$num_lines "$@" | head -n$num_lines | less --QUIT-AT-EOF -F
}
alias gh='ghn'
alias ghA='gh --all'
if _version_check $GIT_VERSION "2.0"; then
  alias gha='gh --exclude=refs/stash --all'
else
  alias gha='gh --all'   # git < 1.9 has no --exclude option
fi

if (( $+commands[delta] )); then
    alias gd='git -c core.pager="delta" diff --no-prefix'
else
    alias gd='git diff --no-prefix'
fi
alias gdc='gd --cached --no-prefix'
alias gds='gd --staged --no-prefix'
alias gs='git status'
alias gsu='gs -u'
alias gu='git pull --autostash'

function ghad() {
  # Run gha (git history) and refresh if anything in .git/ changes
  local GIT_DIR=$(git rev-parse --git-dir)
  local _command="clear; (date; echo ''; git history --all --color) \
    | head -n \$((\$(tput lines) - 2)) | less -FE"

  if [ `uname` == "Linux" ]; then
    which inotifywait > /dev/null || { echo "Please install inotify-tools."; return 1; }
    trap "break" SIGINT
    bash -c "$_command"
    while true; do
      inotifywait -q -q -r -e modify -e delete -e delete_self -e create -e close_write -e move \
        --exclude 'lock' "${GIT_DIR}/refs" "${GIT_DIR}/HEAD" || true;
      bash -c "$_command"
    done;

  else
    which fswatch > /dev/null || { echo "Please install fswatch."; return 1; }
    bash -c "$_command"
    fswatch -o "$GIT_DIR" \
        --exclude='.*' --include='HEAD$' --include='refs/' \
    | xargs -n1 -I{} bash -c "$_command" \
    || true   # exit code should be 0
  fi

  return 0
}

if alias gsd > /dev/null; then unalias gsd; fi
function gsd() {
  # Run gs (git status) and refresh if .git/index changes
  local GIT_DIR=$(git rev-parse --git-dir)
  local _command="clear; (date; echo ''; git status --branch $@)"

  if [ `uname` == "Linux" ]; then
    which inotifywait > /dev/null || { echo "Please install inotify-tools."; return 1; }
    trap "break" SIGINT
    bash -c "$_command"
    while true; do
      inotifywait -q -q -r -e modify -e delete -e delete_self -e create -e close_write -e move \
        "${GIT_DIR}/index" "${GIT_DIR}/refs" || true;
      bash -c "$_command"
    done;

  else
    which fswatch > /dev/null || { echo "Please install fswatch."; return 1; }
    bash -c "$_command"
    fswatch -o $(git rev-parse --git-dir)/index \
            --event=AttributeModified --event=Updated --event=IsFile \
        | xargs -n1 -I{} bash -c "$_command" \
    || true
  fi

  return 0
}

alias gfx='git fixup'

# using the vim plugin GV/Flog
function _vim_gv {
    vim -c ":GV $1" -c "tabclose $"
}
alias gv='_vim_gv'
alias gva='gv --all'

# cd to $(git-root)
function cd-git-root() {
  local _root; _root=$(git-root)
  [ $? -eq 0 ] && cd "$_root" || return 1;
}

# Unalias some prezto aliases due to conflict
if alias gpt > /dev/null; then unalias gpt; fi

# }}}


# Python ======================================= {{{

# anaconda
alias sa='conda activate'   # source activate is deprecated.
alias ca='conda activate'
function deactivate() {
  # In anaconda/miniconda, use `conda deactivate`. In virtualenvs, `source deactivate`.
  # Note: deactivate could have been an alias, but legacy virtualenvs' shell scripts
  # are written wrong (i.e. missing `function`) as they have a conflict with the alias.
  [[ -n "$CONDA_DEFAULT_ENV" ]] && conda deactivate || source deactivate
}

function conda-activate.d() {
    # Ensure the current conda environment's activate.d directory.
    if [[ -z "$CONDA_PREFIX" ]]; then
        >&2 echo "conda environment not found."
        return 1;
    fi
    mkdir -p $CONDA_PREFIX/etc/conda/activate.d
    echo $CONDA_PREFIX/etc/conda/activate.d/$1
}

# virtualenv
alias wo='workon'

# Make sure the correct python from $PATH is used for the binary, even if
# some the package is not installed in the current python environment.
# (Do not execute a wrong bin from different python such as the global one)
alias pip='python -m pip'
alias pip3='python3 -m pip'
alias mypy='python -m mypy'
alias pycodestyle='python -m pycodestyle'
alias pylint='python -m pylint'

# pip
function pip-search() {
  (( $+commands[pip_search] )) || python -m pip install pip_search
  pip_search "$@"
}

# PREFIX/bin/python -> PREFIX/bin/ipython, etc.
alias ipdb='python -m ipdb'
alias pudb='python -m pudb'
alias pudb3='pudb'
alias python-config='${$(which python)%/*}/python3-config'
alias python3-config='${$(which python)%/*}/python3-config'

# ipython
alias ipython='python -m IPython --no-confirm-exit'
alias ipy='ipython --InteractiveShellApp.exec_lines "%i"'  # see ~/.pythonrc.py
alias ipypdb='ipy --InteractiveShellApp.exec_lines "%pdb"'   # with auto pdb calling turned ON

alias ipynb='jupyter notebook'
alias ipynb0='ipynb --ip=0.0.0.0'
alias jupyter='${$(which python)%/*}/jupyter'
alias jupyter-lab='${$(which python)%/*}/jupyter-lab --no-browser'

# ptpython
alias ptpython='python -m ptpython'
alias ptipython='python -m ptpython.entry_points.run_ptipython'
alias ptpy='ptipython'
alias pt='ptpy'

# pip install nose, rednose
alias nt='NOSE_REDNOSE=1 nosetests -v'

# unit test: in verbose mode
alias pytest='python -m pytest -vv'
alias pytest-pudb='pytest -s --pudb'
alias pytest-html='pytest --self-contained-html --html'
alias green='green -vv'

# some useful fzf-grepping functions for python
function pip-list-fzf() {
  pip list "$@" | fzf --header-lines 2 --reverse --nth 1 --multi | awk '{print $1}'
}
function pip-search-fzf() {
  # 'pip search' is gone; try: pip install pip_search
  if ! (( $+commands[pip_search] )); then echo "pip_search not found (Try: pip install pip_search)."; return 1; fi
  if [[ -z "$1" ]]; then echo "argument required"; return 1; fi
  pip-search "$@" | fzf --reverse --multi --no-sort --header-lines=4 | awk '{print $3}'
}
function conda-list-fzf() {
  conda list "$@" | fzf --header-lines 3 --reverse --nth 1 --multi | awk '{print $1}'
}
function pipdeptree-fzf() {
  python -m pipdeptree "$@" | fzf --reverse
}
function pipdeptree-vim() {   # e.g. pipdeptree -p <package>
  python -m pipdeptree "$@" | vim - +"set ft=config foldmethod=indent" +"norm zR"
}

# }}}


# Some useful aliases for CLI scripting (pipe, etc)
alias awk1="awk '{print \$1}'"
alias awk2="awk '{print \$2}'"
alias awk3="awk '{print \$3}'"
alias awk4="awk '{print \$4}'"
alias awk5="awk '{print \$5}'"
alias awk6="awk '{print \$6}'"
alias awk7="awk '{print \$7}'"
alias awk8="awk '{print \$8}'"
alias awk9="awk '{print \$9}'"
alias awklast="awk '{print \$\(NF\)}'"


# Codes ===================================== {{{

alias prettyxml='xmllint --format - | pygmentize -l xml'

if (( $+commands[cdiff] )); then
    # cdiff, side-by-side with full width
    alias sdiff="cdiff -s -w0"
fi

# }}}

# Google Cloud ============================== {{{

function gcp-instances() {
  noglob gcloud compute instances list --filter 'name:'${1:-*} | less -F
}
function gcp-instances-fzf() {
  noglob gcloud compute instances list --filter 'name:'${1:-*} \
    | fzf --header-lines 1 --multi --reverse \
    | awk '{print $1}'
}

# }}}


# FZF magics ======================================= {{{

rgfzf () {
    # ripgrep
    if [ ! "$#" -gt 0 ]; then
        echo "Usage: rgfzf <query>"
        return 1
    fi
    rg --files-with-matches --no-messages "$1" | \
        fzf --prompt "$1 > " \
        --reverse --multi --preview "rg --ignore-case --pretty --context 10 '$1' {}"
}

# }}}

# Etc ======================================= {{{

alias iterm-tab-color="noglob iterm-tab-color"

if (( $+commands[http-server] )); then
    # Disable cache for the http server.
    alias http-server="http-server -c-1"
fi

if (( $+commands[duf] )); then
    # dotfiles install duf
    alias df="duf"
elif (( $+commands[pydf] )); then
    # pip install --user pydf
    # pydf: a colorized df
    alias df="pydf"
fi

function site-packages() {
    # print the path to the site packages from current python environment,
    # e.g. ~/.anaconda3/envs/XXX/lib/python3.6/site-packages/

    local base=$(python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())")
    if [[ -n "$1" ]] && [[ ! -d "$base/$1" ]]; then
        echo "Does not exist: $base/$1" >&2;
        return 1
    else
        echo "$base/$1"
    fi;
}

# open some macOS applications
if [[ "$(uname)" == "Darwin" ]]; then

    # Force run under Rosetta 2 (for M1 mac)
    alias rosetta2='arch -x86_64'

    # brew for intel
    alias ibrew='arch -x86_64 /usr/local/bin/brew'

    # typora
    function typora   { open -a Typora "$@" }

    # skim
    function skim     { open -a Skim "$@" }
    compdef '_files -g "*.pdf"' skim

    # vimr
    function vimr     { open -a VimR "$@" }

    # terminal-notifier
    function notify   { terminal-notifier -message "$*" }

    # some commands that needs to work correctly in tmux
    if [ -n "$TMUX" ] && (( $+commands[reattach-to-user-namespace] )); then
        alias pngpaste='reattach-to-user-namespace pngpaste'
        alias pbcopy='reattach-to-user-namespace pbcopy'
        alias pbpaste='reattach-to-user-namespace pbpaste'
    fi

    # Misc.
    alias texshop-preview="texshop"

fi


# default watch options
alias watch='watch --color -n1'

# nvidia-smi/gpustat every 1 sec
#alias smi='watch -n1 nvidia-smi'
alias watchgpu='watch --color -n0.2 "gpustat --color || gpustat"'
alias smi='watchgpu'

function watchgpucpu {
    watch --color -n0.2 "gpustat --color; echo -n 'CPU '; cpu-usage | ascii-bar;"
}

function usegpu {
    local gpu_id="$1"
    if [[ "$1" == "none" ]]; then
        gpu_id=""
    elif [[ "$1" == "auto" ]] && (( $+commands[gpustat] )); then
        gpu_id=$(/usr/bin/python -c 'import gpustat, sys; \
            g = max(gpustat.new_query(), key=lambda g: g.memory_available); \
            g.print_to(sys.stderr); print(g.index)')
    fi
    export CUDA_DEVICE_ORDER=PCI_BUS_ID
    export CUDA_VISIBLE_DEVICES=$gpu_id
}

if (( ! $+commands[tb] )); then
    alias tb='python -m tbtools.tb'
fi

# }}}
