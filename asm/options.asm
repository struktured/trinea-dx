hirom
; ===== Trinea DX options (beta): runtime toggles stored in unused SRAM tail =====
; SRAM $30:6300 'T', $6301 'D', $6302 opts, $6303 opts^$A5   (invalid -> all OFF = original)
;   opts bit0 turbo (20 Hz logic), bits1-2 Sara speed (0 orig, 1 = 5px-equiv, 2 = 6px-equiv), bit3 faster monsters
; $6304 prev buttons, $6305 feedback ticks, $6306 saved mosaic ($00B4)
!S = $306300

; --- main-loop tick wait (both copies): LDA $082C : CMP #$04 -> JSL turbo : NOP
org $C00268
    JSL turbo
    NOP
org $C002A5
    JSL turbo
    NOP

; --- monster step hook (shared enemy 8-dir step routine C1:3A92)
org $C13A92
    JSL mon
    NOP

; --- player collision chain + per-tick hook
; --- joypad read (replaces perf_joy target): keep raw pad in SRAM scratch, hide face/Start/Select from the game while L+R held
org $C004F8
    JML joy

org $C0FF26
chain:
    JSR $3307
    JSR $365A
    JSR $3E5B
    JSR $3320
    RTS
org $C0FF77
tick:
    SEP #$20
    JSL combo
    JSL sarachk
    BCC +
    LDA $124B
    JSR $3431
    JSR chain
+   RTS
org $C031B7
    JSR chain
    JSR tick
    NOP #6

org $FE0200
getopt:            ; A8 in/out: A = opts (0 if signature invalid)
    LDA.l !S
    CMP #$54
    BNE .z
    LDA.l !S+1
    CMP #$44
    BNE .z
    LDA.l !S+2
    EOR #$A5
    CMP.l !S+3
    BNE .z
    LDA.l !S+2
    RTL
.z: LDA #$00
    RTL

turbo:             ; A8; returns carry = ($082C >= threshold)
    JSL getopt
    AND #$01
    BNE .t
    LDA $082C
    CMP #$04
    RTL
.t: LDA $082C
    CMP #$03
    RTL

sarachk:           ; A8; carry set -> do extra 4px substep this tick
    LDA $1430
    CMP #$02
    BNE .no
    LDA $0825
    CMP #$04
    BNE .no
    LDA $0829
    BNE .no
    JSL getopt
    LSR
    AND #$03
    CMP #$01
    BEQ .s5
    CMP #$02
    BEQ .s6
.no: CLC
    RTL
.s5: LDA $10C2
    AND #$03
    BNE .no
    SEC
    RTL
.s6: LDA $10C2
    LSR
    BCC .no
    SEC
    RTL

mon:
    PHP
    REP #$30
    PHA
    SEP #$20
    JSL getopt
    AND #$08
    REP #$20
    BEQ .out
    LDA $0004
    CMP #$0004
    BNE .out
    LDA $0000
    ORA $0002
    AND #$0007
    BNE .out
    LDA $10C2
    AND #$0003
    BNE .out
    LDA #$0008
    STA $0004
.out:
    PLA
    PLP
    REP #$20
    RTL

; --- L+R held, then X = turbo, Y = Sara speed, A = monsters. Feedback: mosaic blinks (setting value + 1 blinks)
combo:
    PHP
    SEP #$20
    ; current relevant buttons (only while L+R held): bit7 A, bit6 X, bit5 Y
    LDA.l !S+10
    AND #$30
    CMP #$30
    BEQ +
    LDA #$00
    BRA ++
+   LDA.l !S+11
    AND #$40
    LSR
    STA.l !S+8
    LDA.l !S+10
    AND #$C0
    ORA.l !S+8
++  PHA
    JSL getopt
    STA.l !S+9
    ; signature valid? if not and no new press, nothing else to do
    LDA.l !S
    CMP #$54
    BNE .nosig
    LDA.l !S+1
    CMP #$44
    BNE .nosig
    LDA.l !S+2
    EOR #$A5
    CMP.l !S+3
    BEQ .sig
.nosig:
    PLA
    PHA
    BNE +
    PLA
    PLP
    RTL
+   LDA #$54          ; first use: init block, defaults OFF
    STA.l !S
    LDA #$44
    STA.l !S+1
    LDA #$00
    STA.l !S+2
    STA.l !S+4
    STA.l !S+5
    LDA #$A5
    STA.l !S+3
    LDA #$00
    STA.l !S+9
.sig:
    PLA
    PHA
    EOR.l !S+4        ; new presses = cur & ~prev
    AND $01,s
    STA.l !S+8
    PLA
    STA.l !S+4
    LDA.l !S+8
    BIT #$40
    BEQ +
    LDA.l !S+9
    EOR #$01
    STA.l !S+9
    AND #$01
    BRA .set
+   LDA.l !S+8
    BIT #$20
    BEQ +
    LDA.l !S+9
    LSR
    AND #$03
    INC
    CMP #$03
    BCC ++
    LDA #$00
++  PHA
    ASL
    STA.l !S+8
    LDA.l !S+9
    AND #$F9
    ORA.l !S+8
    STA.l !S+9
    PLA
    BRA .set
+   LDA.l !S+8
    BIT #$80
    BEQ .fb
    LDA.l !S+9
    EOR #$08
    STA.l !S+9
    LSR
    LSR
    LSR
    AND #$01
.set:               ; A = displayed value (0..2)
    INC
    ASL
    ASL
    ASL             ; blinks*8 ticks
    PHA
    LDA.l !S+5
    BNE +
    LDA $00B4
    STA.l !S+6
+   PLA
    STA.l !S+5
    LDA.l !S+9
    STA.l !S+2
    EOR #$A5
    STA.l !S+3
.fb:                ; feedback mosaic
    LDA.l !S+5
    BEQ .done
    DEC
    STA.l !S+5
    BEQ .rest
    AND #$04
    BEQ .rest
    LDA #$FF
    STA $00B4
    BRA .done
.rest:
    LDA.l !S+6
    STA $00B4
.done:
    PLP
    RTL

joy:
    PHP
    SEP #$20
-   LDA $4212
    LSR
    BCS -
    LDA $4219
    STA.l !S+11
    STA $0082
    LDA $4218
    STA.l !S+10
    STA $0083
    AND #$30
    CMP #$30
    BNE +
    STA $0083
    LDA $0082
    AND #$0F
    STA $0082
+   JML $C0050C
