; ===== Trinea DX: Select = controls help overlay (on by default; L+R+Start toggles, opts bit7 = OFF) =====
; Press Select in the field or a stage (the same place Start pauses) and the game freezes like the pause screen
; and shows a full-screen BG3 page: an SNES pad with what each button does, plus the current character's
; special moves (docs/MOVES.md). Select or Start closes it and everything is put back exactly.
; How it stays safe:
;  - Runs from the stage pause check (C0:F5BA), so never in menus, dialogue, cutscenes or the attract demo ($F0).
;  - The game logic is frozen inside our own frame loop (the same NMI job $38 the pause loop uses), so the
;    music keeps playing and nothing advances.
;  - Before drawing, the VRAM it overwrites (chr at word $7000, tilemap at word $7800) is DMA-read into WRAM
;    $7E:8000-8FFF, a 4 KB block the game clears every tick and never reads in stages (asm/perf.asm perf_clr).
;    If that block is not all zero the overlay is skipped. On close it is written back and re-zeroed.
;  - CGRAM 0-7, DMA channels 6+7, HDMA ($0831), mosaic, TM/TS/colour-math and BG3 scroll shadows are saved/restored.
;  - BGMODE/BG3SC/BG34NBA/W34SEL ($2105/$2109/$210C/$2124) are write-only and the game has no shadows for them,
;    so every write site the game has gets a tiny trampoline that also stores the value in SRAM (see bottom).
!H   = $7ECF30   ; WRAM: +0 prev Select, +10.. state saved while the overlay is open
!HS  = $306310   ; battery SRAM (2 KB; slots $6000-62FF, DX options $6300-6303): shadows +0 $2105, +2 $2109,
                 ; +4 $210C, +6 $2124 (16-bit spaced). Not WRAM: the game zeroes $7E:2000-FFFF on New Game
                 ; (C0:4C86) after the PPU set-up, so WRAM shadows would be lost; SRAM survives that and resets
!HB  = $7E8000   ; 4 KB save buffer (must be zero; zeroed again on close)
!HCHR = $7000    ; VRAM word address of overlay chr (BG3 2bpp, base nibble 7)
!HMAP = $7800    ; VRAM word address of overlay tilemap (32x32)
incsrc "../build/gen/help.asm"

org $C0F5BA            ; pause check: SEP #$20 / LDA $F0 (demo flag) -> BEQ (go on) / RTS
    JSL help_chk       ; returns with SEP #$20 and A = $F0 (flags as LDA $F0)

org $C0FF33            ; free zeros in bank C0 (to $C0FF55)
help_wait:             ; A8 = NMI job; JSR $8D77 is the game's "wait for NMI job" (needs DB = 0)
    JSR $8D77
    RTL

org $EA0000
help_chk:
    PHP
    SEP #$20
    LDA $F0
    BNE .out
    LDA.l $000082      ; held pad (B Y Sel Start ...); Select hidden by asm/options.asm while L+R are held
    AND #$20
    PHA
    EOR.l !H
    AND $01,s          ; new press
    BEQ .nop
    JSL getopt
    BMI .nop           ; opts bit7 = help OFF
    JSL help_show
.nop:
    PLA
    STA.l !H
.out:
    PLP
    SEP #$20
    LDA $F0
    RTL

help_show:
    PHP
    PHB
    PHD
    REP #$30
    PHA
    PHX
    PHY
    PEA $0000
    PLD
    SEP #$20
    LDA #$00
    PHA
    PLB
    ; refuse unless the 4 KB buffer is all zero (it always is in stages; this guards odd contexts)
    REP #$20
    LDX #$0FFE
-   LDA.l !HB,x
    BEQ +
    JMP .bail
