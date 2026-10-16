hirom
; ---- Trinea DX perf patch (no design change) ----
; 1) NMI joypad read: original waited while $4212.7 (VBlank) set -> NMI burned the rest of every VBlank.
;    Wait only for auto-joypad busy ($4212.0), which is what the read actually needs.
org $C004F8
    JML perf_joy
; 2) per-tick clear of $7E:8000-$8FFF: byte loop STA [$00],y (~1 frame/tick) -> unrolled 16-bit stores.
org $C0C3FA
    JSL perf_clr
    RTS

org $FE0000
perf_joy:
    PHP
    SEP #$20
-   LDA $4212
    LSR
    BCS -
    JML $C00500

perf_clr:
    SEP #$20
    LDA #$7E
    STA $02
    LDX.w #$8000
    STX $00
    PHP
    REP #$20
    LDA.w #$0000
    LDX.w #$0FE0
-
    !i = 0
    while !i < 32
        STA.l $7E8000+!i,x
        !i #= !i+2
    endwhile
    TXA
    SEC
    SBC.w #$0020
    TAX
    LDA.w #$0000
    BCS -
    PLP
    LDA #$00
    LDX.w #$0000
    LDY.w #$1000
    RTL
