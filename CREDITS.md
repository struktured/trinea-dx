# Credits

## Trinea DX v1.0: English translation (2026-09-26)

| Who | What |
|---|---|
| **struktured labs (Carmelo Piccione)** | Project lead. Translation, script editing, ROM hacking (VWF, script relocation, 32 Mbit expansion, pre-rendered system text), English fonts, build tools, testing. |
| **eadmaster** | [RetroSubs](https://github.com/eadmaster/RetroSubs) English subtitles for Trinea (v0.6.2, CC BY-NC-SA 4.0). They were the starting point, and parts of the Sara scenario and opening lines are adapted from them. Also the character table files (`tables/`) and the name list. |
| **4ph** | Font table help: [romhacking.net forum topic 40638](https://www.romhacking.net/forum/index.php?topic=40638.0). |
| **Yanoman / Japan Art Media (JAM)** | The original game, *Trinea* (Super Famicom, 1993). |

Reference material: ritchie's Trinea walkthrough on GameFAQs, Japanese strategy pages (for move names), and
The Cutting Room Floor's Trinea page (debug menu).

## Tools used

- [asar](https://github.com/RPGHacker/asar): SNES assembler (patches in `asm/`).
- [Flips (Floating IPS)](https://github.com/Alcaro/Flips): IPS creation.
- [Mesen](https://github.com/SourMesen/Mesen2): debugger, tracing, memory and VRAM inspection.
- [bsnes-mercury](https://github.com/libretro/bsnes-mercury) (libretro): scripted playtesting and screenshots.
- Python 3 with NumPy and Pillow: script dumper and inserter, font builder, system-text renderer.
