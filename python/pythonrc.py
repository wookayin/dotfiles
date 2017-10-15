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
