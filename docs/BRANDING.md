# struktured labs boot splash (DX build)

- **Source:** ported from River City Ransom SNES (`snes/branding_splash.asm`, `tools/build_branding_splash.py`).
- **Art:** the project owner's own SL monogram and wordmark (`assets/branding/README.md` there: "supplied by the project owner … not Nintendo/Technos assets").
- **Binaries:** `asm/splash/*.bin` were produced with that repo's own `artwork()`/`encode()`. They are mode-3, 8bpp: 367 tiles, a 255-colour palette, and a 32x32 map.
- **Behaviour:**
  - Shown once at power-on/reset: a 64-frame window reveal, then a 3 s hold. Start skips it.
  - It then blanks the screen, clears VRAM, CGRAM, the window registers and DMA channel 0, and jumps to Trinea's original reset at C00087.
  - The only change to existing code is the reset jump at C0FF03. Code and data are in bank E8.
- **Screenshots:** `docs/screenshots/splash.png` (hold), `splash_reveal.png`, `splash_handoff.png` (Trinea's JAM logo after handoff).

## Logo SFX (ported from RCR's ident)
- **Source:** `asm/splash/splash-ident-spc.bin` is RCR's own tiny S-SMP program (`tools/build_ident_spc.py`, echo on). It contains no samples or driver copied from another game.
- **Curve:** `splash-ident-curve.bin` is RCR's production 240-frame curve (`tools/build_sub_wub_trial.curve()`).
- **Start:** the program is uploaded via the IPL before the reveal. One curve step (pitch, volume, sequence) is sent each VBlank from the first reveal frame, as in RCR 4305e.
- **Hold:** 200 frames, so the 240-frame ident finishes.
- **Handoff (full play or Start skip):** writes `$FF` to `$2142`. The ident mutes the DSP, disables echo writes and jumps back to IPL ($FFC0). The splash then waits for `AA/BB` before Trinea's reset runs, so Trinea's own driver upload handshake still works.
- **Timeouts:** every wait is bounded. If the APU never answers, the splash runs silently and skips the key-off.
- **Loudness (v1.1):** the ident was ~4.7 dB quieter than the Yanoman logo jingle that follows it (-24.3 vs -19.6 LUFS). The three BRR block headers in `splash-ident-spc.bin` ($0420, $0429, $0440) go up one range step (+6 dB) and every curve volume byte is scaled by 0.861 (-1.3 dB, peak 116 -> 100). Measured on a Mesen 2.1.1 WAV dump: splash -19.6 LUFS / -12.8 dBFS peak, Yanoman -19.6 LUFS / -3.8 dBFS (unchanged).
