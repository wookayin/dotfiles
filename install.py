#!/usr/bin/env python3
# -*- coding: utf-8 -*-

'''
   @wookayin's              ███████╗██╗██╗     ███████╗███████╗
   ██████╗  █████╗ ████████╗██╔════╝██║██║     ██╔════╝██╔════╝
   ██╔══██╗██╔══██╗╚══██╔══╝█████╗  ██║██║     █████╗  ███████╗
   ██║  ██║██║  ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║
   ██████╔╝╚█████╔╝   ██║   ██║     ██║███████╗███████╗███████║
   ╚═════╝  ╚════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝

   https://dotfiles.wook.kr/
'''
print(__doc__)  # print logo.


import os
import argparse
parser = argparse.ArgumentParser()
parser.add_argument('-f', '--force', action="store_true", default=False,
                    help='If set, it will override existing symbolic links')
parser.add_argument('--skip-vimplug', action='store_true',
                    help='If set, do not update vim plugins.')
parser.add_argument('--skip-zplug', action='store_true',
                    help='If set, skip update of zsh plugins.')

args = parser.parse_args()

################# BEGIN OF FIXME #################
IS_SSH = os.getenv('SSH_TTY', None) is not None

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
    '~/.local/bin/fzf' : dict(src='~/.fzf/bin/fzf', force=True),

    # X
    '~/.Xmodmap' : 'Xmodmap',

    # GTK
    '~/.gtkrc-2.0' : 'gtkrc-2.0',

    # terminal emulators (kitty, alacritty, wezterm)
    '~/.config/kitty': dict(src='config/kitty', cond=not IS_SSH),
    '~/.config/alacritty': dict(src='config/alacritty', cond=not IS_SSH),
    '~/.config/wezterm': dict(src='config/wezterm', cond=not IS_SSH),

    # tmux
    '~/.tmux'      : 'tmux',
    '~/.tmux.conf' : 'tmux/tmux.conf',

    # .config (XDG-style)
    '~/.config/terminator' : 'config/terminator',
    '~/.config/pudb/pudb.cfg' : 'config/pudb/pudb.cfg',

    # pip and python
    #'~/.pip/pip.conf' : 'pip/pip.conf',
    '~/.pythonrc.py' : 'python/pythonrc.py',
    '~/.pylintrc' : 'python/pylintrc',
    '~/.condarc' : 'python/condarc',
    '~/.config/pycodestyle' : 'python/pycodestyle',
    '~/.ptpython/config.py' : dict(action="remove"),
    '~/.config/ptpython/config.py' : 'python/ptpython.config.py',
}


import os
import platform

# Make sure the CWD is the root of dotfiles.
__PATH__ = os.path.abspath(os.path.dirname(__file__))
os.chdir(__PATH__)


post_actions = []
post_actions += [  # Check symbolic link at $HOME
    '''#!/bin/bash
    # Check whether ~/.vim and ~/.zsh are well-configured
    for f in ~/.vim ~/.zsh ~/.vimrc ~/.zshrc; do
        if ! readlink $f >/dev/null; then
            echo -e "\033[0;31m\
WARNING: $f is not a symbolic link to ~/.dotfiles.
Please remove your local folder/file $f and try again.\033[0m"
            echo -n "(Press any key to continue) "; read user_confirm
            exit 1;
        else
            echo "$f --> $(readlink $f)"
        fi
    done
''']

post_actions += [  # fzf
    r'''#!/bin/bash
    # Install junegunn/fzf
    FZF_REPO="https://github.com/junegunn/fzf.git"
    if [[ ! -d "$HOME/.fzf" ]]; then
        git clone "$FZF_REPO" "$HOME/.fzf"
    else
        cd $HOME/.fzf && git fetch --tags
    fi
    cd $HOME/.fzf

    # Checkout the latest release (tag)
    tag=$(git ls-remote --tags --exit-code --refs "$FZF_REPO" \
          | sed -E 's/^[[:xdigit:]]+[[:space:]]+refs\/tags\/(.+)/\1/g' \
          | sort -V | tail -n1)
    git checkout "$tag"

    ./install --all --no-update-rc
''']