+   DEX
    DEX
    BPL -
    SEP #$20
    LDA #$38
    JSL help_wait       ; we are now just after an NMI
    JSR h_off           ; NMI off + forced blank
    ; save shadows / state
    LDA $01CC : STA.l !H+10
    LDA $0831 : STA.l !H+11
    LDA $00B4 : STA.l !H+12
    LDA.w $009F : STA.l !H+65 ; per-frame scroll/wave effect (NMI JMP ($8AC9,x)) and BG3 wave swapper (NMI DF2F):
    LDA.w $00E0 : STA.l !H+66 ; parked while open so nothing in the NMI touches scroll / HDMA under the overlay
    LDA.w $01B3 : STA.l !H+21 ; BG3 HOFS wave (NMI C0:1FBA, fog on Sara's stage 1 screen 2): when set, every NMI rebuilds
    STZ $009F                 ; the wave table and EORs HDMA ch2 (BG3HOFS) into $0831 and $420C (C0:2039). h_wait only
    STZ $00E0                 ; masks $420C after the NMI returns (line ~2), so ch2 already ran on lines 0-1 and left
    STZ $01B3                 ; BG3HOFS at a wave value for the rest of the frame: the overlay swayed. Parked while open
    LDX #$0000
-   LDA $085A,x : STA.l !H+13,x
    LDA $01A9,x : STA.l !H+17,x
    INX
    CPX #$0004
    BNE -
    LDX #$0000          ; DMA channels 7 (general DMA) and 6 (our HDMA on BG3 scroll)
-   LDA $4370,x : STA.l !H+43,x
    LDA $4360,x : STA.l !H+54,x
    INX
    CPX #$000B
    BNE -
    STZ $2121           ; CGRAM 0-11 (24 bytes, saved at !H+75)
    LDX #$0000
-   LDA $213B : STA.l !H+75,x
    INX
    CPX #$0018          ; CGRAM 0-11: palettes 0-2
    BNE -
    ; VRAM -> buffer: chr then map
    LDA #$80 : STA $2115
    REP #$20
    LDA #!HCHR : STA $2116    ; then one dummy $213A read: the read buffer is refilled from the current
    SEP #$20                  ; address before it increments, so the first DMA read would repeat a stale word
    LDA $213A
    LDA #$81 : STA $4370      ; B->A, 2 regs
    LDA #$39 : STA $4371
    LDX.w #!HB : STX $4372
    LDA #$7E : STA $4374
    LDX.w #!HELP_NT*16 : STX $4375
    LDA #$80 : STA $420B
    REP #$20
    LDA #!HMAP : STA $2116
    SEP #$20
    LDA $213A
    LDX.w #!HB+(!HELP_NT*16) : STX $4372
    LDA #$7E : STA $4374
    LDX #$0700 : STX $4375
    LDA #$80 : STA $420B
    ; upload overlay chr / map / palette
    REP #$20
    LDA #!HCHR : STA $2116
    SEP #$20
    LDA #$01 : STA $4370      ; A->B, 2 regs
    LDA #$18 : STA $4371
    LDX.w #help_chr : STX $4372
    LDA.b #help_chr>>16 : STA $4374
    LDX.w #!HELP_NT*16 : STX $4375
    LDA #$80 : STA $420B
    REP #$20
    LDA #!HMAP : STA $2116
    LDA $1430           ; 1 Hornisse, 2 Sara, 3 Ryo (character select cursor + 1, C0:5D94)
    AND #$00FF
    DEC
    CMP #$0003
    BCC +
    LDA #$0001
+   ASL
    TAX
    PHA
    ASL
    CLC
    ADC $01,s           ; character * 6
    PLX                 ; (X = character * 2 again)
    ASL : ASL
    TAY                 ; Y = character * 24 = offset of that character's palette
    LDA.l help_maps,x
    STA $4372
    STA.l !H+67         ; this character's map (to put the X/A/Y/B labels back after L+R)
    SEP #$20
    LDA.b #help_map>>16 : STA $4374
    LDX #$0700 : STX $4375
    LDA #$80 : STA $420B
    STZ $2121
    TYX
    LDY #$0018
-   LDA.l help_pal,x : STA $2122
    INX
    DEY
    BNE -
    ; PPU setup (registers now, shadows so the NMI keeps them)
    LDA #$09 : STA $2105      ; mode 1, BG3 priority
    LDA.b #(!HMAP>>8)&$FC : STA $2109
    LDA.l !HS+4 : AND #$F0 : ORA.b #!HCHR>>12 : STA $210C
    STZ $2124
    STZ $2111 : STZ $2111
    STZ $2112 : STZ $2112
    STZ $2106
    LDX #$0000
-   STZ $01A9,x
    INX
    CPX #$0004
    BNE -
    LDA #$04 : STA $085A : STA $212C
    STZ $085B : STZ $212D
    STZ $085C : STZ $2131
    STZ $00B4
    ; HDMA channel 6 -> BG3VOFS ($2112, mode 2 = one register written twice): spaces the moves list out at
    ; pixel level (table per character, 64 bytes each, built by helpgfx.py). The NMI writes $420C from $0831.
    LDA #$02 : STA $4360
    LDA #$12 : STA $4361
    REP #$20
    LDA $1430
    AND #$00FF
    DEC
    CMP #$0003
    BCC +
    LDA #$0001
+   ASL : ASL : ASL : ASL : ASL : ASL
    CLC
    ADC.w #help_hdma
    STA $4362
    SEP #$20
    LDA.b #help_hdma>>16 : STA $4364
    LDA #$40 : STA $0831 : STA $420C
    LDA #$00 : STA.l !H+69   ; L+R labels not shown
    JSR h_on
    ; wait: Select/Start released, then pressed, then released
    JSR h_rel
-   JSR h_wait
    LDA $0082
    AND #$30
    BEQ -
    JSR h_rel
    ; close
    JSR h_wait
    JSR h_off
    REP #$20
    LDA #!HCHR : STA $2116
    SEP #$20
    LDA #$01 : STA $4370
    LDA #$18 : STA $4371
    LDX.w #!HB : STX $4372
    LDA #$7E : STA $4374
    LDX.w #!HELP_NT*16 : STX $4375
    LDA #$80 : STA $420B
    REP #$20
    LDA #!HMAP : STA $2116
    SEP #$20
    LDX.w #!HB+(!HELP_NT*16) : STX $4372
    LDX #$0700 : STX $4375
    LDA #$80 : STA $420B
    STZ $2121
    LDX #$0000
-   LDA.l !H+75,x : STA $2122
    INX
    CPX #$0018          ; CGRAM 0-11: palettes 0-2
    BNE -
    LDA.l !HS+0 : STA $2105
    LDA.l !HS+2 : STA $2109
    LDA.l !HS+4 : STA $210C
    LDA.l !HS+6 : STA $2124
    LDX #$0000
-   LDA.l !H+13,x : STA $085A,x
    LDA.l !H+17,x : STA $01A9,x
    INX
    CPX #$0004
    BNE -
    LDA $01A9 : STA $2111 : LDA $01AA : STA $2111
    LDA $01AB : STA $2112 : LDA $01AC : STA $2112
    LDA $085A : STA $212C
    LDA $085B : STA $212D
    LDA $085C : STA $2131
    LDA.l !H+12 : STA $00B4 : STA $2106
    LDA.l !H+11 : STA $0831
    LDA.l !H+65 : STA.w $009F
    LDA.l !H+66 : STA.w $00E0
    LDA.l !H+21 : STA.w $01B3
    LDX #$0000
-   LDA.l !H+43,x : STA $4370,x
    LDA.l !H+54,x : STA $4360,x
    INX
    CPX #$000B
    BNE -
    REP #$20            ; re-zero the buffer
    LDA #$0000
    LDX #$0FFE
-   STA.l !HB,x
    DEX
    DEX
    BPL -
    SEP #$20
    JSR h_on
    LDA #$38
    JSL help_wait
.bail:
    REP #$30
    PLY
    PLX
    PLA
    PLD
    PLB
    PLP
    RTL

h_off:                  ; A8: NMI off, forced blank, HDMA off (an effect may run HDMA on channel 7, which the
    LDA #$01 : STA $4200 ; general DMA below also uses; the NMI re-enables HDMA from $0831 after we close)
    LDA #$80 : STA $2100
    STZ $420C
    RTS
h_on:                   ; A8: brightness from the game's shadow, NMI back on ($81 = NMI + auto-joypad)
    LDA $01CC : STA $2100
    LDA $4210
    LDA #$81 : STA $4200
    RTS
h_wait:                 ; A8: one frame while the overlay is up. Right after the NMI (still in vblank) force HDMA
    LDA #$38            ; back to our channel 6 only: the NMI ORs effect channels into $0831 (e.g. C0:7E1C) and
    JSL help_wait       ; writes $420C from it, which would run a stage's scroll wave under the overlay
    LDA #$40 : STA $0831 : STA $420C
    ; fall through: L+R held -> X/A/Y/B labels show the L+R+button DX options (help_lr), released -> back
h_lr:                   ; A8 X16, DB 0. Map rows 3..10, columns 18..31 (8 x 14 words), only on a change, in the
    LDA $0083           ; next vblank (one NMI is skipped, like h_off). The game is frozen here, so L+R+button
    AND #$30            ; never reaches asm/options.asm combo; L+R also hide Select/Start, so the overlay can only
    CMP #$30            ; close with L+R released (combo then sees no held combo and syncs its prev)
    BEQ +
    LDA #$00
+   CMP.l !H+69
    BNE .go
    RTS
.go:
    STA.l !H+69
    PHY
    LDA #$01 : STA $4200 ; the joypad read ends after vblank, so: NMI off, wait for the next vblank, copy there
-   BIT $4212
    BMI -
-   BIT $4212
    BPL -
    LDA #$80 : STA $2115
    LDA #$01 : STA $4370
    LDA #$18 : STA $4371
    LDA.b #help_lr>>16 : STA $4374
    REP #$20
    LDA.l !H+69
    AND #$00FF
    BEQ +
    LDA.w #help_lr+36
    BRA ++
+   LDA.l !H+67
    CLC
    ADC.w #(3*64)+36
++  STA.l !H+71
    LDA.w #!HMAP+(3*32)+18
    STA.l !H+73
    LDY #$0008
-   LDA.l !H+73 : STA $2116 : CLC : ADC #$0020 : STA.l !H+73
    LDA.l !H+71 : STA $4372 : CLC : ADC #$0040 : STA.l !H+71
    LDA #$001C : STA $4375
    SEP #$20
    LDA #$80 : STA $420B
    REP #$20
    DEY
    BNE -
    SEP #$20
    LDA $4210            ; clear the pending NMI flag, NMI + auto-joypad back on (next NMI next frame)
    LDA #$81 : STA $4200
    PLY
    RTS
h_rel:                  ; A8: wait until Select and Start are both up
-   JSR h_wait
    LDA $0082
    AND #$30
    BNE -
    RTS

help_maps: dw help_map, help_map+$700, help_map+$E00
help_pal:  ; per character: 0 background, 1 white, 2 black, 3 grey | 5 yellow (palette 1) | 9 cyan (palette 2: L+R view)
    dw $3461, $7FFF, $0000, $5294, $3461, $13FF, $0000, $0C63, $3461, $7FE0, $0000, $0C63   ; Hornisse: deep blue
    dw $1121, $7FFF, $0000, $5294, $1121, $13FF, $0000, $0C63, $1121, $7FE0, $0000, $0C63   ; Sara: dark green (matches her green PENTA DRAGON ending logo)
    dw $1C2D, $7FFF, $0000, $5294, $1C2D, $13FF, $0000, $0C63, $1C2D, $7FE0, $0000, $0C63   ; Ryo: deep crimson-magenta (matches his pink ending logo)
help_chr:  incbin "../build/gen/help_chr.bin"
help_map:  incbin "../build/gen/help_map.bin"
help_hdma: incbin "../build/gen/help_hdma.bin"
help_lr:   incbin "../build/gen/help_lr.bin"   ; L+R labels: 8 rows x 64 bytes (rows 3..10) (columns 18..31 used)
assert (help_map&$FF0000) == ((help_lr+$1FF)&$FF0000), "help data crosses a bank"
!hn = 0

; ----- shadows for write-only PPU regs: each "LDA #imm / STA $21xx" becomes "JSL tramp / NOP" -----
macro hsh(site, imm, reg, sh)
    pushpc
    assert read1(<site>-2) == $A9 && read1(<site>-1) == <imm> && read1(<site>) == $8D && read2(<site>+1) == <reg>, "help shadow site <site> changed"
    org <site>-2
        JSL hsh_!hn
        NOP
    pullpc
hsh_!hn: db $A9,<imm>        ; same width as the original (8-bit immediate)
    STA <reg>
    STA.l <sh>
    RTL
    !hn #= !hn+1
endmacro
%hsh($C000BD,$09,$2105,!HS+0)
%hsh($C00335,$09,$2105,!HS+0)
%hsh($C064B5,$09,$2105,!HS+0)
%hsh($C064DD,$09,$2105,!HS+0)
%hsh($C0DEF6,$01,$2105,!HS+0)
%hsh($C0F428,$01,$2105,!HS+0)
%hsh($CE322D,$03,$2105,!HS+0)
%hsh($CE4A8E,$01,$2105,!HS+0)
%hsh($CE4E3B,$09,$2105,!HS+0)
%hsh($CE4FA9,$01,$2105,!HS+0)
%hsh($D4FB52,$01,$2105,!HS+0)
%hsh($C000D1,$38,$2109,!HS+2)
%hsh($C0034A,$38,$2109,!HS+2)
%hsh($C05179,$38,$2109,!HS+2)
%hsh($C0653F,$38,$2109,!HS+2)
%hsh($C0DEF1,$04,$2109,!HS+2)
%hsh($C0F42D,$38,$2109,!HS+2)
%hsh($CE4A7A,$58,$2109,!HS+2)
%hsh($D4FB64,$04,$2109,!HS+2)
%hsh($C000E0,$00,$210C,!HS+4)
%hsh($C00354,$00,$210C,!HS+4)
%hsh($C01D3F,$00,$210C,!HS+4)
%hsh($C05110,$00,$210C,!HS+4)
%hsh($C0539D,$01,$210C,!HS+4)
%hsh($C05402,$00,$210C,!HS+4)
%hsh($C06544,$11,$210C,!HS+4)
%hsh($C0DEEC,$00,$210C,!HS+4)
%hsh($C0F432,$00,$210C,!HS+4)
%hsh($CE4A6B,$05,$210C,!HS+4)
%hsh($D4FB6E,$00,$210C,!HS+4)
%hsh($CE3263,$AA,$2124,!HS+6)
; C0:1D84 STA $2109 is a branch target (LDA #$39 / BRA / LDA #$3A): patch STA + PLP instead, back to its RTS
assert read4($C01D84) == $2821098D && read1($C01D88) == $60, "help shadow site C01D84 changed"
pushpc
org $C01D84
    JML h1d84
pullpc
h1d84:
    STA $2109
    STA.l !HS+2
    PLP
    JML $C01D88
; STA/STZ $2123 + $2124 pairs (A or 0): 6 bytes -> JSL + 2 NOPs
assert read4($C00154) == $8D21238D && read2($C00158) == $2124, "help shadow site C00157 changed"
assert read4($C0036F) == $9C21239C && read2($C00373) == $2124, "help shadow site C00372 changed"
assert read4($D4FB97) == $9C21239C && read2($D4FB9B) == $2124, "help shadow site D4FB9A changed"
pushpc
org $C00154 : JSL h0157 : NOP #2
org $C0036F : JSL h0372 : NOP #2
org $D4FB97 : JSL h0372 : NOP #2
pullpc
h0157:
    STA $2123
    STA $2124
    STA.l !HS+6
    RTL
h0372:
    STZ $2123
    STZ $2124
    PHP
    SEP #$20
    PHA
    LDA #$00
    STA.l !HS+6
    PLA
    PLP
    RTL
