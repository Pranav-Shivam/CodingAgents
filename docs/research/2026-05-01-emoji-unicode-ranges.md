# Emoji Unicode Ranges — Research Log
Date: 2026-05-01
Task: Comprehensive emoji detection for security scanning agent

---

## URLs Visited

1. Source: [UTS #51: Unicode Emoji Technical Report](https://unicode.org/reports/tr51/) — Official specification defining emoji properties, ZWJ sequences, variation selectors, tag characters, and the canonical regex pattern. Provided property definitions and the UAX#51 regex template.

2. Source: [Unicode emoji-data.txt (v16.0)](https://www.unicode.org/Public/16.0.0/ucd/emoji/emoji-data.txt) — Authoritative machine-readable property assignments for all six emoji properties. Provided complete Extended_Pictographic ranges used in this report.

3. Source: [emoji-regex — GitHub (mathiasbynens)](https://github.com/mathiasbynens/emoji-regex) — npm package that generates regex from emoji-test-regex-pattern at build time. Does not hardcode ranges; builds dynamically from Unicode data. Confirms that static range lists require manual maintenance per Unicode release.

4. Source: [emoji-test-regex-pattern — GitHub (mathiasbynens)](https://github.com/mathiasbynens/emoji-test-regex-pattern) — The generator that emoji-regex depends on; Java/JavaScript pattern for all emoji in emoji-test.txt per UTS#51.

5. Source: [ripgrep discussion #1623 — Find all emoji in codebase](https://github.com/BurntSushi/ripgrep/discussions/1623) — Community solutions for emoji grep. Provided: UAX#51 rg pattern, `\p{Emoji}`, `\p{Extended_Pictographic}`, note about `--dfa-size-limit` flag.

6. Source: [Python emoji gist (Alex-Just)](https://gist.github.com/Alex-Just/e86110836f3f93fe7932290526529cd1) — Python EMOJI_PATTERN with 11 Unicode block ranges as re.compile character class. Warns it has limitations and recommends demoji.

7. Source: [Python emoji regex gist (Saluev)](https://gist.github.com/Saluev/604c9c3a3d6032770e15a0da143f73bd) — Structured Python pattern decomposed into EMOJI_CORE_SEQUENCE, EMOJI_ZWJ_SEQUENCE, EMOJI_TAG_SEQUENCE components matching UAX#51 structure.

8. Source: [FreeCodeCamp: How to Use RegEx to Match Emoji](https://www.freecodecamp.org/news/how-to-use-regex-to-match-emoji-including-discord-emotes/) — Practical article; concludes `\p{Extended_Pictographic}` flag `u` is the correct modern solution for JS.

9. Source: [alexwlchan: regex library Unicode property escapes](https://alexwlchan.net/notes/2024/regex-library-for-unicode-property-escapes/) — Confirmed `\p{Emoji}` matches digits; `\p{Extended_Pictographic}` does not. Recommends PyPI `regex` library as drop-in replacement for `re`.

10. Source: [hrekov.com: Detect Emoji Python](https://hrekov.com/blog/detect-emoji-python) — Shows simplified Python range pattern; explicitly warns it fails on skin tone modifiers and ZWJ sequences.

11. Source: [Emoji Unicode tables — timwhitlock](https://apps.timwhitlock.info/emoji/tables/unicode) — Historical breakdown of emoji blocks with non-contiguous single-codepoint entries; useful for understanding pre-block-era emoji scattered in Basic Multilingual Plane.

12. Source: [rexegg.com: pcregrep / pcre2grep](https://www.rexegg.com/pcregrep-pcretest.php) — Confirms Windows pcregrep binaries compiled with Unicode properties support. `\p{Extended_Pictographic}` works in pcre2grep on Windows.

13. Source: [GitHub: git-for-windows PCRE v2 commit](https://github.com/git-for-windows/git/commit/94da9193a6eb8f1085d611c04ff8bbb4f5ae1e0a) — Git for Windows added PCRE2 support; means `grep -P` on Windows Git Bash uses PCRE2 with Unicode property support.

---

## Key Facts

### Extended_Pictographic (Unicode 16.0) — complete ranges
Source: https://www.unicode.org/Public/16.0.0/ucd/emoji/emoji-data.txt

BMP ranges (Basic Multilingual Plane — U+0000 to U+FFFF):
00A9, 00AE, 203C, 2049, 2122, 2139, 2194..2199, 21A9..21AA, 231A..231B, 2328, 2388,
23CF, 23E9..23EC, 23ED..23EE, 23EF, 23F0, 23F1..23F2, 23F3, 23F8..23FA, 24C2,
25AA..25AB, 25B6, 25C0, 25FB..25FE,
2600..2605, 2607..260D, 260E, 260F..2610, 2611, 2612, 2614..2615, 2616..2617, 2618,
2619..261C, 261D, 261E..261F, 2620, 2621, 2622..2623, 2624..2625, 2626, 2627..2629,
262A, 262B..262D, 262E, 262F, 2630..2637, 2638..2639, 263A, 263B..263F, 2640, 2641,
2642, 2643..2647, 2648..2653, 2654..265E, 265F, 2660, 2661..2662, 2663, 2664,
2665..2666, 2667, 2668, 2669..267A, 267B, 267C..267D, 267E, 267F, 2680..2685,
2690..2691, 2692, 2693, 2694, 2695, 2696..2697, 2698, 2699, 269A, 269B..269C,
269D..269F, 26A0..26A1, 26A2..26A6, 26A7, 26A8..26A9, 26AA..26AB, 26AC..26AF,
26B0..26B1, 26B2..26BC, 26BD..26BE, 26BF..26C3, 26C4..26C5, 26C6..26C7, 26C8,
26C9..26CD, 26CE, 26CF, 26D0, 26D1, 26D2, 26D3, 26D4, 26D5..26E8, 26E9, 26EA,
26EB..26EF, 26F0..26F1, 26F2..26F3, 26F4, 26F5, 26F6, 26F7..26F9, 26FA, 26FB..26FC,
26FD, 26FE..2701, 2702, 2703..2704, 2705, 2708..270C, 270D, 270E, 270F, 2710..2711,
2712, 2714, 2716, 271D, 2721, 2728, 2733..2734, 2744, 2747, 274C, 274E, 2753..2755,
2757, 2763, 2764, 2765..2767, 2795..2797, 27A1, 27B0, 27BF,
2934..2935, 2B05..2B07, 2B1B..2B1C, 2B50, 2B55,
3030, 303D, 3297, 3299

Supplementary planes:
1F000..1F003, 1F004, 1F005..1F0CE, 1F0CF, 1F0D0..1F0FF (Mahjong/Playing Cards + extended)
1F10D..1F10F, 1F12F, 1F16C..1F16F, 1F170..1F171, 1F17E..1F17F, 1F18E
1F191..1F19A, 1F1AD..1F1E5
1F1E6..1F1FF (Regional Indicators / flags)
1F201..1F202, 1F203..1F20F, 1F21A, 1F22F, 1F232..1F23A, 1F23C..1F23F
1F249..1F24F, 1F250..1F251, 1F252..1F2FF
1F300..1F9FF (all of Misc Symbols/Pictographs, Emoticons, Transport, Supplemental)
1FA00..1FAFF (Symbols Extended-A: chess, shapes, objects, hands, body)

### Emoji_Component property ranges
Source: https://www.unicode.org/Public/16.0.0/ucd/emoji/emoji-data.txt

0023          # hash sign (keycap base)
002A          # asterisk (keycap base)
0030..0039    # digits 0-9 (keycap bases)
200D          # zero width joiner (ZWJ sequences)
20E3          # combining enclosing keycap
FE0F          # variation selector-16 (emoji presentation)
1F1E6..1F1FF  # regional indicator letters (flag pair components)
1F3FB..1F3FF  # skin tone modifiers (Fitzpatrick scale)
1F9B0..1F9B3  # hair component (red, curly, bald, white)
E0020..E007F  # tag characters (subdivision flags like England, Scotland, Wales)

---

## What the Current Agent Misses

Current agent ranges: 1F300–1F9FF, 1FA00–1FAFF, 2600–27BF, FE00–FE0F

MISSED RANGES:

1. U+00A9, U+00AE — copyright (c), registered (R) — both are Emoji
2. U+203C, U+2049 — !! and !? punctuation used as emoji
3. U+2122 — trademark symbol TM
4. U+2139 — information i
5. U+2194..U+2199 — arrows (left-right, up-down, diagonal)
6. U+21A9..U+21AA — curved arrows
7. U+231A..U+231B — watch, hourglass
8. U+2328 — keyboard
9. U+2388 — helm symbol (added in Unicode 16.0 Extended_Pictographic)
10. U+23CF — eject symbol
11. U+23E9..U+23FA — media control buttons (play, pause, etc.)
12. U+24C2 — circled M
13. U+25AA..U+25FE — geometric shapes (small/medium squares, triangles)
14. U+2600..U+25FF range partially missed — current starts at 2600 but agent
    only covers 2600–27BF; misses U+2388 and U+24C2 which are BELOW 2600
15. U+2934..U+2935 — curved arrows
16. U+2B05..U+2B07 — left/down/up arrows
17. U+2B1B..U+2B1C — large black/white squares
18. U+2B50 — star (*)
19. U+2B55 — heavy circle
20. U+3030, U+303D — wavy dash, part alternation mark (CJK area)
21. U+3297, U+3299 — circled CJK ideographs
22. U+1F000..U+1F0FF — Mahjong tiles, Domino tiles, Playing Cards
    (Extended_Pictographic covers the full block minus assigned non-emoji)
23. U+1F100..U+1F1FF — Enclosed Alphanumeric Supplement incl. regional indicators
    (agent has 1F1E0-1F1FF in its FE00-FE0F range? No — FE00-FE0F is variation
    selectors; 1F1E0-1F1FF is completely missing from agent ranges)
24. U+1F200..U+1F2FF — Enclosed CJK Letters and Months extended
25. U+1F700..U+1F77F — Alchemical Symbols (Extended_Pictographic: 1F700..1F776)
26. U+1F780..U+1F7FF — Geometric Shapes Extended (Extended_Pictographic: 1F77B..1F7D5, 1F7E0..1F7F0)
27. U+1F800..U+1F8FF — Supplemental Arrows-C (Extended_Pictographic: 1F900..1F90B starts here)
28. U+E0020..U+E007F — Tag characters for subdivision flags (COMPLETELY MISSING)
29. ZWJ U+200D — zero-width joiner; invisible but creates combined emoji
30. U+20E3 — combining enclosing keycap
31. U+FE0E — VS15 text presentation selector (missed; agent only has FE00-FE0F which
    actually does cover FE0E and FE0F, so this is covered)

Key structural misses:
- The range FE00..FE0F the agent uses IS variation selectors — correctly capturing FE0F
- But the agent completely misses the BMP emoji scattered from U+00A9 to U+2BFF
- Tag characters E0020..E007F are completely absent (needed for flags: England, Scotland, Wales)
- Regional indicators 1F1E0..1F1FF are absent (iOS-style flag pairs)
- Mahjong/Playing Cards 1F000..1F0FF are absent
- Alchemical Symbols 1F700..1F77F are absent
- Geometric Shapes Extended 1F780..1F7FF are absent
