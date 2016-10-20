Dotfiles
========

Personal dotfiles for \*NIX (Mac OS X and Linux) systems.

## Installation

### Clone and Install!

```bash
git clone --recursive -j8 https://github.com/wookayin/dotfiles.git ~/.dotfiles
cd ~/.dotfiles && python install.py
```

Note: The `-j8` (`--jobs 8`) option works with Git >= 2.8 (parallel submodule fetching).
For older versions of Git, try without `-j` option.

The installation script will create symbolic links for the specified dotfiles.
If some target file already exists (e.g. `~/.vim`), you will need to manually resolve the conflict (delete the old one or just ignore).


### install.py script

This is a clunky installation script written in python;
the task definition lies on the top of the script file.


## Tips for Beginners

* Powerline characters not displayed properly? Install [Powerline fonts](https://github.com/powerline/fonts).
* Ruby version is shown unwantedly? A simple workaround might be to install [rvm](https://rvm.io/).
* Does `tmux` look weird? Make sure that tmux version is 1.9a or higher.
