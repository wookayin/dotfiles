" rust ftplugin

let s:project_root = DetermineProjectRoot()

if filereadable(s:project_root . "/Makefile") || filereadable("./Makefile")
elseif filereadable(s:project_root . "/Cargo.toml") || filereadable("./Cargo.toml")
    if &g:makeprg == 'make'
        let &g:makeprg = 'cargo build'
    endif
else
    let b:basename = expand("%:r")
    let b:input_file  = filereadable(b:basename . ".in") ? (b:basename . ".in") : ""
    let b:answer_file = filereadable(b:basename . ".ans") ? (b:basename . ".ans") : ""
    let &l:makeprg = "(" . join([
                \ 'rustc %',
                \ !empty(b:input_file) ? printf('./%s < %s', shellescape(b:basename), shellescape(b:input_file)) :
                \                        printf('./%s', shellescape(b:basename)),
                \ ], " && ") . ")"
endif
