" rust ftplugin

if !filereadable('Makefile')
	let &l:makeprg="(rustc % && ./%:r)"
endif
