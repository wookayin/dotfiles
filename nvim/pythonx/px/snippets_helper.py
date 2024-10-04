"""px.snippets_helper"""

# See $DOTVIM/UltiSnips/python.snippets
# pyright: reportGeneralTypeIssues=false

# Note: Minimum python version is: 3.7+
from __future__ import annotations

from typing import List, Set

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


def on_ts_node(type_name: str | List[str] | Set[str]) -> bool:
    """Returns true if the innermost treesitter node on the current cursor
    has the given type."""

    if isinstance(type_name, str):
        type_name = [type_name]
    type_name = set(type_name)

    node_type: str | None = vim.funcs.luaeval(
        '''(function(t) return t and t:type() or nil end)(
            require("utils.ts_utils").get_node_at_cursor() )'''
    )
    return node_type in type_name


__all__ = (
    'snip_expand',
    'on_ts_node',
)
