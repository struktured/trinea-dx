; struktured labs boot splash (ported from River City Ransom SNES,
; snes/branding_splash.asm; same art, palette conversion and window reveal).
; Runs once at power-on/reset before Trinea's own boot. Start skips it.
; Uses no game RAM besides the stack; VRAM/CGRAM/DMA are cleared before handoff,
; and Trinea's reset then initialises everything itself.
hirom
!SPL_EDGE = $1FF1

org $C0FF03
    jml splash_entry          ; was JML $C00087 (after SEI/CLC/XCE)

org $E80000
splash_entry:
    rep #$38
    lda #$0000 : tcd
    sep #$20
    ldx #$1FFF : txs
    lda #$00 : pha : plb
    lda #$80 : sta $2100
    stz $4200 : stz $420B : stz $420C : stz $420D
    stz $212C : stz $212D : stz $2130 : stz $2131
    lda #$04 : sta $2133
    lda #$03 : sta $2105
    stz $2106 : stz $210B : stz $210C
    lda #$70 : sta $2107
    stz $210D : stz $210D : stz $210E : stz $210E
    stz $2124 : stz $2125 : stz $2126 : stz $2127
    stz $2128 : stz $2129 : stz $212A : stz $212B
    lda #$03 : sta $2123
    lda #$01 : sta $212C : sta $212D : sta $212E : sta $212F
    lda #$80 : sta $2115
    ldx #$0000 : stx $2116
    ldx.w #spl_tiles : ldy.w #spl_tiles_end-spl_tiles : jsr spl_dma
    ldx #$7000 : stx $2116
    ldx.w #spl_map : ldy #$0800 : jsr spl_dma
    stz $2121 : stz $4300
    lda #$22 : sta $4301
    ldx.w #spl_pal : stx $4302
    lda.b #spl_pal>>16 : sta $4304
    ldx #$0200 : stx $4305
    lda #$01 : sta $420B
    lda #$01 : sta $4200      ; auto-joypad only (no NMI) so Start can skip
    stz !SPL_EDGE
    jsr spl_vblank
    lda #$0F : sta $2100
.reveal:
    jsr spl_vblank
    jsr spl_start : bne .done
    lda !SPL_EDGE : cmp #$FC : beq .hold
    clc : adc #$04
    sta !SPL_EDGE : sta $2127
    bra .reveal
.hold:
    lda #$FF : sta $2127
    ldx.w #180                 ; 3 s at 60 Hz
.hf:
    jsr spl_vblank
    jsr spl_start : bne .done
    dex : bne .hf
.done:
    lda #$80 : sta $2100
    stz $4200
    stz $212C : stz $212D : stz $2123 : stz $212E : stz $212F
    stz $2126 : stz $2127
    stz $2105 : stz $2107
    stz $210D : stz $210D : stz $210E : stz $210E
    ldx #$0000 : stx $2116
    lda #$09 : sta $4300
    lda #$18 : sta $4301
    ldx.w #spl_zero : stx $4302
    lda.b #spl_zero>>16 : sta $4304
    ldx #$0000 : stx $4305
    lda #$01 : sta $420B
    stz $2121
    lda #$08 : sta $4300
    lda #$22 : sta $4301
    ldx #$0200 : stx $4305
    lda #$01 : sta $420B
    ldx #$0000
.cd: stz $4300,x : inx : cpx #$0010 : bne .cd
    stz !SPL_EDGE
    jml $C00087               ; Trinea's original reset (CLC/XCE again is harmless)

spl_vblank:
    lda $4212 : bmi spl_vblank
.w: lda $4212 : bpl .w
    rts
spl_start:                    ; Z clear if Start pressed on pad 1
.a: lda $4212 : lsr : bcs .a  ; wait for auto-joypad read to finish
    lda $4219 : and #$10
    rts
spl_dma:
    lda #$01 : sta $4300
    lda #$18 : sta $4301
    lda.b #spl_tiles>>16 : sta $4304
    stx $4302 : sty $4305
    lda #$01 : sta $420B
    rts
spl_zero: db $00
spl_pal: incbin "splash/splash-palette.bin"
spl_map: incbin "splash/splash-map.bin"
spl_tiles: incbin "splash/splash-tiles.bin"
spl_tiles_end:
