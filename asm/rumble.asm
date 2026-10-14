;; Trinea DX - optional RumbleShock rumble (Limited Run Games "SNES Rumble" protocol), port 1 only.
;; Built only by `tools/build.sh --rumble` (asm/main_rumble.asm); the standard translation patch never includes it.
;;
;; Protocol (as decoded by Mesen2 2.1.1 SnesRumbleController and the MiSTer SNES core): after the pad read,
;; 16 bits MSB first on port-1 IOBit (WRIO $4201 bit 6), each bit written and then clocked by one $4016 read.
;; Byte 1 = $72 (sentry), byte 2 = level: high nibble = strong (large) motor, low nibble = weak motor, 0-15.
;; WRIO bit 7 (PPU counter latch / port-2 IOBit) is 1 on every write and WRIO is left at $FF.
;; A normal pad has no pin-6 line, so the extra writes/reads are invisible to it.
;;
;; Non-blocking: the game's own joypad routine ($C0:04F8, auto-joypad, reads $4218/$421A) runs unchanged every
;; frame; this code only appends one 16-clock packet after it (~350 cycles) while a pulse runs, plus two
;; "off" packets when it ends (emulators keep the last level; MiSTer clears it at every latch).
;; Envelopes are per-frame level lists (tapered, short); a new event replaces the running one when its rank is
;; >= the running one's.

!R      = $7ECF00           ; 16 bytes; $7F:D000+ is the game's collision map (was wrongly used before)
!R_POS  = !R+0              ; offset of the next level in rum_env (0 = idle)
!R_RANK = !R+1              ; rank (= event id) of the running pulse
!R_OFF  = !R+2              ; off packets still to send
!R_SIG  = !R+3              ; 2 bytes, $A5 $5A once initialised (power-on RAM is garbage)
!R_CNT  = !R+5              ; pulses started (mod 256, for tests)
!R_EV   = !R+6              ; last event started (tests)
!R_LAST = !R+7              ; level of the last packet sent (tests)
!R_BIGX = !R+8              ; 2 bytes, object of the last big enemy (boss) hit
!BIG_HP = 33                ; enemies with >= this HP count as bosses (normal enemies have <= 32)
!WRIO   = $004201
!JOY0   = $004016

;; ---- events (id = priority rank) ----
!EV_EHIT  = 1               ; player's attack hits a normal enemy
!EV_MAGIC = 2               ; player uses a special move (magic)
!EV_EKILL = 3               ; player kills a normal enemy
!EV_HURT  = 4               ; player takes damage (1-3)
!EV_HURT2 = 5               ; player takes heavy damage (4+)
!EV_BHIT  = 6               ; boss (part) hit / big enemy (HP >= 33) hit
!EV_BKILL = 7               ; boss (part) / big enemy destroyed
!EV_DEATH = 8               ; player dies

macro rum(ev)
    php
    rep #$30
    pha
    phx
    phy
    sep #$30
    lda #<ev>
    jsr rum_start
    rep #$30
    ply
    plx
    pla
    plp
endmacro

;; ================= hooks into the original code =================
org $C00531                 ; joypad routine tail: STA $14A9 / PLP / RTS
    jml rum_frame

org $C101A6                 ; player hurt (normal path): SEP #$20 / SEC / SBC $10BD -> JML back to $C101AC
    jml h_hurt
org $C1015A                 ; player death (normal path): LDA #$01 / STA $10B6
    jsl h_death
    nop
org $C0789F                 ; player hurt (alt. damage routine $C0:7877): SEP #$20 / STA $10B6
    jsl h_hurt_alt
    nop
org $C078A6                 ; player death (alt.): SEP #$20 / LDA #$01 / STA $10B6
    jsl h_death_alt
    nop : nop : nop
org $C14419                 ; enemy damaged (routine $C1:43E1): SEC / SBC $002A / STA $001F,x
    jsl h_ehit
    nop : nop : nop
org $C14403                 ; enemy killed: LDA #$01 / STA $0040,x
    jsl h_ekill
    nop
