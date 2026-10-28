# Submission draft: Trinea DX v1.0 (English translation)

Draft text for the romhacking database sites. Nothing has been submitted yet.

## Where to submit (researched 2026-09-26)

| Venue | Status (Sep 2026) | Notes |
|---|---|---|
| **[Romhack.ing (RHDI)](https://romhack.ing/)** | Active. Spiritual successor to RHDN, alpha from Aug 2024, public registration since Mar 2025. | Hosts the patch file, readme and screenshots, and records No-Intro DAT hashes. Human-translated work is clearly separated from machine translations, which had their downloads disabled in mid-2026. **Recommended primary venue.** Register, then create a "Translation" entry. |
| **[ROMhacking.net (RHDN)](https://www.romhacking.net/submissions/)** | Read-only/news-only since 1 Aug 2024 ([announcement](https://www.romhacking.net/news/3074/)). Submissions **quietly reopened** in early 2025 and new translation entries were still appearing in 2026. | Still the largest audience and archive. The submission page asks you to **host the download yourself** (GitHub Release link is ideal). Its long-term direction is uncertain. **Recommended secondary venue** (link to the GitHub Release). |
| **[RomHack Plaza](https://romhackplaza.org/)** | Active, with a moderated submission queue ([tutorial](https://romhackplaza.org/submit-tutorial/)). | Popular with players. Entries show No-Intro hashes. Good third listing. |
| **[Data Crystal](https://datacrystal.tcrf.net/)** | Active wiki (TCRF family). **Not a patch host.** | Trinea is on its [SNES translation request list](https://datacrystal.tcrf.net/wiki/Translations_Request_List/Super_Nintendo_-_Super_Famicom_-_Satellaview_-_Sufami_Turbo). Mark it done with a link, and optionally add a Trinea ROM map / TBL page from `docs/TECHNICAL.md` and `tables/`. |
| GitHub Releases | The canonical download: `github.com/struktured/trinea-dx/releases` | Attach `Trinea_English_v1.0.zip`. Every site above links here. |

Also worth a short announcement: the RHDN forum thread (topic 40638, where 4ph helped), and the
[TCRF Trinea page](https://tcrf.net/Trinea) talk page if relevant.

**Recommendation:** publish the GitHub Release first. Then submit to **Romhack.ing** (primary), **ROMhacking.net**
(link to the Release) and **RomHack Plaza**, and update **Data Crystal**'s request list.

## Entry fields

- **Title:** Trinea English Translation (Trinea DX v1.0)
- **Game:** Trinea (トリネア), Super Nintendo / Super Famicom, 1993, Yanoman / Japan Art Media (JAM)
- **Category / type:** Translation. Language: English. Status: Complete. Genre: Action RPG.
- **Version / release date:** 1.0 / 2026-09-26
- **Author / group:** struktured labs (struktured)
- **Patch format:** IPS (`Trinea (Japan) [T-En DX by struktured labs v1.1].ips`, 157,542 bytes) in `Trinea_DX_v1.1.zip` with `readme.txt`
- **License:** CC BY-NC-SA 4.0 (translation); MIT (tools/asm source)
- **Source code:** https://github.com/struktured/trinea-dx

### Hashes (No-Intro: Trinea (Japan))

```
Original (headerless)  Trinea (Japan).sfc   2,097,152 bytes
  CRC32  C20419EC
  MD5    8622B25466D1CF31E8A8771838B02CA7
  SHA-1  BA4866A599C9DC380C11F0CB3C1F8E0374D35DFF
Patched                                    4,194,304 bytes
  CRC32  600F507D
  MD5    C04250E577A9A97C80313453F1FD6F7D
  SHA-1  D9A64EEC4356A6281273075E8F4BEADD15DDAB0E
```

### Short description (about 250 chars)

> Complete English translation of Trinea, JAM's 1993 Super Famicom action RPG. All three heroes' scenarios, the
> cutscenes, profiles, character select and shop are translated, with a new variable-width font.

### Long description

> **Trinea** is an overhead action RPG released only in Japan in 1993 by Yanoman and Japan Art Media. You pick one
> of three heroes, each with a separate scenario across time: the masked knight Hornisse, the winged fire-wielder
> Sara Weathers, and the Neo Edo ninja Tetsuya "Ryo" Mifune. Together their stories tie the three orbs to the legend of the
> Penta Dragon.
>
> This patch translates the whole game into English:
> - all 841 script strings in every scenario: dialogue, choices, narration, the opening and ending cutscenes and
>   the character profiles;
> - the character-select screen, shop descriptions and messages, and the money label, which are pre-rendered
>   graphics;
> - a new variable-width dialogue font with automatic word wrap, and lowercase letters for the profile font.
>
> The ROM is expanded to a plain 32 Mbit HiROM (no special chips) with a valid checksum. MiSTer and flash-cart
> users should pre-patch the ROM on a PC. The script was translated by hand from the Japanese. Sara's story builds on eadmaster's
> RetroSubs subtitles (Ryo's and Hornisse's stories and the menus were translated from scratch), keeps a consistent glossary, and gives each hero a distinct voice.
>
> The full source (script, fonts, asm, tools) is on GitHub and rebuilds the patch from your own ROM.
>
> Known caveat: the final-boss win path was verified by triggering the credits directly rather than by a full
> legitimate clear. Reports are welcome.

### Credits

- struktured labs (struktured): project lead, translation, hacking, fonts, tools
- eadmaster: RetroSubs English subtitles and table files (https://github.com/eadmaster/RetroSubs)
- 4ph: character table help (byte-to-Japanese-character mapping) (RHDN forum topic 40638)
- Original game: Yanoman / Japan Art Media (JAM)
- Tools: asar, Flips, Mesen, bsnes-mercury

### Screenshot picks (from `docs/screenshots/`)

1. `character_select.png`: the English name plate and prompt.
2. `dialogue.png`: VWF dialogue box in the opening narration.
3. `shop.png`: the pre-rendered English shop text.
4. `final_cutscene.png`: late-game story text. `title.png` works as the thumbnail or title image.

Most sites want native-resolution captures. These are 512×448 woven interlace frames (the dialogue layer is
interlaced). Downscale to 256×224 if a site requires it.
