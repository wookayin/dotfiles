#!/bin/bash
# Installs essential packages for usual python development environments.

set -eu -o pipefail

packages_basic=(
    # shell & dev env
    ipython ptpython jedi pynvim
    # debugging
    pudb ipdb py-spy debugpy
    # testing
    pytest pytest-xdist pytest-runner pytest-pudb
    # linter
    mypy pylint ruff
    # LSP
    python-lsp-server basedpyright
    # other common modules
    tqdm rich
    imgcat matplotlib Pillow
)

# Jupyter support
# See also: https://github.com/jupyterlab-contrib
packages_jupyter=(
    'jupyterlab >= 4.0'
    'notebook >= 7.0'
    'jupyterlab-lsp >= 5.0.0'
    'jupyterlab-vim >= 4.1'
    jupyterlab-widgets ipywidgets ipympl
    pretty-jupyter
)

# pip: use uv if available. export UV=0 to disable
if [ "${UV:-}" != "0" ] && command -v "uv" 2>&1 >/dev/null; then
    PIP="uv pip"
else
    PIP="python -m pip"
    $PIP install --upgrade pip
fi

PS4='\033[1;33m>>> \033[0m'; set -x;
$PIP install --upgrade "${packages_basic[@]}"
$PIP install --upgrade "${packages_jupyter[@]}"

exit 0;

# vim: set ts=4 sts=4 sw=4:
