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

    jupyter labextension install '@jupyterlab/toc' --no-build

    jupyter labextension install '@jupyter-widgets/jupyterlab-manager' --no-build
    jupyter labextension install 'jupyter-matplotlib' --no-build

    jupyter lab build
}

install_jupyter_extra() {
    # pyviz (hvplot, etc.)
    pip install --upgrade 'hvplot'
    jupyter labextension install '@pyviz/jupyterlab_pyviz' --no-build

    # plotly
    jupyter labextension install 'jupyterlab-plotly' --no-build
    jupyter labextension install 'plotlywidget' --no-build

    # ipyveutify
    pip install --upgrade 'ipyvuetify'
    jupyter nbextension enable --py --sys-prefix 'ipyvuetify'
    jupyter labextension install 'jupyter-vuetify' --no-build

    # ipyaggrid
    pip install --upgrade 'ipyaggrid'
    jupyter labextension install 'ipyaggrid' --no-build

    # build all extensions
    jupyter lab build
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
