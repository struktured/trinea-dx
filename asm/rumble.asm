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
                            ; !R+10 = rum_limit scratch
!R_ZAP  = !R+11             ; Vampierre zap: frames left (0 = off; set/cleared by asm/skip.asm op-39 hook)
!R_ZAPI = !R+12             ; zap pattern index
!R_ON   = !R+13             ; consecutive frames with a non-zero (non-zap) packet
!R_CD   = !R+14             ; cooldown frames after the hard cap: new events ignored
!R_WD   = !R+15             ; NMI watchdog: frames since the last rum_tick
;; Pulse-forever guard (2026-10-23, Sara run on rivalmage pulsing 60 on / 30 off without end): the cap's cooldown
;; simply expired after 30 frames, so a condition that re-arms every frame (multi-hit shot / hazard / contact hit
;; re-entering the hit routine each frame) restarted the cycle forever. Now (1) an event of the same rank no longer
;; restarts a running pulse (one shot per event), (2) the cooldown is re-armed by every event that arrives during it,
;; so it only ends once the triggering condition has been quiet for !RUM_CDN frames, and (3) a leaky bucket (+2 per
;; rumbling frame, -1 per frame) trips the same suppression once rumble has been on for > ~2 s net in a short window.
!R_ACC  = $7ECF1E           ; leaky bucket (free byte after the options scratch !W = $7ECF10..1B)
!RUM_ACC = 240              ; bucket limit (= 120 frames net rumble)
!RUM_CAP = 60               ; hard max continuous rumble (frames), except the scripted zap
!RUM_CDN = 30               ; cooldown after the cap trips
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

macro clrb()                ; B = 0, A kept (M8)
    xba
    lda #$00
    xba
endmacro

macro rum(ev)
    php
    rep #$30
    pha
    phx
    phy
    rep #$10 : sep #$20     ; X16 always: the game NMI inherits X width (C0:6BC3 LDX #$0002 -> BRK under X8)
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

;; NMI watchdog: the NMI handler runs every frame, the pad routine (and so rum_tick) does not - loading, scene
;; changes, message/cutscene loops that read the pad themselves. A pulse cut by such a gap left the RumbleShock at
;; its last level until the pad routine ran again (seen on MiSTer as 10s+ of rumble that stopped on Start).
org $C003C7                 ; NMI: INC $01C9 / LDA #$0000 (A16), then TCD
    jsl rum_nmi
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
    rep #$10 : sep #$20     ; X16 always: the game NMI inherits X width (C0:6BC3 LDX #$0002 -> BRK under X8)
    jsr rum_tick
    rep #$30
    ply
    plx
    pla
    plp
    plp                     ; the game's own PLP (replaced)
    jml $C00535             ; RTS

rum_nmi:                    ; A16, X/Y unknown, DB/D = game's at NMI entry
    inc $01C9               ; replaced
    php
    rep #$30
    phx
    phy
    rep #$10 : sep #$20     ; X16 always: the game NMI inherits X width (C0:6BC3 LDX #$0002 -> BRK under X8)
    %clrb()
    jsr rum_check
    bne .out
    lda.l !R_WD
    cmp #3
    bcs +
    inc
    sta.l !R_WD
    bra .out
+   lda.l !R_LAST           ; pad routine skipped for 3+ frames: if the motor was left on, stop it now
    ora.l !R_POS
    ora.l !R_ZAP
    beq .out
    lda #0
    sta.l !R_POS
    sta.l !R_RANK
    sta.l !R_ZAP
    sta.l !R_ON
    sta.l !R_OFF
    ldx.w #$0020            ; MiSTer raises $4212.0 up to ~1 line after VBlank starts: wait for the auto-read
                            ; to start (timeout: auto-joypad may be off), then send_pkt waits for it to end
-   lda.l $004212
    lsr
    bcs +
    dex
    bne -
+   lda #$00
    jsr send_pkt            ; off packet (sets R_LAST = 0)
.out:
    rep #$30
    ply
    plx
    plp
    lda #$0000              ; replaced
    rtl

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
    sta.l !R_ZAP
    sta.l !R_ZAPI
    sta.l !R_ON
    sta.l !R_CD
    sta.l !R_WD
    sta.l !R_ACC
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

rum_tick:                   ; A8 X16 (B cleared here: TAX/TAY copy B:A)
    %clrb()
    jsr rum_check
    beq +
    jmp rum_init
+   lda #0
    sta.l !R_WD
    lda.l !R_ACC            ; bucket leak
    beq +
    dec
    sta.l !R_ACC