org $C09B09                 ; special move, routine A: DEC $10B8 / STZ $9B
    jsl h_magic_a
    nop
org $C0BAC6                 ; special move, routine B: DEC $10B8 / LDA #$42
    jsl h_magic_b
    nop
org $C0D0A3                 ; special move, routine C: DEC $10B8 / REP #$20
    jsl h_magic_c
    nop
org $D4F465                 ; boss part 1 hit (generic boss handler, HP $0900,x): STA $0900,x / SEP #$20
    jsl h_bhit_d4
    nop
org $D4F4C7                 ; boss part 2 hit
    jsl h_bhit_d4
    nop
org $D4F474                 ; boss part 1 destroyed: REP #$20 / LDA #$0000
    jsl h_bkill_d4
    nop
org $D4F4D6                 ; boss part 2 destroyed
    jsl h_bkill_d4
    nop
org $C86965                 ; bank-C8 boss hit (HP $0B00): STA $0B00 / LDA #$0005
    jsl h_bhit_c8
    nop : nop
org $C8697A                 ; bank-C8 boss destroyed: STZ $0B00 / LDA #$0012
    jsl h_bkill_c8
    nop : nop

;; ================= new code (bank $E7, free) =================
org $E70000
rum_frame:                  ; A16 here, X/Y width unknown; DB = game's
    sta $14A9
    php
    rep #$30
    pha
    phx
    phy
    sep #$30
    jsr rum_tick
    rep #$30
    ply
    plx
    pla
    plp
    plp                     ; the game's own PLP (replaced)
    jml $C00535             ; RTS

rum_init:
    lda #0
    sta.l !R_POS
    sta.l !R_RANK
    sta.l !R_OFF
    sta.l !R_CNT
    sta.l !R_EV
    sta.l !R_LAST
    sta.l !R_BIGX
    sta.l !R_BIGX+1
    lda #$A5
    sta.l !R_SIG
    lda #$5A
    sta.l !R_SIG+1
    rts

rum_check:                  ; Z set = state valid
    lda.l !R_SIG
    cmp #$A5
    bne +
    lda.l !R_SIG+1
    cmp #$5A
+   rts

rum_tick:                   ; A8 X8
    jsr rum_check
    beq +
    jmp rum_init
+   lda.l !R_POS
    tax
    lda.l rum_env,x
    beq .idle
    inx
    txa
    sta.l !R_POS
    lda.l rum_env-1,x
    jsr send_pkt
    lda #2
    sta.l !R_OFF
    rts
.idle:
    lda #0
    sta.l !R_POS
    sta.l !R_RANK
    lda.l !R_OFF
    beq .done
    dec
    sta.l !R_OFF
    lda #0
    jmp send_pkt
.done:
    rts

send_pkt:                   ; A = level
    sta.l !R_LAST
    pha
    lda #$72
    jsr send8
    pla
    jsr send8
    lda #$FF
    sta.l !WRIO
    rts
send8:                      ; MSB first; WRIO bit 7 always 1
    ldy #8
-   asl
    tax
    lda #$80
    bcc +
    lda #$C0
+   sta.l !WRIO
    lda.l !JOY0             ; clock one bit
    txa
    dey
    bne -
    rts

rum_start:                  ; A = event (A8 X8)
    pha
    jsr rum_check
    beq +
    jsr rum_init
+   pla
    tay
    lda.l !R_POS
    tax
    lda.l rum_env,x
    beq .take               ; idle
    tya
    cmp.l !R_RANK
    bcc .skip
.take:
    tya
    sta.l !R_RANK
    sta.l !R_EV
    tyx
    lda.l rum_start_tbl,x
    sta.l !R_POS
    lda.l !R_CNT
    inc
    sta.l !R_CNT
.skip:
    rts

;; ---- hooks ----
h_hurt:                     ; A = life (8-bit after SEP)
    sep #$20
    pha
    lda $10BD               ; pending damage
    cmp #4
    bcs .heavy
    %rum(!EV_HURT)
    bra .go
.heavy:
    %rum(!EV_HURT2)
.go:
    pla
    sec
    sbc $10BD
    jml $C101AC

