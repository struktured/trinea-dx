;; Opening / ending cutscene text. Original: $CE:4879 (A = entry id) clears $7E:6000 ($2000 bytes),
;; finds "00 id param text.. FF" in $CA:2000 and renders all lines at once (83 = next line, +$800),
;; then DMAs the buffer to VRAM at $CE:48BF. New data (from insert_script.py) lives at $E4:0000 with
;; identical entry ids. English entries (first text byte >= $20) are drawn with the VWF core
;; (256 px per line); entries still in Japanese (first byte 00/01) fall back to the original code.
org $CE4879
    JML open_hook
org $E08000
open_hook:                  ; A = id, X16, DP = 0
    SEP #$20
    PHA
    REP #$30
    AND #$00FF : STA.l !TMP
    LDX #$0000
.scan:
    LDA.l $E40000,x : INX : AND #$00FF : BNE .skip
    LDA.l $E40000,x : INX : AND #$00FF : CMP.l !TMP : BNE .scan
    INX
    BRA .found
.skip:
    LDA.l $E40000,x : INX : AND #$00FF : CMP #$00FF : BNE .skip
    BRA .scan
.found:
    LDA.l $E40000,x : AND #$00FF : CMP #$0002 : BCS .english
    SEP #$20                ; Japanese entry: run the original routine (SEP #$20 / PHA done,
    LDX #$6000              ; LDX #$6000 was overwritten by the JML)
    JML $CE487F
.english:
    PHX
    LDX #$6000 : STX $00
    SEP #$20
    LDA #$7E : STA $02
    LDX #$2000
    LDA #$00
    JSL $C083F9             ; clear $7E:6000-7FFF (same as original)
    REP #$30
    PLX
    LDA #$6000 : STA.l !BASE
    LDA #$0100 : STA.l !MAXPX
    LDA #$0020 : STA.l !NCOL
    LDA #$0000 : STA.l !PEN
    SEP #$20
    LDA #$7E : STA.l !BANK
    LDA #$00 : STA.l !HL
    REP #$20
.loop:
    LDA.l $E40000,x : INX : AND #$00FF
    CMP #$00FF : BEQ .done
    CMP #$0083 : BNE +
    LDA.l !BASE : CLC : ADC #$0800 : STA.l !BASE
    LDA #$0000 : STA.l !PEN
    BRA .loop
+   CMP #$0020 : BCC .loop
    CMP #$0080 : BCS .loop
    SEC : SBC #$0020 : STA.l !CHR
    PHX
    JSR vwf_glyph
    REP #$30
    LDA.l !PEN : CLC : ADC.l !WID : STA.l !PEN
    PLX
    BRA .loop
.done:
    SEP #$20
    PLA                     ; drop id (8-bit, pushed at entry)
    JML $CE48BF             ; original DMA of $7E:6000/$7E:7000 + RTS
