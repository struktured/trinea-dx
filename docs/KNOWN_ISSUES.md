# Known issues

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
