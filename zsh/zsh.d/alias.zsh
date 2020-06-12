# Custom alias and functions for ZSH

# Basic
alias reload!=". ~/.zshrc && echo 'sourced ~/.zshrc' again"
alias c='command'

alias cp='nocorrect cp -iv'
alias mv='nocorrect mv -iv'
alias rm='nocorrect rm -iv'

# sudo, but inherits $PATH from the current shell
alias sudoenv='sudo env PATH=$PATH'

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
#alias vimrc='vim +cd\ ~/.vim -O ~/.vim/vimrc ~/.vim/plugins.vim'

alias zshrc='vim +cd\ ~/.zsh -O ~/.zsh/zshrc ~/.zsh/zsh.d/alias.zsh'

# Tmux ========================================= {{{

# create a new session with name
alias tmuxnew='tmux new -s'
# list sessions
alias tmuxl='tmux list-sessions'
# tmuxa <session> : attach to <session> (force 256color and detach others)
alias tmuxa='tmux -2 attach-session -d -t'
# tmux kill-session -t
alias tmuxkill='tmux kill-session -t'

# I am lazy, yeah
alias t='tmuxa'
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

alias gh='git history'
alias gha='gh --exclude=refs/stash --all'
alias ghA='gh --all'
alias gd='git diff --no-prefix'
alias gdc='gd --cached --no-prefix'
alias gds='gd --staged --no-prefix'
alias gs='git status'
alias gsu='gs -u'

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

# using the vim plugin 'GV'!
function _vim_gv {
    vim -c ":GV $1"
}
alias gv='_vim_gv'
alias gva='gv --all'

# cd to $(git-root)
function cd-git-root() {
  local _root; _root=$(git-root)
  [ $? -eq 0 ] && cd "$_root" || return 1;
}

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

# PREFIX/bin/python -> PREFIX/bin/ipython, etc.
alias ipdb='${$(which python)%/*}/ipdb'
alias pudb='${$(which python)%/*}/pudb3'
alias pudb3='${$(which python)%/*}/pudb3'
alias python-config='${$(which python)%/*}/python3-config'
alias python3-config='${$(which python)%/*}/python3-config'

# ipython
alias ipython='${$(which python)%/*}/ipython'
alias ipy='ipython'
alias ipypdb='ipy -c "%pdb" -i'   # with auto pdb calling turned ON

alias ipynb='jupyter notebook'
alias ipynb0='ipynb --ip=0.0.0.0'
alias jupyter='${$(which python)%/*}/jupyter'
alias jupyter-lab='${$(which python)%/*}/jupyter-lab --no-browser'

# ptpython
alias ptpython='${$(which python)%/*}/ptpython'
alias ptipython='${$(which python)%/*}/ptipython'
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
  if [[ -z "$1" ]]; then echo "argument required"; return 1; fi
  pip search "$@" | grep '^[a-z]' | fzf --reverse --nth 1 --multi --no-sort | awk '{print $1}'
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


# Etc ======================================= {{{

alias iterm-tab-color="noglob iterm-tab-color"

if (( $+commands[pydf] )); then
    # pip install --user pydf
    # pydf: a colorized df
    alias df="pydf"
fi

function site-packages() {
    # print the path to the site packages from current python environment,
    # e.g. ~/.anaconda3/envs/XXX/lib/python3.6/site-packages/

    python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())"
    # python -c "import site; print('\n'.join(site.getsitepackages()))"
}

function vimpy() {
    # Open a corresponding file of specified python module.
    # e.g. $ vimpy numpy.core    --> opens $(site-package)/numpy/core/__init__.py
    if [[ -z "$1" ]]; then; echo "Argument required"; return 1; fi

    local _module_path=$(python -c "import $1; print($1.__file__)")
    if [[ -n "$module_path" ]]; then
      echo $module_path
      vim "$module_path"
    fi
}

# open some macOS applications
if [[ "$(uname)" == "Darwin" ]]; then

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
