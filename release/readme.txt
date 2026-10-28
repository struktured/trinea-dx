===============================================================================
                    TRINEA DX v1.1 - English Translation + DX
                          by struktured labs
===============================================================================

Game:          Trinea
Platform:      Super Nintendo / Super Famicom
Genre:         Action RPG
Original:      Yanoman / Japan Art Media (JAM), 1993 (Japan only)
Patch version: 1.1
Release date:  2026-10-27
Status:        Complete
Project:       Trinea DX (enhancement project; v1.0 = English translation)
Source:        https://github.com/struktured/trinea-dx

-------------------------------------------------------------------------------
 CONTENTS
-------------------------------------------------------------------------------
 1. About
 2. ROM information
 3. How to apply the patch
 4. Controls and options
 5. Known issues
 6. Credits
 7. License
 8. Changelog

-------------------------------------------------------------------------------
 1. ABOUT
-------------------------------------------------------------------------------
Trinea is an overhead action RPG with three playable heroes, each with a
separate scenario: the masked knight Hornisse, the winged fire-wielder Sara
Weathers, and the Neo Edo ninja Tetsuya "Ryo" Mifune. This patch translates
the entire game into English:

 - All 841 script strings in all three scenarios: dialogue, choices,
   narration, the opening and ending cutscenes and the character profiles.
 - The character select screen, shop descriptions and messages, and the
   money label.
 - A new variable-width dialogue font and additions to the 8x8 small font.
 - DX extras (v1.1): a performance patch, an L+R options menu (turbo,
   faster monsters, hero speed, rumble off, dialogue skip, help overlay),
   RumbleShock rumble, a Select controls overlay, Start to skip dialogue,
   and a boot splash. Every DX extra can be switched off.
 - The ROM is expanded to 32 Mbit (4 MB HiROM) with a valid checksum.

-------------------------------------------------------------------------------
 2. ROM INFORMATION
-------------------------------------------------------------------------------
Apply the patch to this ROM (No-Intro), headerless:

  File:   Trinea (Japan).sfc
  Size:   2,097,152 bytes (16 Mbit), NO 512-byte copier header
  CRC32:  C20419EC
  MD5:    8622B25466D1CF31E8A8771838B02CA7
  SHA-1:  BA4866A599C9DC380C11F0CB3C1F8E0374D35DFF

After patching:

  Size:   4,194,304 bytes (32 Mbit)
  CRC32:  3985B0B3
  MD5:    DC222F3AB2782F98EC890507C1E87F07
  SHA-1:  96B74801D77BD204951B5BA1D103E8915CB2FA6F

-------------------------------------------------------------------------------
 3. HOW TO APPLY THE PATCH
-------------------------------------------------------------------------------
 1. Make a backup copy of your ROM and check it against the hashes above.
    If your file is 2,097,664 bytes, it has a copier header. Remove the
    header first.
 2. Apply "Trinea (Japan) [T-En DX by struktured labs v1.1].ips" with an IPS
    patcher, for example:
      - Floating IPS (Flips)   https://github.com/Alcaro/Flips
      - ROM Patcher JS (web)   https://www.marcrobledo.com/RomPatcher.js/
      - Lunar IPS
 3. Check that the patched ROM matches the "After patching" hashes.

Emulators that soft-patch IPS files (RetroArch, snes9x, bsnes) can load the
patch if it has the same name as the ROM and sits next to it.

MiSTer, flash carts (SD2SNES/FXPak, EverDrive) and other hardware: patch the
ROM on a PC first and copy the patched .sfc to the device. Do not rely on
soft-patching. The patched game is a plain 32 Mbit HiROM with no special chips.

-------------------------------------------------------------------------------
 4. CONTROLS AND OPTIONS
