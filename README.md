Dotfiles
========

🏠 Personal dotfiles for \*NIX (Mac OS X and Linux) systems.

Installation
------------

### Clone and Install!

One-liner (if, you trust):

```bash
curl -fsSL https://dotfiles.wook.kr/etc/install | bash
```

An alternative:

```bash
git clone --recursive https://github.com/wookayin/dotfiles.git ~/.dotfiles
cd ~/.dotfiles && python install.py
```
<!--
Note: The option `-j8` (`--jobs 8`) works with Git >= 2.8 (parallel submodule fetching).
For older versions of Git, try without `-j` option.
-->

The installation script will create symbolic links for the specified dotfiles.
If some target file already exists (e.g. `~/.vim`), you will need to manually resolve the conflict (delete the old one or just ignore).

### `dotfiles`

Update (pull the changes from upstream and run [`install.py`][install.py] again)

```
$ dotfiles update
```


### [`install.py`][install.py]

This is a clunky installation script written in python;
the task definition lies on the top of the script file.


Some Handy URLs
---------------

Every file is accessible through `dotfiles.wook.kr` (via `curl -L` or `wget`), e.g.

* https://dotfiles.wook.kr/vimrc
* https://dotfiles.wook.kr/vimrc?raw=true
* https://dotfiles.wook.kr/bin/tb


Troubleshooting
---------------

* If something goes wrong, try `dotfiles update` to update everything and re-run [the installation script][install.py] again.
    * If you have your own `~/.zshrc`, `~/.vimrc`, `~/.vim`, etc., then they will not be overwritten by default.
      In such cases you may want to delete those files *manually*.

* If you are using **neovim** and seeing any startup errors (e.g. `no module named neovim`):
    * Make sure that the [`neovim`](https://pypi.python.org/pypi/neovim/) pypi package is installed on [**local** python 3 (see `g:python3_host_prog`)](https://github.com/wookayin/dotfiles/blob/master/nvim/init.vim).
    * e.g. `/usr/local/bin/pip3 install neovim` where the path to `pip` (or `pip3`) depends on your system.
    * If you are not sure, `python3 -m pip install --user neovim` will work in any case.

* [Powerline characters](https://github.com/powerline/powerline#screenshots) are not displayed properly? Install [Powerline fonts](https://github.com/powerline/fonts).
* Does vim color look weird (e.g. black-and-white)? Check your terminal emulator supports [24-bit color](https://github.com/wookayin/dotfiles/pull/9).
* Does tmux look weird? Make sure that tmux version is [2.3](etc/ubuntu-setup.sh) or higher.
    * If you don't have sudo, you can install it locally by `$ dotfiles install tmux`.
* Ruby version is shown unwantedly? A simple workaround might be to install [rvm](https://rvm.io/).


[install.py]: https://github.com/wookayin/dotfiles/blob/master/install.py
