# RumbleShock rumble (optional DX feature)

Build: `tools/build.sh <Trinea (Japan).sfc> --rumble` creates `build/trinea_dx_rumble.{sfc,ips}`.
`--dx` creates `build/trinea_dx.{sfc,ips}`, which is rumble plus the struktured labs boot splash.
The plain translation `build/trinea_en.ips` is unchanged.

## Protocol
- Port 1, sent just after the game's own auto-joypad read (C00531), so input reading is never delayed.
- Packet: `$72` then a level byte. High nibble = strong motor, low nibble = weak motor.
- 16 bits, MSB first, on WRIO $4201 bit 6, each clocked by a `$4016` read. WRIO is restored to $FF.
- A packet goes out only while a pulse is running, followed by two "off" packets. A normal pad ignores all of this.

## Hooks (code in bank E7, state at $7FDF00 re-initialised by a signature check)

| Event (priority) | Site |
|---|---|
| enemy hit (1) | C14419 |
| magic / X special (2) | C09B09, C0BAC6, C0D0A3 |
| enemy kill (3) | C14403 |
| player hurt (4) / hurt with damage 4 or more (5) | C101A6, C0789F |
| boss hit (6) | C14419 when enemy HP is 33 or more (that enemy is remembered); D4F465/D4F4C7; C86965 |
| boss kill (7) | C14403 for the remembered enemy; D4F474/D4F4D6; C8697A |
| player death (8) | C1015A, C078A6 |

A higher-priority event replaces the pulse already running.

## Envelopes (60 Hz frames; tuned 2026-10-16 to RCR's hardware-felt pulse lengths/levels)

| Event | Pulse |
|---|---|
| enemy hit | $46 x6, $34 x2 (8 frames) |
| magic | $46 x4, $68 x4, $8A x8, $68 x4, $46 x4 (24 frames) |
| enemy kill | $CA x12, $96 x4, $64 x4 (20 frames) |
| hurt | $88 x10, $66 x6 (16 frames) |
| hurt (4+ damage) | $CA x14, $97 x6, $64 x4 (24 frames) |
| boss hit | $AA x10, $77 x6 (16 frames) |
| boss kill | $FF x24, $CC x8, $88 x8 (40 frames) |
| death | $FF x20, $DD x8, $AA x6, $77 x6 (40 frames) |

The earlier envelopes were 2-16 frames long and tapered down to levels 1-3, which a real motor barely reacts to.

## Bus trace, all-in build (Mesen2, $4016/$4201/$4212/$4218 log; 1,731 packet frames)
- **Order every frame:** the auto-joypad read finishes, then the game reads $4218/$4219, then 16 pairs of (WRIO write, $4016 read). It is $72 MSB first, then the level, then WRIO = $FF.
- **Timing:** about 27 CPU cycles per bit. A packet takes about 3 scanlines.
- **When it is sent:**
  - The first clock was at scanline 0 (right after VBlank) in 1,714 frames, and at lines 60-99 in the rest.
  - It never landed inside the auto-joypad window (lines 225-227), and every packet had exactly 16 clocks.
  - The options pad reader waits for VBlank to end, like the original game, before reading.
  - The perf patch's $4212 bit-0 wait is replaced by options at C0:04F8, so it does not affect this.
- **Compared with LRG `player.a` and RCR:** same sentry, the same bit order (MSB first on WRIO bit 6, one bit per `$4016` read) and the same write-then-clock order.
  - LRG and RCR do a fresh manual latch and send after 16 or 17 read clocks. We send right after the auto-read's 16 clocks.
  - The LRG spec ("after the automatic read ... has completed ... 16 operations") allows our way. The device shifts on every clock and checks for the $72 pattern.
  - WRIO bit 7 is 1 in our writes and 0 in LRG's. It belongs to port 2 / the PPU latch, not the port-1 pad.
- **SNES Jr / 1CHIP:** the same $4201/$4016 behaviour and pin 6 on port 1. Nothing different is needed.

## Emulator results
- **Mesen2:** packets decode exactly to the table. No send happens on a frame without a pad read. WRIO bit 7 is never cleared.
- **bsnes, boss states:** Seto, Yagura and Stone Giant each give boss hits plus a boss kill.
- **Not covered:** player death and the dedicated D4/C8 boss handlers.

## Real-hardware checklist
- **MiSTer + DualShock (pre-patched ROM):** every event is felt, controls never stick, and there is no rumble when idle. It may feel choppy during slowdown.
- **EverDrive / plain pad:** play exactly as with the plain translation.
- **Death and late bosses:** confirm the long envelopes.
