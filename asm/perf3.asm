; ---- perf3 (issue #3, Vampire/turbo second-half-of-tick work) ----
; Profile of w_vamp_end with turbo: each 4-frame tick is [work1] C1:66F3 NMI sync [work2] C0:8D77 NMI sync.
; work2 (C0:BD27 sprite list build + sort + C0:92B9 OAM clear) spills ~0.1 frame past one frame.
; Three routine-for-routine rewrites; final memory, A, X, Y, P, S, D, DB identical (stack bytes below S may differ).
hirom

; C0:92B9 OAM buffer clear: 13 words $FFFF at 7E:2206, byte $FF at 7E:2205, 108 words $00F0 at 7E:2050+4i.
org $C092B9
	JML oamclr_fast
org $C0BD94
	JML lb_fast
org $C0BDF6
	JML sort_fast
org $FF0400
oamclr_fast:
	PHP
	PHB
	SEP #$20
	LDA #$7E
	PHA
	PLB
	REP #$20
	LDA #$FFFF
	STA $2206
	STA $2208
	STA $220A
	STA $220C
	STA $220E
	STA $2210
	STA $2212
	STA $2214
	STA $2216
	STA $2218
	STA $221A
	STA $221C
	STA $221E
	SEP #$20
	STA $2205
	REP #$20
	LDA #$00F0
	STA $2050
	STA $2054
	STA $2058
	STA $205C
	STA $2060
	STA $2064
	STA $2068
	STA $206C
	STA $2070
	STA $2074
	STA $2078
	STA $207C
	STA $2080
	STA $2084
	STA $2088
	STA $208C
	STA $2090
	STA $2094
	STA $2098
	STA $209C
	STA $20A0
	STA $20A4
	STA $20A8
	STA $20AC
	STA $20B0
	STA $20B4
	STA $20B8
	STA $20BC
	STA $20C0
	STA $20C4
	STA $20C8
	STA $20CC
	STA $20D0
	STA $20D4
	STA $20D8
	STA $20DC
	STA $20E0
	STA $20E4
	STA $20E8
	STA $20EC
	STA $20F0
	STA $20F4
	STA $20F8
	STA $20FC
	STA $2100
	STA $2104
	STA $2108
	STA $210C
	STA $2110
	STA $2114
	STA $2118
	STA $211C
	STA $2120
	STA $2124
	STA $2128
	STA $212C
	STA $2130
	STA $2134
	STA $2138
	STA $213C
	STA $2140
	STA $2144
	STA $2148
	STA $214C
	STA $2150
	STA $2154
	STA $2158
	STA $215C
	STA $2160
	STA $2164
	STA $2168
	STA $216C
	STA $2170
	STA $2174
	STA $2178
	STA $217C
	STA $2180
	STA $2184
	STA $2188
	STA $218C
	STA $2190
	STA $2194
	STA $2198
	STA $219C
	STA $21A0
	STA $21A4
	STA $21A8
	STA $21AC
	STA $21B0
	STA $21B4
	STA $21B8
	STA $21BC
	STA $21C0
	STA $21C4
	STA $21C8
	STA $21CC
	STA $21D0
	STA $21D4
	STA $21D8
	STA $21DC
	STA $21E0
	STA $21E4
	STA $21E8
	STA $21EC
	STA $21F0
	STA $21F4
	STA $21F8
	STA $21FC
	LDA #$0000
	TAX
	PLB
	JML $C092F8		; PLP : RTS

; C0:BD94 sprite list build: 72 slots of $28 bytes at 7E:5000 -> 3-byte entries at 7E:6000.
; Multiply helper C0:81AE inlined; empty slots skip the STZ of an already-zero byte.
; Exits through the original tail at C0:BDE9 with the same A/X/P and a zero loop word on the stack.
lb_fast:
	LDX #$0000
	STX $18
	LDY #$6000
	REP #$20
.loop:
	LDA $5000,x
	AND #$00FF
	BEQ .empty
	BIT #$0080
	BNE .dead
	SEP #$20
	LDA $18
	STA $0000,y
	LDA $5006,x
	STA $004202
	LDA $5011,x
	STA $004203
	REP #$20
	LDA $5003,x
	CLC
	ADC $500B,x
	CLC
	ADC $004216
	STA $0001,y
	SEP #$20
	INC $19
	INY
	INY
	INY
.dead:
	SEP #$20
	STZ $5000,x
	INC $18
	REP #$20
	BRA .next
.empty:
	INC $18
.next:
	TXA
	CLC
	ADC #$0028
	TAX
	CPX #$0B40
	BNE .loop
	CLC
	CLV
	LDA #$0000
	PEA $0000
	JML $C0BDE9

; C0:BDF6 sort of the entries: the same compare/swap sequence as C0:BE10, faster.
; Per pass: current key kept in A as key-1 (swap iff key[y] >= cur  <=>  cur-1 < key[y], one BCC),
; inner loop unrolled x8 entered Duff-style, pass end pointer in $1A/$1B ($1B restored before exit).
; A pass whose current key is 0 uses the plain loop. The last pass runs in the original C0:BDFC code,
; so the exit A/X/Y/P/$1A are the original's; V is 0 on entry and is cleared again before that.
sort_fast:
	LDA $1B
	PHA
	LDX #$6000
	LDY #$6003
.outer:
	LDA $18
	CMP #$01
	BNE +
	PLA
	STA $1B
	CLV
	JML $C0BDFC
+	PHY
	REP #$20
	AND #$00FF
	STA $1A
	ASL
	CLC
	ADC $1A
	STA $1A
	TYA
	CLC
	ADC $1A
	STA $1A
	LDA $0001,x
	BNE .fast
.inner:
	CMP $0001,y
	BCC .sw
	BEQ .sw
.ns:
	INY
	INY
	INY
	CPY $1A
	BNE .inner
.pend:
	PLY
	INX
	INX
	INX
	INY
	INY
	INY
	SEP #$20
	DEC $18
	BRA .outer
.sw:
	PHA
	LDA $0001,y
	STA $0001,x
	PLA
	STA $0001,y
	SEP #$20
	LDA $0000,x
	XBA
	LDA $0000,y
	STA $0000,x
	XBA
	STA $0000,y
	REP #$20
	LDA $0001,x
	BRA .ns
.fast:
	LDA $18
	EOR #$FFFF
	INC
	AND #$0007
	ASL
	ASL
	TAX
	LDA $01,s
	SEC
	SBC.l sort_ftab+2,x
	TAY
	LDA.l sort_ftab,x
	PHA
	LDA $03,s
	SEC
	SBC #$0003
	TAX
	LDA $0001,x
	DEC
	RTS
sort_blk:
.e0:
	CMP $0001,y
	BCC .j0
.e1:
	CMP $0004,y
	BCC .j1
.e2:
	CMP $0007,y
	BCC .j2
.e3:
	CMP $000A,y
	BCC .j3
.e4:
	CMP $000D,y
	BCC .j4
.e5:
	CMP $0010,y
	BCC .j5
.e6:
	CMP $0013,y
	BCC .j6
.e7:
	CMP $0016,y
	BCC .j7
.nb:
	PHA
	TYA
	CLC
	ADC #$0018
	TAY
	PLA
	CPY $1A
	BNE .e0
	JMP sort_fast_pend
.j0:
	JMP .s0
.j1:
	JMP .s1
.j2:
	JMP .s2
.j3:
	JMP .s3
.j4:
	JMP .s4
.j5:
	JMP .s5
.j6:
	JMP .s6
.j7:
	JMP .s7
.s0:
	INC
	PHA
	LDA $0001,y
	STA $0001,x
	PLA
	STA $0001,y
	SEP #$20
	LDA $0000,x
	XBA
	LDA $0000,y
	STA $0000,x
	XBA
	STA $0000,y
	REP #$20
	LDA $0001,x
	DEC
	JMP .e1
.s1:
	INC
	PHA
	LDA $0004,y
	STA $0001,x
	PLA
	STA $0004,y
	SEP #$20
	LDA $0000,x
	XBA
	LDA $0003,y
	STA $0000,x
	XBA
	STA $0003,y
	REP #$20
	LDA $0001,x
	DEC
	JMP .e2
.s2:
	INC
	PHA
	LDA $0007,y
	STA $0001,x
	PLA
	STA $0007,y
	SEP #$20
	LDA $0000,x
	XBA
	LDA $0006,y
	STA $0000,x
	XBA
	STA $0006,y
	REP #$20
	LDA $0001,x
	DEC
	JMP .e3
.s3:
	INC
	PHA
	LDA $000A,y
	STA $0001,x
	PLA
	STA $000A,y
	SEP #$20
	LDA $0000,x
	XBA
	LDA $0009,y
	STA $0000,x
	XBA
	STA $0009,y
	REP #$20
	LDA $0001,x
	DEC
	JMP .e4
.s4:
	INC
	PHA
	LDA $000D,y
	STA $0001,x
	PLA
	STA $000D,y
	SEP #$20
	LDA $0000,x
	XBA
	LDA $000C,y
	STA $0000,x
	XBA
	STA $000C,y
	REP #$20
	LDA $0001,x
	DEC
	JMP .e5
.s5:
	INC
	PHA
	LDA $0010,y
	STA $0001,x
	PLA
	STA $0010,y
	SEP #$20
	LDA $0000,x
	XBA
	LDA $000F,y
	STA $0000,x
	XBA
	STA $000F,y
	REP #$20
	LDA $0001,x
	DEC
	JMP .e6
.s6:
	INC
	PHA
	LDA $0013,y
	STA $0001,x
	PLA
	STA $0013,y
	SEP #$20
	LDA $0000,x
	XBA
	LDA $0012,y
	STA $0000,x
	XBA
	STA $0012,y
	REP #$20
	LDA $0001,x
	DEC
	JMP .e7
.s7:
	INC
	PHA
	LDA $0016,y
	STA $0001,x
	PLA
	STA $0016,y
	SEP #$20
	LDA $0000,x
	XBA
	LDA $0015,y
	STA $0000,x
	XBA
	STA $0015,y
	REP #$20
	LDA $0001,x
	DEC
	JMP .nb
sort_ftab:
	dw sort_blk_e0-1, 0
	dw sort_blk_e1-1, 3
	dw sort_blk_e2-1, 6
	dw sort_blk_e3-1, 9
	dw sort_blk_e4-1, 12
	dw sort_blk_e5-1, 15
	dw sort_blk_e6-1, 18
	dw sort_blk_e7-1, 21
assert pc() <= $FF2000

