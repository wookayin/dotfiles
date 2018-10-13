#!/usr/bin/env python
# -*- coding: utf-8 -*-

print('''
   @wookayin's              ███████╗██╗██╗     ███████╗███████╗
   ██████╗  █████╗ ████████╗██╔════╝██║██║     ██╔════╝██╔════╝
   ██╔══██╗██╔══██╗╚══██╔══╝█████╗  ██║██║     █████╗  ███████╗
   ██║  ██║██║  ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║
   ██████╔╝╚█████╔╝   ██║   ██║     ██║███████╗███████╗███████║
   ╚═════╝  ╚════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝

   https://dotfiles.wook.kr/
''')

import argparse
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('-f', '--force', action="store_true", default=False,
                    help='If specified, it will override existing symbolic links')
parser.add_argument('--skip-vimplug', action='store_true')
parser.add_argument('--skip-zgen', '--skip-zplug', action='store_true')
args = parser.parse_args()

################# BEGIN OF FIXME #################

# Task Definition
# (path of target symlink) : (location of source file in the repository)

tasks = {
    # SHELLS
    '~/.bashrc' : 'bashrc',
    '~/.screenrc' : 'screenrc',

    # VIM
    '~/.vimrc' : 'vim/vimrc',
    '~/.vim' : 'vim',
    '~/.vim/autoload/plug.vim' : 'vim/bundle/vim-plug/plug.vim',

    # NeoVIM
    '~/.config/nvim' : 'nvim',

    # GIT
    '~/.gitconfig' : 'git/gitconfig',
    '~/.gitignore' : 'git/gitignore',

    # ZSH
    '~/.zgen'     : 'zsh/zgen',
    '~/.zsh'      : 'zsh',
    '~/.zlogin'   : 'zsh/zlogin',
    '~/.zlogout'  : 'zsh/zlogout',
    '~/.zpreztorc': 'zsh/zpreztorc',
    '~/.zprofile' : 'zsh/zprofile',
    '~/.zshenv'   : 'zsh/zshenv',
    '~/.zshrc'    : 'zsh/zshrc',

    # Bins
    '~/.local/bin/dotfiles' : 'bin/dotfiles',
    '~/.local/bin/fasd' : 'zsh/fasd/fasd',
    '~/.local/bin/is_mosh' : 'zsh/is_mosh/is_mosh',
    '~/.local/bin/imgcat' : 'bin/imgcat',
    '~/.local/bin/imgls' : 'bin/imgls',
    '~/.local/bin/fzf' : '~/.fzf/bin/fzf', # fzf is at $HOME/.fzf

    # X
    '~/.Xmodmap' : 'Xmodmap',

    # GTK
    '~/.gtkrc-2.0' : 'gtkrc-2.0',

    # tmux
    '~/.tmux'     : 'tmux',
    '~/.tmux.conf' : 'tmux/tmux.conf',

    # .config (XDG-style)
    '~/.config/terminator' : 'config/terminator',
    '~/.config/pudb/pudb.cfg' : 'config/pudb/pudb.cfg',
    '~/.config/fsh/wook.ini' : 'config/fsh/wook.ini',

    # pip and python
    #'~/.pip/pip.conf' : 'pip/pip.conf',
    '~/.pythonrc.py' : 'python/pythonrc.py',
    '~/.pylintrc' : 'python/pylintrc',
    '~/.condarc' : 'python/condarc',
    '~/.config/pycodestyle' : 'python/pycodestyle',
}


from distutils.spawn import find_executable


post_actions = [
    '''#!/bin/bash
    # Check whether ~/.vim and ~/.zsh are well-configured
    for f in ~/.vim ~/.zsh ~/.vimrc ~/.zshrc; do
        if ! readlink $f >/dev/null; then
            echo -e "\033[0;31m\
WARNING: $f is not a symbolic link to ~/.dotfiles.
You may want to remove your local folder (~/.vim) and try again?\033[0m"
            exit 1;
        else
            echo "$f --> $(readlink $f)"
        fi
    done
    ''',

    '''#!/bin/bash
    # Update zgen modules and cache (the init file)
    zsh -c "
        source ${HOME}/.zshrc                   # source zplug and list plugins
        if ! which zgen > /dev/null; then
            echo -e '\033[0;31m\
ERROR: zgen not found. Double check the submodule exists, and you have a valid ~/.zshrc!\033[0m'
            ls -alh ~/.zsh/zgen/
            ls -alh ~/.zshrc
            exit 1;
        fi
        zgen reset
        zgen update
    "
    ''' if not args.skip_zgen else '',

    '''#!/bin/bash
    # validate neovim package installation on python2/3 and automatically install if missing
    RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[0;33m"; WHITE="\033[1;37m"; CYAN="\033[0;36m"; RESET="\033[0m";
    if which nvim >/dev/null; then
        echo -e "neovim found at ${GREEN}$(which nvim)${RESET}"
        host_python3=""
        [[ -z "$host_python3" ]] && [[ -f "/usr/local/bin/python3" ]] && host_python3="/usr/local/bin/python3"
        [[ -z "$host_python3" ]] && [[ -f "/usr/bin/python3" ]]       && host_python3="/usr/bin/python3"
        [[ -z "$host_python3" ]] && host_python3="$(which python3)"
        if [[ -z "$host_python3" ]]; then
            echo "${RED}  Python3 not found -- please have it installed in the system! ${RESET}";
            exit 1;
        fi
        suggest_cmds=()
        for py_bin in "$host_python3" "/usr/bin/python"; do
            echo "Checking neovim package for the host python: ${GREEN}${py_bin}${RESET}"
            neovim_ver=$($py_bin -c 'import neovim; print("{major}.{minor}.{patch}".format(**neovim.VERSION.__dict__))')
            neovim_install_cmd="$py_bin -m pip install --user --upgrade neovim"
            rc=$?; if [[ $rc != 0 ]]; then
                echo -e "${YELLOW}[!!!] Neovim requires 'neovim' package on the host python. Try:${RESET}"
                echo -e "${YELLOW}  $neovim_install_cmd${RESET}"; suggest_cmds+=("$neovim_install_cmd")
            else  # check neovim is up-to-date
                neovim_latest=$(python2 -c 'from xmlrpclib import ServerProxy; print(\
                    ServerProxy("http://pypi.python.org/pypi").package_releases("neovim")[0])')
                if [[ "$neovim_ver" != "$neovim_latest" ]]; then
                    echo -e "${YELLOW}  [!!] Neovim ($neovim_ver) is outdated (latest = $neovim_latest). Needs upgrade!${RESET}"
                    echo -e "${YELLOW}  $neovim_install_cmd${RESET}"; suggest_cmds+=("$neovim_install_cmd")
                else
                    echo -e "${GREEN}  [OK] neovim $neovim_ver${RESET}"
                fi
            fi
        done
        for cmd in "${suggest_cmds[@]}"; do
            echo "\n${CYAN}Executing:${WHITE} $cmd ${RESET}"
            $cmd;
        done
    else
        echo -e "${RED}Neovim not found. Please install using 'dotfiles install neovim'.${RESET}"
    fi
    ''',

    # Run vim-plug installation
    {'install' : '{vim} +PlugInstall +qall'.format(vim='nvim' if find_executable('nvim') else 'vim'),
     'update'  : '{vim} +PlugUpdate  +qall'.format(vim='nvim' if find_executable('nvim') else 'vim'),
     'none'    : ''}['update' if not args.skip_vimplug else 'none'],

    # Install tmux plugins via tpm
    '~/.tmux/plugins/tpm/bin/install_plugins',

    r'''#!/bin/bash
    # Check tmux version >= 2.3 (or use `dotfiles install tmux`)
    _version_check() {    # target_ver current_ver
        [ "$1" = "$(echo -e "$1\n$2" | sort -s -t- -k 2,2n | sort -t. -s -k 1,1n -k 2,2n | head -n1)" ]
    }
    if ! _version_check "2.3" "$(tmux -V | cut -d' ' -f2)"; then
        echo -en "\033[0;33m"
        echo -e "$(tmux -V) is too old. Contact system administrator, or:"
        echo -e "  $ dotfiles install tmux  \033[0m (installs to ~/.local/, if you don't have sudo)"
        exit 1;
    else
        echo "$(which tmux): $(tmux -V)"
    fi
    ''',

    r'''#!/bin/bash
    # Change default shell to zsh
    /bin/zsh --version >/dev/null || (echo -e "Error: /bin/zsh not found. Please install zsh"; exit 1)
    if [[ ! "$SHELL" = *zsh ]]; then
        echo -e '\033[0;33mPlease type your password if you wish to change the default shell to ZSH\e[m'
        chsh -s /bin/zsh && echo -e 'Successfully changed the default shell, please re-login'
    else
        echo -e "\033[0;32m\$SHELL is already zsh.\033[0m $(zsh --version)"
    fi
    ''',

    r'''#!/bin/bash
    # Create ~/.gitconfig.secret file and check user configuration
    if [ ! -f ~/.gitconfig.secret ]; then
        cat > ~/.gitconfig.secret <<EOL
# vim: set ft=gitconfig:
EOL
    fi
    if ! git config --file ~/.gitconfig.secret user.name 2>&1 > /dev/null; then echo -ne '
    \033[1;33m[!!!] Please configure git user name and email:
        git config --file ~/.gitconfig.secret user.name "(YOUR NAME)"
        git config --file ~/.gitconfig.secret user.email "(YOUR EMAIL)"
\033[0m'
        exit 1;
    else
        git config --file ~/.gitconfig.secret --get-regexp user
    fi
    ''',
]

################# END OF FIXME #################

def _wrap_colors(ansicode):
    return (lambda msg: ansicode + str(msg) + '\033[0m')
GRAY   = _wrap_colors("\033[0;37m")
WHITE  = _wrap_colors("\033[1;37m")
RED    = _wrap_colors("\033[0;31m")
GREEN  = _wrap_colors("\033[0;32m")
YELLOW = _wrap_colors("\033[0;33m")
CYAN   = _wrap_colors("\033[0;36m")
BLUE   = _wrap_colors("\033[0;34m")


import os
import sys
import subprocess

if sys.version_info[0] >= 3:  # python3
    from builtins import input
    unicode = lambda s, _: str(s)
else:
    input = raw_input         # python2

from signal import signal, SIGPIPE, SIG_DFL
from optparse import OptionParser
from sys import stderr

def log(msg, cr=True):
    stderr.write(msg)
    if cr:
        stderr.write('\n')

def log_boxed(msg, color_fn=WHITE, use_bold=False, len_adjust=0):
    import unicodedata
    pad_msg = (" " + msg + "  ")
    l = sum(not unicodedata.combining(ch) for ch in unicode(pad_msg, 'utf-8')) + len_adjust
    if use_bold:
        log(color_fn("┏" + ("━" * l) + "┓\n" +
                     "┃" + pad_msg   + "┃\n" +
                     "┗" + ("━" * l) + "┛\n"), cr=False)
    else:
        log(color_fn("┌" + ("─" * l) + "┐\n" +
                     "│" + pad_msg   + "│\n" +
                     "└" + ("─" * l) + "┘\n"), cr=False)


# get current directory (absolute path)
current_dir = os.path.abspath(os.path.dirname(__file__))
os.chdir(current_dir)

# check if git submodules are loaded properly
stat = subprocess.check_output("git submodule status --recursive",
                               shell=True, universal_newlines=True)
submodule_issues = [(l.split()[1], l[0]) for l in stat.split('\n') if len(l) and l[0] != ' ']

if submodule_issues:
    stat_messages = {'+': 'needs update', '-': 'not initialized', 'U': 'conflict!'}
    for (submodule_name, submodule_stat) in submodule_issues:
        log(RED("git submodule {name} : {status}".format(
            name=submodule_name,
            status=stat_messages.get(submodule_stat, '(Unknown)'))))
    log(RED(" you may run: $ git submodule update --init --recursive"))

    log("")
    log(YELLOW("Do you want to update submodules? (y/n) "), cr=False)
    shall_we = (input().lower() == 'y')
    if shall_we:
        git_submodule_update_cmd = 'git submodule update --init --recursive'
        # git 2.8+ supports parallel submodule fetching
        try:
            git_version = str(subprocess.check_output("""git --version | awk '{print $3}'""", shell=True))
            if git_version >= '2.8': git_submodule_update_cmd += ' --jobs 8'
        except Exception as e:
            pass
        log("Running: %s" % BLUE(git_submodule_update_cmd))
        subprocess.call(git_submodule_update_cmd, shell=True)
    else:
        log(RED("Aborted."))
        sys.exit(1)


log_boxed("Creating symbolic links", color_fn=CYAN)
for target, source in sorted(tasks.items()):
    # normalize paths
    source = os.path.join(current_dir, os.path.expanduser(source))
    target = os.path.expanduser(target)

    # bad entry if source does not exists...
    if not os.path.lexists(source):
        log(RED("source %s : does not exist" % source))
        continue

    # if --force option is given, delete and override the previous symlink
    if os.path.lexists(target):
        is_broken_link = os.path.islink(target) and not os.path.exists(os.readlink(target))

        if args.force or is_broken_link:
            if os.path.islink(target):
                os.unlink(target)
            else:
                log("{:50s} : {}".format(
                    BLUE(target),
                    YELLOW("already exists but not a symbolic link; --force option ignored")
                ))
        else:
            log("{:50s} : {}".format(
                BLUE(target),
                GRAY("already exists, skipped") if os.path.islink(target) \
                    else YELLOW("exists, but not a symbolic link. Check by yourself!!")
            ))

    # make a symbolic link if available
    if not os.path.lexists(target):
        try:
            mkdir_target = os.path.split(target)[0]
            os.makedirs(mkdir_target)
            log(GREEN('Created directory : %s' % mkdir_target))
        except:
            pass
        os.symlink(source, target)
        log("{:50s} : {}".format(
            BLUE(target),
            GREEN("symlink created from '%s'" % source)
        ))

errors = []
for action in post_actions:
    if not action:
        continue

    action_title = action.strip().split('\n')[0].strip()
    if action_title == '#!/bin/bash': action_title = action.strip().split('\n')[1].strip()

    log("\n", cr=False)
    log_boxed("Executing: " + action_title, color_fn=CYAN)
    ret = subprocess.call(['bash', '-c', action],
                          preexec_fn=lambda: signal(SIGPIPE, SIG_DFL))

    if ret:
        errors.append(action_title)

log("\n")
if errors:
    log_boxed("You have %3d warnings or errors -- check the logs!" % len(errors),
              color_fn=YELLOW, use_bold=True)
    for e in errors:
        log("   " + YELLOW(e))
    log("\n")
else:
    log_boxed("✔︎  You are all set! ", len_adjust=-1,
              color_fn=GREEN, use_bold=True)

log("- Please restart shell (e.g. " + CYAN("`exec zsh`") + ") if necessary.")
log("- To install some packages locally (e.g. neovim, tmux), try " + CYAN("`dotfiles install <package>`"))
log("- If you want to update dotfiles (or have any errors), try " + CYAN("`dotfiles update`"))
log("\n\n", cr=False)
