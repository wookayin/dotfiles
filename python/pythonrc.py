# .pythonrc.py

# Auto-load common built-in modules that are frequently used
# For instant startup, non-builtins should be imported upon request (use %imp)

import asyncio
import contextlib
import functools
import hashlib
import importlib
import io
import os
import pathlib
import re
import sys
from importlib import reload
from pathlib import Path

# Install Jedi completer to readline (tab completion in vanilla python REPL)
# http://jedi.jedidjah.ch/en/dev/docs/usage.html
try:
    from jedi.utils import setup_readline
    setup_readline()
except ImportError:
    import readline, rlcompleter   # isort:skip
    readline.parse_and_bind("tab: complete")

# https://github.com/laike9m/pdir2
try:
    import pdir
except ImportError:
    pass


def _import_common_modules(full=False):
    """Import common modules such as numpy, pandas, etc."""

    def _import(module_name, symbol=None, _as=None, verbose=True):
        try:
            if not symbol:
                msg = "import {}{}".format(
                    module_name, _as and (' as ' + _as) or '')
            else:
                msg = "from {} import {}{}".format(
                    module_name, symbol, _as and (' as ' + _as) or '')
            sys.stdout.write("%-35s" % msg)
            sys.stdout.flush()

            m = importlib.import_module(module_name)
            obj_or_m = getattr(m, symbol) if symbol else m
            if _as:
                globals()[_as] = obj_or_m
            elif symbol:
                globals()[symbol] = obj_or_m
            else:
                tl_package = module_name.split('.')[0]
                globals()[tl_package] = sys.modules[tl_package]
            if verbose:
                tl_package = module_name.split('.')[0]
                version = getattr(sys.modules[tl_package], '__version__', '')
            sys.stdout.write(version and ('[' + version + ']') or '')
        except ImportError:
            sys.stdout.write('not found')
            return
        finally:
            sys.stdout.write('\n')
            sys.stdout.flush()

    _import('numpy', _as='np')
    _import('jax')
    _import('jax.numpy', _as='jnp')
    _import('pandas', _as='pd')
    _import('matplotlib', _as='mpl')
    _import('matplotlib.pyplot', _as='plt')
    _import('scipy')
    _import('imgcat', symbol='imgcat')
    _import('tqdm.auto', symbol='tqdm')

    if full:   # %imp -a
        _import('tensorflow', _as='tf')


def _import_common_magics():
    ipy = get_ipython()  # pylint: disable=undefined-variable

    def _run(line):
        ipy.run_cell('''\
try:
    {line}
    print('{line}')
except ModuleNotFoundError:
    pass'''.format(line=line))

    _run(r'%load_ext autoreload')
    _run(r'%load_ext imgcat')
    _run(r'%load_ext line_profiler')


def _import_common(full=False):
    _import_common_modules(full=full)
    try:
        _import_common_magics()
    except NameError:
        pass


try:
    get_ipython()   # only if is in ipython
    from IPython.core.magic import register_line_magic

    @register_line_magic
    def i(line):
        """%i: Magic for loading common packages you would need."""
        _import_common(line.strip() == '-a')

    del register_line_magic

except NameError:
    pass  # not ipython, don't do anything
