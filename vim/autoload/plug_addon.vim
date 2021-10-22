" Addons for plug.vim

" UnPlug: deregister a plugin, must be called before plug#end()
" https://github.com/junegunn/vim-plug/issues/469
function! s:unplug(repo)
  let repo = substitute(a:repo, '[\/]\+$', '', '')
  let name = fnamemodify(repo, ':t:s?\.git$??')
  if has_key(g:plugs, name)
    call remove(g:plugs, name)
    call remove(g:plugs_order, index(g:plugs_order, name))
  endif
endfunction
command! -nargs=1 -bar UnPlug call s:unplug(<args>)


" ForcePlugURI: In case when plugin repo URI changes, PlugClean is required.
" To automatically fix it for individual plugin, we force-correct URI of an existing one.
function! s:force_plug_uri(plug_name) abort
  let dir = g:plugs[a:plug_name].dir
  let expected_uri = substitute(g:plugs[a:plug_name].uri,
        \ '^https://git::@github\.com', 'https://github.com', '')
  let actual_uri = system(printf('git config -f %s remote.origin.url',
        \ shellescape(dir . '/.git/config')))
  let actual_uri = substitute(actual_uri, '[[:cntrl:]]', '', 'g')  " strip null characters
  let actual_uri = substitute(actual_uri,
        \ '^https://git::@github\.com', 'https://github.com', '')

  if !v:shell_error && actual_uri != expected_uri
      " Update the remote repository URI.
      echo printf("NOTE: We have automatically corrected URL of the plugin %s: ", a:plug_name)
      echo printf("    %s", actual_uri)
      echo printf(" -> %s", expected_uri)
      call system(printf("git config -f %s remote.origin.url %s",
            \ shellescape(dir . '/.git/config'),
            \ shellescape(g:plugs[a:plug_name].uri))
            \ )
      " The new repository might have diverged (non-fast-forward).
      " At this moment, we haven't fetched the tree; we may rollback to the ancestor commit.
      " This may not work if two remotes do not share the tree at all, but probably it's okay...
      call system(printf(
            \ "git -C %s reset --hard $(git rev-list --reverse --topo-order --first-parent HEAD | sed 1q)",
            \ shellescape(dir)))
  endif
endfunction
command! -nargs=1 -bar ForcePlugURI call s:force_plug_uri(<args>)


" util for version comparison (e.g. 'v11.1.0' < 'v8.10')
function! plug_addon#version_lessthan(ver_given, ver_required)
    let ver_given    = split(substitute(a:ver_given, '^v', '', ''), "\\.")
    let ver_required = split(substitute(a:ver_required, '^v', '', ''), "\\.")
    let ver_given = map(ver_given, 'v:val + 0')
    let ver_required = map(ver_required, 'v:val + 0')
    for i in range(max([len(ver_given), len(ver_required)]))
      let lhs = get(ver_given, i, '')
      let rhs = get(ver_required, i, '')
      if lhs != rhs | return lhs < rhs | endif
    endfor
    return 0
endfunction


" Trick for conditional activation  (see vim-plug#935)
" https://github.com/junegunn/vim-plug/wiki/tips#conditional-activation
function! PlugCond(cond, ...)
  let opts = get(a:000, 0, {})
  return a:cond ? opts : extend(opts, { 'on': [], 'for': [] })
endfunction
