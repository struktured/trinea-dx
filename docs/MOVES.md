# Trinea DX: moves and in-game toggles

These moves were checked in play and in the game code.

## Resources
- **X special counter** ($7E:10B8): only the X button uses it. It starts at 1 and goes up to 5. Pickups and the shop each add 1 ("X Special uses +1!!", or "Adds 1 use of the X special." in the shop).
- **Gold:** each rotate move costs 10% of your current gold, with a minimum of 10G. You can't use one with less than 10G (C0:836C).
- **A+B moves are free.**

## Hornisse
| Input | Move | Cost |
|---|---|---|
| A / B / Y | normal attacks | free |
| mash B (4 quick taps, about 5-10 taps/s) | sword frenzy | free |
| A+B | morning star | free |
| rotate the D-pad, then A | lightning ("Electric Buffalo") | 10% gold (min 10G) |
| X | X special | 1 X-special use |

## Sara
| Input | Move | Cost |
|---|---|---|
| rotate the D-pad, then B | Dragon Fire | 10% gold (min 10G) |
| B+Y | B+Y attack | free |
| A+B | homing flame | free |
| X | X special | 1 X-special use |

## Ryo
| Input | Move | Cost |
|---|---|---|
| rotate the D-pad (slower rotation), then Y | shadow clones | 10% gold (min 10G) |
| B+Y | B+Y attack | free |
| A+B | bombs | free |
| X | X special | 1 X-special use |

## In-game toggles (DX options)
Hold L+R in the field, then tap a button. The screen gives a mosaic blink to confirm: **two blinks = on, one blink = off**. Every toggle defaults to **off**, except dialogue skip (on). Settings are kept in battery SRAM ($30:6300).

| Combo | Toggle |
|---|---|
| L+R+X | turbo (faster game logic) |
| L+R+Y | Sara speed. Cycles off / fast / faster, shown as 1 / 2 / 3 blinks |
| L+R+A | faster monsters |
| L+R+B | rumble off. Use it for testing on real hardware, or when using a pad without rumble motors. Stored in opts bit5 since 2026-10-19; the old bit4 flag (afb92e1a/2339e2b8) is ignored, so those saves get rumble back |
| L+R+Select | Start skips dialogue (default **on**; tapping turns it off, two blinks = on) |

## Start skips dialogue
While a message is printing or waiting for A, press **Start** to skip the rest of the current scene's text. The script still runs every non-text command (story flags, map moves, items, LIFE, character branches, battles), so nothing is missed; only the text is hidden and [wait] prompts are passed. Choice prompts and menus still appear and wait for you. Start = pause in gameplay is unchanged (skip only acts while a script is running). L+R+Select turns it off.

## Rumble: Count Vampierre's zap
In the NEA 1426 revival scene, when the Count vaporizes Gostelo, a crackly strong pulse plays for exactly as long as the zap animation (script op 39 at $E2:1DD4). It does not play if you skipped the scene with Start.

## Tips
- The contraption boss is easy if you attack it from the side.
