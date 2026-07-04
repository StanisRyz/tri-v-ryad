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

## Board Core v0.1

- Board size is 9x9.
- The board uses 5 basic tile types.
- Generated boards avoid starting matches.
- Matches are horizontal or vertical lines of 3 or more matching tiles.
- Swaps are accepted only when they create at least one match.
- Resolve cycles clear matched cells, apply gravity, refill, and repeat cascades until stable.

Hero Lanes remain future battle logic. The current board core stores exact match cell coordinates but does not activate heroes.

## Battle Core v0.1

- A battle has 3 heroes and 1 enemy.
- The board has 3 Hero Lanes: columns 0-2, 3-5, and 6-8 in code.
- Matched cells activate heroes by their column lanes.
- Damage is `hero attack * matched tile count` for each lane.
- Matched tiles charge hero abilities, but real abilities are future work.
- Enemy intent counts down after player turns and triggers a simple attack.
- Victory occurs when enemy HP reaches 0.
- Defeat occurs when moves run out or all heroes are dead.

Animations, real abilities, hero selection, upgrades, and platform systems remain future work.

## First Playable Prototype v0.1

- The prototype runs one fixed test battle.
- The 9x9 board is displayed with placeholder colored tiles.
- Input uses two-click swapping: select one tile, then select a neighboring tile.
- Valid swaps trigger hero damage and ability charge from the initial swap matches.
- Cascades stabilize the board but do not deal damage yet.
- Enemy attacks through simple intent timing.
- The battle shows live HUD, enemy, and hero updates.
- Victory and defeat show a result overlay.
- Restart starts a fresh fixed test battle.

Animations, real abilities, upgrades, hero selection, and platform systems remain future work.

## Mobile Input v0.1

- Hybrid input supports both two-click swaps and drag/swipe swaps.
- Drag direction maps to the neighboring tile in the dominant direction.
- Short swipes are ignored and show simple feedback.
- Input locks during turn processing and remains locked after victory or defeat.
- Invalid input gets simple status feedback such as "Swipe too short", "Outside board", or "Input locked".

Animation, advanced feedback, sound, and gesture polish remain future work.

## Basic Turn Feedback v0.1

- Valid swaps briefly flash involved cells.
- Invalid swaps show simple feedback.
- Initial matched cells highlight before temporary feedback is cleared.
- Activated Hero Lanes highlight after the turn.
- Damage and enemy action are shown through short status messages.
- Input remains locked during feedback and unlocks only after feedback completes.

Full cascade animation, real tile movement, particles, sound, and progression remain future work.

## Hero Abilities v0.1

- Ability charge comes from matched tiles in hero lanes.
- Ready, alive heroes can use abilities from their HeroCard.
- Hero 1: Power Strike deals direct enemy damage.
- Hero 2: Line Break clears the center row and stabilizes the board.
- Hero 3: Rally Heal heals all alive heroes.
- Successful ability use resets that hero's charge to 0.
- Ability use does not consume moves.
- Ability use does not trigger enemy action.
- Ability-cleared tiles do not grant charge or hero damage.

Target selection, cooldowns, ability upgrades, new heroes, level configs, saves, and platform systems remain future work.

## Level System v0.1

- Battles are created from data configs.
- 5 test levels exist.
- Levels define enemy config, moves, enemy intent, and fixed hero configs.
- `LevelSelectScreen` chooses a `level_id`.
- `GameScreen` starts the selected level through `BattlePresenter`.
- Victory and defeat rules stay unchanged.

Progression, unlocks, stars, upgrade rewards, hero selection, and complex objectives remain future work.

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
- No saved level completion, unlocks, stars, or upgrade rewards.
- No target selection or ability upgrades.
- No full cascade animations.
- No real tile movement.
- No sound or particles.