+
   lda.l !R_CD             ; cooldown after the hard cap
    beq +
    dec
    sta.l !R_CD
+   jsr rum_muted           ; L+R+B option: rumble off (cancel any pulse, finish with off packets)
    beq +
    jmp .idle
+   jsr rum_demo            ; attract/title demo ($F0 != 0): no rumble at all
    beq +
    lda #0
    sta.l !R_ZAP
    jmp .idle
+
    lda.l !R_ZAP            ; Vampierre zap cutscene: crackly strong pulses for as long as the animation runs
    beq +
    dec
    sta.l !R_ZAP
    lda.l !R_ZAPI
    inc
    sta.l !R_ZAPI
    and #$07
    tax
    lda.l zap_pat,x
    jsr send_pkt
    lda #2
    sta.l !R_OFF
    rts
+   lda.l !R_POS
    tax
    lda.l rum_env,x
    beq .idle
    lda.l !R_ON             ; hard cap: an event re-armed every frame (e.g. a lingering hit) must not
    inc                     ; keep the motor on; stop, send off packets, ignore events for a while
    sta.l !R_ON
    cmp #!RUM_CAP
    bcc +
    bra .trip
+   lda.l !R_ACC            ; leaky bucket: +2 now (the -1 runs every frame below)
    clc
    adc #2
    bcs .trip
    cmp #!RUM_ACC
    bcs .trip
    sta.l !R_ACC
    lda.l !R_POS
    tax
    inx
    txa
    sta.l !R_POS
    lda.l rum_env-1,x
    jsr rum_limit
    jsr send_pkt
    lda #2
    sta.l !R_OFF
    rts
.trip:
    lda #0
    sta.l !R_ACC
    lda #!RUM_CDN
    sta.l !R_CD
.idle:
    lda #0
    sta.l !R_ON
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

