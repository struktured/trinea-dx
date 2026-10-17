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
Hold L+R in the field, then tap a button. The screen gives a mosaic blink to confirm: **two blinks = on, one blink = off**. Every toggle defaults to **off**. Settings are kept in battery SRAM ($30:6300).

| Combo | Toggle |
|---|---|
| L+R+X | turbo (faster game logic) |
| L+R+Y | Sara speed. Cycles off / fast / faster, shown as 1 / 2 / 3 blinks |
| L+R+A | faster monsters |
| L+R+B | rumble off. Use it for testing on real hardware, or when using a pad without rumble motors |

## Tips
- The contraption boss is easy if you attack it from the side.
