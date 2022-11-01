" highlight the very first line (\%1l)
syntax match qfMakeCommand  /\%1l.*/
hi def link qfMakeCommand  Special

syntax match qfFinishedSuccess '^|| \[Finished in \d\+ seconds\]$'
syntax match qfFinishedError   '^|| \[Finished in \d\+ seconds with code \d*\]$'

hi! qfFinishedSuccess  guifg=#37b24d
hi! qfFinishedError    guifg=#f03e3e