;; Level shaping (issue #4 follow-up, 2026-10-18). 222499a9 capped strong<=$A / weak<=8 AND soft-started every pulse
;; (first packet halved): the common enemy-hit pulse went out as $23 then $46 (strong 2-4/15), below the duty a RumbleShock
;; motor needs to break stall, so rumble felt weak or absent on the Jr. Now: no soft start (a motor needs a kick, not a ramp),
;; every non-zero frame gets a floor of strong 8 / weak 6 (RCR's felt-on-hardware hits are 8-15), and the cap is
;; strong 12 / weak 10 - still well under the old harsh $FF/$CA peaks.
!RUM_MAXS = $C0             ; strong motor max (high nibble)
!RUM_MAXW = $0A             ; weak motor max (low nibble)
!RUM_MINS = $80             ; strong motor floor for any non-zero level
!RUM_MINW = $06             ; weak motor floor for any non-zero level
rum_limit:                  ; A8 = $SW level (non-zero) -> floored/capped level
    pha
    and #$0F
    cmp #!RUM_MAXW+1
    bcc +
    lda #!RUM_MAXW
+   cmp #!RUM_MINW
    bcs +
    lda #!RUM_MINW
+   sta.l !R+10             ; scratch: weak
    pla
    and #$F0
    cmp #!RUM_MAXS+$10
    bcc +
    lda #!RUM_MAXS
+   cmp #!RUM_MINS
    bcs +
    lda #!RUM_MINS
+   ora.l !R+10
    rts

rum_muted:                  ; A8: Z clear = muted by the options block (bit4)
if defined("HAS_OPTS")
    jsl getopt              ; WRAM-cached opts: no per-frame SRAM access (issue #4 hardening)
    and #$20                ; bit5 = off (bit4 = retired old flag, ignored); invalid/blank block = opts 0 = rumble ON
    rts
else
    lda.l $306300           ; no options module: read the block directly
    cmp #$54
    bne .no
    lda.l $306301
    cmp #$44
    bne .no
    lda.l $306302
    eor #$A5
    cmp.l $306303
    bne .no
    lda.l $306302
    and #$20
    rts
.no:
    lda #0
    rts
endif

send_pkt:                   ; A = level
    sta.l !R_LAST
    pha
-   lda.l $004212           ; never clock $4016 while auto-joypad is still reading (real-hw bus contention;
    lsr                     ; RCR lesson: VBlank before auto-read starts is not "done")
    bcs -
    lda #$01                ; fresh manual latch + 16 read clocks, then the packet, exactly like LRG player.a and
    sta.l !JOY0             ; RCR: the packet is sent ~35 lines after the auto-read latch (pad read waits for VBlank
    nop                     ; end since 6cb019c), so re-latch to put it right after a latch on any pad firmware.
    nop                     ; The game already copied $4218/$4219; auto-joypad is idle (wait above).
    lda #$00
    sta.l !JOY0
    nop
    nop
    ldy.w #16
--  lda.l !JOY0
    dey
    bne --
    lda #$72
    jsr send8
    pla
    jsr send8
    lda #$FF
    sta.l !WRIO
    rts
send8:                      ; MSB first; WRIO bit 7 always 1
    ldy.w #8
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

rum_demo:                   ; A8: Z clear = attract demo running (game demo flag $14F0 = DP $1400 + $F0, as tested by LDA $F0 at C0:F5BA; 1 while the title attract demo plays)
    lda.l $0014F0
    rts

rum_start:                  ; A = event (A8 X16)
    %clrb()
    pha
    jsr rum_demo            ; attract demo: never start a pulse
    bne ++
    lda.l !R_CD             ; suppression: ignore, and keep it up while the condition keeps firing
    beq +
    lda #!RUM_CDN
    sta.l !R_CD
++  pla
    rts
+
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
    beq .skip               ; same event already running: one shot, no restart
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
    rep #$10 : sep #$20     ; X16 always: the game NMI inherits X width (C0:6BC3 LDX #$0002 -> BRK under X8)
    lda #!EV_EHIT
    bra .go
.boss:
    rep #$10 : sep #$20     ; X16 always: the game NMI inherits X width (C0:6BC3 LDX #$0002 -> BRK under X8)
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
    rep #$10 : sep #$20     ; X16 always: the game NMI inherits X width (C0:6BC3 LDX #$0002 -> BRK under X8)
    lda #!EV_BKILL
    bra .go
+   rep #$10 : sep #$20     ; X16 always: the game NMI inherits X width (C0:6BC3 LDX #$0002 -> BRK under X8)
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
;; Hardware tuning (2026-10-16): pulses follow the River City Ransom SNES rumble that was
;; felt on real pads (RCR docs/RUMBLE.md: 8-40 frame pulses at flat levels 6-15). Motors need
;; ~50-100 ms and a level of about 4 or more to spin up, so the old 2-16 frame tapered envelopes
;; (many levels 1-3) were mostly below what a real motor reacts to. Weak (low nibble) is on/off on DualShock.
zap_pat: db $CA,$CA,$86,$CA,$A8,$86,$CA,$96   ; crackle (within caps: strong 8-12, weak 6-10)
rum_env:
    db $00                                              ; idle
.ehit: db $86,$86,$86,$86,$86,$86,$86,$86,$86,$86,$00   ; 10 frames
.magic: db $96,$96,$96,$96,$96,$96,$A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8,$86,$86,$86,$86,$86,$86,$00   ; 24 frames
.ekill: db $C8,$C8,$C8,$C8,$C8,$C8,$C8,$C8,$C8,$C8,$C8,$C8,$A8,$A8,$A8,$A8,$A8,$A8,$86,$86,$86,$86,$00   ; 22 frames
.hurt: db $A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8,$86,$86,$86,$86,$86,$86,$00   ; 16 frames
.hurt2: db $C8,$C8,$C8,$C8,$C8,$C8,$C8,$C8,$C8,$C8,$C8,$C8,$C8,$C8,$A8,$A8,$A8,$A8,$A8,$A8,$86,$86,$86,$86,$00   ; 24 frames
.bhit: db $B8,$B8,$B8,$B8,$B8,$B8,$B8,$B8,$B8,$B8,$96,$96,$96,$96,$96,$96,$00   ; 16 frames
.bkill: db $CA,$CA,$CA,$CA,$CA,$CA,$CA,$CA,$CA,$CA,$CA,$CA,$CA,$CA,$CA,$CA,$CA,$CA,$CA,$CA,$CA,$CA,$CA,$CA,$A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8,$86,$86,$86,$86,$86,$86,$86,$86,$00   ; 40 frames
.death: db $CA,$CA,$CA,$CA,$CA,$CA,$CA,$CA,$CA,$CA,$CA,$CA,$CA,$CA,$CA,$CA,$CA,$CA,$CA,$CA,$A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8,$86,$86,$86,$86,$86,$86,$86,$86,$00   ; 40 frames
rum_start_tbl:
    db 0
    db rum_env_ehit-rum_env, rum_env_magic-rum_env, rum_env_ekill-rum_env, rum_env_hurt-rum_env
    db rum_env_hurt2-rum_env, rum_env_bhit-rum_env, rum_env_bkill-rum_env, rum_env_death-rum_env
rum_end:
assert rum_start_tbl-rum_env < 256, "envelope table too large"
