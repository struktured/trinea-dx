# Known issues

## FIXED: dialogue text corrupted the collision map (v1.0 translation bug; also in DX betas)

**Cause:** the English VWF line buffer was placed at `$7F:D000-$7F:D6FF`, and the rumble state at `$7F:DF00`. That region is the game's per-stage collision/attribute map.
- It is built at C026CC (`STA $7FD000,x`, one byte per tilemap word of `$7F:0000`).
- It is tested at C042EA and C13F03 through C14163 (`LDA $7FD000,x : BNE solid`); 19 original instructions index it.
- The original game draws its text at `$7F:8000`, not here.

Every English dialogue line drew glyph pixels into the collision map. This made walls passable or blocked floors, and caused the stuck-in-the-wall-trim softlocks after boss victory dialogue.

The earlier "unused RAM" check (ramtest2) only sampled one moment where the region was zero, so it missed this.

**Evidence** (bsnes, same savestate `h2_end` and the same input on each ROM):
- Japanese ROM: the map is unchanged during the dialogue.
- v1.0 English: the first divergence is frame 10 at `$7FD004` (JP `00`, EN `E0`, a glyph byte). 105 to 366 map bytes are corrupted during the dialogue.
- Fixed build: 0 map bytes differ through the whole dialogue (frames 0-319).
- After frame 319 the English and Japanese runs desync because the dialogue lengths differ. A new stage loads, and both English builds then match each other.
- In the DX build, rumble writes also overwrote `$7FDF00` (JP holds `03` there).
- Image: `docs/screenshots/collision_map_evidence.png`. The bottom panels show the first $800 map bytes; red = differs from JP.

**Fix:** the VWF buffer and its variables moved to `$7E:C800-$7E:CE65`; rumble state moved to `$7E:CF00`. That block (`$7E:C603-$7E:ECFF`) stayed zero in 19 bsnes runs on the JP ROM (2,500 frames each over many stages) and has no indexed long references in the original code. The DX build's hooks were audited and reproduce the displaced instructions exactly. The only remaining differences between DX and EN are stack bytes and a 1-frame input-timing shift from the extra cycles.


## Hornisse stuck in the top wall trim after a boss victory (real hardware)

- **Reported by:** Carmelo, on real hardware, 2026-10-13.
- **Where:** Hornisse's scenario, the throne room / bat-crest hall (the Vampierre castle hall).
- **What happens:** the boss dies and Hornisse does the victory pose. Afterwards he is inside the top wall trim and can't move.
- **Status:** not reproduced yet. Triage was time-boxed. In bsnes, the `w_vamp_end` state plays to the same hall with autofire and shows the victory sequence, but the stuck position did not happen in that short run.
- **Unknown:** whether the original Japanese ROM does the same. Test this first, using a JP save from just before the fight.

**Leads:**
1. **Post-victory pose / auto-walk.** Many Trinea boss rooms move the player to a fixed spot for the victory pose. If that spot or the walk path puts Hornisse's Y above the floor's top edge, the collision check (which normally stops him walking into the wall) may never push him back out.
2. **Collision only.** He may have been against the top wall when the boss died. The pose sprite offset could then put his feet inside a solid tile.

**What separates the two:**
- Does it happen every time, or only when you are near the top wall when the boss dies?
- Does the character's Y match a fixed value every time?

**Translation patch:** it changes text, font and script-relocation code and does not intentionally touch movement or collision. The rumble hooks only read state and return to the original instructions. Still, confirm on the plain `trinea_en.ips` build and on the Japanese ROM before blaming DX.
