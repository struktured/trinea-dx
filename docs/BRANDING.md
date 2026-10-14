# struktured labs boot splash (DX build)

- **Source:** ported from River City Ransom SNES (`snes/branding_splash.asm`, `tools/build_branding_splash.py`).
- **Art:** the project owner's own SL monogram and wordmark (`assets/branding/README.md` there: "supplied by the project owner … not Nintendo/Technos assets").
- **Binaries:** `asm/splash/*.bin` were produced with that repo's own `artwork()`/`encode()`. They are mode-3, 8bpp: 367 tiles, a 255-colour palette, and a 32x32 map.
- **Behaviour:**
  - Shown once at power-on/reset: a 64-frame window reveal, then a 3 s hold. Start skips it.
  - It then blanks the screen, clears VRAM, CGRAM, the window registers and DMA channel 0, and jumps to Trinea's original reset at C00087.
  - The only change to existing code is the reset jump at C0FF03. Code and data are in bank E8.
- **Screenshots:** `docs/screenshots/splash.png` (hold), `splash_reveal.png`, `splash_handoff.png` (Trinea's JAM logo after handoff).
