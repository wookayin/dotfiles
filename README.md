Dotfiles
========

Personal dotfiles for \*NIX (Mac OS X and Linux) systems.

## Installation

### Clone and Install!

```bash
git clone --recursive https://github.com/wookayin/dotfiles.git ~/.dotfiles
cd ~/.dotfiles && python install.py
```

The installation script will create symbolic links for the specified dotfiles.
If the target file already exists (e.g. `~/.vim`), you will have to manually resolve it (delete the old one or just ignore).

### install.py script

This is a clunky installation script written in python;
the task definition lies on the top of the script file.


## Tips for Beginners

* Powerline characters not displayed properly? Install [Powerline fonts](https://github.com/powerline/fonts).
* Ruby version is shown unwantedly? A simple workaround might be to install [rvm](https://rvm.io/).
* Does `tmux` look weird? Make sure that tmux version is 1.9a or higher.
