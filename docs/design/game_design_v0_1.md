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
- Compact HUD row directly below the enemy panel for Level / Moves / Levels.
- 9x9 board in the center, scaled in portrait to align visually with the hero party panel.
- 3 hero cards below the board.
- Board lanes map mechanically to the hero cards: Hero 1 left, Hero 2 center, Hero 3 right.
- Permanent Hero Lane separator/debug grid visuals are not shown during the normal board state.

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
- Retry starts a fresh attempt for the current level.

Animations, hero selection, and platform systems remain future work.

## Mobile Input v0.1

- Hybrid input supports both two-click swaps and drag/swipe swaps.
- Drag direction maps to the neighboring tile in the dominant direction.
- Short swipes are ignored and show simple feedback.
- Input locks during turn processing and remains locked after victory or defeat.
- Invalid input gets simple status feedback such as "Swipe too short", "Outside board", or "Input locked".

Animation, advanced feedback, sound, and gesture polish remain future work.

## Basic Turn Feedback v0.1

- Valid animated turns are owned by `AnimatedTurnFlow`: swap, current match clear, special creation, gravity/refill, cascade repeats, final board handoff, then damage particles/enemy hit/text/result feedback.
- Invalid swaps show simple rejection feedback and then clear transient board state.
- Initial matched cells, cascade cells, booster target previews, booster activation flashes, and special creation sources may show temporary feedback, but selected/highlight/preview/invalid/lane state must be cleared before the final board/result flow continues.
- Activated Hero Lanes highlight temporarily after the turn.
- Damage and enemy action are shown through short status messages.
- Input remains locked during feedback and unlocks only after feedback completes.

Real tile movement, final particle art, real audio, and deeper progression remain future work.

## Board Animation Polish v0.1

- Valid animated turns use the Stage 46-48 stepwise pipeline through `AnimatedTurnFlow`; `TurnFeedbackPresenter` must not replay board movement, match highlights, clear effects, special activation visuals, refill effects, or full-board refresh animations afterward.
- Invalid swaps receive visual rejection feedback on the involved cells.
- Matched/cascade/special/booster clear visuals and booster targeting previews are transient and must clean overlay ghosts, preview nodes, `AnimationLayer` children, tile tint/scale drift, selected-cell state, and highlights before damage particles or result overlay display.
- Board final handoff updates the real `TileView` state while overlay ghosts still cover the board, then removes the overlay only after the real board is ready.
- Input remains locked during the full feedback sequence and unlocks only after `feedback_finished`.
- Board rules, battle rules, progression, rewards, stars, unlocks, upgrades, and save format are unchanged.

Wrapped bombs, special combos, full falling polish, final particle art, real audio, final art, and real tile movement remain future work.

## Result Flow v0.1

- `GameScreen` detects victory/defeat through `BattlePresenter.battle_finished` after the existing turn/booster feedback chain.
- Victory completion and stars are still saved through `ProgressManager.complete_level()` and `LevelCompletionResolver`; result overlay UI only displays prepared data.
- Victory result data includes `level_id`, level display label, stars earned, best stars, moves left, compatibility reward amount, next level id when launchable, whether the next level was newly unlocked, and whether a new zone was unlocked.
- Defeat result data includes `level_id`, level display label, moves left when useful, and a short retry suggestion.
- Victory overlay shows the completed level, stars earned, best stars, moves left, and only true newly earned next-level/zone-unlock messages. Replay wins on already completed levels must not show false new-unlock messages.
- Defeat overlay shows the failed level and a concise suggestion to retry with bigger matches and special tiles.
- Victory actions are Next Level, Retry, and Levels. Defeat actions are Retry and Levels. Next Level is visible and enabled only when another unlocked campaign level exists.
- Next Level hides the overlay, clears transient state, sets the next level id, and reuses the normal `GameScreen` battle start flow so board, battle state, boosters, HUD, enemy, background, modifier, and input are rebuilt.
- Retry hides the overlay and reuses the same battle start flow for the current level.
- Levels returns to `LevelSelectScreen`; `App` calls `refresh_progress_state()` after managers are set so completion, stars, next-level unlocks, and zone availability refresh immediately.
- Result overlays appear only after board animation, special/booster animation, damage particles, enemy hit feedback, transient visual cleanup, and progress save/update are complete.
- Cleanup before result display, retry, next level, and LevelSelect return must leave no booster preview/selection, highlights, animation-layer nodes, pending board state, or particles behind.

## Special Tiles v0.2

- Match 4 creates a line special tile on a deterministic cell inside the match.
- Match 5+ creates a color bomb on a deterministic cell inside the match.
- Horizontal match 4 creates horizontal line tiles.
- Vertical match 4 creates vertical line tiles.
- Horizontal line tiles clear their row when activated.
- Vertical line tiles clear their column when activated.
- Color bombs clear tiles of the activated bomb cell's selected/base tile type.
- Special tile metadata is stored separately from the base tile type.
- Special tile metadata moves with swaps and gravity.
- Refilled tiles do not spawn with special metadata.
- Special tiles affect board clearing only.
- Special-cleared cells do not add extra hero damage in v0.2.
- Special-cleared cells do not add extra ability charge in v0.2.
- Special tiles use simple placeholder markers in `TileView`.
- Special activation feedback uses board resolve result data and remains presentation-only.

Wrapped bombs, special + special combos, special battle rewards, cascade damage, particles, sound, and final art remain future work.

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
- Each hero row shows ability ID, attack level, HP level, current attack, next attack, current max HP, next max HP, upgrade cost, and max/not-enough-points state.
- Upgrade purchases go through `ProgressManager` and `UpgradeResolver`.
- Upgrade costs and stat growth use `UpgradeEconomyConfig`.
- `UpgradeScreen` does not mutate `PlayerProgress` directly and does not read or write save files.
- Upgrades save locally through the existing progress save flow.
- Old saves without `hero_4` or `hero_5` upgrade records are handled safely at 0/0 until upgraded.
- `BattleFactory` uses saved upgraded stats for future battles, including selected `hero_4` and `hero_5`.
- The victory overlay shows reward/stars and links to the Heroes screen, but does not contain +Attack/+HP spending controls.

Hero unlocks, rarity, gacha, hero shards, ability upgrades, reset upgrades, equipment, portraits, and final art remain future work.

## Level System v0.1

- Battles are created from data configs.
- Stage 25 expands the campaign foundation to 100 generated levels.
- Player-facing level labels are numbers-only, such as `Level 1`.
- Level IDs use `level_1` through `level_100`; `level_101` is not part of the catalog.
- Level labels use `Level 1` through `Level 100`.
- Moves use the Stage 25 placeholder curve; upgrade-point rewards use the Stage 27 linear economy curve across the 100 levels.
- Levels define moves, fallback/default enemy config, and fixed hero configs.
- Battles select enemies from the shared `EnemyCatalog` roster through `EnemySelectionResolver` when the level starts.
- `EnemySelectionResolver` is deterministic/testable when given a seeded `RandomNumberGenerator`.
- Selected enemies are scaled by `EnemyScalingResolver` after selection and before `BattleFactory` creates `BattleState`.
- Enemy level scaling is linear-only and changes only HP and attack.
- `LevelSelectScreen` groups the 100-level campaign into 10 zones of 10 levels, shows only the selected unlocked zone, chooses a `level_id`, opens `GameScreen` directly, and opens Settings from its top panel. `MainMenuScreen` and `TeamSelectScreen` remain inactive legacy/future code in the active direct flow (see Stage 32 and Stage 35).
- `GameScreen` starts the selected level through `BattlePresenter`.
- Every level uses the same objective: defeat the enemy.
- Victory and defeat rules stay unchanged.
- 100-level balance is foundation-only v0.1 content tuning and is expected to change after playtesting.

Hero selection, complex objectives, final economy balance, a full LevelSelect UX redesign, and visual LevelSelect polish remain future work.

## Enemy Roster and Selection v0.1

- `EnemyCatalog` contains exactly 10 enemies: training dummy, small slime, goblin scout, goblin fighter, armored goblin, wild wolf, bandit, orc brute, cave shaman, and gatekeeper.
- Enemy IDs, display names, and base stats match the existing `EnemyConfig` definitions.
- `EnemySelectionResolver` selects one valid enemy from `EnemyCatalog` at battle start.
- Tests can inject a seeded `RandomNumberGenerator` for reproducible selection.
- Runtime enemy selection is coordinated by `BattlePresenter`.
- `BattleFactory` accepts an optional selected enemy override and otherwise uses `LevelConfig.enemy_config` as fallback/default data.
- Runtime level enemy selection remains separate from the generated 100-level campaign structure.
- `EnemyScalingResolver` creates a battle-time scaled `EnemyConfig` without mutating `EnemyCatalog`.
- Scaling preserves enemy ID, display name, intent turns, and target lane.
- Scaling uses linear HP and attack multipliers with a mild every-10th-level wall bonus. No exponentials, power formulas, hard wall levels, new enemies, or new enemy mechanics are implemented.

New enemies, new enemy mechanics, boss mechanics, and final enemy balance remain future work.

## Progression v0.1

- Victory grants upgrade points from `LevelConfig.reward_upgrade_points`.
- Rewards can be earned repeatedly in v0.1.
- Upgrade points can improve hero attack or HP.
- Attack level and HP level are stored per hero in `HeroUpgradeState`.
- Attack upgrades cost `1 + attack_level`; HP upgrades cost `1 + hp_level`.
- Attack grows by 2 per attack level; max HP grows by 10 per HP level.
- Attack and HP upgrades are capped at level 20.
- `PlayerProgress` stores upgrade points, hero upgrade state, and level progress.
- Progress saves locally to `user://save_v1.json`.
- `BattleFactory` applies saved attack and HP levels to future battle heroes.
- `HeroConfig` remains base data and is not mutated by upgrades.
- Upgrade rewards remain repeatable in v0.1.

Cloud save, Yandex SDK integration, one-time rewards, stars-based rewards, hero selection, reset upgrades, and complex economy remain future work.

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

One-time rewards, level map, chapters, stars-based rewards, reset upgrades, and deeper upgrade trees remain future work.

## MVP Exclusions

- No ads.
- No payments.
- No Yandex SDK.
- No RuStore or Android-specific code.
- No final art.
- No complex meta progression.
- No one-time rewards or stars-based rewards.
- No level map or chapters.
- No hero unlocks, gacha, rarity, shards, ability upgrades, reset upgrades, equipment, portraits, or final art.
- No cloud save.
- No target selection or ability upgrades.
- No high-polish special activation animation pass beyond current Stage 48 v0.1 H/V/B activation behavior.
- No further booster targeting/animation polish beyond current Stage 49.1 preview/effect behavior unless explicitly requested.
- No further result flow UX polish beyond current Stage 50 summary/action/refresh behavior unless explicitly requested.
- No real ice/frozen-cell behavior, blockers, chains, or portals beyond the current Stage 55.1 v0.1 procedural holes generator with shape variety (including center-hole presets on medium+ tiers), pass-through gravity, and stable inactive-cell visual presentation (`holes` archetype generates real inactive-cell masks using block/center/center-hole shape presets, `GravityResolver` lets tiles fall through inactive gaps, and `TileView`/`BoardView` render/animate holes safely and stably in both static and overlay-animated states; `normal`/`ice` remain full 9x9) unless explicitly requested.
- No real tile movement.
- No real/final audio assets or final particle/effect art.

## Stage 16: Balance and Content Expansion v0.1

- Stage 16 is implemented.
- `LevelCatalog` now contains a 10-level early campaign slice with fixed enemy configs.
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
- No new heroes, battle objectives, healing abilities, shield abilities, buffs, debuffs, target selection, cooldowns, ability upgrades, skill trees, platform SDK, cloud save, ads, payments, final art, sound, or particles were added.

## Stage 18: Special Tiles v0.2

- Stage 18 is implemented.
- Match 4 still creates line special tiles.
- Match 5+ creates color bombs instead of line specials.
- Color bombs clear tiles of the activated bomb cell's selected/base tile type.
- Special tiles remain board-only effects.
- Special-cleared cells do not add extra battle damage or ability charge.
- No special + special combos were added.
- No wrapped bombs were added.
- No particles, sound, final art, Yandex SDK, cloud save, ads, or payments were added.

## Stage 19: Menu and Battle Flow Restructure v0.1

- Stage 19 is implemented.
- New main flow: MainMenu -> Play -> LevelSelect -> TeamSelect -> GameScreen, and MainMenu -> Heroes -> UpgradeScreen.
- Heroes/progression entry moved from LevelSelect into MainMenu; MainMenu now has Play and Heroes buttons.
- `LevelSelectScreen` is now only for choosing a level: showing levels, locked/open/completed/star state, level selection, and Back to MainMenu. Its Team and Heroes buttons and `team_pressed`/`upgrades_pressed` signals were removed.
- `TeamSelectScreen` is now the pre-battle team confirmation screen. It receives a `level_id` through `set_level_id()`, shows the currently saved team, and lets the player change selected heroes. Its Save button was renamed Start Battle and is disabled unless the team has exactly 3 unique heroes and a level_id is set.
- On Start Battle, `TeamSelectScreen` validates and saves the team through `ProgressManager.set_selected_team_ids()` and only then emits `start_battle_pressed(level_id)`. `App.gd` routes that signal to `GameScreen` with the same level_id. `TeamSelectScreen` never creates `BattleState`, opens `GameScreen` directly, or touches save files itself.
- Restart in `GameScreen` keeps the current level_id unchanged; Back/Menu from `GameScreen` returns to `LevelSelectScreen`.
- Back from `UpgradeScreen` returns to `MainMenu` for this stage, including when opened from `GameScreen`'s victory overlay Heroes link.
- Team selection rules, level unlock/star/progression rules, battle rules, and save data formats were not changed.
- No SettingsScreen, reset save, animation toggles, Yandex SDK, cloud save, ads, payments, new levels, new heroes, hero unlocks, gacha, rarity, hero shards, equipment, skill trees, new abilities, new special tiles, new battle objectives, final art, sound, or particles were added.

## Stage 20: UI/UX Polish and Settings v0.1

- Stage 20 is implemented.
- MainMenu now has Play, Heroes, and Settings buttons.
- `SettingsScreen` is a new screen with toggles for Animations, Reduced Motion, Debug Labels, Music, and Sound Effects, and a Back button.
- `PlayerSettings` and `SettingsManager` under `scripts/game/settings/` persist settings to `user://settings_v1.json`, fully separate from `user://save_v1.json` and `PlayerProgress`.
- Missing or corrupted settings data falls back safely to defaults; `reset_settings_to_defaults()` resets settings only.
- Animations and Reduced Motion settings are applied presentation-only in `TileView`, `BoardMotionAnimator`, `TurnFeedbackPresenter`, and `AbilityFeedbackPresenter`, using minimal delays and softer pulses without changing input-unlock timing or `feedback_finished` correctness.
- Debug Labels, when enabled, show `level_id` in `LevelSelectScreen` and `hero_id` in `TeamSelectScreen`, `UpgradeScreen`, and battle `HeroCard`s; clean player-facing names are shown by default.
- Music and Sound Effects toggles persist and are reflected in the UI; no audio assets were added, and `SettingsManager` only mutes/unmutes named audio buses if they exist.
- `TeamSelectScreen` copy was clarified to read as a pre-battle confirmation screen.
- Reset Progress was intentionally not added: no button, API, or settings action deletes, clears, or resets player progress.
- No gameplay, board, battle, progression, hero, level, special tile, or save-progress-format rules were changed.
- No Yandex SDK, cloud save, ads, payments, new levels, new heroes, hero unlocks, gacha, rarity, hero shards, equipment, skill trees, new abilities, new special tiles, new battle objectives, final art, audio assets, or particles were added.

## Stage 21: Battle Screen Layout v0.2

- Stage 21 is implemented.
- The portrait `GameScreen` board is scaled wider and remains square.
- The board's left and right edges visually align with the hero party panel at the 720x1280 base portrait layout.
- Permanent Hero Lane separator lines and always-on lane background/debug fills were removed from the normal board state.
- Temporary lane activation feedback remains presentation-only.
- Hero Lane gameplay rules remain unchanged: columns 0-2, 3-5, and 6-8 still map to lanes 0, 1, and 2.
- No battle rules, board rules, progression, save, settings, enemy, level, ability, special tile, platform, audio, art, or monetization systems were changed.

## Stage 22: Battle HUD Restructure v0.2

- Stage 22 is implemented.
- `EnemyPanel` is now the first battle content block at the top of `GameScreen`.
- Level, moves, and Menu are now grouped in a compact row directly below the enemy.
- Battle HUD level text uses compact `Level N` formatting for current `level_#` ids.
- Stage 21 portrait board scaling is preserved: the board remains square and visually aligned with the hero party panel.
- `LevelCatalog` and level config identity data were not changed.
- No battle rules, board rules, progression, save, settings, enemy, level catalog, ability, special tile, platform, audio, art, or monetization systems were changed.

## Stage 23: Level Identity Cleanup v0.2

- Stage 23 is implemented.
- Player-facing level labels are now numbers-only: `Level 1`, `Level 2`, etc.
- Location-style level names were removed from `LevelCatalog` display names and level UI.
- `LevelLabelFormatter` centralizes `level_#` to `Level N` formatting with safe fallback behavior.
- `level_id` values remain unchanged as `level_1` through `level_10`.
- At Stage 23, the campaign still had exactly 10 levels.
- Enemy configs, rewards, balance, progression rules, battle UI layout, board layout, save format, settings, platform, audio, art, ability rules, and special tile rules were not changed.
- Random enemy selection was handled later in Stage 24.
- A 100-level campaign is implemented later in Stage 25.

## Stage 24: Enemy Roster and Random Enemy Selection v0.1

- Stage 24 is implemented.
- `EnemyCatalog` now contains the shared 10-enemy roster.
- `EnemySelectionResolver` selects an enemy from the roster when a battle starts.
- Selection is deterministic/testable with seeded RNG.
- `LevelConfig.enemy_config` remains fallback/default data for compatibility.
- `BattleFactory` supports selected enemy overrides.
- Level IDs, `Level N` labels, moves, rewards, progression, saves, battle rules, board rules, abilities, special tiles, settings, and UI layout were not changed.
- Enemy scaling and enemy level multipliers are not implemented yet.
- A 100-level campaign is implemented later in Stage 25.

## Stage 25: 100-Level Campaign Foundation v0.1

- Stage 25 is implemented.
- `LevelCatalog` now generates exactly 100 levels instead of manually listing the earlier 10-level slice.
- Level IDs use `level_1` through `level_100`; `level_101` does not exist.
- Player-facing labels use `Level 1` through `Level 100`.
- Moves use placeholder v0.1 ranges: 24-22, 23-21, 22-20, and 21-19 across the campaign bands.
- Repeatable `reward_upgrade_points` use a simple placeholder v0.1 range from 1 to 5 points.
- Runtime enemy selection still uses `EnemyCatalog` and `EnemySelectionResolver` from Stage 24.
- `LevelConfig.enemy_config` remains fallback/default data and cycles through the existing 10-enemy roster.
- Enemy scaling, level multipliers, final economy balance, and full LevelSelect UX polish are not implemented yet.
- No gameplay, board, battle, save, settings, hero, ability, special tile, platform, art, audio, or monetization systems were changed.
- Next planned stage: Stage 26, Enemy scaling and level multipliers v0.1.

## Stage 26: Linear Enemy Scaling and Level Multipliers v0.1

- Stage 26 is implemented.
- `EnemyScalingResolver` scales selected enemies by level number at battle start.
- `EnemyCatalog` remains the base roster; base enemy configs are not mutated.
- `BattlePresenter` selects a base enemy from `EnemyCatalog`, scales it for the current `LevelConfig`, then passes the scaled config to `BattleFactory`.
- Only enemy `max_hp` and `attack` are scaled.
- Enemy ID, display name, intent turns, and target lane are preserved.
- Scaling uses linear formulas only, with no `pow()`, exponentials, level powers, or hard difficulty spikes.
- Every 10th level gets a small deterministic wall-level bonus that remains soft and forgiving.
- Stage 25's 100-level campaign IDs, labels, move curve, reward curve, fallback enemy cycle, and default level remain unchanged.
- Hero economy, rewards, upgrade costs, hero stat progression, LevelSelect zones, backgrounds, battle feedback polish, board rules, abilities, special tiles, saves, Yandex SDK, cloud save, ads, payments, sound, particles, and final art were not changed.
- Next planned stage: Stage 27, Linear rewards and hero upgrade economy v0.2.

## Stage 27: Linear Rewards and Hero Upgrade Economy v0.2

- Stage 27 is implemented.
- `UpgradeEconomyConfig` centralizes economy constants.
- Attack upgrade cost is `1 + attack_level * 1`.
- HP upgrade cost is `1 + hp_level * 1`.
- Attack stat growth is `base_attack + attack_level * 2`.
- Max HP stat growth is `base_max_hp + hp_level * 10`.
- Max attack level and max HP level are both 20.
- `UpgradeResolver` rejects upgrades for invalid heroes, invalid upgrade types, insufficient points, and max level.
- `UpgradeResolver` spends the exact calculated cost and increments only the requested stat level.
- Level rewards use `1 + floor((level_number - 1) / 8) + floor(level_number / 10)`, clamped to 23.
- Every 10th level gives a mild deterministic wall reward bonus through the `floor(level_number / 10)` term.
- Rewards remain repeatable in v0.1.
- `UpgradeScreen` shows current and next stat values, cost text, not-enough-points state, and max-level state.
- Stage 26 enemy scaling was not changed.
- No new gameplay systems, enemies, levels, currencies, gacha, equipment, abilities, special tiles, platform SDK, cloud save, ads, payments, final art, audio assets, or particles were added.
- Economy is v0.2 and still expected to change after playtesting.
- Stage 28 follows this economy work with LevelSelect zones for the 100-level campaign.

## Stage 28: LevelSelect Locked Zones for 100 Levels v0.2

- Stage 28 is implemented.
- `LevelSelectScreen` now groups the 100-level campaign into 10 zones of 10 levels.
- Zone 1 contains Levels 1-10 and is available from the start.
- Zone 2 contains Levels 11-20 and unlocks after Level 10 completion.
- Zone 3 contains Levels 21-30 and unlocks after Level 20 completion.
- Zone 10 contains Levels 91-100 and unlocks after Level 90 completion.
- LevelSelect shows only levels from the selected unlocked zone.
- Zone unlock state is derived from existing level completion data through `ProgressManager` queries.
- No separate zone save data or zone completion records were added.
- Progression, rewards, economy, enemy scaling, battle rules, board rules, saves, settings, platform, art, audio, and monetization systems were not changed.

## Stage 29: Battle Backgrounds and Enemy Scene Presentation v0.1

- Stage 29 is implemented.
- `BattleBackgroundCatalog` now defines 5 placeholder background slots (`background_1` through `background_5`), each with a display name and a placeholder color; `texture_path` is reserved for future real art and stays empty for now.
- `BattleBackgroundSelectionResolver` selects one background at battle start, deterministic/testable with a seeded `RandomNumberGenerator`, mirroring `EnemySelectionResolver`'s style.
- Enemy selection remains the existing Stage 24 random selection from the 10-enemy roster; enemy scaling formulas were not changed.
- Background and enemy selection are independent: each is resolved separately in `BattlePresenter.start_level()`, and neither affects the other's outcome, stats, rewards, or progression.
- `GameScreen` applies the selected background's placeholder color to a background layer behind `BattleRoot`; the layer ignores mouse input so board input is unaffected, and it stays behind `BattleResultOverlay`. A hidden `TextureRect` is wired up so a real texture can be applied later without further plumbing changes.
- `EnemyPanel` presentation was improved with a placeholder avatar area, an HP bar alongside the existing HP text, the enemy's attack value, "attacks in N turns" intent text, and a target lane label (Left/Center/Right/Unknown).
- Current backgrounds are placeholders only; final background images will be added in a later stage.
- No gameplay, battle rules, board rules, rewards, upgrade economy, enemy scaling, progression, saves, settings, LevelSelect zones, hero abilities, special tiles, platform systems, final art, audio, or monetization systems were changed.
- Next planned stage: Stage 30, Battle readability and feedback polish v0.1.

## Stage 30: Battle Readability and Feedback Polish v0.1

- Stage 30 is implemented.
- `BattleMessageFormatter` (`scripts/game/presentation/battle_message_formatter.gd`) centralizes all player-facing battle text so `TurnFeedbackPresenter`, `AbilityFeedbackPresenter`, and `GameScreen` stay free of ad-hoc string building.
- Turn feedback messages are clearer: single/multi-hero damage messages ("Hero 1 dealt 12 damage", "2 heroes attacked for 46 total damage", "No damage dealt"), hero lane activation messages ("Left lane activated", "2 lanes activated") alongside the existing temporary lane highlight, special tile activation messages ("Line special activated", "Color bomb activated", cleared-tile counts, and a safe "Special tile activated" fallback), and full-sentence enemy action messages ("Enemy attacked Hero 2 for 18 damage", "Enemy is preparing an attack").
- Ability feedback messages are clearer for accepted ("Warrior Strike activated", "Warrior Strike dealt 30 damage") and rejected ("Ability is not ready yet", "This hero is down", "Battle is already over", "Ability unavailable") cases.
- Invalid swap/input messages are friendlier: "Swap must create a match", "Choose a neighboring tile", "Swipe a little farther", "Stay inside the board", "Wait until the turn finishes".
- `GameScreen` status text for selecting tiles, resolving a turn, using an ability, and victory/defeat is more player-facing; the battle result overlay's reward/star display is unchanged.
- Presentation settings are respected: `animations_enabled`/`reduced_motion_enabled` continue to control feedback timing and motion, and `debug_labels_enabled` only adds hero/ability IDs to messages when explicitly enabled.
- No damage formulas, board rules, enemy scaling, rewards, upgrade economy, level progression, saves, settings, LevelSelect zones, battle backgrounds, hero abilities, special tile rules, platform systems, final art, audio, or monetization systems were changed.
- The Stage 26-30 block is complete. The next roadmap block will be planned separately.

## Stage 31: Hero Portrait Buttons and Ability Bars v0.1

- Stage 31 is implemented.
- Battle heroes now use square portrait placeholders instead of text-heavy stat cards.
- Hero names and Columns/lane text were removed from battle hero cards.
- HP is shown as a red bar under the portrait; Charge is shown as a blue bar under HP.
- The hero portrait/card now acts as the ability button; the separate Charge/Ability button was removed.
- Pressing a ready hero portrait activates the hero ability. Pressing a not-ready or down hero portrait still routes through the normal ability request flow, so existing "Ability is not ready yet"/"This hero is down" feedback still appears; only an empty slot disables the press.
- Ready heroes (full charge) show a highlight/glow border on the portrait, with an optional subtle pulse respecting `animations_enabled`/`reduced_motion_enabled`.
- Down/dead heroes show a dimmed overlay and an empty HP bar.
- Real hero portrait assets are not required yet; a safe placeholder square is used. The full `ImageSlot` pipeline remains future work.
- No gameplay rules, ability rules, charge formulas, damage formulas, enemy scaling, rewards, upgrade economy, progression, saves, TeamSelect layout, LevelSelect zones, platform systems, art assets, audio assets, or monetization systems were changed.

## Stage 32: Hero Systems Freeze and Direct Match Damage Foundation v0.1

- Stage 32 is implemented.
- Direction change: hero/RPG systems are frozen (not deleted) so gameplay can focus on clean match-3 enemy battles. Hero code, `TeamSelectScreen`, and `UpgradeScreen` remain in the project for a future revisit.
- `FeatureFlags` (`scripts/game/config/feature_flags.gd`) is the single toggle for this direction: `HERO_SYSTEMS_ENABLED := false`, `DIRECT_MATCH_DAMAGE_ENABLED := true`.
- New active flow: MainMenu -> Play -> LevelSelect -> GameScreen. `LevelSelectScreen` now opens `GameScreen` directly (`App._on_level_selected`) instead of routing through `TeamSelectScreen`.
- `TeamSelectScreen` and its `start_battle_pressed(level_id)` signal remain wired in `App.gd` for legacy/future use but are not part of the active Play path.
- `MainMenuScreen`'s Heroes button and `BattleResultOverlay`'s upgrades button are hidden while `HERO_SYSTEMS_ENABLED` is false, so `UpgradeScreen` is not reachable from normal play.
- `GameScreen` hides `HeroPartyPanel` in direct mode and does not connect `ability_requested`, so no hero ability UI or input is active; hiding the panel (rather than removing it) avoids a layout gap since containers skip invisible children when sizing.
- Damage is now direct match damage: 1 cleared crystal = 1 damage. `DirectMatchDamageResolver` (`scripts/game/battle/direct_match_damage_resolver.gd`) counts unique cleared cells, including cascades and special-tile clears (via `BoardResolveResult.total_cleared`).
- `BattleResolver` branches on `FeatureFlags.HERO_SYSTEMS_ENABLED`: the frozen hero-lane/ability/enemy-attack path is preserved unchanged behind the flag; the new direct-damage path applies damage straight to enemy HP and does not run `EnemyActionResolver`, so enemies do not attack in direct mode.
- `BattleState.update_status()` only treats "no alive heroes" as defeat when hero systems are enabled, so direct-mode battles never depend on hero data existing.
- Enemies, enemy HP, enemy scaling, the 100-level campaign, LevelSelect locked zones, moves, stars, victory/defeat, progression, battle backgrounds, and enemy presentation are unchanged and remain active.
- `BattleMessageFormatter.format_direct_damage_message`/`format_enemy_defeated_message` provide direct-mode battle text ("Matched 3 tiles: 3 damage", "Special cleared 9 tiles: 9 damage", "No damage dealt", "Enemy defeated!").
- Color damage multipliers and round modifiers are not implemented yet.
- No hero, upgrade, or TeamSelect files were deleted; no player HP, enemy-attacks-on-player, new levels, new enemies, or new mechanics were added.
- Next planned stage: Stage 33, Round modifiers and color damage rules v0.1.

## Stage 33: Round Modifiers and Color Damage Rules v0.1

