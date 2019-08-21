#!/bin/bash

# Installs common jupyter lab extensions in a single script.

node -v || (echo "node.js required"; exit 1)
set -v

pip install 'jupyterlab>=1.0'
pip install 'ipykernel>=5.0'
pip install 'ipympl'
pip install 'ipywidgets>=7.5.0'

jupyter nbextension enable --py widgetsnbextension

jupyter labextension install @jupyter-widgets/jupyterlab-manager
jupyter labextension install jupyter-matplotlib

# show installed/enabled extensions
jupyter labextension list
