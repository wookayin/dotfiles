#!/bin/bash
# Installs essential packages for usual python development environments.

packages=(
    ipython ptpython
    pudb ipdb py-spy jedi
    pytest pytest-xdist pytest-runner
    rich
    mypy pylint
    yapf
    tqdm
    imgcat
    jupyter pretty-jupyter
    jupyterlab-lsp python-lsp-server
)

python -m pip install --upgrade pip
python -m pip install --upgrade ${packages[@]}


exit 0;

# ------------ Experimental: unverified --------------
jupyter labextension install --no-build '@krassowski/jupyterlab-lsp@3.10.1'
jupyter lab build --dev-build=False --minimize=True