- Stage 33 is implemented.
- Each battle now selects one `RoundModifierConfig` at battle start: a per-battle color damage multiplier applied on top of the Stage 32 direct-damage baseline.
- `RoundModifierConfig` (`scripts/game/config/round_modifier_config.gd`) stores `modifier_id`, `display_name`, `description`, and a `color_multipliers` dictionary; `get_multiplier(tile_type)` defaults to x1 for any color not listed. Only positive multipliers are valid; debuffs/penalties are out of scope.
- `RoundModifierCatalog` (`scripts/game/config/round_modifier_catalog.gd`) defines 6 positive modifiers: `red_x3`, `blue_x3`, `green_x3`, `yellow_x3`, `purple_x3` (each triples one color's damage, all others stay x1), and `all_x2` (doubles every color). `all_x2` is the safe default modifier.
- `RoundModifierSelectionResolver` (`scripts/game/config/round_modifier_selection_resolver.gd`) selects one valid modifier deterministically/testably from a seeded `RandomNumberGenerator`, mirroring `EnemySelectionResolver`/`BattleBackgroundSelectionResolver`. A missing, empty, or invalid catalog falls back to the default modifier without crashing.
- `BattlePresenter.start_level()` selects a round modifier independently of enemy and background selection (its own catalog, resolver, and RNG), stores it as `current_round_modifier`, and emits `round_modifier_changed(modifier)` alongside the existing level/board/state/background signals.
- `BattleResolver.resolve_player_matches()` takes an optional `round_modifier` argument and passes it to the direct-damage path only; the frozen hero path ignores it entirely.
- `DirectMatchDamageResolver` applies `modifier.get_multiplier(tile_type)` per uniquely cleared tile using each match's `tile_type`. Cascaded matches (via `BoardResolveResult` steps) also get color-aware damage since each step keeps its own match data; special-tile activation clears that lack a match (no known color) fall back to x1 damage. With no modifier supplied, behavior is unchanged from Stage 32 (1 cleared crystal = 1 damage).
- Example: a match of 3 red tiles under `red_x3` deals 9 damage; the same match under an unrelated color buff still deals 3 damage.
- `GameScreen` shows a `RoundModifierPanel` (`ModifierNameLabel` + `ModifierDescriptionLabel`) in the battle layout, updated from `round_modifier_changed`. The panel does not block board input and hides safely if no modifier is set.
- Direct-mode battle feedback text was extended for single-color buffed matches ("Matched 3 red tiles x3: 9 damage") while keeping existing generic messages ("Matched 5 tiles: 5 damage", "Cleared 8 tiles: 14 damage" for mixed-color cascades, "Special cleared 9 tiles: 9 damage", "No damage dealt", "Enemy defeated!").
- Stage 32 leftover text was cleaned up: the defeat message no longer says "upgrade heroes" (now "Defeat — use boosted colors and try again"), and the victory overlay's reward text no longer says "upgrade points" while hero systems are frozen.
- Hero/RPG systems remain fully frozen: `TeamSelect`, `UpgradeScreen`/Heroes flow, `HeroPartyPanel`, hero abilities, hero charge, hero lane damage, and hero upgrades stay inactive in normal gameplay, and none of it affects direct match damage.
- No debuffs, negative modifiers, player HP, enemy attacks against the player, new enemies, new levels, or hero systems were added.
- Next planned stage: Stage 34, Direct match-3 balance pass v0.1.

## Stage 34: Direct Match-3 Balance Pass v0.1

- Stage 34 is implemented. This is a balance/configuration-only pass: no new gameplay systems, debuffs, player HP, enemy attacks against the player, new enemies, new levels, asset pipeline, audio, platform SDK, ads, or payments were added.
- `DirectBalanceConfig` (`scripts/game/config/direct_balance_config.gd`) is new and now owns the direct match-3 balance numbers that used to be scattered across `LevelCatalog` and `EnemyScalingResolver`: `get_level_number(level_id)`, `get_moves_for_level(level_number)`, `get_enemy_hp_for_level(base_hp, level_number)`, `get_required_damage_per_move(enemy_hp, moves)`, `get_expected_damage_per_move(level_number)`, `get_balance_checkpoint_levels()` (`[1, 5, 10, 20, 30, 50, 75, 100]`), and `is_wall_level(level_number)`. Every formula is linear or mild stepwise; no `pow()`/`exp()` is used anywhere.
- Enemy HP scaling is tuned for direct damage: `EnemyScalingResolver.scale_enemy()` branches on `FeatureFlags.HERO_SYSTEMS_ENABLED`. When it is false (the default), HP comes from `DirectBalanceConfig.get_enemy_hp_for_level()` — a linear target (`40 + 0.6 * (level_number - 1)`) nudged by the enemy's own base HP (clamped to a ±15% factor around a 470 baseline so level number stays the dominant difficulty driver) — and attack is left at the enemy's unscaled base value, since `BattleResolver` already skips enemy actions entirely in direct mode. `EnemyCatalog` base stats are never mutated, enemy identity/display name/intent turns/target lane are preserved, and the enemy roster is unchanged. The previous hero-mode multiplier curve (`get_hp_multiplier`/`get_attack_multiplier`/`get_wall_level_bonus`, unused pending a future hero-mode revisit) is preserved unchanged.
- Moves are tuned for direct damage: `LevelCatalog._get_moves_for_level()` now delegates to `DirectBalanceConfig.get_moves_for_level()` instead of holding its own copy of the formula (same stepwise curve as before: 24 moves at level 1 down to a floor of 19 by level 100, with no jump larger than 2 between neighboring levels). Exactly 100 levels remain, with `level_1` through `level_100` ids and "Level N" display names unchanged.
- Round modifier random pool is tuned for color-focused play: `RoundModifierCatalog.get_random_pool_modifiers()` is new and returns only the 5 single-color surges (`red_x3`, `blue_x3`, `green_x3`, `yellow_x3`, `purple_x3`), excluding `all_x2` so a normal random battle is always a strategic single-color pick. `all_x2` remains fully valid and is still reachable via `get_default_modifier()` and direct `get_modifier("all_x2")` lookup — it is the default/fallback only, not part of the random pool. `RoundModifierSelectionResolver` prefers `get_random_pool_modifiers()` when the catalog exposes it, falls back to `get_all_modifiers()` for catalogs that only implement the older interface, and still falls back to `all_x2` when no valid modifier is available. No new modifiers, debuffs, or negative multipliers were added.
- Balance checkpoints (`DirectBalanceConfig.get_balance_checkpoint_levels()`): required damage/move stays below expected damage/move at every checkpoint (using a representative ~400-470 base-HP enemy), so all checkpoints are clearable with reasonable boosted-color play: level 1 (24 moves, ~40 HP, ~1.7 required vs 4.0 expected — very forgiving), level 5 (23 moves, ~42 HP, ~1.8 vs 4.0), level 10 (22 moves, ~45 HP, ~2.1 vs 4.0), level 20 (22 moves, ~51 HP, ~2.3 vs 4.2), level 30 (21 moves, ~57 HP, ~2.7 vs 4.4), level 50 (21 moves, ~69 HP, ~3.3 vs 4.8), level 75 (20 moves, ~84 HP, ~4.2 vs 5.4), level 100 (19 moves, ~99 HP, ~5.2 vs 5.8 — harder but still plausible). Wall levels (multiples of 10, per `is_wall_level`) get no extra HP spike since the HP curve is a single smooth line.
- Progression/stars/locked zones are unchanged: `LevelCompletionResolver.calculate_stars()` still uses moves-left as a fraction of each level's own `moves`, so it stays correct under the new moves curve without changes. Zone 2 still unlocks after Level 10 and Zone 3 still unlocks after Level 20 (`level_zone_helper.gd` is level-number based and untouched).
- Hero/RPG systems remain fully frozen (unchanged from Stage 32/33): `TeamSelect`, `UpgradeScreen`/Heroes flow, `HeroPartyPanel`, hero abilities, hero charge, hero lane damage, and hero upgrades stay inactive in normal gameplay. Direct match damage and Stage 33's color multipliers remain fully active.
- Balance is intentionally v0.1 and expected to be re-tuned after playtesting.
- Stage 35 follows this pass with simplified LevelSelect startup and direct-flow UX polish.

## Stage 35: Direct LevelSelect Startup and Simplified UX Polish v0.1

- Stage 35 is implemented.
- The app now starts directly on `LevelSelectScreen`.
- `MainMenuScreen` is skipped/inactive in the active flow and remains in the project as legacy/future code.
- Active flow is now `App startup -> LevelSelect -> GameScreen -> LevelSelect` and `LevelSelect -> Settings -> LevelSelect`.
- `LevelSelectScreen` has a Settings button in its top panel and no active back navigation to MainMenu.
- Settings Back returns to LevelSelect.
- GameScreen Menu/Back and the result overlay's Levels action return to LevelSelect.
- Selecting an unlocked level from LevelSelect still opens GameScreen directly; TeamSelect is not used.
- `TeamSelect`, Heroes/Upgrade flow, `HeroPartyPanel`, hero abilities, hero charge, hero lane damage, and hero upgrades remain inactive in normal gameplay.
- Direct match damage, round modifiers, Stage 34 direct balance, enemies, levels, moves, stars, progression, locked zones, enemy scaling, battle backgrounds, and enemy presentation remain active.
- EnemyPanel and battle result copy avoid active hero-target/upgrade language in direct mode.
- No gameplay systems, debuffs, player HP, enemy attacks against the player, new enemies, new levels, asset pipeline, audio, Yandex SDK, cloud save, ads, payments, final art, sound/music assets, particles, or Reset Progress were added.
- Stage 36 is implemented.
- `ImageSlot` is a reusable placeholder/image UI component that can load a texture from `GameAssetCatalog` or accept a `Texture2D` directly.
- `GameAssetCatalog` maps reserved keys for backgrounds, enemies, tiles, UI panels, and future/frozen hero portraits to future `res://assets/images/` paths.
- Missing asset files are expected and safe: catalog lookup returns `null`, and `ImageSlot` shows its placeholder color.
- Empty asset folders were added under `assets/images/` with `.gitkeep` files only; no real image assets were added.
- `ImageSlot` was not mass-integrated into active UI in Stage 36.
- Active gameplay remains unchanged: LevelSelect startup, direct match damage, round modifiers, Stage 34 direct balance, enemies, levels, moves, stars, progression, zones, battle backgrounds, and enemy presentation remain active.
- Hero/RPG systems remain frozen and inactive.
- Stage 37 follows with asset loading integration for active imageholders.

## Stage 37: Asset Loading Integration for Active Imageholders v0.1

- Stage 37 is implemented.
- `GameAssetCatalog` supports cached safe texture loading through `try_load_texture_cached(asset_key)` and test cleanup through `clear_texture_cache()`.
- Cached loading returns `null` safely for empty, unknown, missing, and non-texture assets; optional missing files are not preloaded.
- `ImageSlot.refresh()` uses the cached loader while direct `set_texture()` behavior remains available.
- `AssetKeyResolver` maps all 5 background IDs, all 10 active enemy IDs, and all 5 active tile types to reserved `GameAssetCatalog` keys.
- `BattleBackgroundConfig` now includes `asset_key`, and all 5 `BattleBackgroundCatalog` entries set it.
- `GameScreen` uses an ImageSlot-backed background layer that applies the selected background asset key and placeholder color while staying behind the battle UI and ignoring input.
- `EnemyPanel` uses `EnemyImageSlot` for enemy visuals, resolving enemy IDs to asset keys and showing a neutral placeholder when images are missing or enemy state is null.
- Tile image rendering is postponed because `TileView` currently relies on Button/stylebox text markers and lightweight tween state; tile asset-key mapping is ready for a later, safer visual pass.
- No real image assets were added.
- Active gameplay remains unchanged: LevelSelect startup, direct match damage, round modifiers, Stage 34 direct balance, enemies, levels, moves, stars, progression, zones, battle flow, and Settings flow remain active.
- Hero/RPG systems remain frozen and inactive.
- Stage 38 follows with the AudioManager foundation.

## Stage 38: AudioManager Foundation v0.1

- Stage 38 is implemented.
- `AudioAssetCatalog` maps reserved audio keys to future `res://assets/audio/` paths and safely returns `null` for empty, unknown, missing, or non-audio resources.
- `AudioAssetCatalog` caches loaded streams and missing keys so optional missing files are not rechecked excessively.
- `AudioManager` is registered as an autoload singleton and owns one music `AudioStreamPlayer` plus an 8-player SFX pool.
- `AudioManager` exposes music and sound-effects enabled state, safe music/SFX play methods, and wrapper methods for reserved UI and battle events.
- Missing audio files safely no-op and do not crash, block input, or change battle feedback timing.
- `assets/audio/music/` and `assets/audio/sfx/` were added with `.gitkeep` files only.
- No real audio files, final music, final sound design, volume sliders, or advanced audio mixing UI were added.
- Music and Sound Effects settings now apply to `AudioManager` on app startup and when SettingsScreen toggles change; settings still persist through `SettingsManager` separately from player progress.
- Minimal presentation-only audio hooks were added for buttons, level selection, swap requests, invalid input/invalid swaps, valid direct-damage turns, special activations, enemy damage, victory, and defeat.
- Active gameplay remains unchanged: LevelSelect startup, direct match damage, round modifiers, Stage 34 direct balance, enemies, levels, moves, stars, progression, zones, battle flow, Settings flow, and ImageSlot-backed imageholders remain active.
- Hero/RPG systems remain frozen and inactive.
- Stage 39 follows with complete AssetKey texture binding.

## Stage 39: Complete AssetKey Texture Binding v0.1

- Stage 39 is implemented.
- `GameAssetCatalog` now reserves safe `res://assets/images/` texture paths for base tiles, special tiles, battle UI panels, LevelSelect visuals, Settings visuals, booster icons, booster button states, stars, and future/frozen hero portraits.
- `assets/images/boosters/` was added with `.gitkeep`; no real image files were added.
- `AssetKeyResolver` now maps background ids, enemy ids, active tile types, special tile types, UI ids, booster ids, level button states, and star states to catalog asset keys. Unknown ids return an empty key safely.
- `TileView` resolves its base tile texture through `AssetKeyResolver.get_tile_asset_key(tile_type)` and `GameAssetCatalog.try_load_texture_cached()`. When the texture is missing, the existing color stylebox placeholder remains visible.
- `TileView` resolves special tile asset keys for future art while preserving the current `H`/`V`/`B` text markers above the fallback/current button visuals.
- `UiAssetBinding` prepares safe metadata/cached lookup binding for panel-style controls that are not yet ImageSlot-backed.
- LevelSelect and Settings background nodes are ImageSlot-backed. LevelSelect panel, zone selector, generated level buttons, star states, Settings panel/toggles, battle HUD, enemy panel, round modifier panel, status label, and result overlay now carry stable reserved asset keys for future texture integration.
- A visual-only `BoosterButton` stub was added. It supports `set_booster_id()`, `set_uses_left()`, `set_selected()`, and `set_disabled_state()`, resolves booster icons through `AssetKeyResolver.get_booster_asset_key()`, and uses placeholder fallback when icon files are missing.
- Booster gameplay, booster economy, booster inventory, target selection, cooldowns, particles, final art, and real image files remain out of scope.
- Active gameplay is unchanged: LevelSelect startup, direct match damage, round modifiers, Stage 34 balance, enemies, levels, moves, stars, progression, zones, battle flow, Settings flow, audio no-op behavior, and ImageSlot-backed battle background/enemy visuals remain active.
- Hero/RPG systems remain frozen and inactive.
- Next planned stage: Stage 40, Booster system foundation v0.1.

## Stage 40: Booster System Foundation v0.1

- Stage 40 is implemented.
- Active battle now has three battle-local boosters: Hammer, Time Freeze, and Rocket Barrage.
- `BoosterConfig` and `BoosterCatalog` define booster id, display name, description, asset key, uses per battle, and targeting mode. The default v0.1 set is `hammer`, `freeze_time`, and `rocket_barrage`.
- `BoosterState` is created fresh for each `BattleState`, tracks uses left, active booster id, and Time Freeze turns, and is not saved as player inventory or economy data.
- `BoosterResolver` owns booster rules. Hammer clears a clipped 3x3 area around a selected crystal; Rocket Barrage clears all crystals of the selected color; Time Freeze adds 3 move-free successful turns.
- Each booster is usable once per battle. Booster activation and targeted booster resolution do not consume moves.
- Hammer and Rocket read tile colors before clearing, calculate direct damage through `DirectMatchDamageResolver`, and apply the current round modifier where tile color is known. Unknown color data falls back to x1.
- Booster clears apply gravity/refill and leave the board full. Extra cascade resolution after booster clears is intentionally not part of v0.1.
- Regular successful swaps consume Time Freeze turns before reducing moves. Invalid swaps do not consume moves or freeze turns.
- `BoosterPanel` displays the three booster buttons, uses left, selected/disabled state, and freeze turns. It replaces the old hidden hero area in active direct-mode combat.
- `GameScreen` owns only UI mode and wiring for booster selection/targeting; `BattlePresenter` coordinates booster requests and emits booster state/result updates.
- `HeroPartyPanel` remains hidden, and hero/RPG systems remain frozen and inactive.
- No booster inventory, persistence, economy, purchases, Yandex SDK, cloud save, ads, payments, particles, final art, new enemies, new levels, or hero-system reactivation were added.
- Next planned stage: Stage 41, Board animation foundation v0.1.

## Stage 41: Board Animation Foundation v0.1

- Stage 41 is implemented.
- `BoardAnimationRequest` defines future animation event types for swap, invalid swap, match clear, special clear, gravity fall, refill, cascade step, booster clear, damage particles, and enemy hit.
- `BoardAnimationSequence` stores ordered animation requests and exposes safe add, export, clear, empty, and size helpers.
- `BoardAnimationController` owns settings-aware placeholder playback. It finishes immediately when animations are disabled, when the sequence is empty, or when no board view is available, and it shortens request durations when reduced motion is enabled.
- `BoardAnimationSequenceBuilder` converts existing `TurnPresentationData` and `BoosterResolveResult` data into animation sequences without changing board, battle, booster, damage, progression, save, asset, audio, or hero-system rules.
- `GameScreen` routes turn presentation and booster resolution through the animation foundation before continuing existing turn feedback or booster status handling, so input remains blocked until the sequence path finishes.
- `BoardView` exposes safe helper methods for tile lookup, cell global center, cell flash, and cell pulse effects. Unknown or missing cells are ignored safely.
- Stage 41 placeholder playback may flash or pulse cells, but high-polish swap movement, explosions, falling crystals, refill movement, cascade-step animation, damage particles, and enemy hit feedback remain future work.
- `animations_enabled` and `reduced_motion_enabled` are respected by the board animation controller.
- No board rules, battle rules, booster rules, balance, progression, saves, Yandex SDK, cloud save, ads, payments, final art, particles, real tile movement, or hero-system reactivation were added.
- Next planned stage: Stage 42, Swap and match clear animations v0.1.

## Stage 42: Swap and Match Clear Animations v0.1

- Stage 42 is implemented.
- `BoardAnimationController` routes `TYPE_SWAP`, `TYPE_INVALID_SWAP`, `TYPE_MATCH_CLEAR`, and `TYPE_SPECIAL_CLEAR` requests to concrete `BoardView` animation methods.
- `BoardView` has an `AnimationLayer` above `TileGrid` for temporary visual nodes used by swap animations.
- Valid swap animation creates two ghost tile controls, hides the original tile visuals while ghosts move toward each other, restores the originals, and cleans the animation layer.
- Valid swap animation defers resolved board refresh so the currently displayed crystals visibly trade places before the board view updates to the resolved turn.
- Invalid swap animation applies a short overlay ghost bounce/shake to the involved cells, leaves board state unchanged, does not move real `TileView` nodes inside `GridContainer`, and keeps invalid visual feedback readable.
- Match clear animation visibly flashes, scales, fades, and restores matched cells.
- Special clear animation uses a stronger gold flash/scale/fade placeholder while final line-blast and color-bomb effects remain future work.
- `animations_enabled` skips animation playback safely, and `reduced_motion_enabled` shortens durations and softens scale/motion.
- Input remains locked through the existing `GameScreen` animation plus `TurnFeedbackPresenter` flow and unlocks after feedback when the battle is not finished.
- No gravity/refill/cascade animation flow, damage particles, enemy hit animation, board rules, battle rules, booster rules, balance, progression, saves, Yandex SDK, cloud save, ads, payments, final art, particles, or hero-system reactivation were added.
- Next planned stage: Stage 43, Gravity, refill and cascade animation flow v0.1.
- Stage 42 hotfix: swap duration and pending-board timing were corrected for visible swap flow, and invalid swap cleanup now restores hidden tiles and clears temporary ghosts safely.

## Stage 43: Gravity, Refill and Cascade Animation Flow v0.1

- Stage 43 is implemented.
- Normal valid swap animation duration is now exactly 1.0 second (`BoardAnimationSequenceBuilder.SWAP_ANIMATION_DURATION`); `reduced_motion_enabled` may still shorten the effective duration, and `animations_enabled = false` still skips the animation immediately.
- Board resolve data now provides animation-friendly fall/refill/cascade data: `GravityResolver` returns `fall_movements` (from, to, tile type, special data, fall distance) and richer `refill_cells` (spawn index, target cell, tile type, special data); `BoardResolveResult` preserves this per cascade step and exposes aggregated `fall_movements`, `refill_cells`, and ordered `cascade_steps`.
- `TurnPresentationData` and `BoosterResolveResult` carry the same fall/refill/cascade data forward from `BoardResolver` and `BoosterResolver` so the presentation layer no longer needs to fake animation over the final board state.
- `BoardAnimationSequenceBuilder` now emits `gravity_fall` and `refill` requests after clear/special-clear requests when movement/refill data exists, followed by a `cascade_step` request (plus its own `gravity_fall`/`refill` requests) for every automatic cascade in resolve order, before the placeholder `enemy_hit` request.
- `BoardView` plays gravity/refill movement through temporary `AnimationLayer` ghosts (`play_gravity_fall_animation`, `play_refill_animation`, `create_tile_ghost_from_data`) and gives cascade matches a short highlight (`play_cascade_step_animation`); real `TileView` nodes inside `GridContainer` are never moved manually, and hidden tile visuals are restored once each step finishes.
- Hammer and Rocket booster clears participate in gravity/refill animation where the booster resolver produces movement data; Time Freeze remains status/audio only. `GameScreen` defers the resolved board update during booster targeting the same way it already did for swaps, so the animation plays before the final board is applied.
- `animations_enabled` and `reduced_motion_enabled` continue to be respected by `BoardAnimationController`.
- No damage particles, richer enemy hit animation, board rules, battle rules, booster rules, balance, progression, saves, Yandex SDK, cloud save, ads, payments, final art, particles, or hero-system reactivation were added.

## Stage 44: Damage Particles and Enemy Hit Feedback v0.1

- Stage 44 is implemented.
- Normal valid swap animation duration is now exactly 0.4 seconds (`BoardAnimationSequenceBuilder.SWAP_ANIMATION_DURATION`), down from 1.0 second; `reduced_motion_enabled` may still shorten the effective duration, and `animations_enabled = false` still skips the animation immediately.
- `GameScreen.tscn` gained a `BattleEffectLayer` `Control` above the board/enemy UI (input-ignoring, cleaned after use) driven by a new `BattleEffectController` (`scripts/game/view/battle_effect_controller.gd`).
- `BattleEffectController` flies lightweight `ColorRect` particles from board cells to the enemy panel, respects `animations_enabled`/`reduced_motion_enabled`, caps particle count (16 normal, 6 reduced motion), always calls its finished callback exactly once, and cleans up temporary particle nodes afterward; missing nodes, disabled animations, or empty events all finish immediately and safely.
- `DamageParticleEventBuilder` (`scripts/game/presentation/damage_particle_event_builder.gd`) builds particle event dictionaries (`cell`, `tile_type`, `damage`, `multiplier`, `is_boosted`, `source`) from `TurnPresentationData` and `BoosterResolveResult`, using exact per-cell tile-color data where available and otherwise distributing total damage safely across representative cleared cells. Zero damage and Time Freeze both produce no events.
- `BoosterResolveResult`/`BoosterResolver` now expose `cleared_cell_tile_types` (cell to tile type) so Hammer/Rocket clears carry enough data to build accurate particle events.
- `EnemyPanel` gained `get_hit_target_global_position()`, `play_hit_feedback(damage)`, `show_floating_damage(damage)`, and `animate_hp_change(current_hp, max_hp)`, all safe if backing UI nodes are missing. A new `HitEffectLayer` overlay hosts floating damage labels, the enemy portrait flashes/shakes briefly on hit (softened/removed under reduced motion), and the HP bar now tweens toward its target value via `configure_presentation()` instead of snapping instantly.
- `GameScreen` plays damage particles and enemy hit feedback after each turn's/booster's board animation sequence finishes and before continuing the existing turn/booster feedback, status, and result-overlay flow; input stays locked throughout. Enemy-damage audio now fires alongside hit feedback instead of immediately at turn-presentation time, and victory/defeat overlays still only appear after this full feedback chain completes.
- No board rules, battle rules, booster rules, balance, progression, saves, Yandex SDK, cloud save, ads, payments, final art, or hero-system reactivation were added.
- Next planned stage: Stage 45, overall gameplay animation polish and reduced-motion support.

## Stage 45: Gameplay Animation Timeline Stabilization v0.1

- Stage 45 is implemented. It fixes animation-layer conflicts that could show a double board (stale real tiles under moving ghosts), stretched/merged-looking crystals during cascades, and pending-board timing bugs, rather than adding new visual effects.
- New `BoardVisualSnapshot` (`scripts/game/view/board_visual_snapshot.gd`) captures a read-only, per-cell copy of `BoardView`'s visible state (tile type, special data, position, size, asset key, placeholder color, marker text) via `BoardVisualSnapshot.from_board_view(board_view)`. It is safe if `board_view` is null, ignores missing cells, and never mutates `BoardView`.
- `BoardView` gained an animation overlay mode: `enter_animation_overlay_mode(snapshot)` hides every real `TileView` and builds one full-board ghost per cell in `AnimationLayer` from the snapshot; `exit_animation_overlay_mode()` clears the ghosts and restores the real tiles; `is_animation_overlay_mode()` reports the state; `force_reset_animation_state()` kills any active tween, clears `AnimationLayer`, and resets every real tile's visibility/scale/modulate/position, for use as an emergency cleanup hook. Repeated enter/exit calls are safe, and entering with a null/empty snapshot is a no-op that never leaves the board hidden.
- While in overlay mode, `play_swap_animation` moves the two matching overlay ghosts directly (no legacy hide/ghost-per-swap duplication); `play_match_clear_animation`/`play_special_clear_animation`/`play_cascade_step_animation` fade the matched cells' overlay ghosts out; `play_refill_animation` fades a new ghost into each vacated cell. `play_gravity_fall_animation` is a documented v0.1 safe fallback (no-op) in overlay mode rather than an exact per-tile falling animation, in line with "prioritize stability over complex visuals." Outside overlay mode (direct/legacy callers, existing unit tests) the original ghost-per-animation behavior is unchanged.
- Real `TileView` nodes inside `GridContainer` are still never moved, scaled, or left hidden by gameplay animation; all movement uses `AnimationLayer` ghosts, and `BoardView.set_board()` always exits overlay mode and restores/clears animation state before applying a new board, so the real board is never shown stacked under stale ghosts.
- `GameScreen` now captures a pre-turn `BoardVisualSnapshot` and enters overlay mode at the start of every animated turn (swap, targeted booster, and non-targeted booster activation) through a shared `_begin_animated_turn()` helper, and the single `_apply_pending_board_for_animation()` choke point exits overlay mode (if still active) before applying the deferred board exactly once. Animations-disabled mid-flow settings changes now force this same apply-and-exit path immediately.
- `GameScreen._force_cleanup_visual_state()` calls `_board_animation_controller.clear_queue()`, `board_view.force_reset_animation_state()`, and `BattleEffectController.clear_effects()`, and clears pending-board state; it runs on every new battle/restart, on Menu/Back, and before showing the victory/defeat result overlay, so stray ghosts or particles can never persist across those transitions.
- Damage particles still only start after `_apply_pending_board_for_animation()` has exited overlay mode and applied the final board, preserving the existing order: board animation finishes -> AnimationLayer is clean -> final board applied -> damage particles -> enemy hit feedback -> turn feedback/result.
- No board rules, battle rules, booster rules, balance, progression, saves, Yandex SDK, cloud save, ads, payments, final art, or hero-system reactivation were added.
- Known limitation: detailed per-tile gravity/refill fall animation is intentionally deferred in overlay mode (fade + refill-fade fallback only); this can be revisited in a future stage once the fade/no-op flow has been playtested. A small number of existing `GameScreen` animation-flow tests use a fixed 4-second wait and can rarely time out on an unusually long random cascade chain; this pre-existing flake is unrelated to Stage 45 and was reproduced on the pre-Stage-45 code as well.

## Stage 46: Stepwise Board Resolution Animation Pipeline v0.1

- Stage 46 is implemented. Player turn resolution now runs in animation lockstep instead of precomputing the whole board result before animation starts: swap -> check current matches -> clear -> gravity/refill -> check cascades -> repeat until stable -> only then compute damage/battle state.
- New `StepwiseBoardResolver` (`scripts/game/board/stepwise_board_resolver.gd`) exposes `BoardResolver`'s match/clear/gravity/special-tile rules one phase at a time (`find_current_matches`, `build_clear_step`, `apply_clear_step`, `apply_gravity_step`, `resolve_next_step`), returning a `BoardResolveStep` (`scripts/game/board/board_resolve_step.gd`) per phase. `BoardResolver.resolve_board()` itself is unchanged and remains the immediate synchronous fallback used whenever `animations_enabled` is false.
- New `AnimatedTurnFlow` (`scripts/game/presentation/animated_turn_flow.gd`) drives a live player turn through these phases directly against the real `BoardModel`: it plays each phase's animation, then applies that phase's board mutation, then checks for the next cascade, repeating until the board is stable. Only once stable does it hand an accumulated `BoardResolveResult` back to `BattlePresenter`.
- `BattlePresenter.request_swap()` now only validates and applies the swap, emitting `swap_accepted` instead of resolving the whole board immediately; `BattlePresenter.finalize_swap_turn()` (called by `AnimatedTurnFlow` once stable, or by `resolve_accepted_swap_immediately()` for the disabled-animation path) runs the existing `BattleResolver`/`TurnPresentationData`/signal-emission tail unchanged. `request_targeted_booster()`/`finalize_booster_turn()` follow the same split for Hammer/Rocket.
- `BoardAnimationSequenceBuilder` gained `build_swap_sequence`, `build_clear_sequence`, `build_gravity_refill_sequence`, and `build_booster_clear_sequence` helpers so each stepwise phase can be animated independently instead of only building one full precomputed turn sequence.
- Clear animations now always target the current, post-swap board state rather than a stale precomputed mapping, and gravity/refill animation plays and fully completes before the next cascade check runs. `BoardView` gained a real overlay-mode gravity fall animation (`_play_overlay_gravity_fall`, relocating the falling ghost to its landing cell) replacing the Stage 45 no-op fallback.
- Hammer/Rocket booster clears now also check for cascades after their initial clear+gravity pass, through `AnimatedTurnFlow.start_booster_clear()` — a real behavior addition, since booster clears previously never triggered cascade resolution. Any extra cleared cells/damage found this way are folded into the booster result before `finalize_booster_turn()` fires.
- `animations_enabled = false` still resolves a turn immediately and synchronously through the original `BoardResolver.resolve_board()` path; this fallback is unchanged from before Stage 46.
- No board rules, damage formulas, booster targeting rules, balance, progression, saves, Yandex SDK, cloud save, ads, payments, final art, or hero-system reactivation were added.

## Stage 46 hotfix: Post-Swap Overlay Ghost Mapping

- Fixed post-swap overlay ghost mapping so the match clear animation now targets the correct post-swap cells. The visible bug: after a swap that created a match, the correct crystals were cleared in the board model, but the clear animation could visually fade the swapped-away source ghost instead of the newly-matched destination ghost.
- Root cause: `BoardView._play_overlay_swap()` only reassigned `_overlay_ghosts[from_cell]`/`_overlay_ghosts[to_cell]` inside the swap tween's `finished` callback, while `BoardAnimationController` advances to the next queued animation request (e.g. match clear) after a fixed timer duration rather than waiting for that `finished` signal — so a match-clear request could run against the stale pre-swap ghost mapping.
- Fix: `_play_overlay_swap()` now flips the `_overlay_ghosts` mapping immediately when the swap tween starts, via a new `_swap_overlay_ghost_mapping()` helper, since the board model is already post-swap at that point. A new `_finalize_overlay_swap()` runs in the tween's `finished` callback only to prune ghosts freed/invalidated mid-tween; `BoardAnimationController` also calls a new `BoardView.finalize_pending_overlay_swap()` after a swap request's timer as an extra safety net.
- The visible swap animation (both ghosts sliding to each other's position) is unchanged, and stepwise board resolution remains active — matches are still found from the live post-swap `BoardModel`, not a stale precomputed set. Eager full-board resolution was not restored.

## Stage 46 polish hotfix: Board Animation Handoff and Invalid Swap Polish v0.1

- Refill crystals in overlay mode now fall from above instead of appearing directly in their target cell: `BoardView._play_overlay_refill()` starts each new ghost above its column (same start-position math as the non-overlay refill animation, stacked by `spawn_index` when several crystals refill the same column) and tweens it down to its cell.
- The whole-board blink at the end of a turn/cascade flow is fixed: a new `BoardView.apply_board_under_overlay(board)` updates the real board data while the real tiles are still hidden behind the overlay, then exits overlay mode — so the real board is already correct the instant it becomes visible, with no frame of stale or blank board in between. `GameScreen._apply_pending_board_for_animation()` uses this instead of exiting overlay mode and calling `set_board()` separately.
- Invalid swap now visually swaps the two crystals and returns them, rather than a small blocked bounce: `BoardView.play_invalid_swap_animation()` moves both crystals to each other's cell and back (using `AnimationLayer` ghosts, real `TileView` nodes hidden and restored, board model untouched), with a dedicated overlay-mode path that animates the existing ghosts in place. The invalid-swap animation duration was raised from 0.12s to 0.24s; a small bounce remains as a fallback for single-cell invalid input.
- Cascade/match highlights no longer stay lit after the animation flow ends: cascade-step flashes no longer call `highlight_cells()`, and `GameScreen` now clears cell highlights once a turn/booster feedback flow (or forced cleanup) completes.
- Stepwise board resolution remains active and unchanged; these were presentation-only fixes.

## Stage 46 polish hotfix 2: Remove Duplicate Feedback and Add Special Creation Animation v0.1

- The remaining whole-board blink and persistent yellow cascade/match highlight were caused by `TurnFeedbackPresenter` replaying an older, separate full-board feedback pass (swap pulse, `highlight_cells()`, match/special clear fade, and a whole-board refill/refresh pulse) after `AnimatedTurnFlow` had already animated the turn live and the final board was applied. `TurnFeedbackPresenter.play_turn_text_feedback_only()` now handles valid turns instead, playing only status/lane/damage text and clearing highlights; the old full feedback path is kept only for invalid swaps.
- Match clear now animates `step.cleared_cells` instead of `step.matched_cells`, so a cell protected for special-tile creation is never faded by the clear animation — this is what caused special-creation cells to visually disappear until the whole turn finished.
- A new special-tile creation animation (`BoardAnimationRequest.TYPE_SPECIAL_CREATE`, `BoardView.play_special_create_animation()`) plays right after match clear whenever a step creates special tiles: the creation cell's ghost (or real tile) gets its marker set and a pulse/flash, so the cell stays visually occupied the whole time instead of appearing empty and then suddenly showing the special marker at the end.
- Cascade/match highlights are still cleared after the flow via `clear_cell_highlights()`, invalid swap still swaps and returns without mutating the board model, and stepwise board resolution remains active and unchanged.

## Stage 46 polish hotfix 3: Special Creation Gather Animation and Preferred Spawn Cell v0.1

- Special tile creation now uses a gather animation instead of just pulsing the creation cell: `SpecialTileResolver.choose_special_cell_for_match(match_result, preferred_cells)` in `StepwiseBoardResolver.build_clear_step()` still decides the creation cell, but `BoardAnimationSequenceBuilder.build_clear_sequence()` now excludes the other matched cells feeding a created special (`created_special_tiles[i].source_cells`) from the plain match-clear fade, and `BoardView._play_overlay_special_create()` slides/shrinks/fades their ghosts into the creation cell before the existing marker-update/pulse plays. `created_special_tiles` entries gained `source_cells` and `tile_type`; the non-overlay real-tile fallback still cannot move real `TileView` nodes, so it just fades the source tiles in place via `play_match_clear()` instead of gathering them.
- Player-created special tiles (from the first match right after a player swap) now prefer the swapped cell: `AnimatedTurnFlow.start_swap_turn()` passes `[to_cell, from_cell]` as `preferred_cells` only for the initial (`cascade_index == 0`) resolve step, so the special lands on the swapped-into cell if it's part of the match, else the swapped-from cell, else the prior deterministic center-cell choice.
- Cascade/gravity-created specials are unaffected: no preferred cells are passed for later cascade steps, so they keep the existing center-cell placement.
- Stepwise board resolution, the swap-and-return invalid-swap behavior, and prior gather/marker fixes are unchanged.

## Stage 47: Animation QA and Board Visual Stability Pass v0.1

- Stage 47 is implemented. It stabilizes the Stage 46 stepwise board animation lifecycle without adding new board rules, damage formulas, booster rules, balance changes, saves, platform SDK work, final art, or hero-system reactivation.
- `AnimatedTurnFlow` remains the active owner of stepwise board visuals during animated turns: swap, match clear, special creation, gravity/refill, cascade, booster clear, and final board handoff.
- `TurnFeedbackPresenter` is text/status/enemy feedback only after valid animated turns. It must not replay swap movement, match highlights, clear fades, refill effects, or whole-board refresh animation after `AnimatedTurnFlow` has already handled those visuals. Invalid swaps may still use their rejection feedback path.
- Booster clear visuals now remove overlay ghosts through `BoardView.play_booster_clear_animation()` before gravity/refill creates replacement ghosts, so Hammer/Rocket flows do not leave duplicate board layers.
- `BoardView.clear_transient_visual_state()` is the shared cleanup point for selected-cell state, match/cascade/special/booster highlights, invalid feedback, lane highlights, temporary tile tint/scale drift, and safe tile refresh. It must not move real `GridContainer` tile children; only emergency force reset may restore positions.
- Cleanup runs after valid turn completion, invalid swap cleanup, booster apply/cancel, result overlay preparation, restart, return to LevelSelect, disabled-animation fallback, and reduced-motion playback.
- Final board handoff uses `BoardView.apply_board_under_overlay(board)`: real `TileView` data is refreshed while overlay ghosts still cover the board, then ghosts are removed only after the real board is ready. Special tiles created during the stepwise flow remain visible through both the overlay animation and the final real-board state.
- Damage particles and enemy hit feedback start only after board stepwise animation is complete, transient highlights are cleared, overlay ghosts are removed, and the final board is applied. Victory/defeat result overlay appears only after that full board + damage + feedback chain completes.
- `BattleEffectController.clear_effects()` cancels in-flight particle playback and suppresses stale callbacks during restart/menu/result cleanup. `AnimatedTurnFlow.cancel()` releases pending step awaits during forced cleanup.
- Normal animations, reduced motion, and disabled animations preserve the same logical order. Reduced motion shortens/softens visuals; disabled animations resolve immediately without leaving ghosts, highlights, stuck awaits, or stale effects.
- Stage 50 result flow UX polish is complete.

## Stage 48: Special Tile Activation Animations v0.1

- Stage 48 is implemented. It adds lightweight, presentation-only special activation visuals to the existing `AnimatedTurnFlow` stepwise board sequence without changing board rules, damage rules, progression, saves, battle state, or hero-system behavior.
- Special activation data now includes the activated special cell, special type, affected/cleared cells, and a color-bomb `base_tile_type` when available. The disabled-animation resolver path preserves the same data shape even though animation playback finishes immediately.
- `BoardAnimationSequenceBuilder` emits `TYPE_SPECIAL_ACTIVATION` before the existing `TYPE_SPECIAL_CLEAR` fade and before gravity/refill for that step, so H/V/B activation is readable without duplicating normal match-clear animation.
- H specials pulse the activation cell and show a horizontal sweep across affected row cells. V specials pulse and show a vertical sweep down affected column cells. B/color bombs pulse the bomb cell and briefly highlight affected cells of the selected/base color before the existing fade/clear.
- In overlay mode, `BoardView` animates overlay ghosts and temporary `AnimationLayer` highlights only; real board tiles remain hidden until final board handoff. Outside overlay mode, fallback visuals pulse/highlight existing controls without manually moving real `TileView` nodes inside the `GridContainer`.
- Cleanup continues through the Stage 47 transient-state and final-handoff path: no row/column/color highlights, ghost nodes, tint, scale, or selected-cell state should remain after the visual chain completes. Reduced motion shortens/softens the same order; disabled animations resolve immediately and safely.
- `TurnFeedbackPresenter` remains text/status/enemy feedback only after a valid animated turn. It may show the special activation status text, but it must not replay H/V/B board visuals, special clears, match highlights, refill effects, or full-board refresh animation.
- Stage 50 result flow UX polish is complete.

## Stage 49: Booster Targeting and Booster Animation Polish v0.1

- Stage 49 is implemented. It improves active direct-mode booster targeting and feedback without changing booster rules, damage formulas, balance, progression, saves, platform code, art assets, or hero-system behavior.
- Hammer and Rocket Barrage use a preview-confirm flow: select a booster, tap a crystal to preview affected cells, then tap the same crystal again to apply. Pressing the same selected booster cancels targeting.
- Hammer preview shows the clipped 3x3 area around the target crystal, including board edges and corners. Activation pulses the target and flashes the 3x3 impact area before the existing booster clear/gravity/refill/cascade path.
- Rocket Barrage preview reads the current visible board tile type at the target cell and highlights all visible cells of that type. Activation pulses the target and flashes the same-color group before the existing clear path.
- Time Freeze stays non-board feedback only: it activates immediately, pulses the booster button/status path, adds free turns, and does not request board clear animation when no cells are cleared.
- Selected booster buttons show readable selected state; used boosters show dim/disabled-looking state but still produce short already-used feedback when pressed. Selected state clears after cancel, apply, or use.
- `BoardView.show_booster_target_preview()` and `clear_booster_target_preview()` own presentation-only preview nodes on `AnimationLayer`; cleanup runs on apply, cancel, selected-booster changes, disabled-animation cleanup, result overlay, restart, and LevelSelect return.
- `BoardAnimationRequest.TYPE_BOOSTER_ACTIVATION` runs before `TYPE_BOOSTER_CLEAR` through `AnimatedTurnFlow`, so damage particles and result overlays still start only after board animation and cleanup finish. `TurnFeedbackPresenter` must not replay booster board visuals.
- Stage 50 result screen and level flow UX polish is complete.

## Stage 49.1: Stronger Booster Affected-Cell Preview v0.1

- Stage 49.1 is implemented. It improves booster preview readability without changing booster rules, targeting logic, activation order, damage formulas, balance, progression, saves, platform code, art assets, or hero-system behavior.
- Hammer affected-cell preview still uses the clipped 3x3 area around the target crystal, now drawn with a stronger near-white inset overlay that is clearly visible on all tile colors.
- Rocket Barrage affected-cell preview still uses all currently visible cells matching the target tile type, now using the same stronger near-white overlay.
- Time Freeze remains non-board feedback only.
- Preview nodes remain presentation-only through `BoardView.show_booster_target_preview()` and `clear_booster_target_preview()`, and cleanup expectations are unchanged: apply, cancel, selected-booster changes, disabled-animation cleanup, result overlay, restart, and LevelSelect return must leave no white overlay nodes behind.

## Stage 50: Result Screen and Level Flow UX Polish v0.1

- Stage 50 is implemented. It improves result screen clarity and level-flow actions without changing board rules, battle rules, booster rules, balance, save format, platform code, art assets, or hero-system behavior.
- `GameScreen` prepares compact victory data after reward/completion save: level id/display label, stars earned, best stars, moves left, reward amount for compatibility, next level id when launchable, newly unlocked next-level state, and newly unlocked zone state.
- `GameScreen` prepares compact defeat data: level id/display label, moves left when useful, and a short retry suggestion.
- `BattleResultOverlay` shows victory title, completed level, stars earned/best stars, moves left, and next-level/zone-unlock feedback only when newly earned.
- `BattleResultOverlay` shows defeat title, failed level, and a retry suggestion.
- Victory actions are Next Level, Retry, and Levels; defeat actions are Retry and Levels. Next Level is hidden/disabled when no launchable next level exists.
- Next Level and Retry both reuse the normal GameScreen battle-start path after cleanup, so board, battle state, boosters, HUD, enemy, background, modifier, and input are rebuilt safely.
- Levels returns through App to LevelSelect, and LevelSelect refreshes progress state immediately after managers are set.
- Result overlay timing remains ordered after board/special/booster animation, damage particles, enemy hit feedback, transient cleanup, and progress save/update. Cleanup before/after result actions must leave no booster preview/selection, highlights, animation-layer nodes, pending board state, or particles behind.

## Stage 51: Procedural Challenge Archetype Foundation v0.1

- Stage 51 is implemented. It is architecture/data-flow foundation only: current board generation still behaves as a normal full 9x9 board for every archetype, and no board rules, battle rules, booster rules, balance, progression, save format, platform code, art assets, or hero-system behavior changed.
- **Challenge archetypes.** `ChallengeArchetype` (`scripts/game/config/challenge_archetype.gd`) defines the required archetype set: `normal`, `ice`, `holes`. The layer is a small, typed id list designed to grow later with blockers, crates, chains, portals, and other board mechanics without breaking existing callers.
- **Archetype cycle.** `ChallengeArchetypeResolver` (`scripts/game/config/challenge_archetype_resolver.gd`) maps a level number to an archetype using a repeating 5-level cycle: `level_number % 5 == 1` -> normal, `== 2` -> ice, `== 3` -> holes, `== 4` -> ice, `== 0` -> holes. Examples: level_1 normal, level_2 ice, level_3 holes, level_4 ice, level_5 holes, level_6 normal (cycle repeats).
- **Difficulty budget.** `DifficultyBudget` (`scripts/game/config/difficulty_budget.gd`) is a small data object (`level_number`, `difficulty_score`, `difficulty_tier`, plus `ice_density`, `hole_count`, `blocker_count`, `validation_attempts`, `layout_complexity` for later generators). `DifficultyBudgetResolver` (`scripts/game/config/difficulty_budget_resolver.gd`) derives these from level number: `difficulty_score` grows linearly per level, normalized into a 0..1 progress value that scales every other budgeted field, and `difficulty_tier` steps through `early` -> `medium` -> `hard` -> `very_hard` at fixed level thresholds. Early levels stay gentle by design; nothing here yet changes actual generated content.
- **Generated challenge data.** `GeneratedBoardChallenge` (`scripts/game/board/generated_board_challenge.gd`) is the data object produced for a battle: `archetype`, `level_id`, `level_number`, `difficulty_score`, `difficulty_tier`, `generation_seed`, `board_mask`, `frozen_cells`, and a `metadata` debug dictionary. For this stage, `board_mask` defaults to a full active 9x9 grid and `frozen_cells` defaults to an empty array; real holes/ice occupy these fields starting in a later stage.
- **Generation seed.** `BattlePresenter` owns a seeded `_challenge_rng`; every `start_level()` call draws a fresh `generation_seed`, and since new battle start, Retry, and Next Level all route through `start_level()`, each of those actions produces a new seed. The seed is stored on the generated `GeneratedBoardChallenge` for debugging and is not yet used for save compatibility.
- **Generator foundation.** `BoardChallengeGenerator` (`scripts/game/board/board_challenge_generator.gd`) builds a `GeneratedBoardChallenge` from level id, level number, archetype, difficulty budget, and seed. All three required archetypes currently return the same full-board placeholder data; only the `archetype` field and debug metadata differ between normal/ice/holes at this stage.
- **Battle startup wiring.** `BattlePresenter.start_level()` resolves the archetype and difficulty budget from the level number, generates a `GeneratedBoardChallenge`, stores it on `current_generated_challenge` (exposed via `get_current_generated_challenge()`), and emits a new `generated_challenge_changed` signal alongside the existing level/board/state signals. `GameScreen` listens for this signal so the generated challenge is available to the battle/game screen layer for future board setup, debug labels, status text, and documentation.
- **Debug visibility.** `GameScreen._on_generated_challenge_changed()` appends `Challenge: <archetype>, seed: <seed>` to the status label only when Debug Labels are enabled in Settings, keeping normal gameplay unobtrusive.
- **Current placeholder behavior.** Regardless of the resolved archetype, the actual board a player interacts with remains a full, normal 9x9 board generated the same way as before this stage — `GeneratedBoardChallenge.board_mask`/`frozen_cells` are not yet consumed by board generation, gravity, or input.
- **Roadmap for next stages:** active cell masks that make `board_mask` actually shape the playable board, gravity/refill logic updated for masked (non-rectangular) boards, procedural hole generation driven by the difficulty budget, an ice obstacle core (frozen cell state and unfreeze-on-match rules), generated challenge validation with retry/fallback generation when a layout is unsolvable, UX polish for archetype-specific board presentation, and balance passes once real archetypes affect actual difficulty.

## Stage 52: Active Cell Mask Core v0.1

- Stage 52 is implemented. It adds real active/inactive cell mask support to the board core so future holes can be genuine gameplay cells excluded from tile generation, matches, swaps, clears, special effects, boosters, and damage. Current gameplay stays visually unchanged because every generated mask is still a full 9x9 placeholder from Stage 51.
- **`is_inside()` vs `is_cell_active()`.** `BoardModel.is_inside(cell)` remains a pure bounds check (0 <= x < width, 0 <= y < height) and does not change meaning. `is_cell_active(cell)` is new and reports whether a cell inside the board is part of the active playable area. `is_playable_cell(cell)` combines both (`is_inside(cell) and is_cell_active(cell)`) and is the check every gameplay system (matches, swaps, clears, specials, boosters, damage) must use — `is_inside()` alone is no longer sufficient once a board can have holes.
- **Inactive cells do not participate in gameplay.** `set_cell_active(cell, false)` immediately forces the cell's tile back to `EMPTY` and drops any special tile metadata; `set_tile()`, `set_special_tile()`, and `swap_tiles()` all guard against inactive cells so this invariant holds everywhere, not just at the moment a cell is deactivated. `duplicate_board()` copies tile data, special tile data, and the active mask together. `has_empty_cells()` now only inspects active cells, so a masked board with holes is never mistaken for an unstable/broken resolve.
- **Mask validation.** `set_active_mask(mask)` accepts the Stage 51 `GeneratedBoardChallenge.board_mask` shape (an Array of `height` rows, each an Array of `width` bool-ish values). A missing, wrongly-sized, or otherwise invalid mask safely falls back to a fully active 9x9 board instead of leaving the board in a partial/corrupt state.
- **`BoardGenerator` is mask-aware.** `generate(width, height, mask)` gained an optional `mask` argument (`generate_with_mask(mask, ...)` is a convenience wrapper). Active cells receive generated tile types exactly as before; inactive cells are skipped and stay empty; starting-match avoidance only considers active neighbor cells. Calling `generate()` with no mask is unchanged.
- **`MatchFinder` and `SwapResolver` are active-aware.** `MatchFinder` treats an inactive cell as a hard break in a horizontal or vertical run, the same as a board edge, so a match can never span a hole and a `MatchResult` never contains an inactive cell. `SwapResolver.try_swap()` rejects a swap when either cell is inactive with reason `"inactive_cell"`, alongside the existing `"out_of_bounds"` and `"not_adjacent"` rejections; active-adjacent-cell behavior is unchanged.
- **Resolve/special/booster/damage filtering.** `SpecialTileResolver.get_line_clear_cells()`, `get_color_bomb_clear_cells()`, and `collect_special_activation_cells()` all filter to `is_playable_cell()`. `BoardResolver`/`StepwiseBoardResolver` only create a special tile on a playable creation cell. `BoosterResolver.get_hammer_cells()`/`get_rocket_cells()` filter the same way, and `resolve_targeted_booster()` rejects an inactive target cell before doing any work. Together these guarantee inactive cells never appear in cleared cells, special cleared cells, activated-special affected cells, color-bomb/line clear cells, damage tile types, or booster affected cells.
- **`GeneratedBoardChallenge.board_mask` is wired into board generation.** `BattlePresenter.start_level()` now runs in this order: resolve level config -> generate `current_generated_challenge` -> generate `BoardModel` using `current_generated_challenge.board_mask` -> create battle state -> emit `generated_challenge_changed`. `GeneratedBoardChallenge.get_debug_label()` now reports active-cell count, e.g. `Challenge: holes, seed: 12345, active: 81/81`.
- **Current placeholder behavior.** Since Stage 51's generator still returns full 9x9 masks for every archetype, the wired-through mask never actually removes any cells yet — gameplay remains a full, normal 9x9 board.
- **Roadmap for next stages:** Stage 53 will update `GravityResolver` for gravity/refill on masked (non-rectangular) boards. Stage 54 will add procedural hole generation driven by the difficulty budget. Stage 55 will add inactive-cell visuals in `BoardView`. Stage 56 will add the ice obstacle core (frozen cell state, unfreeze-on-match rules).

## Stage 53: Gravity and Refill for Masked Boards v0.1

- Stage 53 is implemented. It makes gravity and refill compatible with active/inactive cell masks: inactive cells behave like walls, tiles never fall through them, refill never creates tiles inside them, and each contiguous active segment of a column resolves independently. Current full 9x9 gameplay remains unchanged because generated masks are still full-board placeholders (Stage 51/52).
- **Segment-based gravity/refill.** `GravityResolver.apply_gravity_and_refill()` no longer treats a whole column as one fall lane. For each column it groups contiguous active cells into segments, then applies gravity and refill independently inside each segment. Example: active y0-y1, inactive y2, active y3-y5 produces two independent gravity segments (y0-y1 and y3-y5) instead of one y0-y5 column.
- **Active segment detection.** `_get_active_segments_for_column(board, x)` scans one column top-to-bottom, groups contiguous active cells, and breaks the current segment the moment an inactive cell is found. It returns only non-empty segments, in consistent top-to-bottom order.
- **Gravity inside each segment.** For every segment, gravity collects non-empty tiles and their special metadata from that segment only, clears only that segment's cells, and writes the collected tiles back starting at the segment's bottom, preserving the same fall order as the original whole-column algorithm. Tiles from one segment never fall into another segment or across an inactive cell.
- **Refill inside each segment.** For every segment, refill only fills the remaining empty cells at the segment's top, stopping at the segment boundary; it never refills an inactive cell, and refilled tiles always get `special_data: null`. After refill, every active cell in the segment is filled.
- **Inactive cells stay untouched.** Gravity/refill never reads from or writes to an inactive cell, so inactive cells remain inactive, stay `EMPTY`, and keep no special metadata after `apply_gravity_and_refill()`. `spawned_cells`, `fall_movements`, and `refill_cells` can only ever reference cells inside a resolved segment, so they never point to an inactive cell.
- **Payload compatibility.** `fall_movements` keeps its existing `from`/`to`/`tile_type`/`special_data`/`fall_distance` fields, and `refill_cells` keeps its existing `spawn_index`/`to`/`tile_type`/`special_data` fields, so `BoardAnimationSequenceBuilder` and `BoardView` need no changes. Both dictionaries gained optional segment metadata for future animation use: `segment_index`/`segment_top`/`segment_bottom` on both, plus `segment_spawn_index` on `refill_cells`.
- **Special metadata preserved during segmented falls.** If a tile carrying H/V/B special metadata falls inside a segment, that metadata moves with it (source cell cleared, target cell receives the same special data), exactly as before segmentation.
- **Current full-board behavior is unchanged.** With today's always-full-9x9 mask, every column is exactly one segment spanning `[0, height-1]`, so the segmented algorithm reduces to precisely the pre-Stage-53 whole-column algorithm — gravity, refill, and animation payloads are equivalent and gameplay does not visually change.
- **Out of scope for this stage.** No procedural holes were added (`BoardChallengeGenerator` still returns full 9x9 masks — Stage 54). No inactive-cell visuals were added (Stage 55). No ice obstacle behavior was added (Stage 56).

## Stage 53.1: Procedural Hole Generation Rules Foundation v0.1

- Stage 53.1 is implemented. It adds strict rules, helpers, and validation for future procedural hole generation so hole masks can be symmetrical, readable, safe, and free of isolated or enclosed playable areas — this stage prepares the rule/validation layer for Stage 54 without enabling real generated holes in gameplay yet. `GeneratedBoardChallenge.board_mask` still returns a full 9x9 placeholder.
- **`HoleGenerationRules`** (`scripts/game/config/hole_generation_rules.gd`) is a typed rules object with `min_block_width`/`min_block_height` (default 2/2), `max_block_width`/`max_block_height` (default 3/3), `min_active_cells` (default 65 of the 81 total board cells), `max_hole_cells` (default 16), `symmetry_mode` (default `"quadrant_mirror"`), and four booleans that all default `true`: `keep_center_active`, `require_connected_active_area`, `reject_enclosed_active_pockets`, `reject_single_cell_holes`.
- **Quadrant symmetry around the 9x9 center.** `BoardMaskSymmetry.get_mirrored_cells(cell, width, height)` (`scripts/game/board/board_mask_symmetry.gd`) mirrors a cell `(x, y)` to `(x, y)`, `(width-1-x, y)`, `(x, height-1-y)`, and `(width-1-x, height-1-y)` under `quadrant_mirror`, deduplicated (cells on an axis of symmetry mirror onto themselves). `get_mirrored_block_cells()` mirrors every cell of a rectangular block individually and unions the results, so a whole hole block mirrors correctly into all four quadrants rather than mirroring only its anchor corner.
- **Minimum 2x2 hole block rule.** `HoleGenerationRules` defaults `min_block_width`/`min_block_height` to 2, and `HoleBlockPlacer` rejects any block whose size falls outside `[min_block_width, max_block_width] x [min_block_height, max_block_height]` — so future generator helpers are constrained to prefer 2x2, 2x3, and 3x2 blocks instead of ever placing an isolated single-cell hole.
- **Hole block placement helper.** `HoleBlockPlacer.try_place_hole_block(mask, top_left, block_width, block_height, rules)` (`scripts/game/board/hole_block_placer.gd`) safely punches a block and its mirrored copies into a `board_mask`-shaped Array only if: the block size respects the configured min/max; the block and every mirrored copy stay inside board bounds; the center cell stays active when `keep_center_active` is set; the projected active-cell count would stay `>= min_active_cells`; the projected hole count would stay `<= max_hole_cells`; and the board would never become all-hole or nearly empty. It mutates the mask in place only on full success, otherwise leaves it untouched and returns `false`.
- **Center cell protection.** When `keep_center_active` is true (the default), both `HoleBlockPlacer` and `BoardMaskValidator` treat the board's center cell (`Vector2i(width/2, height/2)`, i.e. `(4, 4)` on a 9x9 board) as a hard constraint: a placement that would deactivate it is rejected, and a mask where it is inactive fails validation with `"center_cell_inactive"`.
- **Active cell minimum limits.** `min_active_cells` and `max_hole_cells` are enforced both at placement time (`HoleBlockPlacer`, using projected counts before mutating) and at validation time (`BoardMaskValidator`, using actual counts), so a mask can never end up with too few playable cells or too many holes regardless of which path produced it.
- **`BoardMaskValidator.validate(mask, rules)`** (`scripts/game/board/board_mask_validator.gd`) returns a `BoardMaskValidationResult` (`scripts/game/board/board_mask_validation_result.gd`) with `valid`, `reasons`, `active_cell_count`, `hole_cell_count`, `connected_component_count`, and `enclosed_active_cell_count`. It checks mask shape is exactly 9x9 (`"invalid_mask_shape"`), active/hole counts against `min_active_cells`/`max_hole_cells`, center-cell activity, connected-active-area, enclosed-pocket, and single-cell-hole-noise rules described below.
- **Connected active area validation.** Uses a 4-neighbor (up/down/left/right only — no diagonals) flood fill to count connected active components. When `require_connected_active_area` is true, more than one active component is invalid (`"active_area_not_connected"`); disconnected active islands are rejected for v0.1.
- **Enclosed active pocket detection.** Flood fills active cells starting only from board-edge cells; any active cell not reached this way is an "enclosed active pocket" — a playable cell walled in by a closed hole contour. When `reject_enclosed_active_pockets` is true, any enclosed pocket makes the mask invalid (`"enclosed_active_pocket_detected"`) with `enclosed_active_cell_count` reporting how many. Enclosed pockets are rejected outright for v0.1, never auto-fixed.
- **Single-cell hole noise rejection.** When `reject_single_cell_holes` is true, a hole cell with no adjacent hole neighbor (a hole "component" of size 1 under 4-neighbor flood fill) makes the mask invalid (`"single_cell_hole_detected"`).
- **`BoardMaskGenerator.generate_holes_mask(rng, difficulty_budget, rules)`** (`scripts/game/board/board_mask_generator.gd`) is the Stage-54-facing API. It already accepts an `rng`, a `difficulty_budget`, and `HoleGenerationRules` so Stage 54 can add real block placement without a signature change; for this stage it always returns a validated full-active 9x9 mask.
- **Current behavior: real generated holes are still not enabled.** None of this layer is wired into `BattlePresenter` or `BoardChallengeGenerator` — `GeneratedBoardChallenge.board_mask` remains a full 9x9 placeholder and current gameplay is entirely unchanged.
- **Roadmap.** Stage 54 will use `HoleGenerationRules`, `BoardMaskSymmetry`, `HoleBlockPlacer`, and `BoardMaskValidator` to generate real procedural holes driven by the difficulty budget. Stage 55 will add inactive-cell visuals in `BoardView`. Stage 56 will add the ice obstacle core.

## Stage 54: Procedural Holes Generator v0.1

- Stage 54 is implemented. `holes`-archetype levels now generate real, safe, symmetrical inactive-cell masks using the Stage 53.1 rules/validator layer. `normal` and `ice` archetypes still return a full active 9x9 mask for now.
- **Real `generate_holes_mask()`.** `BoardMaskGenerator.generate_holes_mask_with_metadata(rng, difficulty_budget, rules)` (`generate_holes_mask()` remains available as a thin mask-only wrapper) follows the expected flow: create a full active 9x9 mask, resolve safe rules, use the difficulty budget to estimate a block count and an attempt budget, place symmetrical hole blocks through `HoleBlockPlacer` for each attempt, validate the result through `BoardMaskValidator`, and return the first valid mask. If no candidate validates within the attempt budget, it falls back to a full active mask (also validated).
- **`HoleGenerationRules` stays the source of truth.** The generator never hardcodes block sizes, cell limits, or symmetry mode — it reads `min_block_width/height`, `max_block_width/height`, `min_active_cells`, `max_hole_cells`, and `symmetry_mode` from the rules object passed in (or a default `HoleGenerationRules` instance), and `HoleBlockPlacer`/`BoardMaskValidator` still enforce `keep_center_active`, `require_connected_active_area`, `reject_enclosed_active_pockets`, and `reject_single_cell_holes`.
- **Symmetrical hole block selection and placement.** Each candidate picks a random block size from `{2x2, 2x3, 3x2}` (clamped to the rules' min/max), anchors it at a random position inside the board's upper-left quadrant (`x, y` in `[0, width/2)`), and places it (with its `quadrant_mirror` copies) via `BoardMaskSymmetry`/`HoleBlockPlacer`. Anchoring strictly inside that quadrant means no mirrored copy can ever reach the center row/column, so `(4, 4)` stays active by construction, in addition to `HoleBlockPlacer`'s own `keep_center_active` check. A placement attempt that `HoleBlockPlacer` rejects (e.g. it would exceed `max_hole_cells`) is simply skipped; the candidate keeps whatever blocks it managed to place.
- **Difficulty-aware generation.** The attempt budget comes from `difficulty_budget.validation_attempts` (falling back to 20 when unavailable). The number of mirrored blocks attempted follows `difficulty_budget.difficulty_tier` (refined by `layout_complexity` within a tier): `early` 1 block, `medium` 1-2, `hard` 2, `very_hard` 2-3. Rules always override difficulty: since `HoleBlockPlacer` and `BoardMaskValidator` independently enforce `min_active_cells`/`max_hole_cells`, a difficulty-requested block that would breach either limit is never applied, regardless of tier.
- **Retry and fallback.** Each attempt builds a fresh candidate mask and validates it; invalid candidates are discarded and a new attempt starts, up to the resolved attempt budget. The last attempt's validation (`reasons`, counts) is kept so fallback metadata can report why generation gave up. If every attempt fails, `generate_holes_mask_with_metadata()` returns a full active 9x9 mask instead, so battle startup can never receive a broken or invalid mask.
- **Metadata.** `GeneratedBoardChallenge.metadata` for a `holes` challenge now includes `generator_version`, `layout_source` (`"procedural_holes"` on success, `"fallback_full_board"` on fallback), `attempts_used`, `fallback_used`, `active_cell_count`, `hole_cell_count`, and `last_validation_reasons`.
- **`BoardChallengeGenerator` routing.** `generate()` now branches on archetype: `normal` and `ice` call `BoardMaskGenerator.build_full_active_mask()`; `holes` seeds a fresh `RandomNumberGenerator` from `generation_seed` (so the same seed reproduces the same hole layout) and calls `generate_holes_mask_with_metadata(mask_rng, difficulty_budget, rules)`, writing the returned mask into `GeneratedBoardChallenge.board_mask` and the returned metadata into `GeneratedBoardChallenge.metadata`.
- **Board safety preserved.** Generated holes rely entirely on the existing Stage 52/53 core: inactive cells stay `EMPTY` with no special metadata; `MatchFinder` ignores them; `SwapResolver` rejects them; `GravityResolver` treats them as walls; `BoardGenerator` only fills active cells. Nothing in the board core changed for this stage.
- **Visuals stay minimal.** `BoardView`/`TileView` already render an inactive `EMPTY` cell safely today — `TILE_COLORS.get()`/`TILE_ASSET_KEYS.get()`/`try_load_texture_cached()` all fall back gracefully for an unrecognized/empty tile type, so an inactive cell shows a plain dark placeholder box with no icon and no stale data, never a crash. No `BoardView`/`TileView` code changed; proper inactive-cell presentation is Stage 55.
- **Improved debug label.** `GeneratedBoardChallenge.get_debug_label()` now reports hole count and fallback state, e.g. `Challenge: holes, seed: 12345, active: 69/81, holes: 12`, with `, fallback: true` appended only when generation fell back to a full board.
- **Roadmap.** Stage 55 will add proper inactive-cell visuals in `BoardView`/`TileView`. Stage 56 will add the ice obstacle core.

## Stage 54.1: Hole Shape Variety and Center-Aware Generation v0.1

- Stage 54.1 is implemented. It fixes Stage 54's generator effectively only ever producing 2x2 corner blocks, and adds real 2x3/3x2 blocks plus center-aware shape presets so `holes` layouts are more varied and visually interesting. `BoardChallengeGenerator` archetype routing (`normal`/`ice` full active, `holes` procedural) is unchanged — this stage only improves generation quality.
- **Why Stage 54 mostly produced 2x2 layouts.** The default `max_hole_cells` was 16. A quadrant-mirrored 2x2 block anchored off-axis already produces 4 distinct mirrored copies (4 x 4 cells = 16) — the entire hole budget in one placement — so a second block, or any 2x3/3x2 block (4 x 6 cells = 24), always exceeded `max_hole_cells` and was rejected by `HoleBlockPlacer`. The upper-left-quadrant-only anchor (`[0, width/2) x [0, height/2)`) also never touched the center row/column, so no shape could ever appear near the board center regardless of budget.
- **Hole shape presets.** `HoleShapePreset` (`scripts/game/board/hole_shape_preset.gd`) names five shape types as simple cell patterns, not art assets: `block_2x2`, `block_2x3`, `block_3x2` (plain rectangle sizes) and `center_diamond`, `center_circle_light` (small cell-offset patterns relative to the board center). `get_block_size()` maps a block shape type to its `Vector2i` size; `get_center_shape_offsets()` returns the pre-mirror offset list for a center shape type.
- **Making 2x3/3x2 blocks truly usable.** `HoleGenerationRules.for_tier(tier)` (new) is the single source of truth for tier-scoped safe caps, raising `max_hole_cells`/`min_active_cells` with difficulty: early 16/65 (unchanged from Stage 53.1's default), medium 20/61, hard 24/57, very_hard 28/53. This alone isn't enough for 2x3/3x2 at every tier (a full 4-copy 24-cell block still exceeds early/medium's caps), so `BoardMaskGenerator` also changes *how* 2x3/3x2 blocks are anchored: instead of the corner-quadrant anchor, they're anchored to straddle a symmetry axis on their odd (3-cell) dimension (e.g. a 2x3 block spans rows 3-5, straddling row 4 on a 9-tall board). That axis's mirror then maps the block onto itself (rows `[3,4,5]` mirror to `[5,4,3]` — the same set), so only the other axis's mirror still produces a second, non-overlapping copy — 2 copies total (12 cells) instead of 4 (24 cells), which fits comfortably even at the early-tier budget. `block_2x2` keeps the original corner-quadrant anchor (4 copies, 16 cells), since that already fit every tier.
- **Center-aware generation mode.** `center_diamond` is a compact 4-cell "bowtie": one 2-cell vertical arm two cells north of center, mirrored via `BoardMaskSymmetry.get_mirrored_cells()` into a matching south arm. `center_circle_light` is a rounder 12-cell accent: a wider 2-column north band mirrored into a matching south band. Both are expanded from a small base offset list (relative to `(4, 4)`) by mirroring each offset individually and unioning the results, then applied via the new `HoleShapePlacer.try_place_shape(mask, cells, rules)` (`scripts/game/board/hole_shape_placer.gd`) — a generalization of `HoleBlockPlacer` for an arbitrary list of cells instead of only a rectangle. It checks in-bounds, `keep_center_active`, and projected `min_active_cells`/`max_hole_cells` exactly like `HoleBlockPlacer` does, and leaves the mask untouched on any failure.
- **Center protection stays absolute, but shape-adjacent holes are now allowed.** Both center presets deliberately only ever touch the center cell's north and south orthogonal neighbors — never all four of `(4,3)`/`(3,4)`/`(5,4)`/`(4,5)` at once — so the center cell can sit visually inside the shape's silhouette while remaining active (`keep_center_active` still holds, and the exact center cell is never included in a shape for v0.1) and connected to the rest of the active area (holing all four orthogonal neighbors would otherwise isolate/enclose the center cell under the validator's 4-neighbor connectivity rule). Each shape's arms are always >=2-cell contiguous clusters, so no single-cell hole noise is produced, and both shapes are symmetric by construction (mirrored around the true center), so no chaotic or one-off center holes appear.
- **Shape selection by difficulty.** `BoardMaskGenerator._resolve_shape_pool(tier)` weights which shape types are attempted: early is mostly `block_2x2` with occasional `block_2x3`/`block_3x2`; medium adds a rare `center_diamond` alongside the blocks; hard includes both `center_diamond` and `center_circle_light`; very_hard leans further into `center_circle_light`, making combined multi-shape candidates (several shapes placed into the same candidate, then validated as a whole) more likely. As always, `HoleGenerationRules`/`HoleBlockPlacer`/`HoleShapePlacer`/`BoardMaskValidator` override shape choice — a shape the pool picks that would break a limit is simply skipped, and the placement loop tries a different shape/position instead.
- **Validator unchanged, still the final authority.** `BoardMaskValidator` was not modified. Every candidate — whatever mix of blocks and center shapes it contains — still must pass: exact 9x9 shape, active/hole cell counts against the (now tier-scoped) rules, center-cell activity, a single 4-neighbor-connected active area, no enclosed active pockets, and no single-cell hole noise.
- **Metadata.** `GeneratedBoardChallenge.metadata` for a `holes` challenge gained `requested_shape_count` (how many shapes this attempt asked for) and `selected_shape_types` (the shape type strings actually placed successfully), alongside the existing Stage 54 fields (`generator_version`, `layout_source`, `attempts_used`, `fallback_used`, `active_cell_count`, `hole_cell_count`, `last_validation_reasons`).
- **Roadmap.** Stage 55 remains inactive-cell visual presentation in `BoardView`/`TileView`. Stage 56 remains the ice obstacle core.

## Stage 54.2: Gravity Pass-Through for Inactive Cells v0.1

- Stage 54.2 is implemented. It changes masked-board gravity so inactive cells act as pass-through gravity corridors instead of walls: tiles must never be stored in an inactive cell, but they can now fall through inactive gaps into an active cell below. Hole shape generation and `normal`/`ice`/`holes` archetype routing are unchanged; this stage only changes gravity/refill behavior over an already-generated inactive-cell mask.
- **From segment-wall gravity to pass-through column gravity.** Stage 53's `GravityResolver` grouped each column into contiguous active segments and resolved gravity independently per segment, so an inactive cell acted as a wall a tile could never cross. Stage 54.2 replaces this with a single pass-through pass per column: `_resolve_column()` scans column `x` bottom-to-top, skipping inactive cells entirely (never read, never written) while collecting every active cell's tile/special data, in order, into two lists — `active_cells_desc` (every active cell in the column) and `falling_tiles` (the subset that held a non-empty tile). Falling tiles are then written back into `active_cells_desc` starting at index 0 (the column's lowest active cell), so a tile can fall straight through any number of inactive cells into the next active cell below a gap. Remaining entries in `active_cells_desc` (the cells nearer the column's top once falling tiles are placed) are refilled with brand-new tiles.
- **Worked example.** Active `y0` (red) / inactive `y1` / inactive `y2` / active `y3` (empty after a clear) now resolves to: red falls from `y0` to `y3` (crossing both inactive cells), `y0` is refilled with a new tile, and `y1`/`y2` remain inactive and empty throughout — matching the stage's exact expected result.
- **Inactive cells stay safe.** Because inactive cells are simply skipped during the column scan (never appear in `active_cells_desc`), they are never written to by gravity or refill at all; combined with `BoardModel`'s own `set_tile()`/`set_special_tile()` guards, they remain inactive, store `BoardModel.EMPTY`, and carry no special metadata after every gravity pass. `spawned_cells`, `refill_cells`, and `fall_movements` (`from`/`to`) can only ever reference cells drawn from `active_cells_desc`, so they can never point at an inactive cell.
- **Special metadata across a pass-through gap.** A tile carrying H/V/B special metadata that falls from an active cell, across one or more inactive cells, into a lower active cell keeps that metadata: the source cell is cleared, the target cell receives the same special data (via `board.get_special_tile()`/`set_special_tile()`, unchanged from Stage 53), and refilled tiles always get `special_data: null`.
- **Fall movement payload.** `fall_movements` keeps its existing fields (`from`, `to`, `tile_type`, `special_data`, `fall_distance`) and gains two new optional fields: `crossed_inactive_cells` (the inactive cells strictly between `from` and `to` in that column — always inactive cells by construction, since every active cell in between would already have consumed an earlier list slot) and `crosses_inactive_gap` (`true` when that list is non-empty). These are unused by any current animation code and exist so a later `BoardView` pass can hide a falling ghost while it visibly crosses a hole instead of sliding over it.
- **Refill payload.** `refill_cells` keeps its existing fields (`spawn_index`, `to`, `tile_type`, `special_data`) and gains `column_active_index` (the refilled cell's position in the column's active-cell list) and `column_spawn_index` (equivalent to `spawn_index`, kept for symmetry with the fall payload's naming). Refill only ever targets active cells, ordered from the cells just above the fallen tiles upward to the top of the column's active cells.
- **Segment metadata removed.** The Stage 53 `segment_index`/`segment_top`/`segment_bottom`/`segment_spawn_index` fields, and the `_get_active_segments_for_column()`/`_resolve_segment()` helpers that produced them, are removed outright rather than kept alongside the new fields — nothing in `BoardAnimationSequenceBuilder` or `BoardView` read those keys (confirmed by search before removing them), and "segment" no longer describes the pass-through model, so keeping them would only be misleading.
- **Full 9x9 behavior is unchanged.** With a full active mask (today's normal/ice gameplay, and most of `holes` since masks stay small), every column has zero inactive cells, so `_resolve_column()`'s scan/write order reduces to exactly the pre-Stage-53 whole-column algorithm — gravity, refill, and animation payloads are equivalent to before, and `BoardAnimationSequenceBuilder`/`BoardView` (which read `fall_movements`/`refill_cells` via `.get()` with defaults) need no changes.
- **Roadmap.** Stage 55 will add inactive-cell visuals and pass-through fall animation polish (using `crossed_inactive_cells`/`crosses_inactive_gap` to hide the falling ghost mid-gap). Stage 56 remains the ice obstacle core.

## Stage 55: Inactive Cell Visual Presentation and Pass-Through Polish v0.1

- Stage 55 is implemented. Inactive cells (holes) are now visually readable as not-playable rather than looking like ordinary empty playable tiles: they never receive highlights, previews, or transient effects, and a falling tile no longer visibly slides over an inactive gap. Board/battle logic — hole generation rules, `normal`/`ice`/`holes` archetype routing, match/swap rules, booster rules, special tile rules, and gravity/refill board-state logic — is entirely unchanged; this stage is presentation-only, using the Stage 54.2 pass-through gravity metadata for safe visual handling.
- **`TileView` inactive visual state.** `set_cell_active(active: bool)` (`scripts/game/view/tile_view.gd`) is the persistent switch between normal and "hole" rendering. While inactive, `_apply_visuals()` unconditionally calls `_apply_inactive_visuals()` — a mostly-transparent dark inset (`INACTIVE_CELL_BACKGROUND_COLOR`) with no border, no icon, and no marker text — regardless of `tile_type`, `special_tile_data`, `_is_selected`, `_is_highlighted`, or `_is_invalid_feedback`, so no later `set_tile()`/`set_special_tile()`/`set_selected()`/`set_highlighted()`/`set_invalid_feedback()` call can accidentally make an inactive cell look active/playable again. Every transient `play_*` effect method (`play_flash`, `play_invalid_flash`, `play_swap_pulse`, `play_invalid_pulse`, `play_match_fade`, `play_match_clear`, `play_special_flash`, `play_special_clear`, `play_invalid_bounce`, `play_refill_appear`) also no-ops while inactive, even if a caller targets one directly, so no lingering tween can flash/scale a hole. Deactivating clears selection/highlight/invalid-feedback state, kills any in-flight tween, resets `modulate`/`scale`, and sets `mouse_filter = MOUSE_FILTER_IGNORE`; the 9x9 `GridContainer` layout stays stable since the tile remains `visible = true` throughout — only its styling, icon, and text change.
- **`BoardView` active-mask rendering.** `refresh_all_tiles()` — the single choke point behind initial board render, full refresh, and (via `GameScreen`'s battle-start flow) restart/next-level/retry, plus the seamless post-overlay handoff in `apply_board_under_overlay()` — now calls `tile.set_cell_active(board.is_cell_active(cell))` before syncing tile/special/selected/highlighted/invalid state, so every render path picks up the mask automatically. A full active 9x9 board (today's normal/ice archetypes, and most of `holes`) looks exactly as it did before this stage.
- **Highlights, previews, and effects skip inactive cells.** `get_tile_views(cells)` now filters out any cell the board reports inactive, which alone protects every caller that gathers tiles this way: selected-cell/match/cascade/special-activation highlighting, invalid-swap feedback, match/special/booster clear flashes, swap feedback, and refill feedback. `flash_cells()` was switched to route through `get_tile_views()` too, closing the one remaining direct `get_tile_view()` loop. Booster preview (`show_booster_target_preview()`) and booster impact-flash (`_play_booster_impact_flash()`) build independent `ColorRect` overlays rather than going through `TileView`, so each got its own explicit inactive-cell filter — Hammer's 3x3 preview area and Rocket's same-color preview area can both include cells outside the always-active target cell, and neither ever draws an overlay on a hole now, regardless of what cell list the caller passed in. If a caller ever does accidentally pass an inactive cell into one of these methods, it's silently skipped rather than rendered.
- **Booster preview handles inactive cells safely.** Since Hammer's preview cell list is a raw 3x3 range around the target cell (built in `GameScreen._get_booster_preview_cells()` without checking active state) and Rocket's is a same-color scan, both rely on `BoardView.show_booster_target_preview()`'s new filter as the single enforcement point rather than needing changes at the cell-list-building call site. `clear_booster_target_preview()` is unchanged and still frees every preview node it created, active-cell or not.
- **Input presentation avoids misleading inactive-cell feedback.** Rather than filtering after the fact in `BoardInputController` or `GameScreen`, `TileView._on_gui_input()`/`_on_pressed()` explicitly refuse to emit `tile_pressed`/`tile_drag_released` while inactive (on top of `mouse_filter = MOUSE_FILTER_IGNORE`), so an inactive cell can never be selected, dragged from, or targeted for booster preview in the first place — `BoardInputController.handle_tile_pressed()`/`handle_tile_drag_released()` and `GameScreen._on_board_tile_pressed()`/`_show_booster_target_preview()` are simply never invoked with an inactive cell, so neither file needed any changes. Core rejection remains in `SwapResolver`/`BoosterResolver` as before; the UI-level fix means that rejection path is never even reached for a tap on a hole.
- **Pass-through fall visuals.** `_play_overlay_gravity_fall()` (the active animated-turn path) reads the Stage 54.2 `crosses_inactive_gap` metadata; a movement that crosses a gap is routed to the new `_animate_overlay_pass_through_fall()` instead of joining the shared straight-line position tween: the ghost fades out near the source, jumps directly to just above the target (no visible motion over the hole), then drops/fades in at the target. Movements that don't cross a gap are completely unchanged, still using the original shared parallel tween. The non-overlay `play_gravity_fall_animation()` fallback path (not used by the active `AnimatedTurnFlow`/overlay-mode animated-turn flow) was left unchanged, since `GravityResolver` already guarantees it's never handed inactive-cell fall data.
- **Refill visual safety.** `_play_overlay_refill()` and `play_refill_animation()` both gained a defensive skip for a refill entry whose `to` cell is inactive, even though `GravityResolver` already guarantees `refill_cells` never targets one — belt-and-suspenders consistent with the rest of the board core's defensive style. Full active 9x9 refill visuals are unaffected.
- **Overlay mode keeps holes visible without extra ghosts.** `hide_real_board_tiles()` (called when entering overlay mode for an animated turn) no longer hides an inactive cell's real `TileView`, and `build_full_board_ghosts()` never builds a ghost for one — using a new `is_active` field captured on `BoardVisualSnapshot` (via `TileView.is_cell_active()`). Since gravity/refill never target an inactive cell, its real "hole" look simply stays in place, correctly rendered, for the entire overlay session with no extra bookkeeping, while every other overlay swap/clear/gravity/refill/special-creation function already gracefully skips a cell with no ghost (pre-existing `null`-check behavior), so nothing else needed to change.
- **Cleanup, reduced motion, and disabled animations are preserved.** `clear_transient_visual_state()` and `force_reset_animation_state()` needed no changes: both already end by calling `refresh_all_tiles()`, which re-applies each tile's correct active state every time, so inactive-cell presentation survives valid turns, cascades, booster use, the result overlay, retry, next level, return to LevelSelect, disabled animations, and reduced motion automatically, without any special-casing for those flows.
- **Roadmap.** Stage 56 will add the ice obstacle core.

## Stage 55.1: Inactive Overlay Stability and Center-Hole Generation Unlock v0.1

- Stage 55.1 is implemented. It fixes an overlay-mode visual bug in inactive-cell rendering and unlocks controlled procedural holes at the board center for medium/hard/very_hard difficulty tiers. No board gameplay rules (match logic, swap logic, gravity board-state logic, booster rules, special tile rules, result flow) changed.
- **What caused the overlay bug.** Stage 55's `hide_real_board_tiles()` deliberately left an inactive cell's real `TileView` visible while hiding every active real tile (which get covered by overlay ghosts instead) during an animated turn. `GridContainer` recomputes its row/column sizing from only its *visible* children — with most of a row/column hidden (the active tiles), the one remaining visible cell (the inactive hole) would stretch to absorb the freed space instead of keeping its own per-cell shape, producing the reported "merge into tall dark vertical areas" symptom. Static (non-overlay) rendering was never affected, since outside overlay mode every real `TileView` stays visible and `GridContainer` sizes them uniformly as usual.
- **How overlay-mode inactive visuals were stabilized.** `hide_real_board_tiles()` now hides every real tile uniformly again — active or inactive — restoring a consistent (empty) visible-child set for `GridContainer` so no cell is ever asked to absorb freed space. `build_full_board_ghosts()` now builds one ghost per cell for every cell, including inactive ones: active cells get the existing tile ghost; inactive cells get a new `create_inactive_hole_ghost()` placeholder — a plain, absolutely-positioned `Control` inside `animation_layer` (not a `GridContainer` child, so it can never be resized by `GridContainer`'s visible-children pass) styled identically to `TileView`'s inactive look (`TileView.INACTIVE_CELL_BACKGROUND_COLOR`, no border, no icon/text, `disabled = true`, `mouse_filter = MOUSE_FILTER_IGNORE`). Since gravity/refill never target an inactive cell (Stage 52-54.2), nothing ever animates this placeholder; it simply sits in its correct per-cell rect, stable, for the whole overlay session — visually identical between static and animated states. `exit_animation_overlay_mode()` now also calls `refresh_all_tiles()` (in addition to `show_real_board_tiles()`) so every real tile, including inactive ones, is guaranteed freshly synced from `BoardModel` the instant it becomes visible again; this is a defensive addition since `apply_board_under_overlay()` already refreshes just before calling it, but it now also covers any other caller.
- **Pass-through fall visuals preserved.** The Stage 55 `crosses_inactive_gap`/`crossed_inactive_cells` handling in `_play_overlay_gravity_fall()`/`_animate_overlay_pass_through_fall()` needed no changes at all — it only ever reads/writes active-cell ghosts (`from`/`to` in `fall_movements` are always active by construction), so it was never affected by the inactive-ghost bug or its fix. A gap-crossing fall still fades its ghost out near the source, jumps to just above the target, and drops/fades in, with no visible motion over the hole; non-crossing falls are unchanged. Inactive cells stay visually stable underneath/around any such animation since their own placeholder ghost never moves.
- **Center-hole generation unlock.** Previously, `HoleGenerationRules.keep_center_active` was always `true`, and every center shape preset deliberately avoided the exact center cell `(4, 4)` as a hard rule. `HoleGenerationRules.for_tier(tier)` now also resolves `keep_center_active` per tier via a new `_keep_center_active_for_tier()`: `true` for `early` (unchanged — no center-hole shape ever appears in its pool anyway), `false` for `medium`/`hard`/`very_hard`. Rectangular corner-quadrant and axis-straddling blocks are provably incapable of ever placing a cell at the exact board center (Stage 54.1 geometry: their anchor ranges never reach the center row/column), so relaxing this flag for those tiers has zero effect on block placement — it only matters for the new shapes that actually try to touch the center cell. This makes center protection effectively shape-dependent without needing a per-call override parameter: `HoleShapePlacer.try_place_shape()` and `BoardMaskValidator.validate()` were not modified at all — their existing `if rules.keep_center_active: ... reject/flag if cell == center` checks already behave correctly once the rules object they're handed has the tier-appropriate value.
- **New center-hole shapes.** `HoleShapePreset` gained three presets that deliberately include the exact center cell (relative offset `(0, 0)`), each forming one connected hole cluster so no single-cell hole noise is ever produced: `center_dot_plus` (5 cells: the center cell plus its 4 radius-1 orthogonal neighbors — the smallest safe center-inclusive shape), `center_diamond_hole` (9 cells: the same cross extended to radius 2 in each direction, per the stage's own suggested example of "center plus north/south/east/west neighbors"), and `center_circle_hole_light` (9 cells: a solid 3x3 block centered on the center cell, a compact circle-like approximation reserved for higher tiers since it uses more hole budget at once). All three are self-symmetric under `quadrant_mirror` by construction, so `BoardMaskGenerator._try_place_center_shape()`'s existing per-offset mirroring logic (unchanged) handles them with no special-casing. The existing `center_diamond`/`center_circle_light` presets are completely unchanged and still never touch the exact center cell.
- **Shape selection by difficulty.** `BoardMaskGenerator._resolve_shape_pool(tier)`: `early` is unchanged (`block_2x2`/`block_2x3`/`block_3x2` only, no center shapes of any kind). `medium` keeps its existing `block_2x2`/`block_2x3`/`block_3x2`/`center_diamond` entries and adds one `center_diamond_hole` entry (rare). `hard` keeps its existing block and `center_diamond`/`center_circle_light` entries and adds `center_dot_plus`, `center_diamond_hole`, and `center_circle_hole_light`. `very_hard` keeps its existing entries and adds `center_dot_plus` once plus `center_diamond_hole`/`center_circle_hole_light` each twice, so center-hole presets (and multi-shape candidates combining them with blocks) are weighted more likely to be picked, exactly as the stage asked for.
- **Validator remains the final authority.** `BoardMaskValidator` was not modified in this stage — it still rejects disconnected active area, enclosed active pockets, single-cell hole noise, too many holes, and an invalid 9x9 mask shape exactly as before; only the `keep_center_active` value carried by the tier-scoped rules object changed. If a center-hole shape placement fails validation (e.g. it would disconnect the active area given whatever else is already in the candidate), `BoardMaskGenerator`'s existing attempt-retry loop and full-active-mask fallback handle it exactly like any other unlucky candidate — center-hole shapes are never forced through at the expense of a broken mask.
- **Metadata.** `GeneratedBoardChallenge.metadata` for a `holes` challenge gained `center_cell_inactive` (whether the exact center cell ended up a hole in the final mask) and `center_axis_holes_count` (how many distinct cells along the center row and center column are holes), alongside the existing `selected_shape_types`, `requested_shape_count`, `fallback_used`, `active_cell_count`, `hole_cell_count`, and `last_validation_reasons` from Stage 54/54.1.
- **Roadmap.** Stage 56 will add the ice obstacle core.

## Stage 56: Ice Obstacle Core v0.1

Stage 56 is implemented. It adds the core ice/blocker obstacle data model, ice damage rules (direct clear plus orthogonal-adjacent clear, deduplicated per event), the resolve payload needed to animate it, and a placeholder visual layer. Procedural ice generation and any new ice-specific win goals are explicitly out of scope and remain Stage 57+; no board/battle gameplay rule outside ice-obstacle interactions changed.

- **`CellObstacleType` (`scripts/game/board/cell_obstacle_type.gd`).** A new, deliberately small board obstacle type layer: `NONE`/`ICE`, plus `is_valid()`/`is_ice()` helpers. This mirrors `SpecialTileType`'s shape but is a separate concept from both `TileType` and `SpecialTileType` — ice is a cell obstacle layer placed on top of an active cell, not a tile color or a match-created special. Extending this list (blockers, crates, chains, locks) later only means adding another constant here plus new `BoardModel`/`IceDamageResolver`/view handling, not touching `TileType`.
- **`BoardModel` obstacle storage.** Two new sparse `Dictionary` fields, `_obstacle_types` (`Vector2i -> CellObstacleType`) and `_obstacle_layers` (`Vector2i -> int`), following the exact same "sparse, absent means none" shape as the existing `_special_tiles` dictionary — kept fully separate from `_tiles` (tile type), `_special_tiles` (special metadata), and `_active` (the active/inactive mask). New API: `get_cell_obstacle(cell)`, `has_cell_obstacle(cell)`, `is_cell_iced(cell)`, `get_cell_obstacle_layers(cell)`, `set_cell_obstacle(cell, obstacle_type, layers := 1)`, `clear_cell_obstacle(cell)`, `damage_cell_obstacle(cell, amount := 1)`, and `get_ice_cells()`. Normal ice is represented as `obstacle_type = ICE, layers = 1`; double ice as `layers = 2` — the same `CellObstacleType.ICE` constant for both, distinguished purely by layer count, so future code only ever needs to branch on `is_ice()` plus a layer check rather than on separate `ICE_1`/`ICE_2` enum values. `damage_cell_obstacle(cell, amount)` reduces the layer count by `amount`, removing the obstacle entirely (via `clear_cell_obstacle()`) once it reaches 0, and returns `{cell, obstacle_type, previous_layers, new_layers, broken}` (or `{}` if the cell had no obstacle) so callers can build animation/payload data from one call.
- **Inactive cells and obstacles.** `set_cell_obstacle()` refuses to place an obstacle on an inactive cell (clearing any existing one instead), exactly mirroring `set_tile()`/`set_special_tile()`'s existing inactive-cell guards. `set_cell_active(cell, false)` now also calls `clear_cell_obstacle(cell)` alongside its existing `_tiles[...] = EMPTY` and `clear_special_tile(cell)` calls, so "an inactive cell can never carry an obstacle" holds everywhere in the board core without every caller needing to remember it — the same pattern Stage 52 established for tile/special data.
- **Obstacles are pinned to the cell, not the tile.** `swap_tiles()` was not touched — it already only moves `_tiles`/`_special_tiles` entries between two cells, so an ice-covered cell's obstacle correctly stays in place even if the covering tile is swapped away. `GravityResolver` was not touched either: it only ever reads/writes tile and special data per column, never obstacle state, so a falling/refilled tile landing in an iced cell does not disturb the ice, and a refilled tile never creates a new obstacle (there is no code path that would call `set_cell_obstacle()` from gravity/refill).
- **`duplicate_board()`.** Both obstacle dictionaries are copied (plain `Dictionary.duplicate()`, since values are primitive ints rather than objects needing `duplicate_data()` like `SpecialTileData`), so a duplicated board's ice state matches the source exactly.
- **`GeneratedBoardChallenge.frozen_cells` wiring.** `BoardModel.apply_frozen_cells(frozen_cells: Array)` is the new entry point: each entry may be a bare `Vector2i` (shorthand for 1-layer ice) or a `{"cell": Vector2i, "layers": int}` `Dictionary` (for richer future data), and any invalid, out-of-bounds, or inactive-cell entry is silently skipped rather than erroring, so a partially-invalid `frozen_cells` array degrades gracefully instead of corrupting the board. `BattlePresenter.start_level()` calls `board.apply_frozen_cells(current_generated_challenge.frozen_cells)` immediately after generating the playable board. Since `BoardChallengeGenerator.generate()` still always produces an empty `frozen_cells` array for every archetype (unchanged this stage), this wiring is currently a no-op in practice — but Stage 57's procedural ice generator only needs to populate the array with real cell data; no further changes to this call site are needed.
- **`IceDamageResolver` (`scripts/game/board/ice_damage_resolver.gd`).** The single place ice-damage rules live, used by every clear path. Given a board and a batch of `cleared_cells` from one clear event, it builds one deduplicated target set: every cleared cell that is iced (direct damage), plus every orthogonal (up/down/left/right only — never diagonal) neighbor of a cleared cell that is itself iced and on an `is_playable_cell()` cell (adjacent damage), using a `Dictionary`-as-set to guarantee each qualifying cell is included at most once regardless of how many times it qualifies (cleared directly *and* adjacent to another cleared cell; adjacent to two different cleared cells in the same event; etc.) — this directly satisfies the "no double-damaging the same ice in one resolve event" requirement without any special-case bookkeeping at each call site. `apply_ice_damage(board, cleared_cells)` mutates the board (calling `damage_cell_obstacle()` per target cell) and returns the resulting event list. `preview_ice_damage(board, cleared_cells)` computes the identical target set and predicts each event's outcome (`previous_layers`/`new_layers`/`broken`) without mutating anything — needed because the animated turn flow must know what ice feedback to play *before* the board is actually cleared (see below). Two static helpers, `extract_damaged_cells()`/`extract_broken_cells()`, pull cell lists back out of an event array for payload/animation code that only needs "which cells" rather than the full event dictionaries.
- **Wired into every clear source.** `BoardResolver.resolve_board()` (the non-animated, all-at-once resolve path) and `BoosterResolver.resolve_targeted_booster()` (Hammer, Rocket Barrage) both call `board.clear_cells(cleared_cells)` immediately followed by `IceDamageResolver.apply_ice_damage(board, cleared_cells)` — both paths already fully mutate the board before any animation plays, so mutate-then-record is correct and sufficient. `StepwiseBoardResolver.build_clear_step()` calls `preview_ice_damage()` (board not yet mutated for this step) and stores the result on `step.ice_events`; `apply_clear_step()` later calls `board.clear_cells(step.cleared_cells)` then `apply_ice_damage()` to actually mutate — this two-phase split exists because `AnimatedTurnFlow.start_swap_turn()`/`start_booster_clear()` build and play the clear animation sequence from `step` *before* calling `apply_clear_step()`, so the preview must already be correct at build time. Because `BoardResolver`'s and `StepwiseBoardResolver`'s existing per-cascade-step logic already unifies normal match cells, color-bomb clear cells, and horizontal/vertical line-special clear cells into one `cleared_cells` list before either resolver touches the board, all of those sources get ice damage "for free" through this one pair of call sites — no separate ice-handling code was needed per match type or per special type.
- **Resolve payload.** `BoardResolveResult` (used by `BoardResolver`) and `BoardResolveStep` (used by `StepwiseBoardResolver`) both gained an `ice_events` field (each entry: `cell`, `obstacle_type`, `previous_layers`, `new_layers`, `broken`), plus `BoardResolveResult` aggregates `ice_damaged_cells`/`ice_broken_cells` across all its steps and `BoardResolveStep` exposes the same via `get_ice_damaged_cells()`/`get_ice_broken_cells()` helper methods; both are included in `to_dictionary()`. `BoosterResolveResult` gained the same `ice_events` field and derived cell lists in its `to_dictionary()`. `TurnPresentationData` (the headless/non-animated presentation data object) carries the first resolve step's `ice_events` the same way it already carries `special_cleared_cells`/`fall_movements`/etc.
- **Animation request and ordering.** A new `BoardAnimationRequest.TYPE_ICE_EVENT` constant carries an `ice_events` payload. `BoardAnimationSequenceBuilder` queues one of these requests immediately before the tile-clear request it accompanies, in every sequence-building method that has clear data available: `build_clear_sequence()` (the live `AnimatedTurnFlow` per-cascade-step path), `build_from_turn_presentation()`/`build_from_booster_result()` (the headless/non-animated fallback paths), `build_booster_activation_and_clear_sequence()` (the live booster path), and `_add_cascade_step_requests()` (extra cascade steps appended after the first). This produces exactly the expected visual order: ice damage/break feedback, then the tile clear fade, then gravity/refill. `BoardAnimationController` handles `TYPE_ICE_EVENT` by splitting its `ice_events` payload into cells that were merely damaged (still icy — `broken == false`) versus cells whose ice fully broke (`broken == true`), calling `BoardView.play_ice_damage_animation()`/`play_ice_break_animation()` respectively so the two outcomes get visually distinct feedback. If animations are disabled entirely, `BoardAnimationController`/`_finish_immediately()` skip playing any request — but `BoardModel`'s obstacle state has already been mutated synchronously by the underlying resolver before any animation request is even built, so obstacle state always stays correct regardless of whether feedback plays.
- **`TileView` ice overlay.** Two child `ColorRect` nodes (`IceOverlay`, `IceOverlayInner`), created once in `_ready()` and anchored to fill the tile (`PRESET_FULL_RECT`, `IceOverlayInner` inset a few pixels). Since a `Control`'s children paint after the parent's own rendering, these render on top of the `Button`'s icon/text/stylebox without needing any change to how tile color/icon/special-marker rendering works. `set_cell_obstacle(obstacle_type, layers)` stores the state and re-applies visuals; `_apply_ice_overlay()` shows/colors `IceOverlay` (a lighter translucent blue/white tint for 1-layer ice, a stronger tint for 2-layer) and additionally shows `IceOverlayInner` only for 2-layer ice, so double ice reads as visually "thicker" via a second overlay rather than a separate sprite/asset. Both overlays are force-hidden whenever the tile is inactive (`_apply_inactive_visuals()`), matching the rule that an inactive cell never shows an obstacle. `play_ice_damage()` briefly flashes `IceOverlay` cold-white then re-applies the steady-state overlay; `play_ice_break()` fades both overlays to transparent then re-applies (which, since the caller is expected to sync the new — already-broken — obstacle state only after or alongside this call, ends up hiding the overlay for good). Both no-op while the tile is inactive, matching every other `play_*` method's existing convention.
- **`BoardView` rendering.** `refresh_all_tiles()` — already the single choke point behind initial render, full refresh, restart/next-level/retry, and the post-overlay handoff in `apply_board_under_overlay()` — now also calls `tile.set_cell_obstacle(board.get_cell_obstacle(cell), board.get_cell_obstacle_layers(cell))` per cell, so ice presentation is automatically correct everywhere `refresh_all_tiles()` already runs, with no new call sites needed elsewhere. `create_tile_ghost_from_data()` gained optional `obstacle_type`/`obstacle_layers` parameters; when ice is present it adds a matching `IceOverlay` `ColorRect` child to the ghost `Button`, reusing `TileView.ICE_OVERLAY_COLOR`/`ICE_OVERLAY_COLOR_DOUBLE` so overlay-ghost and real-tile ice read identically. `build_full_board_ghosts()` (the whole-board overlay-mode ghost builder) passes obstacle data straight from the snapshot for every active-cell ghost; the transient moving-tile ghosts built during swap/gravity-fall/refill/special-create animations intentionally do not carry obstacle data, since ice belongs to the cell rather than the tile passing through it. `play_ice_damage_animation(cells)`/`play_ice_break_animation(cells)` dispatch to real `TileView.play_ice_damage()`/`play_ice_break()` outside overlay mode, or to new `_play_overlay_ice_damage()`/`_play_overlay_ice_break()` helpers in overlay mode that tween a ghost's `IceOverlay` child directly (found via `get_node_or_null("IceOverlay")`) — the break variant frees that child node once the fade tween completes, so no stale overlay is ever left behind on a ghost that a later gravity/refill/special-create step might reuse or reposition in the same overlay session.
- **`BoardVisualSnapshot`.** Gained `obstacle_type`/`obstacle_layers` fields per cell, read via new `TileView.get_obstacle_type()`/`get_obstacle_layers()` getters using the exact same `tile.has_method(...)`-guarded optional-field pattern the existing `is_active` field already uses, so `build_full_board_ghosts()` can render ice on an overlay ghost from snapshot data alone.
- **Out of scope for this stage.** No procedural ice placement was added (`GeneratedBoardChallenge.frozen_cells` is still always empty — Stage 57). No new ice-specific win/level goals were added. Enemy damage, stars, the result overlay, boosters' damage/targeting rules, special tile rules, and progression rules are all unchanged beyond the ice-obstacle clear/damage interactions described above.
- **Roadmap.** Stage 57 will generate `frozen_cells` procedurally for ice-archetype levels (real ice layouts driven by the difficulty budget, mirroring how Stage 54 generated real hole layouts for the `holes` archetype), likely followed by ice-specific win goals and UX/balance polish once real archetypes affect difficulty.

## Stage 57: Procedural Ice Generator v0.1

Stage 57 is implemented. `ice`-archetype levels now generate real, readable frozen-cell layouts via a difficulty-tier-scoped rules object and pattern generator, mirroring how Stage 54 generated real hole layouts for the `holes` archetype. `normal` and `holes` archetype routing are unchanged, and this stage does not combine holes and ice on the same board.

- **`IceGenerationRules` (`scripts/game/config/ice_generation_rules.gd`).** A typed rules object with the same shape as `HoleGenerationRules`: `min_ice_cells`/`max_ice_cells`, `max_double_ice_cells`, `double_ice_chance`, `cluster_size_min`/`cluster_size_max`, `allowed_pattern_types` (an `Array[String]` of pattern-type constants defined on this same class: `PATTERN_SMALL_CLUSTER`/`PATTERN_EDGE_PATCH`/`PATTERN_CENTER_PATCH`/`PATTERN_DIAGONAL_BAND`), and `validation_attempts`. `IceGenerationRules.for_tier(tier)` is the single source of truth for the tier -> ice-budget mapping, so no other file hardcodes per-tier numbers: `early` is 3-6 ice cells, no double ice, `small_cluster` only, 20 attempts; `medium` is 5-9 cells, up to 1 double-ice cell at a 15% roll chance, adds `edge_patch`, 25 attempts; `hard` is 7-12 cells, up to 3 double-ice cells at 30%, adds `center_patch`, 30 attempts; `very_hard` is 9-16 cells, up to 5 double-ice cells at 45%, adds `diagonal_band`, 35 attempts.
- **`IcePatternGenerator` (`scripts/game/board/ice_pattern_generator.gd`).** The generation entry point, `generate_frozen_cells(rng, board_mask, difficulty_budget, rules) -> Dictionary` (returns `{"frozen_cells": Array, "metadata": Dictionary}`), mirrors `BoardMaskGenerator.generate_holes_mask_with_metadata()`'s overall shape: resolve a tier-scoped rules object if none is passed explicitly, compute a randomized target ice-cell count within `min_ice_cells`/`max_ice_cells` (clamped to the active-cell count), then loop up to `rules.validation_attempts` times building a fresh candidate and validating it, returning the first valid candidate or an empty-`frozen_cells` fallback if none validates.
- **Building a candidate.** `_build_candidate()` repeatedly draws a random pattern type from `rules.allowed_pattern_types`, generates that pattern's cell list, and folds any new cells into a `Dictionary`-as-set (so duplicate cells across overlapping patterns are naturally deduplicated) until the target count is reached or a placement-attempt budget (`target_count * 6`) runs out; a pattern that returns no usable cells (e.g. it walked itself into a corner with no room left) is simply skipped and another attempt/pattern is tried, exactly like `BoardMaskGenerator`'s per-shape retry behavior.
- **Readable patterns, not random noise.** Four pattern types, each intentionally a small, legible shape rather than scattered single-cell noise: **`small_cluster`** grows a short orthogonal random walk from a random active anchor cell (repeatedly picks a random cell already in the cluster and adds one of its unclaimed active orthogonal neighbors) until it reaches a randomized size within `cluster_size_min`/`cluster_size_max`; **`edge_patch`** picks one of the four board edges at random and lays a short contiguous strip of cells along it; **`center_patch`** grows outward from the board's center cell through a fixed ring of offsets (center, then its orthogonal and diagonal neighbors) up to the target patch size; **`diagonal_band`** walks a short diagonal line (one of the two diagonal directions) from a random active anchor, stopping at the board edge. Every pattern generator filters its proposed cells against the active-cell lookup before returning them, so a pattern can never propose an inactive or out-of-bounds cell even transiently.
- **Difficulty-tier pattern pools.** Early levels only ever draw `small_cluster` with a small cluster-size range, producing a single small, sparse patch. Medium/hard/very_hard progressively unlock `edge_patch`/`center_patch`/`diagonal_band` and widen `cluster_size_min`/`cluster_size_max`, and since `_build_candidate()`'s outer loop keeps drawing patterns until the (larger, tier-scoped) target ice count is reached, higher tiers naturally end up combining multiple patterns/clusters on one board rather than needing separate "how many patterns" logic.
- **Active-cell safety.** `_active_cells_from_mask()` reads the board mask the same rows-of-bools shape `BoardMaskGenerator`/`BoardModel.set_active_mask()` already use, and every pattern generator is handed an `active_lookup` `Dictionary` built from that list — cells are only ever proposed from (or filtered down to) that lookup, so ice can never land outside the board or on an inactive cell. Because `ice`-archetype levels still use a full active 9x9 mask in this stage (see routing below), this safety net is currently a no-op in practice, but it means a future stage combining archetypes needs no changes to `IcePatternGenerator` itself.
- **1-layer and 2-layer output.** `_assign_double_ice()` converts the deduplicated cell set into the exact output shape `BoardModel.apply_frozen_cells()` (Stage 56) already accepts: a bare `Vector2i` for 1-layer ice, or a `{"cell": Vector2i, "layers": 2}` `Dictionary` for double ice. Each placed cell independently rolls `rules.double_ice_chance` against a running `double_budget` that starts at `rules.max_double_ice_cells` and decrements every time a roll succeeds, so double ice can never exceed the cap no matter how many rolls succeed — once the budget hits 0, every remaining cell is forced to 1-layer ice regardless of further rolls.
- **Validation.** `_validate()` checks, in order: every output cell is in the active-cell lookup (`cell_not_active`); the output has no duplicate cells (`duplicate_cells`, checked directly on the final `frozen_cells` list rather than only relying on the internal set's structural uniqueness); total ice-cell count is within `min_ice_cells`/`max_ice_cells` (`below_min_ice_cells`/`above_max_ice_cells`); double-ice count is within `max_double_ice_cells` (`above_max_double_ice_cells`); and total ice cells never exceed `MAX_SATURATION_RATIO` (a hardcoded 50%) of the active-cell count (`board_oversaturated`) — this last check is independent of whatever a hand-built/future rules object's own `max_ice_cells` allows, so a misconfigured rules object still can't produce an unplayably-frozen board. Unlike `BoardMaskValidator`, there is no connectivity or enclosed-pocket check: ice is a Stage 56 obstacle overlay on an already-active cell, not a hole that removes the cell from play, so it can never disconnect or wall off part of the board the way an inactive-cell mask could.
- **Fallback.** If no candidate validates within `rules.validation_attempts` (or the board mask has no active cells at all), `generate_frozen_cells()` returns an empty `frozen_cells` array along with fallback metadata (`ice_fallback_used: true`, `layout_source: "fallback_no_ice"`) — battle startup always proceeds with a normal, ice-free board rather than ever erroring or blocking.
- **`BoardChallengeGenerator` routing.** `generate()` now has three branches: `holes` (unchanged — procedural mask via `BoardMaskGenerator`, `frozen_cells` stays empty); `ice` (new — `board_mask` is `BoardMaskGenerator.build_full_active_mask()`, same as before, but `frozen_cells` now comes from `IcePatternGenerator.generate_frozen_cells()`, called with a `RandomNumberGenerator` seeded from `generation_seed` so a given seed reproduces the same ice layout, mirroring exactly how the `holes` branch already seeds its own mask RNG); everything else (`normal`) is unchanged — full active mask, empty `frozen_cells`, placeholder metadata. Holes and ice are deliberately not combined in this stage: an `ice` challenge's `board_mask` is always fully active, and a `holes` challenge's `frozen_cells` is always empty.
- **Metadata/debug.** `GeneratedBoardChallenge.metadata` for an `ice` challenge now includes `generator_version`, `layout_source` (`"procedural_ice"` on success, `"fallback_no_ice"` on fallback), `selected_ice_patterns` (the pattern-type strings actually used to build the returned candidate), `ice_cell_count`, `double_ice_cell_count`, `ice_attempts_used`, `ice_fallback_used`, and `ice_validation_reasons` (the last validation attempt's rejection reasons, useful for debugging a difficult-to-satisfy rules configuration). `GeneratedBoardChallenge.get_debug_label()` appends `, ice: <count>, double: <count>` to its existing `Challenge: <archetype>, seed: <seed>, active: <x>/<y>, holes: <n>` label when `archetype == "ice"`, plus `, ice_fallback: true` when generation fell back, e.g. `Challenge: ice, seed: 12345, active: 81/81, holes: 0, ice: 12, double: 2`.
- **Stage 56 obstacle core untouched.** This stage only produces data; it does not change how ice behaves once placed. `BattlePresenter.start_level()` already calls `board.apply_frozen_cells(current_generated_challenge.frozen_cells)` (Stage 56), so a real `ice` challenge's frozen cells flow into the existing, unmodified `BoardModel` obstacle layer, `IceDamageResolver` direct/adjacent damage rules, per-clear-event dedup, and `TileView`/`BoardView` placeholder ice presentation with zero additional wiring.
- **Out of scope for this stage.** No new ice-specific win/level goals were added. No victory-condition changes. Stars, rewards, the result overlay, enemy damage, moves, and boosters are all unchanged.
- **Roadmap.** Stage 58 remains challenge cycle integration and tuning: balance passes once `normal`/`ice`/`holes` all meaningfully affect difficulty across the full 100-level campaign, plus any generated-challenge validation/retry work and archetype-specific UX polish not covered by this stage or Stage 51-56.

## Stage 57.1: Symmetric Ice Patterns and Stronger Ice Visuals v0.1

Stage 57.1 is implemented. It brings Stage 57's ice generation closer to how holes are generated — symmetrical, shape-based, and visually intentional, with a real chance of ice landing on the exact board center — and strengthens the placeholder ice overlay colors so normal and double ice read as clearly distinct at a glance. Archetype routing and Stage 56's ice damage rules are completely unchanged; this is a generation-quality and visual-readability patch only.

- **`IceShapePreset` (`scripts/game/board/ice_shape_preset.gd`).** A new shape-name-and-geometry helper mirroring `HoleShapePreset`'s role. Center presets are offset lists relative to the exact board center cell: `center_diamond_light` (center cell plus its 4 radius-1 orthogonal neighbors, 5 cells), `center_square_light` (a solid 3x3 square centered on the board center, 9 cells), `center_diamond_heavy` (the light diamond's cross extended out to radius 2, 9 cells), and `center_square_heavy` (the light square plus 4 radius-2 orthogonal arm cells, 13 cells). Unlike `HoleShapePreset`'s center offsets — which `BoardMaskGenerator` must mirror through `BoardMaskSymmetry` because they're only a single representative arm — every `IceShapePreset` center offset list is already fully self-symmetric about the single center cell by construction, so `IcePatternGenerator` just adds the offsets to the resolved center cell directly with no separate mirroring pass. Mirrored-block presets (`mirrored_block_2x2`/`mirrored_block_2x3`/`mirrored_block_3x2`) are plain rectangle sizes, exactly like `HoleShapePreset`'s block presets.
- **50% center-ice chance.** `IceGenerationRules.center_ice_chance` (0.35 for `early`, 0.5 for `medium`/`hard`/`very_hard`) is rolled once per `generate_frozen_cells()` call via `safe_rng.randf()`. On success, `_try_generate_center_candidate()` builds a randomized (seed-reproducible) ordering of `rules.allowed_center_shape_types` and returns the first shape whose active-cell-filtered offset list is non-empty and whose cell count fits under both `rules.max_ice_cells` and the new `rules.max_center_ice_cells` cap; that candidate is validated through the same `_validate()` every other path uses, and returned immediately on success. If the roll fails, or no allowed center shape is non-empty/small-enough/valid, generation falls straight through to the symmetric/scattered path below — a failed or skipped center-ice attempt never blocks a battle from getting ice, it just means that battle's ice isn't center-anchored.
- **Symmetric non-center ice.** `_build_symmetric_candidate()` replaces the old `_build_candidate()` as the fallback path: each placement attempt now checks `rules.prefer_symmetry and not rules.allowed_symmetric_shape_types.is_empty()` and, if true, draws a mirrored-block shape type and places it via new `_generate_mirrored_block_cells()` instead of drawing from the Stage 57 scattered-pattern pool. `_generate_mirrored_block_cells()` anchors one copy of the block anywhere on the board, then mirrors it across a single randomly chosen axis (horizontal: `x -> width-1-x`, or vertical: `y -> height-1-y`) rather than `BoardMaskSymmetry`'s full 4-way quadrant mirror — a full quadrant mirror would produce up to 4x the block's cell count, which would blow straight past ice's much smaller per-tier caps compared to holes' larger hole budget (e.g. a quadrant-mirrored 2x3 block is 24 cells; a single-axis-mirrored one is 12, which fits comfortably under `hard`'s 12-cell cap). `early` tier still has `allowed_symmetric_shape_types` empty, so it falls through to the original scattered-pattern pool exactly as Stage 57 did — no regression for the gentlest tier.
- **Tier-scoped shape pools stay structurally safe.** `IceGenerationRules.for_tier()` only ever lists a center or symmetric shape for a tier if that shape's fixed cell count already fits under that tier's `max_ice_cells`/`max_center_ice_cells` (e.g. `center_square_heavy` at 13 cells is only offered starting `very_hard`, whose cap is 16; `mirrored_block_2x3`/`3x2` at 12 cells each are only offered from `hard` upward, whose cap is 12+), so a listed shape is never structurally doomed to fail validation before it's even attempted.
- **Validation and active-cell safety fully preserved.** Both new generation paths (center shapes and mirrored blocks) build a candidate in the exact same `{"frozen_cells", "selected_patterns", "cell_set"}` shape the original scattered-pattern path already used, so they both flow through the same unmodified `_validate()`: every cell inside the board and active, no duplicate cells, ice/double-ice counts within `min_ice_cells`/`max_ice_cells`/`max_double_ice_cells`, and total ice cells under the `MAX_SATURATION_RATIO` (50%) ceiling. Nothing about validation semantics changed — only what gets validated got richer, exactly as Stage 54.1 did for hole shapes.
- **1-layer/2-layer output unchanged.** All three generation paths (center, symmetric, scattered) call the same unmodified `_assign_double_ice()` introduced in Stage 57, so output is still a bare `Vector2i` for 1-layer ice or a `{"cell": Vector2i, "layers": 2}` `Dictionary` for double ice, with double-ice assignment still hard-capped by `rules.max_double_ice_cells` regardless of which generation path produced the candidate.
- **Stronger, more distinct ice visuals.** `TileView.ICE_OVERLAY_COLOR` changed from a light, easy-to-miss blue-white tint to a strong near-white frost (`Color(0.96, 0.98, 1.0, 0.58)`) that reads clearly on every tile color. `TileView.ICE_OVERLAY_COLOR_DOUBLE`/`ICE_OVERLAY_INNER_COLOR` changed from a slightly-stronger version of the same pale blue-white to a genuinely different, strong blue hue (`Color(0.20, 0.55, 0.95, 0.72)`/`Color(0.10, 0.40, 0.85, 0.55)`), so double ice is now distinguishable from normal ice by color, not just by the existing thicker second-overlay-layer treatment. Inactive cells still never show either overlay (`_apply_inactive_visuals()` unchanged), and the overlay still renders as a `ColorRect` child on top of the tile's own icon/text/stylebox, fully separate from tile color and the special H/V/B marker. `BoardView`'s overlay-mode ghost ice rendering (`create_tile_ghost_from_data()`, `_play_overlay_ice_damage()`/`_play_overlay_ice_break()`) reads `TileView.ICE_OVERLAY_COLOR`/`ICE_OVERLAY_COLOR_DOUBLE` directly, so it picks up the new colors automatically with no code changes needed there.
- **Metadata/debug.** `GeneratedBoardChallenge.metadata` for an `ice` challenge gains `selected_ice_shape_types` (an explicit alias of the existing `selected_ice_patterns`, matching this stage's naming), `center_ice_roll` (the raw roll value, for inspecting near-miss rolls), `center_ice_used` (whether the returned candidate came from the center-shape path), `center_ice_cell_count` (how many cells the center shape contributed, when used), and `symmetric_ice_used` (whether the returned candidate used a mirrored-block shape), alongside all of Stage 57's existing fields (`ice_cell_count`, `double_ice_cell_count`, `ice_attempts_used`, `ice_fallback_used`, `ice_validation_reasons`, `layout_source`).
- **Stage 56 ice damage rules untouched.** Direct-clear damage, adjacent orthogonal-clear damage, one-hit-per-cell-per-event dedup, 1-layer break-after-one-hit, and 2-layer break-after-two-hits all still work exactly as Stage 56 built them; this stage never touches `IceDamageResolver`, `BoardModel`'s obstacle layer, or any resolver wiring.
- **Archetype routing untouched.** `BoardChallengeGenerator.generate()`'s three branches (`normal` full active/no ice, `holes` procedural mask/no ice, `ice` full active mask/procedural ice) are unchanged; holes and ice are still not combined in this stage.
- **Roadmap.** Stage 58 remains challenge cycle integration and tuning, unchanged from Stage 57's roadmap note.

## Stage 57.2: Ice Density and Cycle Variant Rules v0.1

Stage 57.2 is implemented. Ice-archetype levels are now dense (32-40 frozen cells, every difficulty tier), read as clearly 4-way symmetric, and split by campaign cycle position into a weak (1-layer-only) or strong (2-layer-only) variant. Archetype routing and Stage 56's ice damage rules are completely unchanged; this is a generation density/topology and variant-rules patch.

- **Density replaces tier scaling.** `IceGenerationRules.MIN_ICE_CELLS`/`MAX_ICE_CELLS` (32/40, new class constants) are now the only values `for_tier()` uses for `min_ice_cells`/`max_ice_cells` and `max_center_ice_cells`, regardless of tier — superseding Stage 57/57.1's tier-scaled "gentle early / denser later" counts, since every ice level must now hit the same dense range. `allowed_center_shape_types`/`allowed_symmetric_shape_types` are likewise the full `IceShapePreset` lists for every tier now (previously early had a restricted pool), since even the largest single shape (13 cells) is well under the new per-level target and needs topping up regardless of tier; only `center_ice_chance` (0.35 early, 0.5 medium+), `validation_attempts`, and the scattered-pattern top-up pool/cluster sizes still vary by tier. The saturation guard (`MAX_SATURATION_RATIO`, unchanged at 0.5) keeps 40/81 (~49.4%) safely under its ceiling — a validated candidate can never exceed this regardless of what a hand-built rules object's `max_ice_cells` allows.
- **`IceVariant`/`IceVariantResolver` (`scripts/game/config/ice_variant.gd`/`ice_variant_resolver.gd`).** `IceVariant` defines `WEAK`/`STRONG`/`NONE` as a variant layer *inside* the existing `ice` archetype — not a new archetype, and `ChallengeArchetypeResolver`'s 5-level cycle (1 normal, 2 ice, 3 holes, 4 ice, 5 holes) is untouched. `IceVariantResolver.resolve_for_level(level_number)` reuses that same cycle: `level_number % 5 == 2` (the first `ice` slot in the cycle) resolves to `WEAK`, `== 4` (the second `ice` slot) resolves to `STRONG`; every other position returns `NONE` defensively, though in practice `ice`-archetype generation is only ever invoked on cycle positions 2 or 4, so a real ice level always resolves to exactly one of `WEAK`/`STRONG`. `BoardChallengeGenerator.generate()` calls `IceVariantResolver.resolve_for_level(level_number)` and passes the result into `IceGenerationRules.for_tier(tier, variant)`, which stores it directly on the returned rules object (`rules.ice_variant`) rather than threading it through every constructor call site.
- **Deterministic layer assignment.** `IcePatternGenerator._assign_layers(rng, cell_set, rules)` now switches on `rules.ice_variant`: `WEAK` forces every cell to a bare `Vector2i` (1-layer) via `_assign_all_weak()`; `STRONG` forces every cell to `{"cell": cell, "layers": 2}` via `_assign_all_strong()`; `NONE` falls back to the original Stage 57/57.1 `_assign_probabilistic_layers()` (per-cell `double_ice_chance` roll capped by `max_double_ice_cells`), kept only so a caller that builds an `IceGenerationRules` without resolving a variant still gets the old behavior rather than an error. Weak levels therefore never contain a single `layers: 2` entry, and strong levels never contain a single 1-layer entry — deterministically, not probabilistically.
- **Center shapes seed instead of finish.** `_pick_center_shape_cells()` (renamed/refactored from Stage 57.1's `_try_generate_center_candidate()`) now only resolves and returns the chosen center shape's active-filtered cell set (and its shape-type label) — it no longer assigns layers, builds a complete candidate, or validates anything itself. `generate_frozen_cells()` passes that cell set into `_build_symmetric_candidate()` as a `seed_cell_set`, which starts its working `cell_set` from the seed (instead of empty) and keeps placing symmetric/scattered cells exactly as before until the randomized 32-40 `target_count` is reached; only the resulting *full* candidate is validated. A center square/diamond therefore always marks where a layout starts, never the whole layout — satisfying the stage's explicit "center shapes should seed the layout, not define the whole layout" requirement.
- **True 4-way quadrant-mirrored symmetric placement.** `_generate_mirrored_block_cells()` no longer picks a single random mirror axis (Stage 57.1's 2-copy behavior); it now anchors a 2x2/2x3/3x2 block strictly inside the board's upper-left quadrant (`[0, width/2) x [0, height/2)`, exactly like `BoardMaskGenerator`'s corner-block hole placement) and calls the existing, unmodified `BoardMaskSymmetry.get_mirrored_block_cells()` to produce all four quadrant-mirrored copies — on a 9x9 board this is exactly `(x, y)`, `(8-x, y)`, `(x, 8-y)`, `(8-x, 8-y)` per cell in the block, deduplicated. Anchoring strictly inside the quadrant (never crossing the center row/column) guarantees the four copies never overlap, so a 2x2 block contributes exactly 16 cells and a 2x3/3x2 block contributes exactly 24 — one or two placements alone comfortably cover the 32-40 target with roughly even distribution across all four quadrants (e.g. ~8 cells/quadrant for a 32-cell non-center layout, as the stage's example describes).
- **Deterministic ice fallback.** If no randomized candidate validates within `rules.validation_attempts`, `generate_frozen_cells()` no longer returns an empty `frozen_cells` array (Stage 57/57.1's old fallback for a failed search) or bails to the scattered path — it now calls new `_build_deterministic_fallback_cell_set()`, which quadrant-mirrors two fixed, non-random 2x2 block anchors (`Vector2i(0, 0)` and `Vector2i(0, 2)`, chosen so their mirrored copies never overlap) for exactly 32 cells on a full active board, then assigns layers via `_assign_fallback_layers()` (all-strong if `rules.ice_variant == STRONG`, all-weak otherwise) with no randomness involved anywhere in this path — it is structurally guaranteed to succeed regardless of rng state, satisfying "fallback should not return empty frozen_cells for ice levels anymore."
- **Validation.** `_validate()` keeps every Stage 57/57.1 check (in-bounds, active, no duplicates, `min_ice_cells`/`max_ice_cells`, saturation) and adds a variant check: `ice_variant == WEAK` rejects any candidate with `strong_count > 0` (reason `weak_variant_has_strong_ice`); `ice_variant == STRONG` rejects any candidate with `weak_count > 0` (reason `strong_variant_has_weak_ice`); `ice_variant == NONE` keeps the old `above_max_double_ice_cells` cap check instead. This runs identically for randomized candidates and the deterministic fallback candidate, so the fallback is defensively validated too even though it's structurally guaranteed to pass.
- **Metadata/debug.** `GeneratedBoardChallenge.metadata` for an `ice` challenge gains `ice_variant`, `target_ice_count` (the randomized 32-40 value generation aimed for), `weak_ice_cell_count`, `strong_ice_cell_count`, and `fallback_symmetric_used`, alongside Stage 57/57.1's existing `selected_ice_shape_types`/`selected_ice_patterns`/`ice_cell_count`/`ice_attempts_used`/`ice_fallback_used`/`ice_validation_reasons`/`center_ice_roll`/`center_ice_used`/`center_ice_cell_count`/`symmetric_ice_used`/`layout_source`. `double_ice_cell_count` is kept as an alias of `strong_ice_cell_count` for any existing reader of that Stage 57/57.1 field name. `GeneratedBoardChallenge.get_debug_label()` now appends `, ice_variant: <weak|strong>, ice: <count>, weak: <count>, strong: <count>` for an `ice` challenge, replacing Stage 57's single `, ice: <count>, double: <count>` pair.
- **Stage 56 ice damage rules untouched.** Direct-clear damage, adjacent orthogonal-clear damage, one-hit-per-cell-per-event dedup, weak-ice-breaks-after-one-hit, and strong-ice-breaks-after-two-hits all still work exactly as Stage 56 built them; this stage never touches `IceDamageResolver`, `BoardModel`'s obstacle layer, or any resolver wiring.
- **Archetype routing and cycle untouched.** `ChallengeArchetypeResolver`'s 5-level cycle (1 normal, 2 ice, 3 holes, 4 ice, 5 holes) and `BoardChallengeGenerator.generate()`'s three archetype branches are unchanged; only the `ice` branch now resolves and threads through a variant. Holes and ice are still not combined in this stage.
- **Roadmap.** Stage 58 remains challenge cycle integration and tuning, unchanged from Stage 57/57.1's roadmap note.

## Stage 57.3: Debug Ice Visibility Filter v0.1

Stage 57.3 is implemented. It adds a temporary, strongly visible debug overlay for iced cells so Stage 57.2's dense 32-40-cell procedural ice generation can be visually confirmed during manual testing — no ice generation, damage, variant, board-resolver, or booster logic changed. This is a placeholder visual aid, explicitly meant to be toggled off or deleted once final ice art replaces it.

- **The problem.** Stage 57.1 strengthened the ice overlay to a "strong near-white" (normal) / "strong blue" (double) frost, but in practice it still read as fairly subtle against colorful match-3 crystals — nowhere near as obvious as, say, `BoardView`'s booster target preview. With Stage 57.2 now generating 32-40 ice cells per level (roughly 40-50% of the board), confirming the density/placement visually during manual testing needed a much bolder, unmistakable filter.
- **`TileView.ICE_DEBUG_VISIBILITY_ENABLED`.** A new `const` (default `true`) is the single toggle. While `true`, `TileView.resolve_ice_overlay_color(layers)` returns `ICE_DEBUG_OVERLAY_COLOR` (`Color(1.0, 1.0, 1.0, 0.78)` — the same strength as `BoardView.BOOSTER_TARGET_PREVIEW_COLOR`) for *every* iced cell regardless of layer count, instead of Stage 57.1's `ICE_OVERLAY_COLOR`/`ICE_OVERLAY_COLOR_DOUBLE`. Flipping the const back to `false` (or deleting the debug branch inside `resolve_ice_overlay_color()`/`resolve_ice_overlay_inner_color()`) fully restores Stage 57.1's original placeholder frost look with no other code changes needed.
- **Weak/strong distinction preserved under the flat white filter.** Strong (2-layer) ice already had a second, inset `IceOverlayInner` `ColorRect` (Stage 56/57.1) for a "thicker" look; `TileView.resolve_ice_overlay_inner_color()` now returns a new, strong blue `ICE_DEBUG_OVERLAY_COLOR_DOUBLE_INNER` while debug mode is on (instead of Stage 57.1's softer blue), so a strong-ice cell still reads as clearly distinct from a weak-ice cell — strong white overlay plus a visibly blue inset square — rather than every iced cell looking identical under the debug filter.
- **One source of truth reaches every render path.** `resolve_ice_overlay_color()`/`resolve_ice_overlay_inner_color()` are the only place the debug/final choice is made. `TileView._apply_ice_overlay()` (real board tiles, called from `_apply_visuals()` on every `set_tile()`/`set_special_tile()`/`set_cell_obstacle()`/selection/highlight change) and `BoardView.create_tile_ghost_from_data()` (overlay-mode animation ghosts) both call these same two functions, so the filter automatically appears on: the initial board render, `refresh_all_tiles()` (the existing choke point behind full refresh/restart/next-level/retry/post-overlay handoff), every overlay-mode ghost built during an animated turn, and with animations disabled or reduced motion (since those paths still call the same `set_cell_obstacle()`/`_apply_visuals()` chain synchronously). No per-call-site special-casing was needed anywhere.
- **Overlay ghosts gained the inner layer they were missing.** `create_tile_ghost_from_data()` previously only ever built a single `IceOverlay` child for a ghost, with no equivalent to `TileView`'s `IceOverlayInner` — so double ice never visually read as "thicker" in overlay mode the way it did on the real board. This stage adds the missing `IceOverlayInner` child (same inset offsets as `TileView.ICE_OVERLAY_INSET`) whenever `obstacle_layers >= 2`, colored via `resolve_ice_overlay_inner_color()`, so overlay-mode and static-mode strong ice now look identical. `BoardView._play_overlay_ice_break()` was extended to also fade-and-free a ghost's `IceOverlayInner` node (mirroring what it already did for `IceOverlay`) so a broken strong-ice ghost never leaves a stale inner square behind.
- **Booster previews already compatible, no changes needed.** `BoardView.show_booster_target_preview()`/`_play_booster_impact_flash()` build their own independent `ColorRect` nodes directly under `animation_layer` and call `move_to_front()` on them, entirely separate from the `IceOverlay`/`IceOverlayInner` children living inside a `TileView`/ghost `Button` node — so a booster preview already draws on top of any ice overlay with no interaction, and `clear_booster_target_preview()` only ever frees its own preview node list, never touching ice overlay nodes.
- **Nothing gameplay-related changed.** `IceGenerationRules`, `IcePatternGenerator` (patterns, density, center-seeding/top-up, 4-way symmetric placement, deterministic fallback), `IceVariant`/`IceVariantResolver`, `IceDamageResolver`, `BoardModel`'s obstacle layer, `BoardResolver`/`StepwiseBoardResolver`, `BoosterResolver`, and the result flow are all untouched by this stage — only the color two existing `ColorRect` overlay nodes render was changed.
- **Roadmap.** Stage 58 remains challenge cycle integration and tuning; retiring this debug filter (toning it back down, or replacing it with final ice art) is expected to happen alongside future ice-specific UX/art polish, not as part of Stage 58 itself.

## Stage 57.4: Rectangular Ice Clusters and Symmetry Completion v0.1

Stage 57.4 is implemented. It fixes "stair-step"/partial-rectangle ice layouts: non-center ice generation now always places exactly one mirrored-block rectangle per candidate, atomically, so a shape can never be truncated mid-placement the way the previous cell-by-cell loop allowed. Weak/strong variant rules (Stage 57.2), ice damage rules (Stage 56), and the debug visibility filter (Stage 57.3) are all unchanged; this is a generation-quality-only patch.

- **Why partial/stair-step clusters happened.** Stage 57.1's `_build_symmetric_candidate()` (and Stage 57.2's revision of it) added a pattern's cells to the working `cell_set` one at a time inside a `for cell in pattern_cells` loop, breaking out the moment `cell_set.size()` reached `target_count` or `rules.max_ice_cells` — including partway through a mirrored-block shape's cells. Since a mirrored rectangle's four quadrant copies were all generated together but added to the candidate individually, a candidate could end up with, say, 3 of a quadrant's 4 cells, reading as an incomplete/asymmetric "stair-step" cluster instead of a clean rectangle — visually the opposite of the "symmetrical, shape-based, and visually intentional" placement Stage 57.1 was meant to deliver.
- **Atomic shape placement.** New `IcePatternGenerator._build_rectangular_candidate()` replaces `_build_symmetric_candidate()` as the sole candidate-building path. For each shape type in `rules.allowed_symmetric_shape_types` (tried in a random, seed-reproducible order), it calls the unchanged `_generate_mirrored_block_cells()` to get the shape's *entire* mirrored cell set up front, then only ever considers accepting that whole set — never a subset. A shape whose full cell count doesn't fit under whatever cap currently applies is simply skipped in favor of a different shape/size, exactly mirroring how `BoardMaskGenerator`'s hole-shape placement already skips (rather than partially applies) a shape that doesn't fit `HoleGenerationRules`' caps.
- **Rectangular cluster validation.** New `_analyze_quadrant_rectangles(non_center_cell_set, width, height)` groups a candidate's non-center cells into the board's four quadrants (split by the exact center cell), computes each non-empty quadrant's bounding rectangle (min/max x and y), and checks two things: every cell inside that bounding rectangle is actually present in the cell set (no internal gaps — `cells.size() == rect_width * rect_height`), and every non-empty quadrant's rectangle has the exact same width/height as every other non-empty quadrant (true 4-way congruence, catching the case where four *different* shapes happen to occupy the four quadrants rather than one shape mirrored consistently). Center-shape cells are excluded by the caller before this analysis runs — per the stage's explicit requirement, a center shape is never treated as, or expected to form, a quadrant rectangle.
- **Completion pass.** New `_complete_rectangle_gaps(non_center_cell_set, active_lookup, width, height)` fills any active, currently-missing cell inside each quadrant's own bounding rectangle, returning the enlarged cell set and how many quadrants actually needed filling. `_build_rectangular_candidate()` runs this defensively right after generating a shape's mirrored cells (re-analyzing afterward to confirm the fill actually produced a clean rectangle) — in the common case on today's always-full-active 9x9 board this is a no-op, since atomic placement already produces a complete rectangle by construction, but it's real, exercised logic rather than a stub, and it's the mechanism a future combined archetype (ice cells landing near an inactive hole cell) would lean on if a mirrored copy ever lost a cell to inactivity.
- **Center shape budget rule.** For each candidate rectangle shape, `_build_rectangular_candidate()` first tries pairing it with the (optional) center seed, accepting the combination only if it stays within `[rules.min_ice_cells, rules.max_ice_cells]`. If that combination doesn't fit, it tries the rectangle *alone* — the center seed is dropped entirely, never the rectangle truncated — and may then use the enlarged absolute cap (see below) if the rectangle alone exceeds the normal cap. Among every shape/pairing that produces a valid option, the one whose total cell count is closest to the attempt's randomized `target_count` is selected. The stage's explicit priority ("rectangle completion has priority... remove the center shape if needed... center shape is optional, rectangular symmetry is required") is satisfied structurally: nothing in this function is ever capable of truncating a rectangle to make room for a center shape, only capable of dropping the center shape to make room for a rectangle.
- **Rectangle presets.** `IceShapePreset.get_mirrored_block_shape_types()` grew from 3 sizes to 8: the existing `mirrored_block_2x2`/`2x3`/`3x2` plus new `mirrored_block_2x4`/`4x2`/`3x3`/`4x3`/`3x4`. `get_block_size()` maps each to its `Vector2i` dimensions. Per-quadrant cell counts are 4 (2x2), 6 (2x3/3x2), 8 (2x4/4x2), 9 (3x3), and 12 (4x3/3x4); mirrored across all four quadrants (`_generate_mirrored_block_cells()`, unchanged from Stage 57.2) that's 16/24/24/32/32/36/48/48 total cells. `IceGenerationRules.for_tier()` still assigns the full `get_mirrored_block_shape_types()` list to every tier's `allowed_symmetric_shape_types` (Stage 57.2's tier-uniform approach), so no tier gets a restricted shape pool.
- **48-cell absolute cap.** New `IceGenerationRules.ABSOLUTE_RECTANGULAR_MAX_ICE_CELLS` (48) is only usable when `_validate()`'s rectangular-symmetry check passes: whenever the caller passes an `effective_max_ice_cells` above the normal `rules.max_ice_cells` (40), `_validate()` re-runs `_analyze_quadrant_rectangles()` on the candidate's non-center cells and adds a `not_rectangular_symmetric_for_absolute_cap` rejection reason if they don't form one complete, congruent rectangle. A candidate that pairs a rectangle with a center shape never qualifies for this cap (center-plus-rectangle combinations are capped at the normal 40, since the *center* cells aren't part of the rectangular check, but combining them still can't just be waved through the enlarged cap meant specifically for a clean single rectangle) — only a rectangle used *alone* (center dropped) can reach up to 48. `min_ice_cells` (32) is unchanged and still applies regardless of which cap is in effect.
- **Rectangular fallback.** `_build_deterministic_fallback_cell_set()` now calls `BoardMaskSymmetry.get_mirrored_block_cells()` directly for one fixed 2x4 block anchored at `(0, 0)` — 8 cells/quadrant x 4 = exactly `MIN_ICE_CELLS` (32) — instead of Stage 57.2's two separate 2x2 block anchors (which happened to combine into the same clean 2x4 region by coincidence of their exact placement, but weren't expressed as one shape). The fallback is still fully deterministic (no `rng` involved) and still calls `_assign_fallback_layers()` to honor the resolved ice variant (all-weak or all-strong).
- **Metadata/debug.** `GeneratedBoardChallenge.metadata` for an `ice` challenge gains: `rectangular_completion_used` (whether `_complete_rectangle_gaps()` actually filled anything for the returned candidate), `center_shape_removed_for_completion` (whether a center seed was dropped to let the rectangle fit), `incomplete_rectangles_detected` (whether the pre-completion analysis found gaps), `completed_rectangle_count` (how many quadrants the completion pass filled), `rectangle_shapes_used` (the non-center shape type(s) in the final candidate), `absolute_rectangular_cap_used` (whether the 48-cell cap was the one satisfied), and `final_ice_cell_count` (the returned candidate's total ice count, mirroring `ice_cell_count` for clarity in debug tooling) — alongside every existing Stage 57/57.1/57.2 field (`ice_variant`, `target_ice_count`, `weak_ice_cell_count`, `strong_ice_cell_count`, `center_ice_roll`, `center_ice_used`, `center_ice_cell_count`, `symmetric_ice_used`, `selected_ice_shape_types`/`selected_ice_patterns`, `ice_attempts_used`, `ice_fallback_used`, `ice_validation_reasons`, `layout_source`).
- **Everything else untouched.** Weak/strong variant assignment (`_assign_layers()`/`_assign_all_weak()`/`_assign_all_strong()`), the `level_number % 5` variant cycle (`IceVariant`/`IceVariantResolver`), direct/adjacent-orthogonal ice damage (`IceDamageResolver`), `BoardResolver`/`StepwiseBoardResolver` match/gravity logic, `BoardChallengeGenerator`'s archetype routing/cycle, the result flow, and the Stage 57.3 `TileView.ICE_DEBUG_VISIBILITY_ENABLED` debug overlay are all completely unchanged by this stage.
- **Roadmap.** Stage 58 remains challenge cycle integration and tuning, unchanged from Stage 57/57.1/57.2/57.3's roadmap notes.

## Stage 57.5: Cell-Anchored Ice Overlays and Per-Step Ice Sync v0.1

Stage 57.5 is implemented. It fixes two ice presentation bugs — ice visually "falling" with a tile ghost during gravity/refill, and ice visuals only catching up to the true post-clear obstacle state once the entire animated turn finished rather than after each individual clear/cascade/booster step. Ice generation (Stage 57/57.1/57.2/57.4), weak/strong variant rules (Stage 57.2), and every ice damage rule (Stage 56) are unchanged; this is a presentation/animation-synchronization patch only.

- **Why ice appeared to fall during gravity.** Ice is a `BoardModel` cell obstacle, entirely separate from tile state — `swap_tiles()`/`GravityResolver` never move it. But `BoardView.create_tile_ghost_from_data()` built `IceOverlay`/`IceOverlayInner` as *child nodes of the moving tile ghost* it returned, back in Stage 56/57.1. Since gravity/refill/swap animate that ghost's `position` property directly, any ice overlay parented under it necessarily moved along with the falling/sliding crystal, even though the real obstacle stayed at its original cell the whole time — a purely presentational bug, since `BoardModel`'s obstacle dictionaries were never actually touched by gravity.
- **Tile ghosts and obstacle overlays separated.** `create_tile_ghost_from_data(tile_type, special_data, ghost_position, ghost_size)` dropped its `obstacle_type`/`obstacle_layers` parameters entirely and no longer builds any ice-related child node — it now only ever renders tile color/icon and the special H/V/B marker, exactly matching the stage's "tile ghosts contain tile color/icon and special marker only" requirement. Every existing call site (gravity fall, refill, swap-adjacent helpers, the special-creation fallback ghost) already called it without obstacle arguments, so none needed changes beyond the shared function's simplified signature.
- **Cell-anchored obstacle overlay ghosts.** New `_create_obstacle_overlay_ghost(ghost_position, ghost_size, obstacle_type, obstacle_layers)` builds the ice visual as its own standalone node — a `ColorRect` (plus an inset `ColorRect` child for strong/double ice, matching `TileView`'s existing two-layer look) — added directly to `animation_layer` at a fixed board-cell position, with no parent/child relationship to any tile ghost. It returns `null` (creating nothing) for a non-ice obstacle or zero layers, so an active cell with no ice never gets an overlay node at all, and inactive cells are untouched (they still only ever get the existing `create_inactive_hole_ghost()` placeholder). A new `BoardView._overlay_obstacle_ghosts: Dictionary` (`Vector2i -> Control`) — deliberately a separate dictionary from `_overlay_ghosts` (the moving tile ghosts) — tracks these by board cell; `build_full_board_ghosts()` populates it once per turn, reading each snapshot cell's existing `obstacle_type`/`obstacle_layers` fields (added back in Stage 56/57.1, unchanged).
- **Gravity/refill now only moves crystals.** `_play_overlay_gravity_fall()`, `_play_overlay_refill()`, `play_gravity_fall_animation()`, and `play_refill_animation()` only ever read/write `_overlay_ghosts` — none of them reference `_overlay_obstacle_ghosts` at all — so a cell-anchored ice overlay now stays exactly where it was placed through every gravity/refill animation, with zero per-movement obstacle-specific logic required; the separation itself is what fixes the bug, not any new movement-blocking code. New `_keep_obstacle_ghost_on_top(cell)` addresses a secondary z-order wrinkle: a newly created/moved tile ghost is appended as `animation_layer`'s *last* child, which would otherwise draw over an already-existing ice overlay at its destination cell (children later in the tree draw on top of earlier ones); this helper re-raises the destination cell's obstacle ghost (if any) back to the front, and is called after a gravity-fall movement lands, after a refill ghost is placed, and after the special-creation fallback ghost is spawned.
- **Per-step ice sync using existing event data.** `IceDamageResolver`'s event dictionaries already carried `cell`/`obstacle_type`/`previous_layers`/`new_layers`/`broken` since Stage 56, so no source-data changes were needed (satisfying the stage's data-completeness check trivially). `BoardAnimationController._play_ice_event_request()` now also collects each *damaged-but-not-broken* cell's `new_layers` into a `cell -> new_layers` dictionary and passes it to `BoardView.play_ice_damage_animation(cells, new_layers_by_cell)` (previously it only passed the cell list). `TileView.play_ice_damage(new_obstacle_layers := -1)` applies that new layer count to its own `_obstacle_layers` field *inside* its flash tween's completion callback, immediately before that same callback re-renders the overlay (`_apply_ice_overlay()`) — so the existing cold-white flash plays first, using whatever color was already showing, and then the overlay settles directly into the reduced-layer look (strong blue -> weak white, or unchanged if no reduction) the instant the flash ends, rather than waiting for a later `refresh_all_tiles()` at the end of the whole turn. `play_ice_break()`'s completion callback now also directly clears `_obstacle_type`/`_obstacle_layers` (previously it only re-rendered using whatever those fields already held, which was stale until end-of-turn), so `is_iced()` correctly reports false — and the overlay stays correctly hidden — immediately once the fade finishes. `BoardView._play_overlay_ice_damage(cells, new_layers_by_cell)`/`_play_overlay_ice_break(cells)` mirror this exactly against the cell-anchored obstacle ghost instead of a `TileView`. Since every clear source (normal match, cascade, line specials, color bombs, Hammer, Rocket Barrage) already funnels its ice events through the same `TYPE_ICE_EVENT` request built from `IceDamageResolver`'s output, this fix applies uniformly to all of them with no per-source special-casing.
- **New BoardView sync API.** `sync_overlay_ice_event(event: Dictionary)` is a convenience wrapper that reads `cell`/`obstacle_type`/`new_layers`/`broken` from a raw ice event dictionary and calls `update_cell_obstacle_visual(cell, obstacle_type, layers)`, which dispatches to either the real `TileView.set_cell_obstacle()` (outside overlay mode) or `update_overlay_obstacle_ghost(cell, obstacle_type, layers)` / `remove_overlay_obstacle_ghost(cell)` (inside overlay mode) depending on whether the target layer count is still icy. `update_overlay_obstacle_ghost()` lazily creates an obstacle ghost if none exists yet for that cell (a defensive fallback — normally `build_full_board_ghosts()` already created one for any cell that started the turn iced), otherwise recolors the existing ghost's outer/inner `ColorRect`s and toggles the inner one's visibility based on the new layer count. All of these — plus the ghost-creation and flash-tween-callback paths above — resolve their colors through the existing `TileView.resolve_ice_overlay_color(layers)`/`resolve_ice_overlay_inner_color()` static helpers (Stage 57.3) rather than any new color logic, so overlay-mode ice always matches the real board's colors, including the still-active Stage 57.3 debug visibility filter, with zero duplication.
- **Final board handoff stays safe.** `clear_animation_layer()` (already called unconditionally by `exit_animation_overlay_mode()`, itself called from `apply_board_under_overlay()`'s final-handoff path) now also clears the `_overlay_obstacle_ghosts` dictionary alongside its existing `_overlay_ghosts.clear()`, so no dangling obstacle-ghost reference survives past the point where `animation_layer`'s children are all freed. `refresh_all_tiles()`, called right after, re-syncs every real `TileView`'s obstacle state from the authoritative final `BoardModel` regardless of whatever the per-step animation already showed, so the real board is always correct even if an animation step were somehow skipped or interrupted.
- **Everything else untouched.** `IcePatternGenerator`/`IceGenerationRules`/`IceShapePreset` (generation, density, rectangular cluster rules), `IceVariant`/`IceVariantResolver` (weak/strong resolution), `IceDamageResolver` (direct/adjacent-orthogonal damage, per-event dedup), `BoardResolver`/`StepwiseBoardResolver`/`BoosterResolver` match/gravity/booster logic, `BoardChallengeGenerator` archetype routing, and the result flow are all completely unchanged by this stage.
- **Roadmap.** Stage 58 remains challenge cycle integration and tuning, unchanged from prior ice-stage roadmap notes.
