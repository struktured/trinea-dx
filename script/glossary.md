# Trinea English glossary

Chosen English terms used throughout `script/en/`. Sources: the dumped JP script, eadmaster's RetroSubs name list
(https://github.com/eadmaster/RetroSubs, CC-BY-NC-SA 4.0), ritchie's GameFAQs walkthrough (faqs/36391), Japanese
strategy pages (super-famicom.jp, retroxgame.com, sakuhindb) for move names, and struktured's stream notes
(private). If you change a term, grep `script/src/*.txt` and re-run `tools/py/merge_en.py`.

## Heroes

| JP | English | Notes |
|----|---------|-------|
| ホルニッセ | **Hornisse** | German for "hornet". A masked knight, called the "legendary hero" (伝説の英雄). "Hornisse" is an alias (とおり名); his real name is Jiltania Weathers. Voice: terse and formal, a weary soldier. |
| ジルタニア（・ウェザーズ） | **Jiltania (Weathers)** | Hornisse's real name. Sara's father. Sara's scenario calls him "Jiltania" (Forfahren) or "Dad" (Sara). |
| サラ（・ウェザーズ／ウェザース） | **Sara Weathers** | Winged, horned girl who controls fire. Daughter of Jiltania and Lisa. Voice: bright and a bit cheeky ("Lucky me!"). She says お父さん = "Dad"; when she echoes Lillie's お父様 it becomes "Father". The JP spells it both ウェザーズ and ウェザース; English is always "Weathers". |
| 御船 椋 哲也 | **Tetsuya "Ryo" Mifune** | Neo Edo ninja of the Heaven Clan (天忍), member no. 4 of E.S.P. 8. **In all dialogue and speaker tags he is リョウ, rendered "Ryo".** See the decision below. |
| リョウ／椋 | **Ryo** | His ninja/code name (椋, read "Ryou"). The game gives this name, not Tetsuya, on every speaker tag. |

### The Ryou / Tetsuya decision
The game's own menus and marketing call the third hero 御船哲也 (char-select label, profile, the RetroSubs "Tetsuya Mifune"). But **every line he speaks is credited to 《リョウ》**, and the other characters call him リョウ, 椋, 天忍の椋, or リョウくん. The narration (DB_8000_0122) explains: "御船 椋 哲也... those who knew him simply called him 椋【リョウ】". So 椋 is his ninja name, written as a middle name.
**What I chose:**
- Speaker tags and dialogue use **Ryo** everywhere, as the game does. Switching to "Tetsuya" would mean overriding over a hundred credited lines, and would lose the in-world logic: Ryo is the name he fights under, while Midori, Echigoya, Graf and the Resistance all use the ninja name.
- The full name **Tetsuya "Ryo" Mifune** (given name first, nickname in quotes) is used wherever the JP writes out 御船 椋 哲也: DB_8000_0070/0102/0122 and DB_0000_0007. It is also recommended for the char-select label, which is graphics/system text. If that label is too narrow, use "Ryo".
- **Romanization is "Ryo", not "Ryou".** It matches the GameFAQs walkthrough ("Mifune 'Ryo' Tetsuya"), reads naturally in English, and saves a character on every speaker tag. If struktured prefers "Ryou", it is one global replace in `script/src/*.txt`: `\[hl\]Ryo\[hl\]`, `Ryo:`, `"Ryo"`, `Ryo!`, and so on.
- The RetroSubs profile header "Tetsuya Mifune (Untranslated)" is superseded.

## Supporting cast

| JP | English | Notes |
|----|---------|-------|
| リサ（・ウェザーズ） | **Lisa Weathers** | Hornisse's wife and Sara's mother (pregnant with Sara in NEA 1426). She calls Hornisse あなた, rendered "dear". Not in the task's name list; the name comes from RetroSubs. |
| リーリエ | **Lillie** | Lisa's attendant, later Sara's guardian figure. Sara calls her リーリエさん = "Miss Lillie" at first, and just "Lillie" once they are close. (FAQ: "Leerie Spencer".) |
| サラの父 | **Sara's Father** | Speaker tag for Jiltania in Sara's opening, before his name is revealed. |
| フォアファーレン | **Forfahren** | The good wizard who recruits the heroes. From German *Vorfahren* = "ancestors"; the RetroSubs spelling is kept. First appears as 謎の老人. |
| グラフ | **Graph** | The evil wizard, Forfahren's "friend", who kills him and tricks the heroes. German *Graf* = "count", which matches the game's German naming (Hornisse, Forfahren). The FAQ writes "Graph". Also appears as 謎の老人 in his own recruit scenes. |
| 謎の老人 | **Mysterious Old Man** | Speaker tag used before either wizard is named. |
| ヴァンピエール伯爵 | **Count Vampierre** | Campy vampire lord of Rose Castle. Slips into feminine speech (〜わ, 〜のよ) when rattled, rendered with camp ("Ooh, how vexiiing!!"). Signs his notes 美しきヴァンピエール = "Vampierre the Beautiful". |
| 中央のハデな紳士 | **Flashy Gentleman** | Literally "the flashy gentleman in the middle". Vampierre's tag before he introduces himself. |
| 分身 ヴァンピエール | **Doppel Vampierre** | Boss form. Literally "Clone Vampierre"; "Doppel" keeps the German flavor. His call "名付けて…" = "I call it...", struktured's phrasing from the stream notes. |
| 復活 ヴァンピエール | **Vampierre Reborn** | Final boss form in NEA 1426. |
| サルニッセ | **Hornuisance** | Vampierre's deliberate mangling of Hornisse (JP: サル "monkey" + ニッセ). Replaced with an English pun. |
| ゴステロ | **Gostelo** | Vampierre's butler and mad scientist (RetroSubs spelling). |
| 黒い男 | **Man in Black** | Vampierre's son, the avenger of NEA 1444. FAQ: "Darkman". "Man in Black" is used both as his tag and as the common noun ("a man in black"). |
| 謎の声 | **Mysterious Voice** | The Man in Black before he appears. |
| ヴァンピエール伯爵部隊 | **Count Vampierre's Guard** | His knight corps. |
| ペンタナイツ | **Penta Knights** | Penta Yellow / Black / Dark / Green / Red (ペンタイエロー…ペンタレッド). |
| ドラゴンナイト | **Dragon Knights** | Troops Vampierre sent to raid the town (C2_s01_0057). |
| ペンタドラゴン | **Penta Dragon** | The five-headed demon dragon (伝説の魔竜). Title of the GB prequel. |
| 闇黒大王（混沌の闇黒大王） | **Dark King (of Chaos)** | Epithet of the Penta Dragon in the opening and finale. |
| 越後屋 / 越後屋八兵 | **Echigoya / Hachibei Echigoya** | Neo Edo crime boss, servant of the Penta Dragon. Echigoya is the stock name of the corrupt merchant in samurai dramas (see notes). |
| 弥生 | **Yayoi** | Echigoya's only daughter. Ojou-sama laugh おーっほっほっ = "Oh-ho-ho-ho!". Ryo calls her 弥生どの = "Lady Yayoi". |
| ルリア 緑 ルーシア / 緑 | **Ruria Midori Lucia / Midori** | **One woman**, not three. The profile says she is a single third-generation American named 「ルリア緑ルーシア」, Ryo's love interest (the feeling is mutual). She leads the Resistance. Ryo calls her 緑 = "Midori". RetroSubs and the FAQ wrongly split her into "Ruria, Midori and Lucia"; that is corrected here. |
| レジスタンス | **Resistance** | Speaker tag for Resistance members, and for Midori before she gives her name. |
| 青獅子 / 紅獅子 | **Blue Leo / Red Leo** | Thug duo (RetroSubs). Laugh ケケケ = "Kekeke". |
| YAGURA－12号 / 13号 / 1号 | **YAGURA-12 / YAGURA-13 / YAGURA-1** | Karakuri (clockwork) war mechs. Katakana-only speech, rendered in ALL CAPS. |
| 忍者大名 | **Ninja Lord** | RetroSubs. Literally "Ninja Daimyo". |
| 武装魔神忍者隊 | **Armored Demon Ninja Squad** | Ninja of the Gray / Blue / Green Clan (忍者【灰家】【青家】【緑家】). |
| カッパ侍 | **Kappa Samurai** | |
| 古今百石 | **Kokin Hyakuseki** | Poetry-loving samurai boss. The name puns on the *Kokinshū* anthology and *hyakunin isshu*. His waka are rendered as 5-7-5-ish mock verse. |
| 武装侍 SUKE / KAKU | **Armored Samurai SUKE / KAKU** | Parody of Suke-san and Kaku-san from *Mito Kōmon*. |
| 天忍 / 地忍 / 神忍 / 風忍 | **Heaven / Earth / Divine / Wind Clan** | Ninja schools of E.S.P. 8. Members: Ryo (椋, Heaven), Baku (爆, Earth), Kurenai (紅, Divine), Shin (真, Wind). |
| ESP・8 / E・S・P・8 | **E.S.P. 8** | Neo Great Edo Defense Special Unit 8 (ネオ大江戸防衛第8特殊部隊). |
| アテンプトの衛士 | **Attempt Guard** | Imprisoned soldiers in NEA 403. |
| 国王ヘイス | **King Heyce** | King of Attempt (FAQ spelling). |
| リィシス | **Lysis** | Heyce's wife. FAQ: "Licys". |
| セトー | **Seto** | Villain holding Attempt. FAQ: "Setoh". |
| 石巨人 | **Stone Giant** | |
| ストーンゴーレム / JR | **Stone Golem / Stone Golem Jr.** | |
| ロバット / THE 8 / アップル / パワードスーツ | **Robat / THE 8 / Apple / Powered Suit** | Yayoi's NEA 2403 arena fighters (FAQ spellings). THE 8 speaks katakana, rendered in ALL CAPS. |
| 暦者の書 | **Book of Chronicles** | Save/load book. Its three save slots, 暦本【1】–【3】, are "Chronicle 1–3". |

## Places and eras

| JP | English | Notes |
|----|---------|-------|
| NEA暦○○年 | **the year NEA ○○** / "NEA ○○" in menus | Calendar era. Stages: NEA 403 (Attempt), 1403 (Forfahren's era / final), 1425–1426 (Hornisse's era), 1444 (Sara's era), 2100/2115 (Neo Edo), 2403 (cyberpunk arena). |
| ローゼ城 | **Rose Castle** | Vampierre's castle (RetroSubs). |
| ウェザード王国 | **Kingdom of Weathard** | Hornisse's kingdom (DB_8000_0064). The reading ウェザード is uncertain: could also be "Weathered" or "Wezard". |
| ネオ江戸 / ネオ大江戸 | **Neo Edo / Neo Great Edo** | Future Tokyo. |
| ネオ大江戸八百八町 | **the 808 districts of Neo Great Edo** | From the idiom 八百八町 (Edo's "808 towns"). |
| ネオ人形町 | **Neo Ningyocho** | District name (Ningyōchō is a real Tokyo neighborhood). |
| アテンプト | **Attempt** | "World where the gods dwell", NEA 403. |

## Items, upgrades, system

| JP | English | Notes |
|----|---------|-------|
| TRINEA | **TRINEA** | Kept in caps. Formed by the three orbs. |
| 青／緑／紅のオーブ | **Blue / Green / Crimson Orb** | Hornisse seeks the Blue, Sara the Green, Ryo the Crimson. 紅 = "crimson", not "red", to echo 深紅マント "crimson cape". The opening's 【青／緑／紅】 is "Blue, Green and Crimson"; RetroSubs had "Water, Nature and Fire". |
| 5つの光 | **the Five Lights** | |
| 呪歌 | **Cursed Song** | The Man in Black's power source. |
| 不死の宝石 | **gem of immortality** | |
| 必殺ワザ（の使用回数） | **special move (uses)** | Item/shop pickup: "Special move uses increased by 1!!" |
| LIFE（が回復しました） | **LIFE (restored!)** | Kept as "LIFE" to match the HUD graphic. |
| 攻撃力 | **attack power** | Shop. |
| 所持金 / 金 / お金 | **money / G** | Shop currency label "G" (SYS_7600 金). The HUD word 所持金 is graphics. |
| 暦本 | **Chronicle** | Save slot. |
| 時のとびら | **Door of Time** | Load prompt. |
| 《どうしますか？》 | **<What will you do?>** | Choice prompt. |
| たたっ斬る！ | **Cut it down!** | Choice, used both for a locked door and for Vampierre. Also Ryo's catchphrase in the profile ("I'll cut you down!"). |
| 力をかす！ / やめとく | **Lend a hand! / No thanks** | Recruit choice. |

## Special moves (from JP strategy pages; not in the dumped script)

| JP | English | Hero | Input |
|----|---------|------|-------|
| ドラゴンファイヤー | **Dragon Fire** | Sara | rotate D-pad, then B |
| エレクトリック・バッファロー | **Electric Buffalo** | Hornisse | rotate D-pad, then A |
| 分身の術 | **Shadow Clone Technique** | Ryo | rotate D-pad, then Y |

## Speech tics

| JP | English |
|----|---------|
| 〜でござる (Ryo) | Stiff, formal, contraction-free English ("I shall", "It is", "That I cannot forgive!"). Drops into casual "Bring it on!!" / "Let's go!!" when he uses 〜ぜ. |
| 〜じゃ (Forfahren / Graf) | Folksy old-man English ("my boy", "Ho ho ho", "I'm counting on you"). |
| ヴァハハハ (Man in Black) | "Vahahaha!" (kept as his signature laugh). |
| おーっほっほっ (Yayoi) | "Oh-ho-ho-ho!" |
| ハッハッハッ | "Ha ha ha!" |
