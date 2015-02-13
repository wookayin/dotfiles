#!/usr/bin/python


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

    # GIT
    '~/.gitconfig' : 'git/gitconfig',
    '~/.gitignore' : 'git/gitignore',

    # ZSH
    '~/.zprezto'  : 'zsh/zprezto',
    '~/.zsh'      : 'zsh',
    '~/.zlogin'   : 'zsh/zlogin',
    '~/.zlogout'  : 'zsh/zlogout',
    '~/.zpreztorc': 'zsh/zpreztorc',
    '~/.zprofile' : 'zsh/zprofile',
    '~/.zshenv'   : 'zsh/zshenv',
    '~/.zshrc'    : 'zsh/zshrc',

    # Bins
    '~/.local/bin/fasd' : 'zsh/fasd/fasd',

    # X
    '~/.Xmodmap' : 'Xmodmap',

    # GTK
    '~/.gtkrc-2.0' : 'gtkrc-2.0',

    # tmux
    '~/.tmux.conf' : 'tmux.conf',

    # .config
    '~/.config/terminator' : 'config/terminator',
}

actions = [
    # Run vim-plug installation
    'vim +PlugInstall +qall now'
]

################# END OF FIXME #################


import glob, os
from optparse import OptionParser
from sys import stderr

# command line arguments
def option():
    parser = OptionParser()
    parser.add_option("-f", "--force", action="store_true", default=False)
    (options, args) = parser.parse_args()
    return options

# get current directory (absolute path) and options
current_dir = os.path.abspath(os.path.dirname(__file__))
options = option()

for target, source in tasks.items():
    # normalize paths
    source = os.path.join(current_dir, source)
    target = os.path.expanduser(target)

    # if source does not exists...
    if not os.path.lexists(source):
        print >> stderr, ("source %s : does not exists" % source)
        continue

    # if --force option is given, delete the previously existing symlink
    if os.path.lexists(target) and os.path.islink(target) and options.force == True:
        os.unlink(target)

    # make a symbolic link!
    if os.path.lexists(target):
        print >> stderr, ("%s : already exists" % target) + (options.force and ' (not a symlink, hence --force option ignored)' or '')
    else:
        try:
            mkdir_target = os.path.split(target)[0]
            os.makedirs(mkdir_target)
            print >> stderr, 'Created directory : {}'.format(mkdir_target)
        except:
            pass
        os.symlink(source, target)
        print >> stderr, ("%s : symlink created from '%s'" % (target, source))

for action in actions:
    print 'Executing : ' + action
    os.system(action)
