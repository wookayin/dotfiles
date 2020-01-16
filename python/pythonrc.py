# .pythonrc.py
# http://jedi.jedidjah.ch/en/dev/docs/usage.html
try:
    from jedi.utils import setup_readline
    setup_readline()
except ImportError:
    import readline, rlcompleter
    readline.parse_and_bind("tab: complete")

# https://github.com/laike9m/pdir2
try:
    import pdir
except ImportError:
    pass

# Auto-load common packages that are frequently used
# For instant startup, non-builtins should be imported lazily
import os, sys, re

# disable lazy_import because lazy-loaded numpy causes many problem
'''
try:
    import lazy_import
    try:
        np = lazy_import.lazy_module("numpy")
        pd = lazy_import.lazy_module("pandas")
        tf = lazy_import.lazy_module("tensorflow")
        matplotlib = lazy_import.lazy_module("matplotlib")
        plt = lazy_import.lazy_module("matplotlib.pyplot")
        scipy = lazy_import.lazy_module("scipy")
    except Exception as e:
        # lazy_import doesn't work with ptipython, ignore the error
        print("Error: lazy_import startup failed.")
        import traceback; traceback.print_exc()
        print("")
except ImportError:
    print("Automatic lazy-import has been disabled. (to enable: pip install lazy_import)")
'''
