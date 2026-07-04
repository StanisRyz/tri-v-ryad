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

Animations, hero selection, and platform systems remain future work.

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

Animations, hero selection, and platform systems remain future work.

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

Full cascade animation, real tile movement, particles, sound, and deeper progression remain future work.

## Board Animation Polish v0.1

- Valid swaps receive a short visual pulse/flash on the swapped cells.
- Invalid swaps receive visual rejection feedback on the involved cells.
- Matched cells highlight and fade during turn feedback.
- Board refresh/refill receives lightweight appear feedback after matched cells fade.
- Input remains locked during the full feedback sequence and unlocks only after `feedback_finished`.
- Board rules, battle rules, progression, rewards, stars, unlocks, upgrades, and save format are unchanged.

Color bombs, wrapped bombs, special combos, full falling animation, cascade damage, cascade-step animation, particles, sound, final art, and real tile movement remain future work.

## Special Tiles v0.1

- Match 4+ creates a line special tile on a deterministic cell inside the match.
- Horizontal matches create horizontal line tiles.
- Vertical matches create vertical line tiles.
- Horizontal line tiles clear their row when activated.
- Vertical line tiles clear their column when activated.
- Special tile metadata is stored separately from the base tile type.
- Special tile metadata moves with swaps and gravity.
- Refilled tiles do not spawn with special metadata.
- Special-cleared cells do not add extra hero damage in v0.1.
- Special-cleared cells do not add extra ability charge in v0.1.
- Special tiles use simple placeholder markers in `TileView`.

Color bombs, wrapped bombs, special + special combos, special battle rewards, cascade damage, particles, sound, and final art remain future work.

## Hero Abilities v0.2

- Ability charge comes from matched tiles in hero lanes.
- Ready, alive heroes can use abilities from their HeroCard.
- All hero abilities deal direct enemy damage.
- Ability damage is `hero attack * ability damage_multiplier`.
- Warrior Strike uses x5 damage.
- Guardian Strike uses x4 damage.
- Healer Strike uses x3 damage.
- Mage Strike uses x6 damage.
- Ranger Strike uses x4 damage.
- Successful ability use resets that hero's charge to 0.
- Ability use does not consume moves.
- Ability use does not trigger enemy action.
- Ability use does not advance enemy intent.
- Hero abilities do not modify the board.
- Hero abilities do not clear tiles.
- Hero abilities do not heal heroes.

Target selection, cooldowns, healing abilities, shield abilities, buffs, debuffs, board-clearing hero abilities, ability upgrades, new heroes, cloud saves, and platform systems remain future work.

## Hero Roster and Team Selection v0.1

- The roster has 5 placeholder heroes in `HeroCatalog`.
- The player selects exactly 3 unique heroes for battle.
- Selected team order maps directly to Hero Lanes: first hero to lane 0, second hero to lane 1, third hero to lane 2.
- Selected team IDs are stored in `TeamSelectionState` inside `PlayerProgress`.
- `ProgressManager` reads, validates, saves, and normalizes selected team data.
- `TeamSelectionResolver` owns validation rules: exactly 3 heroes, no duplicates, and all IDs exist in `HeroCatalog`.
- Battles use the selected team when `BattleFactory` receives both `PlayerProgress` and `HeroCatalog`.
- All roster heroes have an `ability_id` mapping to the v0.2 damage-only abilities.
- Missing or invalid saved team data uses the default team: Warrior, Guardian, and Healer.

Gacha, rarity, hero unlocks, hero shards, portraits, drag-and-drop team UI, and roster balance pass remain future work.

## Character Upgrade Screen v0.2

- Upgrade points are spent in the Heroes screen, implemented through the existing `UpgradeScreen` route.
- All 5 roster heroes from `HeroCatalog` can be upgraded.
- Attack and HP are upgraded separately.
- Each hero row shows ability ID, attack level, HP level, current attack, next attack, current max HP, and next max HP.
- Upgrade purchases go through `ProgressManager` and `UpgradeResolver`.
- `UpgradeScreen` does not mutate `PlayerProgress` directly and does not read or write save files.
- Upgrades save locally through the existing progress save flow.
- Old saves without `hero_4` or `hero_5` upgrade records are handled safely at 0/0 until upgraded.
- `BattleFactory` uses saved upgraded stats for future battles, including selected `hero_4` and `hero_5`.
- The victory overlay shows reward/stars and links to the Heroes screen, but does not contain +Attack/+HP spending controls.

Hero unlocks, rarity, gacha, hero shards, ability upgrades, max levels, scaling costs, reset upgrades, equipment, portraits, and final art remain future work.

## Level System v0.1

- Battles are created from data configs.
- Stage 16 adds a 10-level early campaign slice.
- Levels 1-2 are very easy intro battles, levels 3-4 add light challenge, levels 5-6 make upgrades feel useful, levels 7-9 are noticeably harder, and level 10 is the first early mini-boss gatekeeper.
- Levels define enemy config, moves, enemy intent, and fixed hero configs.
- `LevelSelectScreen` chooses a `level_id`.
- `GameScreen` starts the selected level through `BattlePresenter`.
- Every level uses the same objective: defeat the enemy.
- Victory and defeat rules stay unchanged.
- Balance is v0.1 content tuning and is expected to change after playtesting.

Hero selection and complex objectives remain future work.

## Progression v0.1

- Victory grants upgrade points from `LevelConfig.reward_upgrade_points`.
- Rewards can be earned repeatedly in v0.1.
- Upgrade points can improve hero attack or HP.
- Attack level and HP level are stored per hero in `HeroUpgradeState`.
- `PlayerProgress` stores upgrade points, hero upgrade state, and level progress.
- Progress saves locally to `user://save_v1.json`.
- `BattleFactory` applies saved attack and HP levels to future battle heroes.
- `HeroConfig` remains base data and is not mutated by upgrades.
- Upgrade rewards remain repeatable in v0.1.

Cloud save, Yandex SDK integration, one-time rewards, stars-based rewards, hero selection, max levels, scaling costs, reset upgrades, and complex economy remain future work.

## Campaign Progression v0.1

- Level 1 is always unlocked.
- Each next level unlocks after the previous level is completed.
- Victory saves level completion.
- Defeat does not complete a level and does not unlock the next level.
- Stars are based on remaining moves at victory.
- 1 star is awarded for any victory.
- 2 stars are awarded when at least 25% of level moves remain.
- 3 stars are awarded when at least 50% of level moves remain.
- Best stars and best remaining moves are preserved across replays.
- Local save stores level progress in `user://save_v1.json`.

One-time rewards, level map, chapters, stars-based rewards, max upgrade levels, scaling costs, reset upgrades, and deeper upgrade trees remain future work.

## MVP Exclusions

- No ads.
- No payments.
- No Yandex SDK.
- No RuStore or Android-specific code.
- No final art.
- No complex meta progression.
- No one-time rewards or stars-based rewards.
- No level map or chapters.
- No hero unlocks, gacha, rarity, shards, ability upgrades, max upgrade levels, scaling upgrade costs, reset upgrades, equipment, portraits, or final art.
- No cloud save.
- No target selection or ability upgrades.
- No full cascade animations.
- No real tile movement.
- No sound or particles.

## Stage 16: Balance and Content Expansion v0.1

- Stage 16 is implemented.
- `LevelCatalog` now contains a 10-level early campaign slice from Training Dummy through Gatekeeper.
- The campaign uses a simple enemy HP/attack, moves, and upgrade-point reward curve.
- All levels still use the single objective: defeat the enemy.
- Balance tests cover catalog size, unique IDs, required content fields, total reward range, and broad difficulty growth.
- No new mechanics, objectives, heroes, abilities, special tiles, platform SDK, cloud save, ads, payments, monetization, final art, sound, or particles were added.
- Stage 17 is now complete.

## Stage 17: Unified Damage Abilities v0.2

- Stage 17 is implemented.
- `AbilityData` now includes `damage_multiplier`.
- All five current hero abilities are damage-only enemy strikes.
- Healing hero abilities were removed.
- Board-clearing hero abilities were removed.
- Hero abilities do not modify the board.
- Hero abilities do not consume moves.
- Hero abilities do not advance enemy intent.
- All levels still use the single objective: defeat the enemy.
- No new heroes, battle objectives, healing abilities, shield abilities, buffs, debuffs, target selection, cooldowns, ability upgrades, skill trees, color bombs, new special tiles, platform SDK, cloud save, ads, payments, final art, sound, or particles were added.
- Next planned stage: Stage 18, Special tiles v0.2: color bomb and activation polish.
