setlocal expandtab
setlocal iskeyword+=:

if !filereadable('Makefile')
	let &g:makeprg = "pandoc % -t latex -o %:r.pdf && open %:r.pdf"
endif
