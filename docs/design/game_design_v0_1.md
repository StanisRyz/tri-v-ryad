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
