hirom
; ===== Trinea DX options (beta): runtime toggles stored in unused SRAM tail =====
; SRAM $30:6300 'T', $6301 'D', $6302 opts, $6303 opts^$A5   (invalid -> all OFF = original)
;   opts bit0 turbo (20 Hz logic), bits1-2 hero speed (0 orig, 1 = 5px-equiv, 2 = 6px-equiv), bit3 faster monsters,
;   bit4 RETIRED (was rumble off in afb92e1a/2339e2b8; ignored so saves that toggled it get rumble back),
;   bit5 rumble off (read by asm/rumble.asm rum_muted), bit6 Start-skips-dialogue off (asm/skip.asm),
;   bit7 RETIRED (was Select help overlay off via L+R+Start; ignored so saves that set it still get the overlay)
; scratch (prev buttons, feedback ticks, saved mosaic, raw pad) lives in WRAM !W+4..+11, not SRAM: SRAM is only read when
; the WRAM cache is invalid and only written when a toggle changes (issue #4 real-hardware hardening)
!S = $306300
!W = $7ECF10      ; WRAM cache/scratch (hw fix #4): +0 $A5 = cache valid, +1 opts, +2 sig valid, +3 opts^$5A (cache check), +4..+11 pad/feedback scratch

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
; --- joypad read (replaces perf_joy target): keep raw pad in SRAM scratch, hide face buttons/Select from the game while L+R held (Start passes through: L+R+Start = plain pause)
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
getopt:            ; A8 in/out: A = opts (0 if signature invalid). SRAM is read only when the WRAM cache is invalid
    LDA.l !W         ; cache valid only if +0 = $A5 AND +3 = opts^$5A: power-on WRAM is not zeroed on real
    CMP #$A5         ; hardware (MiSTer fills a pattern), so a lone $A5 marker could accept garbage opts
    BNE .load
    LDA.l !W+1
    EOR #$5A
    CMP.l !W+3
    BNE .load
    LDA.l !W+1
    RTL
.load:
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
    STA.l !W+1
    LDA #$01
    BRA .fin
.z: LDA #$00
    STA.l !W+1
.fin:
    STA.l !W+2
    LDA.l !W+1
    EOR #$5A
    STA.l !W+3
    LDA #$A5
    STA.l !W
    LDA.l !W+1
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

sarachk:           ; A8; carry set -> do one extra step this tick. Any hero (was Sara only): step $0825 is 4 px
    LDA $0825        ; (Sara, Hornisse) or 8 px (Ryo); the extra step is the hero's own step size, so the boost is the
    CMP #$04         ; same +25/+50 % for everyone and the 4/8 px grid alignment and collision chain are unchanged
    BEQ +
    CMP #$08
    BNE .no
    LDA $0069        ; Ryo (8 px step): a doubled 8 px step outruns the BG column streamer on scrolling maps
    CMP.l !W+12      ; (garbled columns), so no extra step while the camera ($0069) moved since the last check
    STA.l !W+12      ; ($7ECF1C, free; STA keeps Z)
    BNE .no
+
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
    SEC              ; exact original exit flags: REP #$20 / CMP #$0000 leaves C=1
    RTL

; --- L+R held, then X = turbo, Y = hero speed, A = monsters, B = rumble off. Feedback: mosaic blinks (setting value + 1 blinks)
combo:
    PHP
    SEP #$20
if defined("HAS_SKIP")
    JSL sk_field            ; field tick: no script running -> skip mode off, Start edge tracker synced
endif
    ; current relevant buttons (only while L+R held): bit7 A, bit6 X, bit5 Y, bit4 B
    LDA.l !W+10
    AND #$30
    CMP #$30
    BEQ +
    LDA #$00
    BRA ++
+   LDA.l !W+11
    AND #$40
    LSR
    STA.l !W+8
    LDA.l !W+11      ; B -> bit4 (rumble off)
    AND #$80
    LSR
    LSR
    LSR
    ORA.l !W+8
    STA.l !W+8
    LDA.l !W+11      ; Select -> bit3 (dialogue skip off)
    AND #$20
    LSR
    LSR
    ORA.l !W+8
    STA.l !W+8
    LDA.l !W+10
    AND #$C0
    ORA.l !W+8
++  PHA
    JSL getopt
    STA.l !W+9
    ; signature valid? (cached by getopt above) if not and no new press, nothing else to do
    LDA.l !W+2
    BNE .sig
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
    STA.l !W+4
    STA.l !W+5
    LDA #$A5
    STA.l !S+3
    LDA #$00
    STA.l !W+9
    STA.l !W          ; invalidate cache
.sig:
    PLA
    PHA
    EOR.l !W+4        ; new presses = cur & ~prev
    AND $01,s
    STA.l !W+8
    PLA
    STA.l !W+4
    LDA.l !W+8
    BIT #$40
    BEQ +
    LDA.l !W+9
    EOR #$01
    STA.l !W+9
    AND #$01
    BRL .set
+   LDA.l !W+8
    BIT #$20
    BEQ +
    LDA.l !W+9
    LSR
    AND #$03
    INC
    CMP #$03
    BCC ++
    LDA #$00
++  PHA
    ASL
    STA.l !W+8
    LDA.l !W+9
    AND #$F9
    ORA.l !W+8
    STA.l !W+9
    PLA
    BRA .set
+   LDA.l !W+8
    BIT #$80
    BEQ .bchk
    LDA.l !W+9
    EOR #$08
    STA.l !W+9
    LSR
    LSR
    LSR
    AND #$01
    BRA .set
.bchk:
    LDA.l !W+8
    BIT #$10
    BEQ .schk
    LDA.l !W+9
    AND #$EF          ; drop the retired bit4 (old rumble-off) on any rumble toggle
    EOR #$20          ; rumble off is bit5 now
    STA.l !W+9
    LSR
    LSR
    LSR
    LSR
    LSR
    AND #$01
    BRA .set
.schk:
    LDA.l !W+8
    BIT #$08
    BEQ .fb
    LDA.l !W+9
    EOR #$40          ; bit6 = Start-skips-dialogue OFF
    STA.l !W+9
    ASL
    ASL
    LDA #$00
    ROL               ; A = bit6
    BRA .set
.set:               ; A = displayed value (0..2)
    INC
    ASL
    ASL
    ASL             ; blinks*8 ticks
    PHA
    LDA.l !W+5
    BNE +
    LDA $00B4
    STA.l !W+6
+   PLA
    STA.l !W+5
    LDA.l !W+9
    STA.l !S+2
    EOR #$A5
    STA.l !S+3
    LDA #$00
    STA.l !W          ; invalidate cache (re-read SRAM once)
.fb:                ; feedback mosaic
    LDA.l !W+5
    BEQ .done
    DEC
    STA.l !W+5
    BEQ .rest
    AND #$04
    BEQ .rest
    LDA #$FF
    STA $00B4
    BRA .done
.rest:
    LDA.l !W+6
    STA $00B4
.done:
    PLP
    RTL

joy:
    PHP
    SEP #$20
-   LDA $4212        ; hardware-safety fix: wait for VBlank END like the original game (not just auto-joypad
    BMI -            ; busy): keeps the original NMI timing (main thread never runs inside VBlank, rumble's
                     ; manual $4016 clocking never overlaps auto-joypad) - suspected cause of real-hw freezes
    LDA $4219
    STA.l !W+11
    STA $0082
    LDA $4218
    STA.l !W+10
    STA $0083
    AND #$30
    CMP #$30
    BNE +
    STA $0083
    LDA $0082
    AND #$1F          ; keep Start (bit4) and the d-pad; hide B/Y/Select
    STA $0082
+   JML $C0050C