post_actions += [  # video2gif
    '''#!/bin/bash
    # Download command line scripts
    mkdir -p "$HOME/.local/bin/"
    _download() {
        curl -L "$2" > "$1" && chmod +x "$1"
    }
    ret=0
    set -v
    _download "$HOME/.local/bin/video2gif" "https://raw.githubusercontent.com/wookayin/video2gif/master/video2gif" || ret=1
    exit $ret;
''']

post_actions += [  # antidote (zsh plugins)
    '''#!/bin/bash
    # Update zsh bundles and cache (the init file)
    zsh -c "
        # source zsh plugin manager and list plugins
        DOTFILES_UPDATE=1 __p9k_instant_prompt_disabled=1 source ${HOME}/.zshrc
        if ! which antidote > /dev/null; then
            echo -e '\033[0;31m\
ERROR: antidote not found. Double check the submodule exists, and you have a valid ~/.zshrc!\033[0m'
            ls -alh ~/.zsh/antidote/
            ls -alh ~/.zshrc
            exit 1;
        fi
        antidote update
        antidote reset
        source ~/.zshrc
    "
    ''' if not args.skip_zplug else \
        '# zsh plugins update (Skipped)'
]

post_actions += [  # tmux plugins
    # Install tmux plugins via tpm
    '~/.tmux/plugins/tpm/bin/install_plugins',

    r'''#!/bin/bash
    # Check tmux version >= 2.3 (or use `dotfiles install tmux`)
    _version_check() {    # target_ver current_ver
        [ "$1" = "$(echo -e "$1\n$2" | sort -s -t- -k 2,2n | sort -t. -s -k 1,1n -k 2,2n | head -n1)" ]
    }
    if [[ `uname` == "Linux" ]] && ! type tmux >/dev/null 2>&1; then
        echo -e "\033[0;33mInstalling tmux because not installed globally.\033[0m"
        bin/dotfiles install tmux
        export PATH="$PATH:~/.local/bin"
    elif ! _version_check "2.3" "$(tmux -V | cut -d' ' -f2)"; then
        echo -en "\033[0;33m"
        echo -e "$(tmux -V) is too old. Contact system administrator, or:"
        echo -e "  $ dotfiles install tmux  \033[0m (installs to ~/.local/, if you don't have sudo)"
        exit 1;
    else
        echo "$(which tmux): $(tmux -V)"
    fi
''']

post_actions += [  # default shell
    r'''#!/bin/bash
    # Change default shell to zsh
    /bin/zsh --version >/dev/null || (\
        echo -e "\033[0;31mError: /bin/zsh not found. Please install zsh.\033[0m"; exit 1)
    if [[ ! "$SHELL" = *zsh ]]; then
        echo -e '\033[0;33mPlease type your password if you wish to change the default shell to ZSH\e[m'
        chsh -s /bin/zsh && echo -e 'Successfully changed the default shell, please re-login'
    else
        echo -e "\033[0;32m\$SHELL is already zsh.\033[0m $(zsh --version)"
    fi
''']

post_actions += [  # install some essential packages (linux)
    '''#!/bin/bash
    # Install node, rg, fd locally
    export PATH="$PATH:$HOME/.local/bin"
    type node >/dev/null 2>&1 || bin/dotfiles install node
    type rg   >/dev/null 2>&1 || bin/dotfiles install ripgrep
    type fd   >/dev/null 2>&1 || bin/dotfiles install fd
    '''
] if platform.system() == "Linux" else []

post_actions += [  # neovim
    '''#!/bin/bash
    bash "etc/install-neovim.sh"
''']

post_actions += [  # vim-plug
    # Run vim-plug installation
    {'install' : 'PATH="$PATH:~/.local/bin"  nvim --headless +"Lazy! install" +qall',
     'update'  : 'PATH="$PATH:~/.local/bin"  nvim --headless +"Lazy! update"  +qall',
     'none'    : '# vim plugins: skipped',
     }['update' if not args.skip_vimplug else 'none']
    + '\n' +
    r'''#!/bin/bash
    if [[ -n "~/.vim/plugged/*.cloning(#qN)" ]]; then
        echo "Cleaning up plugin installation artifacts..."
        rm -fv ~/.vim/plugged/*.cloning
    fi
    '''
]

post_actions += [  # gitconfig.secret
    r'''#!/bin/bash
    # Create ~/.gitconfig.secret file and check user configuration
    if [ ! -f ~/.gitconfig.secret ]; then
        cat > ~/.gitconfig.secret <<EOL
# vim: set ft=gitconfig:
EOL
    fi
    if ! git config --file ~/.gitconfig.secret user.name 2>&1 > /dev/null || \
       ! git config --file ~/.gitconfig.secret user.email 2>&1 > /dev/null; then echo -ne '
    \033[1;33m[!!!] Please configure git user name and email:
        git config --file ~/.gitconfig.secret user.name "(YOUR NAME)"
        git config --file ~/.gitconfig.secret user.email "(YOUR EMAIL)"
\033[0m'
        echo -en '\n'
        echo -en "(git config user.name) \033[0;33m Please input your name  : \033[0m"; read git_username
        echo -en "(git config user.email)\033[0;33m Please input your email : \033[0m"; read git_useremail
        if [[ -n "$git_username" ]] && [[ -n "$git_useremail" ]]; then
            git config --file ~/.gitconfig.secret user.name "$git_username"
            git config --file ~/.gitconfig.secret user.email "$git_useremail"
        else
            exit 1;   # error
        fi
    fi

    # get the current config
    echo -en '\033[0;32m';
    echo -en 'user.name  : '; git config --file ~/.gitconfig.secret user.name
    echo -en 'user.email : '; git config --file ~/.gitconfig.secret user.email
    echo -en '\033[0m';
''']


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

from signal import signal, SIGPIPE, SIG_DFL
from sys import stderr

if sys.version_info[0] >= 3:  # python3
    unicode = lambda s, _: str(s)
    from builtins import input
else:  # python2
    input = sys.modules['__builtin__'].raw_input


def log(msg, cr=True):
    stderr.write(msg)
    if cr:
        stderr.write('\n')

def log_boxed(msg, color_fn=WHITE, use_bold=False, len_adjust=0):
    import unicodedata
    pad_msg = (" " + msg + "  ")
    l = sum(not unicodedata.combining(ch) for ch in unicode(pad_msg, 'utf-8')) + len_adjust  # noqa
    if use_bold:
        log(color_fn("┏" + ("━" * l) + "┓\n" +
                     "┃" + pad_msg   + "┃\n" +
                     "┗" + ("━" * l) + "┛\n"), cr=False)
    else:
        log(color_fn("┌" + ("─" * l) + "┐\n" +
                     "│" + pad_msg   + "│\n" +
                     "└" + ("─" * l) + "┘\n"), cr=False)

def makedirs(target, mode=511, exist_ok=False):
    try:
        os.makedirs(target, mode=mode)
    except OSError as ex:  # py2 has no exist_ok=True
        import errno
        if ex.errno == errno.EEXIST and exist_ok: pass
        else: raise

# get current directory (absolute path)
current_dir = os.path.abspath(os.path.dirname(__file__))
os.chdir(current_dir)

# check if git submodules are loaded properly
stat = subprocess.check_output("git submodule status --recursive",
                               shell=True, universal_newlines=True)
submodule_issues = [(l.split()[1], l[0]) for l in stat.split('\n')  # noqa
                    if len(l) and l[0] != ' ']

if submodule_issues:
    stat_messages = {'+': 'needs update', '-': 'not initialized', 'U': 'conflict!'}
    for (submodule_name, submodule_stat) in submodule_issues:
        log(RED("git submodule {name} : {status}".format(
            name=submodule_name,
            status=stat_messages.get(submodule_stat, '(Unknown)'))))
    log(YELLOW("Git submodules are not initialized.\n"))

    update_submodule = True
    if update_submodule:
        git_submodule_update_cmd = 'git submodule update --init --recursive'
        # git 2.8+ supports parallel submodule fetching
        try:
            git_version = str(subprocess.check_output(
                """git --version | awk '{print $3}'""", shell=True))
            if git_version >= '2.8':
                git_submodule_update_cmd += ' --jobs 8'
        except Exception:
            pass
        log("Running: %s" % CYAN(git_submodule_update_cmd))
        subprocess.call(git_submodule_update_cmd, shell=True)
    else:
        log(RED("Aborted."))
        sys.exit(1)


log_boxed("Creating symbolic links", color_fn=CYAN)
for target, item in sorted(tasks.items()):
    # normalize paths
    if isinstance(item, str):
        item = {'src': item}

    source = item.get('src', None)
    force = item.get('force', False)
    fail_on_error = item.get('fail_on_error', False)

    if not item.get('cond', True):
        continue

    if source:
        source = os.path.join(current_dir, os.path.expanduser(source))
    target = os.path.expanduser(target)

    if item.get('action', None) == 'remove':
        try:
            os.unlink(target)
        except OSError:  # FileNotFoundError
            pass
        continue

    assert source is not None
    # bad entry if source does not exists...
    if force:
        pass  # Even if the source does not exist, always make a symlink
    elif not os.path.lexists(source):
        log(RED("source %s : does not exist" % source))
        continue

    # if --force option is given, delete and override the previous symlink
    if os.path.lexists(target):
        is_broken_link = os.path.islink(target) and not os.path.exists(os.readlink(target))
        err = ""

        if is_broken_link:  # safe to remove
            if os.path.islink(target):
                os.unlink(target)

        elif os.path.islink(target):
            if args.force:
                os.unlink(target)
            else:
                msg = GRAY("already exists, skipped")
                log("{:60s} : {}".format(BLUE(target), msg))
        elif fail_on_error:
            err = RED("already exists, please remove " + target + " manually.")
        else:
            if args.force:
                err = YELLOW("already exists but not a symbolic link; --force option ignored")
            else:
                err = YELLOW("exists, but not a symbolic link. Check by yourself!!")
        if err:
            log("{:60s} : {}".format(BLUE(target), err))
            if fail_on_error:
                sys.exit(1)

    # make a symbolic link if available
    if not os.path.lexists(target):
        mkdir_target = os.path.split(target)[0]
        if not os.path.isdir(mkdir_target):
            makedirs(mkdir_target)
            log(GREEN('Created directory : %s' % mkdir_target))
        os.symlink(source, target)
        log("{:60s} : {}".format(
            BLUE(target),
            GREEN("symlink created from '%s'" % source)
        ))

errors = []
for action in post_actions:
    if not action:
        continue

    action_title = action.strip().split('\n')[0].strip()
    if action_title == '#!/bin/bash':
        action_title = action.strip().split('\n')[1].strip()

    log("\n", cr=False)
    log_boxed("Executing: " + action_title, color_fn=CYAN)
    ret = subprocess.call(['bash', '-e', '-c', action],
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
    log_boxed("✔  You are all set! ",
              color_fn=GREEN, use_bold=True)

log("- Please restart shell (e.g. " + CYAN("`exec zsh`") + ") if necessary.")
log("- To install some packages locally (e.g. neovim, tmux), try " + CYAN("`dotfiles install <package>`"))
log("- If you want to update dotfiles (or have any errors), try " + CYAN("`dotfiles update`"))
log("\n\n", cr=False)

sys.exit(len(errors))
