; struktured labs boot splash (ported from River City Ransom SNES,
; snes/branding_splash.asm; same art, palette conversion and window reveal).
; Runs once at power-on/reset before Trinea's own boot. Start skips it.
; Uses no game RAM besides the stack; VRAM/CGRAM/DMA are cleared before handoff,
; and Trinea's reset then initialises everything itself.
hirom
!SPL_EDGE = $1FF1
!SPL_SND = $1FF2   ; curve frames sent
!SPL_SEQ = $1FF3
!SPL_ERR = $1FF4   ; 0 ok, EE upload failed, ED IPL not back (game reset clears WRAM)

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
    stz !SPL_SND : stz !SPL_SEQ : stz !SPL_ERR
    jsr spl_upload             ; ident SPC program; C set = no APU response
    bcc +
    lda #$EE : sta !SPL_ERR
+   ldx #$0000                 ; X = curve offset for the whole splash
    jsr spl_vblank
    lda #$0F : sta $2100
.reveal:
    jsr spl_vblank
    jsr spl_send
    jsr spl_start : bne .done
    lda !SPL_EDGE : cmp #$FC : beq .hold
    clc : adc #$04
    sta !SPL_EDGE : sta $2127
    bra .reveal
.hold:
    lda #$FF : sta $2127
    ldy.w #200                 ; ~3.3 s at 60 Hz (ident curve is 240 frames from reveal start)
.hf:
    jsr spl_vblank
    jsr spl_send
    jsr spl_start : bne .done
    dey : bne .hf
.done:
    lda #$80 : sta $2100
    lda !SPL_ERR : bne .noapu  ; never uploaded: APU is still at IPL
    lda #$FF : sta $2142       ; key off, mute, SPC jumps back to IPL ($FFC0)
    jsr spl_wait_ipl
    bcc .noapu
    lda #$ED : sta !SPL_ERR
.noapu:
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
    stz !SPL_EDGE : stz !SPL_SND : stz !SPL_SEQ
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
spl_send:                     ; one curve step per VBlank (pitch lo/hi, volume), sequence last
    lda !SPL_ERR : bne .r
    lda !SPL_SND : cmp #240 : bcs .r
    lda.l spl_curve,x : sta $2140
    lda.l spl_curve+1,x : sta $2141
    lda.l spl_curve+2,x : sta $2143
    inc !SPL_SEQ : lda !SPL_SEQ : sta $2142
    inx : inx : inx
    inc !SPL_SND
.r: rts
spl_wait_port0:               ; wait until $2140 == A (bounded)
    ldy #$FFFF
.p: cmp $2140 : beq .ok
    dey : bne .p
    sec : rts
.ok: clc : rts
spl_wait_ipl:
    ldy #$FFFF
.p: lda $2140 : cmp #$AA : bne .n
    lda $2141 : cmp #$BB : beq .ok
.n: dey : bne .p
    sec : rts
.ok: clc : rts
spl_upload:                   ; standard IPL transfer to $0200, then execute it
    jsr spl_wait_ipl : bcs .ret
    ldx #$0200 : stx $2142
    lda #$01 : sta $2141
    lda #$CC : sta $2140
    jsr spl_wait_port0 : bcs .ret
    ldx #$0000
.s: lda.l spl_spc,x : sta $2141
    txa : sta $2140
    jsr spl_wait_port0 : bcs .ret
    inx : cpx.w #spl_spc_end-spl_spc : bne .s
    stz $2141
    ldy #$0200 : sty $2142
    inx : inx
    txa : sta $2140
    lda #$55                   ; (RCR waits for the ident program's ready ack)
    jsr spl_wait_port0
.ret: rts
spl_zero: db $00
spl_curve: incbin "splash/splash-ident-curve.bin"
spl_spc: incbin "splash/splash-ident-spc.bin"
spl_spc_end:
spl_pal: incbin "splash/splash-palette.bin"
spl_map: incbin "splash/splash-map.bin"
spl_tiles: incbin "splash/splash-tiles.bin"
spl_tiles_end:
