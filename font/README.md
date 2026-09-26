# font/

English fonts drawn for this project, stored as ASCII-art text sources (`#` = stroke). Binaries are generated at build time.

- `en/glyphs.txt`: original 8×16-cell variable-width dialogue font design (v1).
- `en/glyphs_v2.txt`: taller v2, derived from v1 by `tools/py/font_v2.py` (cap height 8, x-height 6, same advance
  widths). The build uses this one by default; set `TRINEA_FONT=font/en/glyphs.txt` to build with v1.
- `en_small/glyphs8.txt`: 8×8 lowercase letters and punctuation added to the profile font (`tools/py/build_small.py`).

Licensed CC BY-NC-SA 4.0.
