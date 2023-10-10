" highlight the very first line (\%1l)
syntax match qfMakeCommand  /\%1l.*/
hi def link qfMakeCommand  Special

syntax match qfFinishedSuccess /^|| \[Finished in [0-9.]\+ seconds\]\s*$/
syntax match qfFinishedError   /^|| \[\(Finished\|Killed\) \(in\|after\) [0-9.]\+ seconds with \(code\|signal\) \d\+.*\]\s*$/

hi! qfFinishedSuccess  guifg=#37b24d
hi! qfFinishedError    guifg=#f03e3e
