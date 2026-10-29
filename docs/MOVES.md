# Trinea DX: moves and in-game toggles

These moves were checked in play and in the game code.

## Resources
- **X special counter** ($7E:10B8): only the X button uses it. It starts at 1 and goes up to 5. Pickups and the shop each add 1 ("X Special uses +1!!", or "Adds 1 use of the X special." in the shop).
- **Gold:** each rotate move costs 10% of your current gold, with a minimum of 10G. You can't use one with less than 10G (C0:836C).
- **A+B moves are free.**

Button tables: C0:894B (Hornisse), C0:88FE (Sara), C0:8998 (Ryo). Each maps a button or combo to an action, and the first match wins. Move names come from watching each move in Mesen.

## Hornisse
| Input | Move | Cost |
|---|---|---|
| B | stab | free |
| A | overhead slash ("Overhead" in the Select overlay) | free |
| Y | low sweep ("Low sweep" in the Select overlay) | free |
| B+Y | no move of its own: his table has no B+Y entry, so it is the B stab | free |
| mash B (4 quick taps, about 5-10 taps/s) | sword frenzy | free |
| A+B | morning star | free |
| rotate the D-pad, then A | lightning ("Electric Buffalo") | 10% gold (min 10G) |
| X | shock wave (he raises his sword, the screen pulses blue with a dark ring at his feet, then every enemy on screen explodes) | 1 X-special use |

## Sara
| Input | Move | Cost |
|---|---|---|
| rotate the D-pad, then B | Dragon Fire | 10% gold (min 10G) |
| B | fire shot (sparks fly forward) | free |
| A | spark shot (small magic bolt) | free |
| Y | wing spin (she turns a full circle with her wings spread; close range, no projectile) | free |
| B+Y | star fall (Sara glows gold, then a huge star crashes down) | free |
| A+B | homing flame (sparks steer into the nearest enemy; looks like B with no enemy on screen). A and B must go down on the same frame: the first button pressed locks in the move (A first = A, B first = B) | free |
| X | giant star (the screen pulses red and a huge purple star-field star grows over the whole screen, hitting every enemy) | 1 X-special use |

## Ryo
| Input | Move | Cost |
|---|---|---|
| rotate the D-pad (slower rotation), then Y | shadow clones | 10% gold (min 10G) |
| B | sickle (close range) | free |
| A | chain sickle (thrown on a chain) | free |
| Y | throwing blade | free |
| B+Y | wall of fire (a column of flames in front of him) | free |
| A+B | bombs | free |
| X | petal storm (the screen turns magenta and three-lobed petals swirl across it, then every enemy on screen explodes) | 1 X-special use |

## In-game toggles (DX options)
Hold L+R in the field, then tap a button. The screen gives a mosaic blink to confirm: **two blinks = on, one blink = off**. Every toggle defaults to **off** (rumble itself is on; L+R+B turns it off). Settings are kept in battery SRAM ($30:6300).

| Combo | Toggle |
|---|---|
| L+R+X | turbo (faster game logic) |
| L+R+Y | Hero speed, for any hero (Hornisse, Sara, Ryo). Mainly there to bring Sara up to her Game Boy speed. Cycles off / fast / faster, shown as 1 / 2 / 3 blinks |
| L+R+A | faster monsters |
| L+R+B | rumble off. Use it for testing on real hardware, or when using a pad without rumble motors. Stored in opts bit5 since 2026-10-19; the old bit4 flag (afb92e1a/2339e2b8) is ignored, so those saves get rumble back |
| L+R+Start | nothing special: plain Start (pause). The old help-overlay toggle was removed; saves that had it off get the overlay back |
| L+R+Select | nothing (v1.1.1 removed the dialogue-skip toggle; saves that had skip off skip again) |

## Select: controls help
Press **Select** in the field or a stage (anywhere Start would pause) to freeze the game and show a full-screen page: an SNES pad with what each button does, plus the current character's moves from this file. **Select or Start** closes it and the screen comes back exactly as it was (the music keeps playing). It never opens in menus, shops, dialogue, cutscenes or the attract demo. It is always available (there is no off switch; the old L+R+Start toggle was removed). While it is open, **hold L+R** and the X/A/Y/B labels change to the L+R+button DX options (Turbo, Fast foes, Hero speed, Rumble off), shown in cyan below the "L+R: DX opts" hint; let go and they change back. Pressing a button there does not toggle anything (the game is frozen; Select/Start close it only once L+R are released). Screenshots: `docs/screenshots/overlay_lr_*.png`. In the original game Select does nothing in play (it is only read on the title screen and by an unreachable debug menu), so nothing is taken away. Screenshots: `docs/screenshots/help_overlay_*.png`.

## Start skips dialogue
While a message is printing or waiting for A, press **Start** to skip the rest of the current scene's text (a press while text is still printing takes effect at the next prompt, so menus such as the save list always draw in full). The script still runs every non-text command (story flags, map moves, items, LIFE, character branches, battles), so nothing is missed; only the text is hidden and [wait] prompts are passed. Choice prompts and menus still appear and wait for you. Start = pause in gameplay is unchanged (skip only acts while a script is running). It is always available (no toggle since v1.1.1).

## Rumble: Count Vampierre's zap
In the NEA 1426 revival scene, when the Count vaporizes Gostelo, a crackly strong pulse plays for exactly as long as the zap animation (script op 39 at $E2:1DD4). It does not play if you skipped the scene with Start.

## Tips
- The contraption boss is easy if you attack it from the side.
