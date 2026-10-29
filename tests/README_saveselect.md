# Save-select / Start regression

`saveselect_start_sweep.py ROM tag START 2000 2080 2` boots with a save, takes CONTINUE, then presses
Start at each frame while "Chronicle 1/2/3" is printing and compares the menu against a reference.
Before the fix (official dc222f3a and perf t5) frames 2016-2042 left "Chronicle 1 / C" (list truncated
by dialogue skip). After: all frames show the full list (only cursor-blink diff at 2000).
Needs a .sav next to it (sp.sav) and the libretro bsnes core; headless.
