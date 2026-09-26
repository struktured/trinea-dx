;; ---------------------------------------------------------------------------------------------
;; English VWF (variable-width font) for Trinea.
;; Bytes 0x20-0x7F inside a message are 1-byte ASCII glyphs (font/en/font.bin, 16 rows x 2bpp,
;; <=8px wide, advance table font/en/widths.bin), drawn proportionally into a RAM buffer that has
;; exactly the game's native text-strip layout: per 16px cell 4 tiles TL,TR,BL,BR, 4bpp, planes 2/3 = 0.
;;  * dialogue ($C0:16D3 loop): hook at $C0:16E0 (JSR $17EB -> tramp). Line buffer $7F:D000,
;;    only touched cells are DMA'd with the game's own NMI job #6 (params $0BB4.., dest $0423 =
;;    table $C0:17B2[$0408] + cell*$40, same as $C0:1761). $040A (cell column) is kept equal to
;;    ceil(pen/16) so $1886 newline/scroll, page clear (STZ $040A), wait-cursor etc. keep working.
;;    If $040A/$0408 were changed by other code (choice menus, 81, JP glyphs) the pen follows.
;;  * opening/ending cutscene text ($CE:4879): whole entry rendered into $7E:6000 (4 lines x $800).
;; JP 2-byte glyphs (00/01 xx) and control bytes 80..FF keep the original code paths.
;; ---------------------------------------------------------------------------------------------
!BUF   = $7FD000        ; dialogue line buffer: 12 cells * 128 bytes = $600 ($7FD000-$7FD6FF verified unused: work/ramtest2.py)
!PEN   = $7FD600
!CHR   = $7FD602
!WID   = $7FD604
!SRC   = $7FD606
!COL   = $7FD608
!SH    = $7FD60A
!TMP   = $7FD60C
!K0    = $7FD60E
!K1    = $7FD610
!OFFA  = $7FD612
!OFFB  = $7FD614
!CNT   = $7FD616
!LASTCOL = $7FD618
!LASTLN  = $7FD61A
!BASE  = $7FD61C        ; 16-bit buffer base (in bank !BANK)
!BANK  = $7FD61E        ; 8-bit
!HL    = $7FD61F        ; 8-bit highlight flag
!MAXPX = $7FD660        ; 16-bit line width in px
!NCOL  = $7FD662        ; 16-bit number of 8px columns in a line
!LINE  = $7FD664
!TA    = $7FD620        ; 32 bytes (col c,   16 rows x p0,p1)
!TB    = $7FD640        ; 32 bytes (col c+1)

org $C016E0
    JSR vwf_tramp           ; was JSR $17EB

org $C0FF0C                 ; free zeros in bank C0
vwf_tramp:
    CMP #$20 : BCC .ctrl
    CMP #$80 : BCS .ctrl
    JSL vwf_char
    RTS
.ctrl:
    JMP $17EB
assert pc() <= $C0FF25

org $E00000
;; ---------------------------------------------------------------- dialogue
vwf_char:                   ; in: A8=char, Y=script ptr, DP=$0400, DB=$00, X16. out: Y+1, A8 = char
    PHP
    PHB
    REP #$30
    PHY
    AND #$00FF
    SEC : SBC #$0020
    STA.l !CHR
    LDA.w #!BUF&$FFFF : STA.l !BASE
    LDA #$00C0 : STA.l !MAXPX       ; 192 px
    LDA #$0018 : STA.l !NCOL        ; 24 columns
    SEP #$20
    LDA #$7F : STA.l !BANK
    LDA.l $000409 : STA.l !HL
    REP #$20
    LDA.l $00040A : AND #$00FF : BNE .notnew
.clearall:
    LDX #$05FE
    LDA #$0000
.clr: STA.l !BUF,x
    DEX : DEX : BPL .clr
    LDA.l $00040A : AND #$00FF : ASL #4 : STA.l !PEN
    BRA .ready
.notnew:                    ; column/line changed by someone else (choice menus, 81, JP chars)?
    CMP.l !LASTCOL : BNE .moved
    LDA.l $000408 : AND #$00FF : CMP.l !LASTLN : BEQ .ready
    BRA .clearall
.moved:
    LDA.l $000408 : AND #$00FF : CMP.l !LASTLN : BNE .clearall
    LDA.l $00040A : AND #$00FF : ASL #4 : STA.l !PEN
    ASL #3 : TAX            ; x = col*128 : clear buffer from this cell on
    LDA #$0000
.clr2: CPX #$0600 : BCS .ready
    STA.l !BUF,x
    INX : INX : BRA .clr2
.ready:
    JSR vwf_glyph           ; C=1 -> nothing drawn (space / overflow)
    BCS .advance
    ; ---- DMA touched cells
    LDA.l !COL : LSR : STA.l !K0
    LDA.l !COL : INC : LSR : CMP #$000C : BCC + : LDA #$000B : +
    STA.l !K1
    SEC : SBC.l !K0 : INC : XBA : LSR           ; *128
    STA.l $000BB9
    LDA.l !K0 : XBA : LSR : CLC : ADC.w #!BUF&$FFFF : STA.l $000BB6
    LDA.l $000408 : AND #$00FF : ASL : TAX
    LDA.l $C017B2,x : STA.l !TMP
    LDA.l !K0 : ASL #6 : CLC : ADC.l !TMP : STA.l $000423
    SEP #$20
    LDA #$01 : STA.l $000BB4
    LDA #$18 : STA.l $000BB5
    LDA #$7F : STA.l $000BB8
    LDA #$06 : STA.l $000084
-   LDA.l $000084 : BNE -
    REP #$20
.advance:
    LDA.l !PEN : CLC : ADC.l !WID
    CMP #$00C1 : BCC + : LDA #$00C0 : +
    STA.l !PEN
    CLC : ADC #$000F : LSR #4
    BNE + : INC : +
    SEP #$20 : STA.l $00040A : REP #$20
    AND #$00FF : STA.l !LASTCOL
    LDA.l $000408 : AND #$00FF : STA.l !LASTLN
    PLY : INY
    PLB
    PLP
    LDA #$20                ; any value except FE/FF
    RTL

;; ---------------------------------------------------------------- core
;; draw glyph !CHR at !PEN into buffer !BANK:!BASE (native strip layout), 16-bit A/X/Y on entry.
;; sets !WID (advance); returns C=1 if nothing was drawn (space or line overflow), else C=0 and !COL.
vwf_glyph:
    PHB
    LDA.l !CHR : TAX
    LDA.l vwf_widths,x : AND #$00FF : STA.l !WID
    LDA.l !PEN : CLC : ADC.l !WID : DEC
    CMP.l !MAXPX : BCS .nodraw                   ; would overflow the line: drop glyph (inserter wraps)
    LDA.l !CHR : BNE .draw                       ; space: nothing to draw
.nodraw:
    PLB
    SEC
    RTS
.draw:
    ASL : ASL : ASL : ASL : ASL : STA.l !SRC
    LDA.l !PEN : AND #$0007 : STA.l !SH
    LDA.l !PEN : LSR : LSR : LSR : STA.l !COL
    JSR vwf_coloff : CLC : ADC.l !BASE : STA.l !OFFA
    LDA.l !COL : INC : JSR vwf_coloff : CLC : ADC.l !BASE : STA.l !OFFB
    ; ---- pass 1: shifted glyph rows into TA/TB
    LDX #$0000
.p1:
    PHX
    TXA : CLC : ADC.l !SRC : TAX
    LDA.l vwf_font,x
    PLX
    STA.l !TMP
    SEP #$20
    LDA.l !HL : BEQ +
    LDA.l !TMP+1 : ORA.l !TMP : STA.l !TMP      ; highlight: p0 |= p1 (same as $C0:1740)
+   REP #$20
    LDA.l !TMP : AND #$00FF : XBA : JSR vwf_shift
    SEP #$20 : STA.l !TB,x : XBA : STA.l !TA,x : REP #$20
    LDA.l !TMP : AND #$FF00 : JSR vwf_shift
    SEP #$20 : STA.l !TB+1,x : XBA : STA.l !TA+1,x : REP #$20
    INX : INX : CPX #$0020 : BNE .p1
    ; ---- pass 2: OR into buffer (DB = buffer bank)
    SEP #$20 : LDA.l !BANK : PHA : PLB : REP #$20
    LDX #$0000
.p2:
    TXA : CMP #$0010 : BCC + : ADC #$002F : +   ; rows 8-15 are in the bottom tile (+64 bytes)
    STA.l !TMP
    CLC : ADC.l !OFFA : TAY
    LDA.l !TA,x : ORA $0000,y : STA $0000,y
    LDA.l !COL : INC : CMP.l !NCOL : BCS +      ; col c+1 beyond line
    LDA.l !TMP : CLC : ADC.l !OFFB : TAY
    LDA.l !TB,x : ORA $0000,y : STA $0000,y
+   INX : INX : CPX #$0020 : BNE .p2
    PLB
    CLC
    RTS

vwf_coloff:                 ; A = 8px column -> byte offset in strip: (c>>1)*128 + (c&1)*32
    PHA : AND #$0001 : ASL #5 : STA.l !CNT
    PLA : LSR : XBA : LSR : CLC : ADC.l !CNT
    RTS

vwf_shift:                  ; A16 >>= SH
    PHX
    PHA : LDA.l !SH : TAX : PLA
    CPX #$0000 : BEQ +
-   LSR : DEX : BNE -
+   PLX
    RTS

vwf_font:
    incbin "../build/font/font.bin"
vwf_widths:
    incbin "../build/font/widths.bin"
