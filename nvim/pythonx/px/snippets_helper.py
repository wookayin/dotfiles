"""px.snippets_helper"""

# See $DOTVIM/UltiSnips/python.snippets
# pyright: reportGeneralTypeIssues=false


import vim  # type: ignore
try:
    import typing
    if typing.TYPE_CHECKING:
        import pynvim  # type: ignore
        vim = pynvim.Nvim(...)  # type: ignore  # noqa
except ImportError:
    pass


def snip_expand(snip, jump_pos=1, jump_forward=False):
    """A post-jump action to expand the nested snippet.

    Example:
    ```
    post_jump "snippets_helper.snip_expand(snip, 1)"
    snippet Nested
    print: Inner$1
    endsnippet
    snippet Inner
    "Inner Snippet"
    endsnippet
    ```

    See 'snippets-aliasing' in the Ultisnips doc.
    """
    if snip.tabstop != jump_pos:
        return
    vim.eval(r'feedkeys("\<C-R>=UltiSnips#ExpandSnippet()\<CR>")')
    if jump_forward:
        vim.eval(r'feedkeys("\<C-R>=UltiSnips#JumpForwards()\<CR>")')


def on_ts_node(type_name: str) -> bool:
    """Returns true if the innermost treesitter node on the current cursor
    has the given type."""

    return int(vim.funcs.luaeval(
        'require("utils.ts_utils").get_node_at_cursor():type() == "{}"'\
        .format(type_name))
    ) > 0


__all__ = (
    'snip_expand',
    'on_ts_node',
)