-------------------------------------------------------------------------------
 Select   In the field or a stage, shows a pad diagram with button actions
          and your hero's moves (Hornisse blue, Sara green, Ryo pink).
          Press Select or Start to close it. Hold L+R while it is open to
          see the DX option buttons.
 Start    While text is showing, skips the rest of the scene's dialogue.
          Story flags, map moves and battles still happen.

 Options menu: in the field, hold L+R, then tap a button:
   X       Turbo                     (default off)
   Y       Hero speed                (default off)
           Works for any hero, but it is mainly there to bring
           Sara up to the speed she had in the Game Boy version.
   A       Faster monsters           (default off)
   B       Rumble off                (rumble is on by default)
   Select  Start-skips-dialogue      (default on)
   Start   Select help overlay       (default on)
 Two blinks mean on, one blink means off. Settings are saved in SRAM.

 Moves (full list in docs/MOVES.md in the source repository):
 - X special: only X spends it. You start with 1 and can hold up to 5.
 - Rotate moves cost 10% of your gold (min 10G). A+B moves are free.
 - Hornisse: A = Overhead, Y = Low sweep; mash B for the sword frenzy;
   A+B morning star; rotate the D-pad then A for lightning.
 - Sara: rotate then B for Dragon Fire; B+Y star fall; A+B homing flame.
 - Ryo: rotate (slower) then Y for shadow clones; B+Y wall of fire;
   A+B bombs.

 Rumble works with RumbleShock-style pads on real hardware and MiSTer.

-------------------------------------------------------------------------------
 5. KNOWN ISSUES
-------------------------------------------------------------------------------
 - The final-boss win path (ending and credits after defeating the last boss)
   was verified by triggering the credits sequence directly, not through a
   legitimate full playthrough. Please report any problems.
 - A few story readings are interpretive. See script/TRANSLATION_NOTES.md in
   the source repository.
 - The game's existing English graphics (title, LIFE/ATTACK/SPEED, staff
   credits) are unchanged.

Bug reports: https://github.com/struktured/trinea-dx/issues

-------------------------------------------------------------------------------
 6. CREDITS
-------------------------------------------------------------------------------
 struktured labs (struktured)
     Project lead, translation, ROM hacking, fonts, tools, testing
 eadmaster
     RetroSubs English subtitles for Trinea, the base for Sara's story
     only, and the character table files. Ryo's and Hornisse's stories
     and the menus were translated from scratch.
     https://github.com/eadmaster/RetroSubs
 4ph
     Character table help (the byte-to-Japanese-character mapping)
     https://www.romhacking.net/forum/index.php?topic=40638.0
 Yanoman / Japan Art Media (JAM)
     The original game

 Tools: asar, Floating IPS (Flips), Mesen, bsnes-mercury, Python.

-------------------------------------------------------------------------------
 7. LICENSE
-------------------------------------------------------------------------------
The translation (English text, fonts, tables) is licensed under Creative
Commons Attribution-NonCommercial-ShareAlike 4.0 (CC BY-NC-SA 4.0), because
Sara's story builds on eadmaster's RetroSubs English translation
(CC BY-NC-SA 4.0).
The patch code and build tools are MIT-licensed; see the source repository.
Distribute this patch under CC BY-NC-SA 4.0: free of charge, with credit,
and share-alike.

Do NOT distribute pre-patched ROMs. Trinea is (c) 1993 Yanoman / Japan Art
Media. This is an unofficial fan translation, not affiliated with the rights
holders.

-------------------------------------------------------------------------------
 8. CHANGELOG
-------------------------------------------------------------------------------
 v1.1 (2026-10-27)
   - Speed improvements, L+R options menu, rumble, Select controls
     overlay (Hornisse blue, Sara green, Ryo pink; Hornisse A = Overhead,
     Y = Low sweep), Start skips dialogue, staff roll credits.
   - Fixed: final-boss freeze (rumble left X/Y 8-bit during NMI);
     0 freezes in 45 soak runs vs ~2 in 39 before.
   - Wizard spelled "Graph" consistently; opening line fix.
 v1.0.1 (2026-10-13)
   - Fixed: dialogue text corrupted the stage collision map, so after
     talking you could get stuck in walls or walk through them (e.g. after
     a boss victory). Text now uses RAM the game never touches.
 v1.0 (2026-09-26)
   - First public release. Complete English translation.
===============================================================================
