; perf2: OAM high-table update in C0:9233 (issue #3).
; Replaces the 2-bit shift loop at C0:9284-92B0 with a table lookup plus an
; unrolled shift chain. Uses JML out/back so the stack bytes (PHX/PHA garbage)
; are the same as the original. Results are identical: $06, $16, A, X, and C.
; Entry: m16 x16, X = OAM offset, $06 = high bits for this sprite.
org $C09284
	JML oamhi_fast
org $FF0000
oamhi_fast:
	PHX
	TXA
	LSR
	LSR
	PHA
	LSR
	LSR
	LSR
	ASL                 ; C=0
	LDX #$FFFC
	STX $16
	TAX
	PLA
	AND #$0007
	BEQ .store          ; n=0: $06 unchanged, $16=FFFC, C=0
	ASL
	TAX
	LDA.l .mask,x
	STA $16
	LDA $06
	JMP (.ent,x)
.c14:	ASL
	ASL
.c12:	ASL
	ASL
.c10:	ASL
	ASL
.c8:	ASL
	ASL
.c6:	ASL
	ASL
.c4:	ASL
	ASL
.c2:	ASL
	ASL
	STA $06
	LDA $01,s           ; X0 again (pushed by PHX)
	LSR
	LSR
	LSR
	LSR
	LSR
	ASL
	TAX
	SEC                 ; original loop leaves C=1
.store:
	LDA $7E2200,x
	AND $16
	ORA $06
	STA $7E2200,x
	JML $C092B1
.mask:	dw $FFFC,$FFF3,$FFCF,$FF3F,$FCFF,$F3FF,$CFFF,$3FFF
.ent:	dw 0,.c2,.c4,.c6,.c8,.c10,.c12,.c14
