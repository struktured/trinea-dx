!HAS_OPTS = 1
!HAS_SKIP = 1
incsrc "main.asm"
incsrc "rumble.asm"
incsrc "splash.asm"
incsrc "perf.asm"      ; perf first: options re-points C0:04F8 to its own pad reader
incsrc "options.asm"
incsrc "skip.asm"