h_death:
    %rum(!EV_DEATH)
    lda #$01
    sta $10B6
    rtl

h_hurt_alt:                 ; A16 = new life
    sep #$20
    %rum(!EV_HURT)
    sta $10B6
    rtl

h_death_alt:
    sep #$20
    %rum(!EV_DEATH)
    lda #$01
    sta $10B6
    rtl

h_ehit:                     ; A8 = enemy HP before the hit, X16 = enemy object
    php
    rep #$30
    pha
    phx
    phy
    sep #$20
    cmp #!BIG_HP
    bcc +
    rep #$20                ; remember the big enemy (boss) object
    txa
    sta.l !R_BIGX
    sep #$20
    bra .boss
+   jsr is_big
    beq .boss
    sep #$30
    lda #!EV_EHIT
    bra .go
.boss:
    sep #$30
    lda #!EV_BHIT
.go:
    jsr rum_start
    rep #$30
    ply
    plx
    pla
    plp
    sec
    sbc $002A
    sta $001F,x
    rtl

h_ekill:                    ; X16 = enemy object
    php
    rep #$30
    pha
    phx
    phy
    sep #$20
    jsr is_big
    bne +
    lda #0
    sta.l !R_BIGX
    sta.l !R_BIGX+1
    sep #$30
    lda #!EV_BKILL
    bra .go
+   sep #$30
    lda #!EV_EKILL
.go:
    jsr rum_start
    rep #$30
    ply
    plx
    pla
    plp
    lda #$01
    sta $0040,x
    rtl

is_big:                     ; X16: Z set when X == remembered big-enemy object (returns A8)
    rep #$20
    txa
    cmp.l !R_BIGX
    sep #$20
    rts

h_magic_a:
    %rum(!EV_MAGIC)
    dec $10B8
    stz $9B
    rtl

h_magic_b:
    %rum(!EV_MAGIC)
    dec $10B8
    lda #$42
    rtl

h_magic_c:
    dec $10B8
    %rum(!EV_MAGIC)
    rep #$20
    rtl

h_bhit_d4:                  ; A16
    sta $0900,x
    sep #$20
    %rum(!EV_BHIT)
    rtl

h_bkill_d4:
    %rum(!EV_BKILL)
    rep #$20
    lda.w #$0000
    rtl

h_bhit_c8:                  ; A16
    sta $0B00
    %rum(!EV_BHIT)
    lda.w #$0005
    rtl

h_bkill_c8:
    stz $0B00
    %rum(!EV_BKILL)
    lda.w #$0012
    rtl

;; ================= envelope table: tune here =================
;; One byte per frame (60 Hz): $SW = strong motor S (0-15), weak motor W (0-15). A $00 byte ends the pulse.
rum_env:
    db $00                                              ; idle
.ehit:   db $04,$03,$00                                 ; light tap, weak motor only
.magic:  db $13,$24,$35,$46,$57,$57,$57,$46,$35,$24,$13,$12,$00  ; swell and fade
.ekill:  db $64,$53,$42,$31,$00                         ; short tapered thump
.hurt:   db $96,$85,$63,$42,$21,$00                     ; jolt
.hurt2:  db $C8,$B7,$96,$74,$53,$32,$21,$00             ; heavy jolt
.bhit:   db $75,$64,$43,$22,$00                         ; boss hit
.bkill:  db $FF,$FF,$EE,$DD,$CC,$BB,$AA,$99,$88,$77,$66,$55,$44,$33,$22,$11,$00   ; boss destroyed
.death:  db $FC,$EB,$DA,$C9,$B8,$A7,$96,$85,$74,$63,$52,$41,$31,$21,$11,$00       ; player down
rum_start_tbl:
    db 0
    db rum_env_ehit-rum_env, rum_env_magic-rum_env, rum_env_ekill-rum_env, rum_env_hurt-rum_env
    db rum_env_hurt2-rum_env, rum_env_bhit-rum_env, rum_env_bkill-rum_env, rum_env_death-rum_env
rum_end:
assert rum_start_tbl-rum_env < 256, "envelope table too large"
