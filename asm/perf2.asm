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
	LDA.l oamhi_fast_mask,x
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
assert pc() <= $FF0080


; ---- C1:444E object proximity scan (Vampire AI hot path, issue #3) ----
; Same algorithm and the same final memory values; A, X, Y and P at exit are the same.
; C1:4511, 4561, 433B, 42F1, 5B7F, 44D9 and 44BF are inlined. That removes the
; PHP/PLP and JSR/RTS pairs and the PHA/PLA temps (Y is the temp, saved and restored).
; The $1A07 record counter is kept up to date each record, as in the original.
; Exit goes through the original PLP/RTS at C1:44BD, so the stack and PBR are unchanged.
; Only stack bytes below S (dead scratch) can differ.
org $C1444E
	JML ai_scan
org $FF0080
ai_scan:
	PHP
	SEP #$20
	LDA $10BB
	BNE .out0
	PHY
	STZ $1A07
	LDX #$1A0A
	BRA .first
.done:
	LDA $1A07           ; A=$14 at exit, as in the original
	PLY
.out0:
	JML $C144BD
.next:
	INC $1A07           ; kept live: a record pointer can alias $1A07
	LDX $1A08
	CPX #$1CB6           ; last record: $1A0A+19*$24
	BEQ .done
	REP #$20
	TXA
	CLC
	ADC #$0024
	TAX
.first:
	STX $1A08
.loop:
	REP #$20
	LDA $000001,x
	TAX
	SEP #$20
	LDA $000040,x
	AND #$01
	BNE .next
	LDX $1A08
	LDA $000000,x
	BEQ .next
	; 4511 then the LSR in 4561: $0004/$0006 end as the size, or size*2 if $0B,x != 0
	LDA $000B,x
	REP #$20
	BEQ .s1
	LDA $000D,x
	AND #$00FF
	ASL
	STA $0004
	LDA $000C,x
	AND #$00FF
	ASL
	STA $0006
	BRA .s2
.s1:	LDA $000D,x
	AND #$00FF
	STA $0004
	LDA $000C,x
	AND #$00FF
	STA $0006
.s2:	LDA $0005,x
	STA $0000
	LDA $0007,x
	STA $0010
	TAY
	LDA $000020,x
	AND #$00FF
	STA $0008
	LDA $0817
	CLC
	ADC #$0028
	STA $000A
	LDA #$0002
	STA $000E
	TYA
	CLC
	ADC $0008
	STA $0002
	JSR .t433
	BEQ .fail
	LDA $0010
	STA $0002
	LDA $0815
	STA $0008
	LDA #$0004
	STA $000C
	LDA #$0006
	STA $000E
	LDA $0817
	STA $000A
	; 42F1
	LDA $0000
	SEC
	SBC $0008
	BPL .h2p
	EOR #$FFFF
	INC
	TAY
	LDA $0004
	ASL
	ASL
	ASL
	STA $0012
	TYA
	SEC
	SBC $0012
	BMI .h2
	BRA .fail
.h2p:	TAY
	LDA $000C
	ASL
	ASL
	ASL
	STA $000C
	TYA
	SEC
	SBC $000C
	BPL .fail
.h2:	JSR .t433
	BEQ .fail
	SEP #$20
	; 44D9
	LDA $00000F,x
	CMP $10BD
	BCC +
	STA $10BD
+	LDA $000004,x
	BEQ .nx
	; 44BF: clear the 36-byte record
	LDA #$24
	STA $0029
	LDY #$0024
-	STZ $0000,x
	INX
	DEY
	BNE -
	JMP .next
.fail:
	SEP #$20
	STZ $0028
.nx:	JMP .next

; 433B on $0002/$000A/$000E/$0006. Called with A16 and returns A16.
; Z=1 means miss ($28=0), Z=0 means hit ($28=1). A's high byte is the same as in the original.
.t433:
	LDA $0002
	SEC
	SBC $000A
	BPL .tp
	EOR #$FFFF
	INC
	TAY
	LDA $0006
	ASL
	ASL
	ASL
	STA $0012
	TYA
	SEC
	SBC $0012
	BMI .thit
	BRA .tmiss
.tp:	TAY
	LDA $000E
	ASL
	ASL
	ASL
	STA $000E
	TYA
	SEC
	SBC $000E
	BMI .thit
.tmiss:	SEP #$22            ; Z=1
	STZ $0028
	REP #$20
	RTS
.thit:	SEP #$20
	LDA #$01            ; Z=0
	STA $0028
	REP #$20
	RTS


; ---- C0:91F9 sprite tile loop (C0:BD27 hot path, issue #3) ----
; The 91F9 double loop with the per-tile C0:9233 inlined (no JSR/RTS per tile).
; The OAM high-table part is the same code as oamhi_fast above. The $02/$00 byte
; merge is done with XBA instead of PHA/ORA $01,s/PLA, so the stack slot is not used.
; Final memory, A, X, Y, P, S, D and DB are the same; only stack bytes below S can differ.
; Exit goes through the original PLD/PLB/RTS at C0:9230.
org $C091F9
	JML tile_fast
org $FF0200
tile_fast:
	PHB
	PHD
	PHA
	PLB
	REP #$20
	LDA $0C
	STA $02
.outer:
	REP #$20
	LDA $0A
	STA $00
	SEP #$20
	LDA $0E
	STA $14
.inner:
	REP #$20
	TXA
	CMP #$0200
	BCC +
	JMP .after          ; original: RTS with A=X and the CMP flags
+	LDA $00
	CMP #$FFC0
	BCS .y
	CMP #$0140
	BCC .y
	LDA #$01F0
	STA $00
	BRA .w
.y:	LDA $02
	CMP #$FFF0
	BCS .w
	CMP #$00F0
	BCC .w
	LDA #$01F0
	STA $00
.w:	SEP #$20
	LDA $02
	XBA
	LDA $00
	REP #$20
	STA $7E2000,x
	LDA $04
	ORA $0000,y
	STA $7E2002,x
	LDA $00
	XBA
	AND #$0001
	ORA $12
	STA $06
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
	BEQ .st          ; n=0: $06 unchanged, $16=FFFC, C=0
	ASL
	TAX
	LDA.l oamhi_fast_mask,x
	STA $16
	LDA $06
	JMP (.tent,x)
.t14:	ASL
	ASL
.t12:	ASL
	ASL
.t10:	ASL
	ASL
.t8:	ASL
	ASL
.t6:	ASL
	ASL
.t4:	ASL
	ASL
.t2:	ASL
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
.st:
	LDA $7E2200,x
	AND $16
	ORA $06
	STA $7E2200,x
	PLX
	INX
	INX
	INX
	INX
	INY
	INY
	JMP .after
.after:
	LDA $00
	CLC
	ADC $10
	STA $00
	SEP #$20
	DEC $14
	BEQ +
	JMP .inner
+	REP #$20
	LDA $02
	CLC
	ADC $10
	STA $02
	SEP #$20
	DEC $0F
	BEQ +
	JMP .outer
+	JML $C09230
.tent:	dw 0,.t2,.t4,.t6,.t8,.t10,.t12,.t14
assert pc() <= $FF0400
