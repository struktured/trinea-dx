hirom
; ===== Trinea DX: Start skips the rest of the current script's dialogue (always on) =====
; Start (new press) while a message is printing or waiting at [wait] turns on skip mode (armed at the next [wait]). While it is on, the script
; interpreter keeps running every opcode as usual (flags, map moves, items, HP, character branches, battles); only the
; text is suppressed: glyphs are not drawn, [wait] (80) does not wait for A, 88 delays / 81 / 83 newlines are consumed.
; [page] (82) and [END] (FE) still clear the box. Skip mode ends when the script returns to the game ($C0:0DCF), at
; every choice/menu prompt (op 05, op 46: shown normally, the player picks) and on any field tick.
; Always on (v1.1.1): the L+R+Select toggle is gone and saved opts bit6 is ignored.
!SK  = $7ECF20      ; $5C = skip mode on (anything else = off; power-on WRAM is random)
!SKP = $7ECF21      ; last seen Start bit ($00/$10) for edge detection

org $C0FF0C                 ; replaces vwf.asm's tramp (same address, same contract)
sk_tramp:
    JSL sk_byte             ; C=1: byte consumed by skip mode (Y advanced, A kept)
    BCS .ret
    CMP #$20 : BCC .ctrl
    CMP #$80 : BCS .ctrl
    JSL vwf_char
.ret:
    RTS
.ctrl:
    JMP $17EB
assert pc() <= $C0FF25

org $C0FF8E                 ; free zeros in C0 (to $C0FFAD)
t1B31:
    JSR $1B31               ; cursor blink tick (busy-wait helper of the [wait] loop)
    RTL
t_end:                      ; script returns to the game
    JSL sk_clear
    JMP $805D
t_op05:                     ; choice prompt (character-branched 2 options)
    SEP #$20
    JSL sk_clear
    JMP $4986
t_op46:                     ; menu prompt
    SEP #$20
    JSL sk_clear
    JMP $4DAE
assert pc() <= $C0FFAD

org $C00DCF
    JSR t_end
org $C00FB9
    JSR t_op05
    NOP : NOP
org $C04C93
    JSR t_op46
    NOP : NOP

org $C0183A                 ; [wait] (80): was "release A, then press A, cursor off" in 32 bytes
    SEP #$20
    JSL w80                 ; C=1 A pressed normally, C=0 skip mode (no wait, no cursor-off)
    BCC +
    JSR $1BBE
+   LDX #$0001
    STX $0427
    JMP $1819

assert pc() <= $C0185B

org $E90000
sk_clear:                   ; any width; preserves A
    PHP
    SEP #$20
    PHA
    LDA #$00
    STA.l !SK
    PLA
    PLP
    RTL

sk_field:                   ; A8 (from options combo)
    LDA #$00
    STA.l !SK
    LDA.l $000082
    AND #$10
    STA.l !SKP
    RTL

sk_edge:                    ; A8: A = new Start press ($10/0, flags set), !SKP updated. B (high byte of A) clobbered
    LDA.l $000082
    AND #$10
    PHA
    EOR.l !SKP              ; changed and now pressed -> new press
    AND $01,s
    XBA
    PLA
    STA.l !SKP
    XBA                     ; A = new press, Z from it
    RTL

; Skip mode is only ARMED at a [wait] (w80). A Start press while text is printing only sets "pending" ($A3); the
; next [wait] turns that into skip mode. Text that leads into a choice/menu prompt with no [wait] in between (the
; Cube of Time "Chronicle 1/2/3" list, op 46) is therefore always drawn in full: before this, a Start press while
; that list was printing hid the rest of it (real-hardware report: "Chronicle 1" / "C" / blank). op 05/46, the
; script end and field ticks clear pending as well (sk_clear / sk_field store 0).
sk_poll:                    ; A8, from w80; skip on? -> Z clear (A=$5C). Arms on a new press or a pending one.
    LDA.l !SK
    CMP #$5C
    BEQ .on
    JSL sk_edge
    BNE .arm
    LDA.l !SK
    CMP #$A3
    BNE .off
.arm:
    JSL getopt              ; (v1.1.1: opts bit6 ignored, Start always skips; NOPs keep the layout)
    NOP : NOP : NOP : NOP
    LDA #$5C
    STA.l !SK
    RTL                     ; Z clear
.on:
    LDA #$5C
    RTL
.off:
    LDA #$00
    STA.l !SK
    RTL                     ; Z set

sk_pollp:                   ; A8, while printing: skip on? -> Z clear. A new press only marks pending.
    LDA.l !SK
    CMP #$5C
    BEQ .on
    JSL sk_edge
    BEQ .no
    LDA #$A3
    STA.l !SK
.no:
    LDA #$00
    RTL                     ; Z set
.on:
    LDA #$5C
    RTL

sk_byte:                    ; A8 = message byte, Y = ptr. C=1 -> consumed (Y+1)
    PHP
    PHA
    JSR sk_pollw
    BEQ .no
    LDA $01,s
    CMP #$20 : BCC .no
    CMP #$80 : BCC .eat     ; glyph
    CMP #$80 : BEQ .eat     ; [wait]
    CMP #$81 : BEQ .eat
    CMP #$83 : BEQ .eat     ; line break (nothing is drawn)
    CMP #$88 : BEQ .eat     ; delay
.no:
    PLA
    PLP
    CLC
    RTL
.eat:
    PLA
    PLP
    INY
    SEC
    RTL
sk_pollw:                   ; A8 here; JSL sk_pollp from a JSR context
    JSL sk_pollp
    RTS

w80:                        ; A8 X16, DB=$00. [wait]: release A, then press A; Start (skip) aborts
.rel:
    JSL t1B31
    JSL sk_poll
    BNE .skip
    LDA.l $000083
    AND #$80
    BNE .rel
.prs:
    JSL t1B31
    JSL sk_poll
    BNE .skip
    LDA.l $000083
    AND #$80
    BEQ .prs
    SEC
    RTL
.skip:
    CLC
    RTL

; ===== Count Vampierre vaporizes Gostelo (NEA 1426, DB_0000_0024 -> 0025): op 39 animation "23 24 25 00 1f"
; Rumble (asm/rumble.asm zap pattern) for exactly as long as that op-39 animation runs; none if Start-skip is on.
!ZAPOP = $E21DD4            ; the op-39 byte of that animation in the relocated $DB:0000 scripts (bank $E2)
; (checked after build: ROM[$E2:1DD4..] = 39 23 24 25 00 1F FF 06)
org $C06083
    JML z39
org $C0609D
    JML z39end
    NOP : NOP : NOP

org $E90400
z39:                        ; op 39 entry: Y = op+1, bank in $0402
    PHP
    SEP #$20
    PHA
    LDA.l $000402
    CMP.b #!ZAPOP>>16
    BNE .out
    REP #$20
    TYA
    CMP.w #(!ZAPOP+1)&$FFFF
    SEP #$20
    BNE .out
    LDA.l !SK
    CMP #$5C
    BEQ .out                ; skipping: no rumble
    LDA #$F0                ; safety cap 240 frames; op-39 exit stops it
    STA.l !R_ZAP
.out:
    PLA
    PLP
    PHP                     ; original C0:6083 PHP / PHB / PHD / SEP #$20
    PHB
    PHD
    SEP #$20
    JML $C06088
z39end:                     ; original C0:609D PLY / PLD / PLB / PLP / BRL $0F1A
    PHP
    SEP #$20
    PHA
    LDA #$00
    STA.l !R_ZAP
    PLA
    PLP
    PLY
    PLD
    PLB
    PLP
    JML $C00F1A
