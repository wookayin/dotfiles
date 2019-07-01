" Addons for plug.vim

" UnPlug: deregister a plugin, must be called before plug#end()
" https://github.com/junegunn/vim-plug/issues/469
function! s:unplug(repo)
  let repo = substitute(a:repo, '[\/]\+$', '', '')
  let name = fnamemodify(repo, ':t:s?\.git$??')
  call remove(g:plugs, name)
  call remove(g:plugs_order, index(g:plugs_order, name))
endfunction
command! -nargs=1 -bar UnPlug call s:unplug(<args>)


" ForcePlugURI: In case when plugin repo URI changes, PlugClean is required.
" To automatically fix it for individual plugin, we force-correct URI of an existing one.
function! s:force_plug_uri(plug_name)
  let dir = g:plugs[a:plug_name].dir
  let expected_uri = substitute(g:plugs[a:plug_name].uri,
        \ '^https://git::@github\.com', 'https://github.com', '')
  let actual_uri = system(printf('git config -f %s remote.origin.url',
        \ shellescape(dir . '/.git/config')))
  let actual_uri = substitute(actual_uri, '[[:cntrl:]]', '', 'g')  " strip null characters
  let actual_uri = substitute(actual_uri,
        \ '^https://git::@github\.com', 'https://github.com', '')

  if !v:shell_error && actual_uri != expected_uri
      echo printf("NOTE: We have automatically corrected URL of the plugin %s: ", a:plug_name)
      echo printf("    %s", actual_uri)
      echo printf(" -> %s", expected_uri)
      call system(printf("git config -f %s remote.origin.url %s",
            \ shellescape(dir . '/.git/config'),
            \ shellescape(g:plugs[a:plug_name].uri))
            \ )
  endif
endfunction
command! -nargs=1 -bar ForcePlugURI call s:force_plug_uri(<args>)
