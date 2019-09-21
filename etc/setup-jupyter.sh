#!/bin/bash

# Installs common jupyter lab extensions in a single script.

node -v || (echo "node.js required"; exit 1)
set -v

install_jupyter_basic() {
    pip install 'jupyterlab>=1.1'
    pip install 'ipykernel>=5.0'
    pip install 'ipympl'
    pip install 'ipywidgets>=7.5.0'

    jupyter nbextension enable --py --sys-prefix 'widgetsnbextension'

    jupyter labextension install '@jupyterlab/toc'

    jupyter labextension install '@jupyter-widgets/jupyterlab-manager'
    jupyter labextension install 'jupyter-matplotlib'
}

install_jupyter_extra() {
    # pyviz (hvplot, etc.)
    pip install --upgrade 'hvplot'
    jupyter labextension install '@pyviz/jupyterlab_pyviz'

    # ipyveutify
    pip install --upgrade 'ipyvuetify'
    jupyter nbextension enable --py --sys-prefix 'ipyvuetify'
    jupyter labextension install 'jupyter-vuetify'

    # ipyaggrid
    pip install --upgrade 'ipyaggrid'
    jupyter labextension install 'ipyaggrid'
}

# ----------------------------------------------
install_jupyter_basic
# ----------------------------------------------
if [[ -n "$1" && "$1" == "--all" ]]; then
    install_jupyter_extra
fi
# ----------------------------------------------

#
# ----------------------------------------------
# show installed/enabled extensions
# ----------------------------------------------
jupyter labextension list
