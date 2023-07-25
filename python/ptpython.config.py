"""
~/.ptpython/config.py -- ptpython config used by @wookayin.

Based on the config template:
https://github.com/prompt-toolkit/ptpython/blob/master/examples/ptpython_config/config.py
"""
# pyright: reportGeneralTypeIssues=false

from prompt_toolkit.filters import ViInsertMode
from prompt_toolkit.key_binding.key_processor import KeyPress, KeyPressEvent
from prompt_toolkit.keys import Keys
from prompt_toolkit.output import ColorDepth
from prompt_toolkit.styles import Style

import ptpython.python_input
from ptpython.style import default_ui_style
from ptpython.layout import CompletionVisualisation

__all__ = ["configure"]


def configure(repl: ptpython.python_input.PythonInput):
    """
    Configuration method. This is called during the start-up of ptpython.

    :param repl: `PythonRepl` instance.
    """
    # Show function signature (bool).
    repl.show_signature = True

    # Show docstring (bool).
    repl.show_docstring = True

    # Show the "[Meta+Enter] Execute" message when pressing [Enter] only
    # inserts a newline instead of executing the code.
    repl.show_meta_enter_message = True

    # Show completions. (NONE, POP_UP, MULTI_COLUMN or TOOLBAR)
    repl.completion_visualisation = CompletionVisualisation.POP_UP

    # When CompletionVisualisation.POP_UP has been chosen, use this
    # scroll_offset in the completion menu.
    repl.completion_menu_scroll_offset = 0

    # Show line numbers (when the input contains multiple lines.)
    repl.show_line_numbers = False

    # Show status bar.
    repl.show_status_bar = True

    # When the sidebar is visible, also show the help text.
    repl.show_sidebar_help = True

    # Highlight matching parethesis.
    repl.highlight_matching_parenthesis = True

    # Line wrapping. (Instead of horizontal scrolling.)
    repl.wrap_lines = True

    # Mouse support.
    # This should be disabled so that mouse wheel can be used for navigating
    # the scrollback buffer of terminal emulator or tmux. This option is for
    # selecting text and scrolling through ptpython windows.
    repl.enable_mouse_support = False

    # Complete while typing. (Don't require tab before the
    # completion menu is shown.)
    repl.complete_while_typing = True

    # Fuzzy and dictionary completion.
    repl.enable_fuzzy_completion = True
    repl.enable_dictionary_completion = True

    # Vi mode.
    repl.vi_mode = True

    # Paste mode. (When True, don't insert whitespace after new line.)
    repl.paste_mode = False

    # Use the classic prompt. (Display '>>>' instead of 'In [1]'.)
    repl.prompt_style = 'classic'  # 'classic' or 'ipython'

    # Don't insert a blank line after the output.
    repl.insert_blank_line_after_output = False

    # History Search.
    # When True, going back in history will filter the history on the records
    # starting with the current input. (Like readline.)
    # Note: When enable, please disable the `complete_while_typing` option.
    #       otherwise, when there is a completion available, the arrows will
    #       browse through the available completions instead of the history.
    repl.enable_history_search = False

    # Enable auto suggestions. (Pressing right arrow will complete the input,
    # based on the history.)
    repl.enable_auto_suggest = True

    # Enable open-in-editor. Pressing C-x C-e in emacs mode or 'v' in
    # Vi navigation mode will open the input in the current editor.
    repl.enable_open_in_editor = True

    # Enable system prompt. Pressing meta-! will display the system prompt.
    # Also enables Control-Z suspend.
    repl.enable_system_bindings = True

    # Ask for confirmation on exit.
    repl.confirm_exit = False

    # Enable input validation. (Don't try to execute when the input contains
    # syntax errors.)
    repl.enable_input_validation = True

    # Use this colorscheme for the code.
    # Ptpython uses Pygments for code styling, so you can choose from Pygments'
    # color schemes. See:
    # https://pygments.org/docs/styles/
    # https://pygments.org/demo/
    # >>> list(ptpython.style.get_all_styles())

    # A colorscheme that looks good on dark backgrounds is 'native':
    # but I use a bit different colorschme (friendly) rather than the default
    repl.use_code_colorscheme('friendly')

    # Set color depth (keep in mind that not all terminals support true color).
    # We use 24-bit true color.
    repl.color_depth = ColorDepth.DEPTH_24_BIT

    # Min/max brightness
    repl.min_brightness = 0.0  # Increase for dark terminal backgrounds.
    repl.max_brightness = 1.0  # Decrease for light terminal backgrounds.

    # Syntax.
    repl.enable_syntax_highlighting = True

    # Get into Vi navigation mode at startup
    repl.vi_start_in_navigation_mode = False

    # Preserve last used Vi input mode between main loop iterations
    repl.vi_keep_last_used_mode = False

    # Install custom colorscheme named 'my-colorscheme' and use it.
    repl.install_ui_colorscheme("my-colorscheme", custom_ui_colorscheme)
    repl.use_ui_colorscheme("my-colorscheme")

    # Add custom key binding.
    # ControlA and ControlE should work as Home/End (emac-style keybindings).
    @repl.add_key_binding(Keys.ControlA)
    def _(event: KeyPressEvent): event.cli.key_processor.feed(KeyPress(Keys.Home))
    @repl.add_key_binding(Keys.ControlE)
    def _(event: KeyPressEvent): event.cli.key_processor.feed(KeyPress(Keys.End))

    # Ctrl-P and Ctrl-N should navigate the history when completion is not shown.
    @repl.add_key_binding(Keys.ControlP)
    def _(event: KeyPressEvent):
        if event.app.current_buffer.complete_state:
            event.app.current_buffer.complete_previous(disable_wrap_around=True)
        else:
            event.app.current_buffer.history_backward()

    @repl.add_key_binding(Keys.ControlN)
    def _(event: KeyPressEvent):
        if event.app.current_buffer.complete_state:
            event.app.current_buffer.complete_next(disable_wrap_around=True)
        else:
            event.app.current_buffer.history_forward()

    # Ctrl-Space: Starts auto-completion
    @repl.add_key_binding(Keys.ControlSpace)
    def _(event: KeyPressEvent):
        event.app.current_buffer.start_completion(select_first=False)

    # Ctrl-R: History search fzf (requires pyfzf)
    @repl.add_key_binding(Keys.ControlR)
    def _(event: KeyPressEvent):
        import subprocess, collections

        # REPL history. Oldest item first -> Newest item first
        lines = event.app.current_buffer.history.get_strings()[::-1]
        lines = list(collections.OrderedDict.fromkeys(lines))  # uniquify

        fzf = subprocess.Popen([
            'fzf',
            "--layout=reverse",
            "--scheme=history",
            "--prompt", 'REPL History> ',
            "--height", '~30%',
            "+m"
        ], stdout=subprocess.PIPE, stdin=subprocess.PIPE)
        for line in lines:
            line = line.replace('\n', '\r')
            fzf.stdin.write((line + '\n').encode())  # type: ignore
        fzf.stdin.flush()  # type: ignore
        fzf_output = fzf.communicate()[0].decode()

        if fzf_output:
            fzf_output = fzf_output.replace('\r', '\n').rstrip('\n')
            event.app.current_buffer.text = ''   # clear the input buffer
            event.app.current_buffer.insert_text(fzf_output, overwrite=True)

        event.app.renderer.reset()

    """
    @repl.add_key_binding("c-b")
    def _(event):
        " Pressing Control-B will insert "pdb.set_trace()" "
        event.cli.current_buffer.insert_text("\nimport pdb; pdb.set_trace()\n")
    """

    # Typing ControlE twice should also execute the current command.
    # (Alternative for Meta-Enter.)
    """
    @repl.add_key_binding("c-e", "c-e")
    def _(event):
        event.current_buffer.validate_and_handle()
    """

    # Typing 'jj' in Vi Insert mode, should send escape. (Go back to navigation
    # mode.)
    """
    @repl.add_key_binding("j", "j", filter=ViInsertMode())
    def _(event):
        " Map 'jj' to Escape. "
        event.cli.key_processor.feed(KeyPress(Keys("escape")))
    """

    # Custom key binding for some simple autocorrection while typing.
    """
    corrections = {
        "impotr": "import",
        "pritn": "print",
    }

    @repl.add_key_binding(" ")
    def _(event):
        " When a space is pressed. Check & correct word before cursor. "
        b = event.cli.current_buffer
        w = b.document.get_word_before_cursor()

        if w is not None:
            if w in corrections:
                b.delete_before_cursor(count=len(w))
                b.insert_text(corrections[w])

        b.insert_text(" ")
    """

    # Add a custom title to the status bar. This is useful when ptpython is
    # embedded in other applications.
    """
    repl.title = "My custom prompt."
    """


