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

## Envelopes (one level per frame)

| Event | Levels |
|---|---|
| enemy hit | 04 03 |
| magic | 13 24 35 46 57 57 57 46 35 24 13 12 |
| enemy kill | 64 53 42 31 |
| hurt | 96 85 63 42 21 |
| hurt (4+ damage) | C8 B7 96 74 53 32 21 |
| boss hit | 75 64 43 22 |
| boss kill | FF FF EE DD CC BB AA 99 88 77 66 55 44 33 22 11 |
| death | FC EB DA C9 B8 A7 96 85 74 63 52 41 31 21 11 |

## Emulator results
- **Mesen2:** packets decode exactly to the table. No send happens on a frame without a pad read. WRIO bit 7 is never cleared.
- **bsnes, boss states:** Seto, Yagura and Stone Giant each give boss hits plus a boss kill.
- **Not covered:** player death and the dedicated D4/C8 boss handlers.

## Real-hardware checklist
- **MiSTer + DualShock (pre-patched ROM):** every event is felt, controls never stick, and there is no rumble when idle. It may feel choppy during slowdown.
- **EverDrive / plain pad:** play exactly as with the plain translation.
- **Death and late bosses:** confirm the long envelopes.
