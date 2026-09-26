===============================================================================
                    TRINEA - English Translation v1.0
                          by struktured labs
===============================================================================

Game:          Trinea
Platform:      Super Nintendo / Super Famicom
Genre:         Action RPG
Original:      Yanoman / Japan Art Media (JAM), 1993 (Japan only)
Patch version: 1.0
Release date:  2026-09-26
Status:        Complete
Source:        https://github.com/struktured/trinea-english

-------------------------------------------------------------------------------
 CONTENTS
-------------------------------------------------------------------------------
 1. About
 2. ROM information
 3. How to apply the patch
 4. Known issues
 5. Credits
 6. License
 7. Changelog

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
  CRC32:  8EDB17F7
  MD5:    62668BCD5A12B5BADF034A21B8DF5EDC
  SHA-1:  E0B232E4854B29DD181C57DE54ED22CBD9F119B6

-------------------------------------------------------------------------------
 3. HOW TO APPLY THE PATCH
-------------------------------------------------------------------------------
 1. Make a backup copy of your ROM and check it against the hashes above.
    If your file is 2,097,664 bytes, it has a copier header. Remove the
    header first.
 2. Apply "Trinea (Japan) [T-En by struktured labs v1.0].ips" with an IPS
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
 4. KNOWN ISSUES
-------------------------------------------------------------------------------
 - The final-boss win path (ending and credits after defeating the last boss)
   was verified by triggering the credits sequence directly, not through a
   legitimate full playthrough. Please report any problems.
 - A few story readings are interpretive. See script/TRANSLATION_NOTES.md in
   the source repository.
 - The game's existing English graphics (title, LIFE/ATTACK/SPEED, staff
   credits) are unchanged.

Bug reports: https://github.com/struktured/trinea-english/issues

-------------------------------------------------------------------------------
 5. CREDITS
-------------------------------------------------------------------------------
 struktured labs (Carmelo Piccione)
     Project lead, translation, ROM hacking, fonts, tools, testing
 eadmaster
     RetroSubs English subtitles for Trinea and the table files, which
     were the base for this project
     https://github.com/eadmaster/RetroSubs
 4ph
     Font table help
     https://www.romhacking.net/forum/index.php?topic=40638.0
 Yanoman / Japan Art Media (JAM)
     The original game

 Tools: asar, Floating IPS (Flips), Mesen, bsnes-mercury, Python.

-------------------------------------------------------------------------------
 6. LICENSE
-------------------------------------------------------------------------------
The translation (English text, fonts, tables) is licensed under Creative
Commons Attribution-NonCommercial-ShareAlike 4.0 (CC BY-NC-SA 4.0), because
it builds on eadmaster's RetroSubs English translation (CC BY-NC-SA 4.0).
The patch code and build tools are MIT-licensed; see the source repository.
Distribute this patch under CC BY-NC-SA 4.0: free of charge, with credit,
and share-alike.

Do NOT distribute pre-patched ROMs. Trinea is (c) 1993 Yanoman / Japan Art
Media. This is an unofficial fan translation, not affiliated with the rights
holders.

-------------------------------------------------------------------------------
 7. CHANGELOG
-------------------------------------------------------------------------------
 v1.0 (2026-09-26)
   - First public release. Complete English translation.
===============================================================================
