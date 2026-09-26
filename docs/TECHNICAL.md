# Technical notes

Addresses are SNES HiROM addresses in the original *Trinea (Japan)* ROM unless noted. The patches (asar 1.91) are
applied to a copy of the original. `asm/main.asm` is the master file.

## ROM layout (32 Mbit HiROM)

`asm/expand.asm` grows the ROM from 16 to 32 Mbit (header ROM-size byte $C0:FFD7 = $0C), and asar fixes the checksum.
The original data stays where it is. New data goes into banks $E0-$E6:

| Bank | Contents |
|---|---|
| $E0 | VWF engine and opening/ending renderer code, English font and width table |
| $E1:0000 | event scripts from $DB:8000 (`$0405 == 0`) |
| $E2:0000 | event scripts from $DB:0000 (`$0405 == 2`) |
| $E3:0000 | 11-entry start table (was $C2:0000) plus the $C2 event scripts |
| $E4:0000 | opening/ending cutscene text |
| $E5:0000 | character profiles (pointer table $C0:5FCE rewritten) |
| $E6:0000 | pre-rendered system-text cells (character select, shop) |

## Script relocation (`asm/relocate.asm`)
Scripts are addressed as `[$0400]` (bank in $0402) + 16-bit Y. Three routines choose the bank: the label scanner
$C0:0BF5, script (re)start $C0:0D90 and the sub-thread $C0:2F0C. Each is patched to use the new banks.

## Script inserter (`tools/py/insert_script.py`)
- Rebuilds every script block from the original bytecode (`walk.py` reads it from your ROM). Opcodes and labels are
  kept verbatim. Message text (opcode 01, choice ops 05/46) is replaced by the encoded English, matched by message ID.
- English is 1 byte per character (ASCII $20-$7F). $7F is the ellipsis glyph. The original control bytes are kept.
- Word-wrap by pixel width: dialogue is 192 px × 3 lines, with an automatic `80 82` page break. The opening is
  240 px, centred. Profiles are 24 columns × 4 lines.
- **FF carry-over:** after an FF-terminated message the box stays open, and the next message continues on the same
  line. The inserter tracks the pen position across such messages, as long as only "benign" opcodes (sound, item
  effect, counter, flags, sfx: 1b 27 43 2c 07 0f) sit between them.
- Options: `--placeholder` puts test text in untranslated dialogue; `--jp-only` ignores `script/en`.
  `TRINEA_OVERRIDE=file.json` (`{id: text}`) swaps in text for debug/showcase builds.

## Dialogue VWF (`asm/vwf.asm`)
- $C0:16E0 `JSR $17EB` is redirected through a trampoline at $C0:FF0C to `JSL $E0:0000` for bytes $20-$7F.
- Glyphs are drawn into a line buffer at $7F:D000-$7F:D5FF (variables at $7F:D600-$7F:D665). A RAM sentinel test
  showed this region is never used by the game. Only the touched 16×16 cells are DMA'd, through the game's own NMI
  job 6.
- The column in $040A is kept equal to ceil(pen/16), so choice menus and other engine code that moves the cursor still work.
- The dialogue layer runs in interlace mode. A single emulator field shows every other line, so weave two fields for
  faithful screenshots.

## Opening/ending (`asm/opening.asm`)
$CE:4879 jumps to `$E0:8000`. It renders the entry (same IDs, text at $E4:0000) with the VWF core into $7E:6000
(4 lines × 256 px), then continues with the original DMA at $CE:48BF.

## Profiles / small font (`asm/smallfont.asm`)
Lowercase letters and punctuation are added to the 8×8 profile font in unused tiles $9E-$C3. The profiles are moved
to $E5 ($C0:5E97 `LDA $E50000,x`).

## System text (`tools/py/sysgfx.py`)
The character-select and shop screens draw big-font glyphs from $C3:8000 into a 2bpp strip buffer at $7F:F000
(64 bytes per 16×16 cell), and show messages as tilemap ranges of that strip. English lines are pre-rendered
with the VWF font into whole cells in bank $E6. The two glyph fetches are repointed ($C0:5633 for character select,
$C0:6991 for the shop), and the glyph lists and tilemap pieces are rewritten:

- glyph lists: $C0:56F0 (42 cells), $C0:75FC (63 cells), $C0:767C (29 cells)
- shop message pieces: table $C0:7170, rewritten in place in $C0:7182-$75F7

## Fonts
- `font/en/glyphs.txt` is the original English design (ASCII art). `tools/py/font_v2.py` derives `glyphs_v2.txt`
  from it (cap height 8, x-height 6, same advance widths). The build uses v2 by default; `TRINEA_FONT` overrides it.
- `tools/py/build_font.py` writes `build/font/font.bin` (96 glyphs × 16 rows × 2 planes; colour 1 stroke, colour 2
  drop shadow) and `widths.bin`.
- `font/en_small/glyphs8.txt` goes through `tools/py/build_small.py` to produce `build/font/small_add.bin` and
  `small_map.json`.
