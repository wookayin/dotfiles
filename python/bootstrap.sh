#!/bin/bash
# Installs essential packages for usual python development environments.

set -ex

packages_basic=(
    # shell :)
    ipython ptpython jedi
    # debugging
    pudb ipdb py-spy
    # testing
    pytest pytest-xdist pytest-runner pytest-pudb
    # linter
    mypy pylint ruff
    # formatter
    yapf black
    # LSP and DAP
    python-lsp-server pyright
    debugpy
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

python -m pip install --upgrade pip
python -m pip install --upgrade "${packages_basic[@]}"
python -m pip install --upgrade "${packages_jupyter[@]}"

exit 0;
