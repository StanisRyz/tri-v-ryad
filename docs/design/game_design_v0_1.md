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
- Activated Hero Lanes highlight temporarily after the turn.
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

Wrapped bombs, special combos, full falling animation, cascade damage, cascade-step animation, particles, sound, final art, and real tile movement remain future work.

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
- No full cascade animations.
- No real tile movement.
- No sound or particles.

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
- Next planned stage: Stage 36, ImageSlot asset placeholder pipeline v0.1.
