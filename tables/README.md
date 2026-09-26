# tables/

Character tables (Thingy `.tbl` format) for the original game's text encoding. `tools/py/dump_script.py` uses them
to dump the Japanese script from your ROM into `build/jp/`.

- `trinea_big.tbl`: 2-byte big-font (dialogue) glyph table
- `trinea_small.tbl`: 1-byte 8×8 small-font (profile) table

Based on eadmaster's RetroSubs Trinea table files (https://github.com/eadmaster/RetroSubs, CC BY-NC-SA 4.0), with
corrections. Licensed CC BY-NC-SA 4.0.