# Custom colorscheme for the UI.
# See `ptpython/layout.py` and `ptpython/style.py` for all possible tokens.
# see https://github.com/prompt-toolkit/ptpython/blob/master/ptpython/layout.py
# see https://github.com/prompt-toolkit/ptpython/blob/master/ptpython/style.py#L65 (a bit outdated)
# see https://github.com/prompt-toolkit/python-prompt-toolkit/blob/master/src/prompt_toolkit/styles/defaults.py#L16
custom_ui_colorscheme = Style.from_dict({
    **default_ui_style,

    # These default style does not exist in default_ui_style().
    # see ptpython.ipython:IPythonInput and prompt-toolkit/ptpython#517
    "pygments.prompt": "#009900",
    "pygments.promptnum": "#00ff00 bold",

    # color customizations, like vim colorscheme (Pmenu, PmenuSel, etc.)
    "completion-menu": "bg:#fff3bf",
    "completion-menu.completion.current": "bg:#ffffff #ff2020 bold",
    "completion-menu.completion fuzzymatch.inside": "fg:#f03e3e",
    "completion-menu.completion.current fuzzymatch.outside": "fg:#ff2020",
    "completion-menu.completion.current fuzzymatch.inside": "bold",

    "signature-toolbar": "bg:#a5d8ff #000000",
    "signature-toolbar current-name": "bg:#4dabf7 #ffffff bold",
})
