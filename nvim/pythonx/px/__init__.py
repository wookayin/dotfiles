"""The px module for nvim python rplugins."""

import importlib
import sys


def __import__(module):
    """Force reload and import a submodule."""
    if not module.startswith('px.'):
        module = 'px.' + module

    if module in sys.modules:
        importlib.reload(sys.modules[module])
    return importlib.import_module(module)
