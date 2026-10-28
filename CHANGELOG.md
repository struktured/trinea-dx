# Changelog

## v1.1 (2026-10-27): Trinea DX
- Speed improvements: perf patch plus optional turbo, faster monsters, and hero speed (any hero; mainly to bring Sara up to her Game Boy speed).
- Options menu: hold L+R in the field, then X turbo / Y hero speed / A faster monsters / B rumble off / Select dialogue skip / Start help overlay. Saved in SRAM.
- RumbleShock rumble, on by default.
- Select controls overlay: pad diagram plus each hero's moves, in the ending-logo colors (Hornisse blue, Sara green, Ryo pink). Hornisse A = "Overhead", Y = "Low sweep". Holding L+R shows the DX option buttons.
- Start skips dialogue (default on). Staff roll credits the translation and Trinea DX.
- Fixed: final-boss hard freeze. Rumble hooks ran with X/Y 8-bit, and an NMI landing in them crashed in the game's palette effect. 0 freezes in 45 soak runs vs ~2 in 39 before.
- Fixed: rumble stuck on or pulsing endlessly; no rumble during the title demo.
- Wizard spelled "Graph" consistently; opening line (OPEN_28) fix; Ryo-scenario text polish.

## v1.0.1 (2026-10-13)
- Fixed: dialogue text corrupted the stage collision map.

## v1.0 (2026-09-26)
- First public release: complete English translation.
