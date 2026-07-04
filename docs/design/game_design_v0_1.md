# Game Design v0.1

## Genre

Tri V Ryad is a vertical match-3 battle game for Godot 4.x, planned for Yandex Games / Web-first release.

## Board

- Board size: 9 columns by 9 rows.
- Orientation: portrait 9:16.
- Base resolution: 720x1280.

## Heroes

The player will choose or bring 3 heroes before battle.

Each hero owns one vertical lane group on the board:

- Hero 1: columns 1-3.
- Hero 2: columns 4-6.
- Hero 3: columns 7-9.

## Hero Lanes

Hero Lanes are the core future mechanic.

Future rule: matches activate heroes based on the affected columns.

Future rule: heroes charge abilities from matched tiles in their own lanes.

Examples:

- A match contained only in columns 1-3 should support Hero 1 activation.
- A match contained only in columns 4-6 should support Hero 2 activation.
- A match contained only in columns 7-9 should support Hero 3 activation.
- A match spanning lane borders may later support multiple heroes or special rules.

Exact activation, charge, targeting, and combo rules are intentionally not implemented in this stage.

## Battle Screen Layout

- Enemy panel at the top.
- HUD near the top for level and moves placeholders.
- 9x9 board frame in the center.
- 3 hero cards below the board.
- Board lanes visually map to the hero cards: Hero 1 left, Hero 2 center, Hero 3 right.

## Future Progression

After battles, the player will later receive upgrade points. Upgrade points will improve hero attack and HP.

Complex meta progression is not part of the foundation stage.

## MVP Exclusions

- No ads.
- No payments.
- No Yandex SDK.
- No RuStore or Android-specific code.
- No final art.
- No complex meta progression.
- No match detection.
- No tile swapping.
- No board state.
- No battle state.
- No damage, HP, or abilities.
