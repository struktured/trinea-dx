# Trinea translation notes

## Status
All 841 strings in the JP script (dumped to `build/jp/` from your ROM) have an `en` field in `script/en/` (526 unique JP texts; byte-identical duplicates reuse the same translation).

| Category | Strings |
|---|---|
| Opening / cutscenes (OPEN + hero intro narrations DB_8000_0064/0094/0122) | 50/50 |
| Character profiles | 3/3 |
| System / shop / menus / choices / save book | 154/154 |
| Sara scenario | 103/103 |
| Tetsuya (Ryo) scenario | 112/112 |
| Hornisse scenario | 122/122 |
| Shared NPC / mixed | 150/150 |
| Control-only stubs (`[END]`, `[wait][END]`, `[88]` runs) | 147/147 |

Categories come from `tools/py/coverage_en.py`: by block, or by which hero's speaker tag appears.

## Approach
- **Workflow.** I extracted the unique JP strings, translated them block by block into `script/src/*.txt`, and merged them
  into JSON with `tools/py/merge_en.py`. The merge checks terminators, leading `[wait]/[page]` prefixes, `[hl]` parity,
  preservation of unknown control codes (`[81]`), choice length (24 chars max), and page length (about 90 chars; 3 lines × about 30).
- **RetroSubs base.** eadmaster's lines were the starting point for the opening and Sara's scenario. Each one was re-checked
  against the dump, and most were reworded for flow or accuracy. Main corrections:
  - **Ruria Midori Lucia is ONE person** (Ryo's love interest, a third-generation American who leads the Resistance). RetroSubs has
    "We are... Ruria, Midori and Lucia." The JP is 私は…ルリア 緑 ルーシア ("I am..."), and the Tetsuya profile confirms it.
  - Opening 【青／緑／紅】 is "Blue, Green and Crimson", not "Water, Nature and Fire". These are the three orbs (Hornisse = Blue,
    Sara = Green, Ryo = Crimson).
  - DB_0000_0025 (Vampierre to Gostelo): RetroSubs has "Some clueless old scientist". The JP is 謎の老人とは……!?, which reads as Vampierre
    hinting that *he* was the mysterious old man who left the gem. Now: "...that the mysterious old man was......!?" (see doubtful lines).
  - Sara says お父さん = "Dad" (RetroSubs mixed in "Father"), which keeps her voice young. Lillie and others say "your father".
  - "Tennin's clan" became "Heaven Clan" (天忍), with the parallel Earth / Divine / Wind clans.
- **struktured's stream phrasing** was used where the same JP appears: DB_0000_0032 ("Enduring this humiliation... surviving this far...
  It was because I believed a day like this would come......", "That day is the day you perish!!"). "I call it..." (名付けて…) is used for
  Vampierre's form reveals. The Vampiume / Maris / "DIEEE!" lines in the project's early stream notes do **not** occur anywhere in the
  dumped script (grep finds no マリス, ヴァンピューム, 死ねー or おにく). They are probably graphics text, or come from Penta Dragon.
- **Voices.** Hornisse: clipped, formal, world-weary ("Nothing good ever happens when I'm called that"). Sara: bright, informal,
  a little sassy. Ryo: でござる rendered as stiff, formal, contraction-free English, dropping into casual "Bring it on!!" on 〜ぜ lines.
  Forfahren and Graf: folksy old men ("my boy", "Ho ho ho"). Vampierre: overly polite, and campy when he slips into feminine speech
  ("Ooh, how vexiiing!!"). YAGURA and THE 8 (katakana-only robots) speak in ALL CAPS. Yayoi: "Oh-ho-ho-ho!", "lover boy", "darling".
- **Names.** See `glossary.md`, including the Ryo/Tetsuya decision: "Ryo" in all dialogue and tags, and "Tetsuya "Ryo" Mifune" where
  the full name 御船 椋 哲也 appears.

## Lines needing review (doubtful or uncertain)
| ID(s) | Issue |
|---|---|
| C2_s03_0055, C2_s05_0070, C2_s04_0025 | Date slips, now **corrected**. See "Continuity corrections" below. |
| C2_s08_0054 / 0061 / 0068 | The last line, "Exactly!!", is credited to 謎の老人 (Mysterious Old Man), not Forfahren. It may be Graf's voice cutting in just before he appears, or a tag slip. Tag kept. |
| DB_0000_0025 | The 謎の老人とは……!? reading (Vampierre was the old man?) is interpretive. |
| DB_0000_0042 | Dying Vampierre: 話が…ちが…う…ぞ…/フォ…レ……ン, rendered "This... isn't... what... we agreed...... For...ren". It implies a deal with "Forfahren", or with Graf posing as him. Check the story intent. |
| C2_s06_0003–0026 | Neo Edo bathhouse gags: Sara's blush, Ryo singing たびゆけばァ (the naniwa-bushi *Mori no Ishimatsu* opening "On the road I go~") and trying to peek. The bathhouse setting is **inferred from context**. Verify in-game; the Ryo lines depend on it. |
| C2_s05_0003/0004 | Ryo: "!? ...Ah!? Forgive my intrusion." Context unknown (probably entering an occupied room). |
| C2_s05_0010 | "Curse that Echigoya! Such a cowardly trick......" followed by LIFE restored. The trigger object is unknown. |
| C2_s05_0031 / 0033 | Kokin Hyakuseki's joke waka rendered as mock 5-7-5. The originals are deliberately inane; tone check welcome. |
| C2_s01_0039 (shared) | Choice たたっ斬る! = "Cut it down!" serves both the locked door and the Vampierre confrontation. "Cut him down!" would suit the latter, but they share one string. |
| C2_s01_0065 | Vampierre's weather non sequitur ("The sun is out today... What dreadful weather") is intentional deflection, and a vampire joke. |
| DB_0000_0029/0030 | サルニッセ pun localized as "Hornuisance". The split is across two messages ("Hmph" + "! It's Hornisse!"), so check that the rendering joins them. |
| C2_s06_0074, DB_8000_0122 | Readings of the fallen ninja 爆 / 紅 / 真 as Baku / Kurenai / Shin are guesses (紅 could be Beni or Kō; 真 could be Makoto). |
| DB_8000_0064 | ウェザード王国 = "Kingdom of Weathard" (reading uncertain; ties to "Weathers"). |
| C2_s08_0029 | Robat's only line ミー!! = "Meee!!". It could be a cry, or English "Me!". |
| PROFILE_* | English runs about 160–200 chars per page versus about 100 JP glyphs. The small-font profile box capacity is unknown, so trim once the layout is known. |
| SYS_56C4, SYS_7600 | Hard-coded lengths. `en_parts` gives the text, but it must be re-pointed. "G" is used for 金; "Not enough / money!!" is split across the two JP pieces お金 / がたりません. |
| OPEN_* | Pre-broken with `[br]` at about 32 chars, on the assumption that the opening renderer doesn't wrap. Re-flow once its width is known. |
| C2_s06_0001 | An extra `[wait]` was added mid-line (harmless). |

## Continuity corrections
By struktured's decision, the English quietly fixes clear factual and date slips in the original script. Each fix is listed here.
Era anchors used: Hornisse's home era is NEA 1425 (his "22 years" to 1403 is correct). Sara's home era is about 1444
(Forfahren's "about 40 years" in C2_s03_0032; the NEA 1444 stage is "a painful and sad era" for her). Ryo's home era is NEA 2100
(Forfahren's "about 700 years" in C2_s05_0061; the NEA 2115 Resistance's "15 years ago" is consistent).

| ID | Original Japanese claim | Corrected English claim | Why |
|---|---|---|---|
| C2_s03_0055 | Graf to Sara: 「サラのいた時代からじゃと 22年ほど過去じゃ」 (NEA 1403 is about 22 years before her time) | "some 40 years before your own time" | Copy-paste of Hornisse's line. Forfahren tells Sara "about 40 years" (C2_s03_0032), which matches her era of about 1444. |
| C2_s05_0070 | Graf to Ryo: 「きみのいた時代からじゃと 22年ほど過去じゃ」 (about 22 years) | "some 700 years before your own time" | Same copy-paste. Forfahren tells Ryo "about 700 years" (C2_s05_0061), which matches NEA 2100. |
| C2_s04_0025 | Hornisse to the Man in Black: 「あれは 15年前……」 (that was 15 years ago) | "That was nearly twenty years ago......" | Hornisse fought Vampierre in his own era, NEA 1425 (with the revival in 1426), and this scene is NEA 1444: 18–19 years. "Nearly twenty" covers both. |

Checked and **left unchanged** because they are consistent: Hornisse's "22 years" (C2_s01_0079/0092); the Resistance's "15 years ago"
for Echigoya's defeat (DB_8000_0070/0102, NEA 2100 to 2115); Forfahren's 40 / 700 (C2_s03_0032, C2_s05_0061). The "Exactly!!" tag
on C2_s08_0054/0061/0068 is ambiguous rather than clearly wrong, so it stays flagged above and was not changed.

## Cultural notes
- **Echigoya (越後屋)**: the stock corrupt merchant of period dramas ("Echigoya, you are quite the villain" / "Nay, not so much as you, my lord").
  Kept as a name, since the joke carries over by genre.
- **SUKE / KAKU**: parody of Suke-san and Kaku-san, the retainers from *Mito Kōmon*. The joke survives as names only.
- **Kokin Hyakuseki (古今百石)**: pun on the *Kokin Wakashū* poetry anthology. He composes waka (5-7-5-7-7) and death poems.
- **バテレン (bateren)**: the Edo-era word for Portuguese missionaries, or "padres". Ryo uses it for Western magic and vampires; rendered
  "the foreign priests' tales" and "foreign sorcery".
- **キツネにばかされた**: "bewitched by a fox" (kitsune trickery); kept literally.
- **八百八町**: "808 districts", the traditional hyperbole for Edo's many neighborhoods.
- **Karakuri (からくり)**: Edo-period clockwork automata, hence the YAGURA "karakuri war machines".
- **ござる / 拙者 / お主**: samurai and ninja speech, rendered through register (formal, no contractions, "I shall") rather than
  fake-archaic thee/thou.
- **German names**: Hornisse (hornet), Forfahren (≈ Vorfahren, "ancestors"), Graf ("count"), Rose Castle (Burg Rose), Doppel Vampierre.
  These keep the game's Germanic fantasy flavor.
