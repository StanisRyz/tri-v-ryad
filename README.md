# Tri V Ryad

Tri V Ryad is a Godot 4.x match-3 battle game intended for Yandex Games and Web-first release targets.

The project is currently through Stage 37: Asset loading integration for active imageholders v0.1. Hero/RPG systems (TeamSelect, hero party UI, hero abilities/charge/lane damage, hero upgrades) remain frozen and hidden from the active flow via `FeatureFlags.HERO_SYSTEMS_ENABLED := false`, and gameplay deals direct match-3 damage to the enemy. Each battle selects one positive round modifier that multiplies damage for matched cells of specific colors, while Stage 34 direct balance controls moves and enemy HP. The active flow remains App startup -> LevelSelect -> GameScreen -> LevelSelect, with Settings opened from the LevelSelect top panel; MainMenu remains in the project as inactive legacy/future code but is skipped by normal startup and play. The app shell, a level-select hub with numbers-only labels for `level_1` through `level_100` grouped into 10 locked zones, a shared 10-enemy base roster with battle-start random enemy selection and direct-mode HP scaling, ImageSlot-backed battle background and enemy visual placeholders, the safe cached `ImageSlot`/`GameAssetCatalog` placeholder image pipeline, a persistent Settings screen, a playable 9x9 board with placeholder tiles, hybrid two-click plus drag/swipe swapping, UI-independent board and battle logic, line special tiles, color bombs, saved campaign progress with stars/unlocks, and lightweight swap, clear, special activation, and refill feedback all remain active for a vertical 9:16 game. Hero code, MainMenu, TeamSelect, and UpgradeScreen remain in the project (not deleted) for a future revisit.

## Project Direction

- Target platform: Yandex Games / Web first.
- Engine: Godot 4.x.
- Renderer: Compatibility / `gl_compatibility`.
- Main orientation: vertical 9:16 portrait.
- Base resolution: 720x1280.
- Main mechanic planned for later: Hero Lanes on a 9x9 match-3 board.

## Hero Lanes

The future battle board will be 9 columns by 9 rows. The player will bring 3 heroes into battle, and each hero will own one vertical lane group:

- Hero 1: columns 1-3.
- Hero 2: columns 4-6.
- Hero 3: columns 7-9.

Match combinations activate heroes based on the columns involved. Heroes charge abilities from matched tiles in their lanes. Victory rewards grant upgrade points that can improve hero attack and HP.

## Current Status

This stage includes:

- A Godot project with `scenes/app/App.tscn` as the main scene.
- A minimal screen router.
- An inactive legacy `MainMenuScreen` kept for future use, skipped by the active startup flow.
- A scrollable `LevelSelectScreen` hub with a Settings button, a zone selector for the 100-level campaign, numbers-only labels, lock/completion/star state, and direct routing to `GameScreen`.
- Inactive legacy `TeamSelectScreen` and `UpgradeScreen` code retained for a future hero-systems revisit.
- A persistent `SettingsScreen` route opened from LevelSelect for presentation/audio setting toggles.
- A playable battle screen with a top enemy panel, compact Level/Moves/Levels HUD row, widened 9x9 `BoardView`, placeholder `TileView` tiles, hidden inactive hero party panel, status text, result overlay, and a Levels button back to LevelSelect.
- Reusable UI components: `BattleHud`, `EnemyPanel`, `HeroPartyPanel`, `HeroCard`, `BattleResultOverlay`, and `ImageSlot`.
- `GameAssetCatalog` maps reserved image asset keys to future `res://assets/images/` paths and loads optional textures safely with a small cache for loaded and missing textures.
- `AssetKeyResolver` maps background IDs, enemy IDs, and tile types to `GameAssetCatalog` asset keys without scattering string literals through UI code.
- `GameScreen` uses an `ImageSlot` for the active battle background, applying the selected background asset key and placeholder color.
- `EnemyPanel` uses an `ImageSlot` for the active enemy visual, resolving the selected enemy ID to a reserved enemy asset key.
- Empty asset folders under `assets/images/backgrounds/`, `assets/images/enemies/`, `assets/images/tiles/`, `assets/images/ui/`, and `assets/images/heroes/` for later real images.
- A lightweight `LayoutManager` for UI-only portrait and landscape layout decisions.
- UI-independent board generation, match detection, swap validation, gravity/refill, and cascade resolution under `scripts/game/board/`.
- Special tile board logic under `scripts/game/board/`: `SpecialTileType`, `SpecialTileData`, and `SpecialTileResolver`.
- `BoardModel` keeps base tile type storage as the match color/type and stores special tile metadata in a separate layer.
- Match 4 creates a line special tile at a deterministic match cell.
- Match 5+ creates a color bomb at a deterministic match cell.
- Horizontal match 4 creates a horizontal line special, and vertical match 4 creates a vertical line special.
- Activated horizontal line specials clear their row; activated vertical line specials clear their column.
- Activated color bombs clear all cells of their selected/base tile type.
- Special metadata moves with tiles during swaps and gravity, and refilled tiles have no special metadata.
- Special tiles affect board clearing only; special-cleared cells do not add extra battle damage or ability charge yet.
- `TileView` shows simple placeholder `H`/`V`/`B` markers for special tiles.
- UI-independent battle logic under `scripts/game/battle/`: heroes, enemy, battle state, Hero Lane activation, damage, ability charge, enemy intent/action, and turn results.
- Data-driven configs under `scripts/game/config/`: `HeroConfig`, `EnemyConfig`, `EnemyCatalog`, `EnemySelectionResolver`, `EnemyScalingResolver`, `LevelConfig`, `LevelLabelFormatter`, and `LevelCatalog`.
- `EnemyCatalog` contains the shared 10-enemy roster, using the existing enemy IDs, display names, and base stats.
- `EnemySelectionResolver` selects an enemy from that roster when a battle starts and supports deterministic tests through seeded `RandomNumberGenerator` injection.
- `EnemyScalingResolver` applies soft linear level multipliers to selected enemies at battle start, after enemy selection and before `BattleFactory` creates `BattleState`.
- Enemy scaling changes only battle-time `max_hp` and `attack`; enemy identity, display name, intent turns, and target lane are preserved, and `EnemyCatalog` base stats are not mutated.
- `LevelCatalog` deterministically generates a 100-level campaign foundation with numbers-only display names and `level_1` through `level_100` IDs.
- Level rewards remain in config for compatibility; active direct-mode UI focuses on saved progress and stars while hero upgrades are frozen.
- `LevelConfig.enemy_config` remains compatibility fallback/default data; runtime battle starts use the shared roster selection.
- Hero roster definitions under `scripts/game/config/` with `HeroCatalog`.
- `HeroConfig` carries immutable base hero stats plus `ability_id`.
- `BattleFactory` creates battle state from level configs, optional enemy overrides, or the saved selected team when `PlayerProgress` and `HeroCatalog` are available.
- Selected team order maps to Hero Lanes: slot 1 to lane 0, slot 2 to lane 1, and slot 3 to lane 2.
- Local progression under `scripts/game/progression/`: `PlayerProgress`, `HeroUpgradeState`, `UpgradeEconomyConfig`, `UpgradeResolver`, and `ProgressManager`.
- Saved team selection under `scripts/game/progression/` with `TeamSelectionState` and `TeamSelectionResolver`.
- `PlayerProgress` stores selected team IDs, and `ProgressManager` is the boundary for reading, validating, saving, and normalizing selected team data.
- Saved level progress under `scripts/game/progression/`: `LevelProgressState` and `LevelCompletionResolver`.
- Local save handling under `scripts/game/save/` with `SaveManager`.
- Progress, completion, stars, and hero upgrades are saved locally to `user://save_v1.json`.
- Selected team data is saved locally to `user://save_v1.json`.
- Missing, incomplete, duplicated, or unknown saved team data falls back to the default team: `hero_1`, `hero_2`, `hero_3`.
- Victory grants `LevelConfig.reward_upgrade_points` from a deterministic linear reward curve, and rewards can be earned repeatedly in v0.1.
- Victory saves level completion and stars based on remaining moves.
- Best stars and best remaining moves are preserved across replays.
- Sequential unlocks open each next level after the previous level is completed.
- `LevelSelectScreen` groups the 100-level campaign into 10 zones of 10 levels, shows only the selected unlocked zone, and derives zone availability from existing level completion data.
- Zone 1 is available from the start, Zone 2 unlocks after Level 10 completion, Zone 3 unlocks after Level 20 completion, and Zone 10 unlocks after Level 90 completion.
- No separate zone save data or zone completion records are stored.
- `LevelSelectScreen` shows numbers-only level labels plus locked, open, completed, and star state for visible zone levels.
- Upgrade points and hero upgrades remain saved/implemented for inactive hero systems, but they are not part of the active direct flow.
- `UpgradeScreen` now acts as the full roster character upgrade screen.
- `UpgradeScreen` shows all 5 `HeroCatalog` heroes, current upgrade points, ability IDs, attack/HP levels, current attack/HP, next attack/HP previews, linear upgrade costs, max-level/not-enough-points state, and +Attack/+HP buttons.
- +Attack/+HP purchases go through `ProgressManager` and `UpgradeResolver`.
- Old saves without `hero_4` or `hero_5` upgrade records are handled safely and create those records when displayed or upgraded.
- The victory overlay only shows reward/stars and links to Heroes; it does not contain upgrade spending UI.
- `BattleFactory` combines base `HeroConfig` data with mutable `PlayerProgress` when creating battle heroes.
- A `BattlePresenter` that coordinates the prototype battle and selects enemies from `EnemyCatalog` without platform, save, ad, or SDK code.
- `BattlePresenter.start_level(level_id)` starts selected levels, and Restart preserves the current level.
- Five roster strike abilities: Warrior Strike, Guardian Strike, Healer Strike, Mage Strike, and Ranger Strike.
- Roster heroes use damage-only `ability_id` mappings: `warrior_strike`, `guardian_strike`, `healer_strike`, `mage_strike`, and `ranger_strike`.
- Ability readiness in `HeroCard`, with ability requests routed through `BattlePresenter`.
- Ability feedback for accepted damage and rejected requests.
- Ability use does not consume moves or tick enemy intent.
- Hero abilities do not heal heroes and do not modify, clear, or highlight board cells.
- Hybrid tile swapping through `BoardInputController`: two-click fallback, mouse drag, and touch/swipe style input.
- `BoardMotionAnimator` coordinates view-only board motion feedback without changing board, battle, progression, or save rules.
- Lightweight `TileView` animation helpers for swap pulses, invalid pulses, match fade, refill appear, and visual reset.
- `BoardView` exposes presentation-only animation helpers over existing tile views.
- Valid swaps get a short visual pulse/flash on the swapped cells.
- Invalid swaps get brief rejection feedback on the involved cells.
- Matched cells highlight and fade before board refresh/refill feedback.
- Board refresh/refill gets lightweight appear feedback; this is not full falling animation.
- Input locking during turn feedback and after victory/defeat remains tied to `feedback_finished`.
- Swapped cell feedback, invalid swap feedback, match highlights, refill feedback, temporary Hero Lane highlights, and short damage/enemy action status messages.
- The portrait battle board is scaled to match the hero party panel width, and permanent Hero Lane separator/debug grid visuals are removed from the normal board state.
- Live enemy, HUD, and hero updates.
- Basic victory/defeat overlay with restart flow.
- Headless board core tests in `scripts/tests/board_core_test.gd`.
- Headless battle core tests in `scripts/tests/battle_core_test.gd`.
- Playable battle smoke test in `scripts/tests/playable_battle_smoke_test.gd`.
- Board input controller tests in `scripts/tests/board_input_controller_test.gd`.
- Turn presentation data tests in `scripts/tests/turn_presentation_data_test.gd`.
- Ability core tests in `scripts/tests/ability_core_test.gd`.
- Ability presentation data tests in `scripts/tests/ability_presentation_data_test.gd`.
- Level config tests in `scripts/tests/level_config_test.gd`.
- Balance curve tests in `scripts/tests/balance_curve_test.gd`.
- Battle factory tests in `scripts/tests/battle_factory_test.gd`.
- Enemy catalog tests in `scripts/tests/enemy_catalog_test.gd`.
- Enemy selection tests in `scripts/tests/enemy_selection_test.gd`.
- Enemy scaling tests in `scripts/tests/enemy_scaling_test.gd`.
- Upgrade economy tests in `scripts/tests/upgrade_economy_test.gd`.
- Reward curve tests in `scripts/tests/reward_curve_test.gd`.
- Upgrade screen data tests in `scripts/tests/upgrade_screen_data_test.gd`.
- Progression tests in `scripts/tests/progression_test.gd`.
- Save manager tests in `scripts/tests/save_manager_test.gd`.
- Battle factory progress tests in `scripts/tests/battle_factory_progress_test.gd`.
- Level completion tests in `scripts/tests/level_completion_test.gd`.
- Level zone helper tests in `scripts/tests/level_zone_helper_test.gd`.
- LevelSelect zone UI tests in `scripts/tests/level_select_zones_test.gd`.
- Special tile tests in `scripts/tests/special_tile_test.gd`.
- Documentation for future implementation rules.

This stage excludes:

- Wrapped bombs, special + special combos, special battle damage, cascade damage, full cascade-step animation, full falling animation, real tile movement, particles, sound, and final art.
- Target selection, cooldowns, ability upgrades, gacha, rarity, hero unlocks, hero shards, hero inventory, portraits, final art, drag-and-drop team UI, and complex ability additions.
- One-time rewards, stars-based rewards, level map, chapters, complex economy, reset upgrades, and complex objectives.
- New heroes, hero unlocks, gacha, rarity, shards, ability upgrades, TeamSelectScreen rework, Yandex SDK, cloud save, ads, payments, sound, particles, and final art.
- Cloud saves, ads, payments, Yandex SDK, RuStore, Android-specific code, and monetization.
- Battle backgrounds, enemy presentation polish, battle feedback polish, and full LevelSelect UX polish.

## Stage 16: Balance and Content Expansion v0.1

Stage 16 is complete. The project now has a 10-level early campaign slice using the existing defeat-the-enemy objective, enemy HP/attack fields, move limits, and repeatable `reward_upgrade_points`.

The curve is intentionally simple: levels 1-2 are forgiving intro fights, levels 3-4 are light challenge, levels 5-6 begin to reward upgrades, levels 7-9 are noticeably harder, and level 10 is an early mini-boss. Balance is v0.1 and expected to change after playtesting.

No new mechanics were introduced in Stage 16. Yandex SDK, cloud save, ads, payments, monetization, final art, sound, and particles remain out of scope. Stage 18 is now complete.

## Stage 17: Unified Damage Abilities v0.2

Stage 17 is complete. All hero abilities now deal damage to the enemy using `hero attack * ability damage_multiplier`.

Healing hero abilities and board-clearing hero abilities were removed. Ability use still does not consume moves, does not advance enemy intent, and does not modify the board. All battle objectives remain defeat-the-enemy.

No new heroes, objectives, target selection, cooldowns, ability upgrades, SDK, cloud save, ads, payments, final art, sound, or particles were added.

## Stage 18: Special Tiles v0.2

Stage 18 is complete. Match 4 still creates line special tiles, while match 5+ now creates color bombs.

Color bombs clear all tiles of the activated bomb cell's selected/base tile type. Special tiles remain board-only effects: special-cleared cells do not add extra battle damage or ability charge, and no special + special combos, wrapped bombs, particles, sound, final art, Yandex SDK, cloud save, ads, or payments were added.

## Stage 19: Menu and Battle Flow Restructure v0.1

Stage 19 is complete. The main navigation flow is now:

- MainMenu -> Play -> LevelSelect -> TeamSelect -> GameScreen
- MainMenu -> Heroes -> UpgradeScreen

MainMenu now has Play and Heroes buttons. Heroes opens UpgradeScreen directly from the main menu, and Back from UpgradeScreen returns to MainMenu. Play opens LevelSelect, which is now only responsible for showing levels and their locked/open/completed/star state; the Team and Heroes buttons were removed from LevelSelect. Selecting an unlocked level now routes to TeamSelectScreen instead of opening GameScreen directly.

TeamSelectScreen is now the pre-battle team confirmation screen: it receives a `level_id` via `set_level_id()`, shows the currently saved team, and lets the player change selected heroes. Its Save button was renamed to Start Battle and is disabled unless exactly 3 unique heroes are selected and a level_id is set. Pressing Start Battle saves the team through `ProgressManager.set_selected_team_ids()` and, only on success, emits `start_battle_pressed(level_id)`, which App.gd routes to GameScreen with that level_id. TeamSelectScreen never creates BattleState, opens GameScreen directly, or touches save files itself.

No battle, board, progression, save, hero upgrade, or special tile systems were changed in Stage 19.

## Stage 20: UI/UX Polish and Settings v0.1

Stage 20 is complete. MainMenu now has three entry points: Play, Heroes, and Settings.

`SettingsScreen` is a new screen reachable from MainMenu. It exposes toggles for Animations, Reduced Motion, Debug Labels, Music, and Sound Effects, and a Back button that returns to MainMenu. Settings are read from and written through `SettingsManager`.

`PlayerSettings` and `SettingsManager` under `scripts/game/settings/` persist settings separately from player progress, in `user://settings_v1.json`. This is a completely separate file from `user://save_v1.json`; loading, saving, or resetting settings never touches `PlayerProgress` or the save file. Missing or corrupted settings files fall back safely to defaults. `SettingsManager.reset_settings_to_defaults()` resets settings only and never resets player progress.

Animations and Reduced Motion settings are applied presentation-only: `TileView`, `BoardMotionAnimator`, `TurnFeedbackPresenter`, and `AbilityFeedbackPresenter` read these settings (wired through `GameScreen.set_settings_manager()`) to use minimal delays when animations are disabled and softer scale/color pulses when reduced motion is enabled. Input unlock timing and `feedback_finished` behavior are unchanged.

Debug Labels, when enabled, show `level_id` in `LevelSelectScreen`, `hero_id` in `TeamSelectScreen` and `UpgradeScreen`, and `hero_id` in battle `HeroCard`s. When disabled (the default), only clean player-facing names are shown.

Music and Sound Effects toggles are persisted and reflected in the UI. No audio assets were added in this stage; `SettingsManager` mutes/unmutes the `Music`/`SFX` audio buses by name when those buses exist, and is a safe no-op otherwise.

**Reset Progress was intentionally not added.** There is no Reset Progress button, API, or settings action that deletes, clears, or migrates player progress.

No gameplay, board, battle, progression, save-progress-format, hero, level, or special tile rules were changed in this stage. Yandex SDK, cloud save, ads, payments, final art, audio assets, and particles remain out of scope.

## Stage 21: Battle Screen Layout v0.2

Stage 21 is complete. The portrait battle board is scaled wider so its left and right edges visually align with the hero party panel. The board remains square and inside the 720x1280 safe-margin content width.

Permanent Hero Lane separator lines and always-on lane background/debug fills were removed from the normal board state. Hero Lane activation feedback remains temporary and presentation-only.

Hero Lane gameplay rules remain unchanged: columns 0-2, 3-5, and 6-8 still map to lanes 0, 1, and 2 through the existing battle logic. No gameplay, progression, enemy, level, save, settings, platform, audio, art, monetization, ability, board matching, or special tile rules were changed.

## Stage 22: Battle HUD Restructure v0.2

Stage 22 is complete. `EnemyPanel` is now the top battle screen element, with the compact Level / Moves / Menu row placed directly below it.

The battle HUD now displays compact `Level N` text such as `Level 1` and `Level 10` without changing `LevelCatalog` or level identity data. Stage 21 board scaling was preserved: the portrait board remains square and visually aligned with the hero party panel.

No gameplay, progression, enemy, level catalog, save, settings, platform, audio, art, monetization, ability, board matching, or special tile rules were changed.

## Stage 23: Level Identity Cleanup v0.2

Stage 23 is complete. Player-facing level labels are now numbers-only: `Level 1`, `Level 2`, and so on through the current 10-level campaign.

Location-style level names were removed from `LevelCatalog` display names and level UI. At Stage 23, `level_id` values remained unchanged as `level_1` through `level_10`, and the campaign still had exactly 10 levels.

Enemy configs, rewards, balance, progression, battle UI layout, board layout, save format, settings, platform, audio, art, monetization, abilities, and special tile rules were not changed during Stage 23. Random enemy selection was handled later in Stage 24, and the 100-level campaign foundation was handled later in Stage 25.

## Stage 24: Enemy Roster and Random Enemy Selection v0.1

Stage 24 is complete. `EnemyCatalog` now defines the shared 10-enemy roster using the existing enemy IDs, display names, and base stats.

`EnemySelectionResolver` selects an enemy from the roster when a battle starts. Selection is deterministic and testable when a seeded `RandomNumberGenerator` is injected, while runtime battles use the presenter's RNG. `BattleFactory` now accepts an optional enemy override and otherwise falls back to `LevelConfig.enemy_config`.

Level IDs, `Level N` labels, moves, rewards, progression, saves, battle rules, board rules, abilities, special tiles, settings, and UI layout were not changed.

## Stage 25: 100-Level Campaign Foundation v0.1

Stage 25 is complete. `LevelCatalog` now generates 100 levels deterministically instead of manually listing the earlier 10-level slice.

Level IDs remain in the existing style: `level_1` through `level_100`. Player-facing labels remain numbers-only: `Level 1` through `Level 100`. `level_101` is not part of the catalog.

Moves use a safe placeholder curve: levels 1-10 use 24 to 22 moves, levels 11-30 use 23 to 21 moves, levels 31-60 use 22 to 20 moves, and levels 61-100 use 21 to 19 moves. Repeatable `reward_upgrade_points` use a simple placeholder curve from 1 to 5 points across the campaign.

Runtime enemy selection still uses `EnemyCatalog` and `EnemySelectionResolver` from Stage 24. `LevelConfig.enemy_config` remains fallback/default data for compatibility and cycles through the existing roster; enemy scaling, enemy level multipliers, new enemies, and final economy balance were not added.

No gameplay, board, battle, save, settings, hero, ability, special tile, platform, art, audio, or monetization systems were changed. Full LevelSelect UX polish remains future work.

## Stage 26: Linear Enemy Scaling and Level Multipliers v0.1

Stage 26 is complete. Enemies now scale linearly by level number at battle start.

`EnemyCatalog` remains the source of base roster stats. `BattlePresenter` selects a base enemy through `EnemySelectionResolver`, scales that selected enemy through `EnemyScalingResolver`, and passes the scaled config to `BattleFactory.create_state()`.

Only enemy `max_hp` and `attack` are scaled. Enemy ID, display name, intent turns, and target lane are preserved. Scaling uses readable linear formulas only: no exponentials, powers, or hard difficulty spikes. Every 10th level receives a small wall-level bonus that remains soft and deterministic.

Hero economy, rewards, upgrade costs, LevelSelect zones, backgrounds, battle feedback polish, saves, board rules, hero abilities, special tiles, platform SDK, cloud save, ads, payments, sound, particles, and final art were not changed. Stage 25's 100-level campaign structure remains unchanged.

## Stage 27: Linear Rewards and Hero Upgrade Economy v0.2

Stage 27 is complete. Hero upgrade costs, hero attack growth, hero HP growth, and 100-level rewards now use readable linear formulas from `UpgradeEconomyConfig`.

Attack upgrades cost `1 + attack_level * 1`; HP upgrades cost `1 + hp_level * 1`. Attack grows as `base_attack + attack_level * 2`; max HP grows as `base_max_hp + hp_level * 10`. Attack and HP upgrade levels are capped at 20.

Level rewards use `1 + floor((level_number - 1) / 8) + floor(level_number / 10)`, clamped to a safe max of 23. Every 10th level therefore gives a mild extra wall reward without adding new reward types.

`UpgradeScreen` now displays cost/status text for each stat and disables upgrades when the player lacks points or the stat is at max level. Stage 26 enemy scaling was not changed. No new gameplay systems, enemies, levels, currencies, gacha, equipment, abilities, special tiles, platform SDK, cloud save, ads, payments, final art, audio assets, or particles were added. Economy balance is v0.2 and expected to change after playtesting.

## Stage 28: LevelSelect Locked Zones for 100 Levels v0.2

Stage 28 is complete. `LevelSelectScreen` now groups the 100-level campaign into 10 zones of 10 levels each.

Zone 1 is available from the start. Zone 2 unlocks after Level 10 is completed, Zone 3 unlocks after Level 20 is completed, and Zone 10 unlocks after Level 90 is completed. The screen defaults to the highest unlocked zone, lets the player switch among unlocked zones, and builds buttons only for the selected zone.

Zone state is derived from existing level completion/progression data. No separate zone save data, zone completion records, progression rewards, reward curve changes, upgrade economy changes, enemy scaling changes, battle rule changes, board rule changes, save changes, settings changes, platform integration, art, audio, or monetization systems were added.

## Stage 29: Battle Backgrounds and Enemy Scene Presentation v0.1

Stage 29 is complete. `BattleBackgroundCatalog` defines 5 placeholder background slots (`background_1`-`background_5`), each with a display name and a placeholder color; `BattleBackgroundSelectionResolver` selects one background at battle start using the same deterministic seeded-RNG style as `EnemySelectionResolver`.

Each battle now has independent random enemy selection (Stage 24) and random background selection (Stage 29) — the two are unrelated and neither affects the other's outcome. `BattlePresenter.start_level()` selects both and emits `battle_background_changed`. `GameScreen` listens for this signal and applies the placeholder color to a background layer behind `BattleRoot`; the layer ignores mouse input and stays behind `BattleResultOverlay`. A `TextureRect` is wired up for future real background art but stays hidden until a `texture_path` resource actually exists.

`EnemyPanel` presentation was improved: it now shows a placeholder avatar area, an HP bar alongside the existing HP text, the enemy's attack value, "attacks in N turns" intent text, and a target lane label (Left/Center/Right/Unknown).

No gameplay, battle rules, board rules, rewards, upgrade economy, enemy scaling, progression, saves, settings, LevelSelect zones, hero abilities, special tiles, platform systems, final art, audio, or monetization systems were changed. Backgrounds are placeholders only; final background images will be added in a later stage.

## Stage 30: Battle Readability and Feedback Polish v0.1

Stage 30 is complete. `BattleMessageFormatter` centralizes all player-facing battle text in one place, keeping `TurnFeedbackPresenter`, `AbilityFeedbackPresenter`, and `GameScreen` free of ad-hoc string building.

Turn damage messages are clearer ("Hero 1 dealt 12 damage", "2 heroes attacked for 46 total damage", "No damage dealt"), hero lane activations announce a short readable message ("Left lane activated", "2 lanes activated") while keeping the existing temporary lane highlight and without restoring permanent lane separator visuals, special tile activation gets readable feedback ("Line special activated", "Color bomb activated", or a cleared-tile count) with a safe generic fallback when the exact type is unavailable, and enemy action messages read as full sentences ("Enemy attacked Hero 2 for 18 damage").

Invalid swap and invalid input messages are friendlier ("Swap must create a match", "Choose a neighboring tile", "Swipe a little farther", "Stay inside the board", "Wait until the turn finishes"). Ability feedback messages are clearer for both accepted ("Warrior Strike activated", "Warrior Strike dealt 30 damage") and rejected ("Ability is not ready yet", "This hero is down", "Battle is already over") cases. `GameScreen` status text for selecting tiles, resolving turns, using abilities, and the victory/defeat outcome is more player-facing, and the battle result overlay's reward/star display is unchanged.

Presentation settings continue to be respected: `animations_enabled` and `reduced_motion_enabled` still control feedback timing and motion, and `debug_labels_enabled` only adds hero/ability IDs to messages when explicitly turned on; with it off, all messages stay plain player-facing text.

No damage formulas, board rules, enemy scaling, rewards, upgrade economy, level progression, saves, settings, LevelSelect zones, battle backgrounds, hero abilities, special tile rules, platform systems, final art, audio, or monetization systems were changed. The Stage 26-30 block is now complete; the next roadmap block will be planned separately.

## Stage 31: Hero Portrait Buttons and Ability Bars v0.1

Stage 31 is complete. `HeroCard` (`scenes/ui/HeroCard.tscn`, `scripts/ui/hero_card.gd`) was redesigned as a square portrait-style battle control instead of a text-heavy stat card: each card now centers on a square portrait placeholder, with a red HP bar and a blue Charge bar stacked underneath it. Hero name text and Columns/lane text were removed from battle hero cards, and the separate Charge/Ability button was removed entirely.

The hero portrait itself is now the ability button: pressing it emits `HeroCard.ability_pressed(lane_index)`, which `HeroPartyPanel` forwards as `ability_requested(lane_index)` to `GameScreen` exactly as before. Pressing a portrait always routes through the ability request flow when a hero occupies that slot, whether or not the ability is ready or the hero is alive, so existing "Ability is not ready yet" / "This hero is down" feedback from `AbilityFeedbackPresenter` still plays; only an empty slot (no hero assigned) disables the press.

When a hero's charge is full, the portrait shows a bright gold ready-highlight border (a subtle scale pulse plays when `animations_enabled` is true and `reduced_motion_enabled` is false; the highlight border alone is shown otherwise). Defeated/down heroes show a dimmed overlay over the portrait and an empty HP bar; ability presses on a down hero still route through and are safely rejected by existing ability rules. `debug_labels_enabled` optionally shows a tiny hero-id label on the portrait; with it off, no hero id or lane text is shown anywhere on the card.

Real hero portrait art and the shared `ImageSlot` asset pipeline are not part of this stage; a safe placeholder square is used instead. No battle rules, ability rules, charge formulas, damage formulas, enemy scaling, rewards, upgrade economy, progression, saves, LevelSelect zones, TeamSelect layout, platform systems, art assets, audio, or monetization systems were changed.

## Stage 32: Hero Systems Freeze and Direct Match Damage Foundation v0.1

Stage 32 is complete. Hero/RPG systems are frozen and the active gameplay flow now uses direct match-3 damage: clearing crystals damages the enemy directly, at 1 damage per uniquely cleared cell. Hero code was not deleted — it is only hidden/gated from the active flow so it can be revisited later.

`FeatureFlags` (`scripts/game/config/feature_flags.gd`) is the single switch for this direction: `HERO_SYSTEMS_ENABLED := false` and `DIRECT_MATCH_DAMAGE_ENABLED := true`. Navigation changed so `LevelSelectScreen` opens `GameScreen` directly (`App._on_level_selected`); `TeamSelectScreen` and its `start_battle_pressed` signal remain in the project for a future hero-systems revisit but are not used by the active Play path. `MainMenuScreen`'s Heroes button and `BattleResultOverlay`'s upgrades button are hidden while hero systems are disabled, so `UpgradeScreen` is not reachable from normal play (the screen and hero upgrade code still exist).

`GameScreen` hides `HeroPartyPanel` in direct mode and does not connect its `ability_requested` signal, so no hero ability UI or input is active; `VBoxContainer` layout naturally closes the gap since hidden controls are skipped for sizing.

`DirectMatchDamageResolver` (`scripts/game/battle/direct_match_damage_resolver.gd`) counts unique cleared cells (matches, cascades, and special-tile clears via `BoardResolveResult.total_cleared`) and returns that count as damage — 1 cleared crystal = 1 damage, with no color multipliers yet. `BattleResolver` branches on `FeatureFlags.HERO_SYSTEMS_ENABLED`: the frozen hero path (Hero Lane damage, ability charge, enemy attacks against heroes) runs unchanged when the flag is true, while the new direct-damage path runs when it is false and skips `EnemyActionResolver` entirely, so enemies never attack in direct mode. `BattleState.update_status()` only treats "no alive heroes" as a defeat condition when hero systems are enabled, so direct-mode battles never depend on hero data existing. Enemy HP, enemy scaling, 100 levels, LevelSelect zones, moves, stars, victory/defeat, progression, battle backgrounds, and enemy presentation are all unchanged and remain fully active.

`BattleMessageFormatter.format_direct_damage_message` and `format_enemy_defeated_message` provide direct-mode battle text ("Matched 3 tiles: 3 damage", "Special cleared 9 tiles: 9 damage", "No damage dealt", "Enemy defeated!"), used by `TurnFeedbackPresenter` instead of the old hero/lane/ability messages when hero systems are disabled.

No color damage multipliers, round modifiers, buff/debuff UI, player HP, enemy attacks against the player, new levels, new enemies, or new mechanics were added, and no hero, upgrade, or TeamSelect files were deleted. Next planned stage: Stage 33, Round modifiers and color damage rules v0.1.

## Stage 33: Round Modifiers and Color Damage Rules v0.1

Stage 33 is complete. Each battle now selects one `RoundModifierConfig` at battle start through `RoundModifierCatalog` and `RoundModifierSelectionResolver` (`scripts/game/config/`), mirroring the deterministic seeded-RNG style already used by `EnemySelectionResolver` and `BattleBackgroundSelectionResolver`. Modifiers are positive buffs only in this stage: `red_x3`, `blue_x3`, `green_x3`, `yellow_x3`, and `purple_x3` triple one color's damage while every other color stays at the default x1 multiplier, and `all_x2` doubles every color. `BattlePresenter.start_level()` selects a round modifier independently of enemy and background selection and emits `round_modifier_changed(modifier)`.

`DirectMatchDamageResolver` now applies the selected modifier's color multiplier per uniquely cleared tile, using each match's `tile_type` (including per-step cascade matches from `BoardResolveResult`); special-tile activation clears without a known color still fall back to x1 damage, and passing no modifier keeps the exact Stage 32 behavior (1 cleared crystal = 1 damage). `BattleResolver.resolve_player_matches()` takes an optional `round_modifier` argument that only affects the direct-damage path; the frozen hero path ignores it.

`GameScreen` shows a `RoundModifierPanel` (`ModifierNameLabel` + `ModifierDescriptionLabel`) with the active modifier's name and a short description (e.g. "Red crystals deal x3 damage"); the panel does not block board input. Direct-mode battle feedback text now includes a color-specific message for single buffed-color matches ("Matched 3 red tiles x3: 9 damage") alongside the existing generic messages. Stage 32 leftover text was cleaned up: the defeat message no longer references "upgrade heroes" and the victory overlay's reward text no longer says "upgrade points" while hero systems are frozen.

Hero/RPG systems remain fully frozen (unchanged from Stage 32): TeamSelect, the Heroes/UpgradeScreen flow, `HeroPartyPanel`, hero abilities, hero charge, hero lane damage, and hero upgrades stay inactive in normal gameplay and have no effect on direct match damage. No debuffs, negative modifiers, player HP, enemy attacks against the player, new enemies, or new levels were added. Next planned stage: Stage 34, Direct match-3 balance pass v0.1.

## Stage 34: Direct Match-3 Balance Pass v0.1

Stage 34 is complete. This is a balance/configuration-only pass that re-tunes enemy HP, moves, and the round modifier random pool for the simplified direct match-3 loop introduced in Stage 32/33 — no new gameplay systems were added.

`DirectBalanceConfig` (`scripts/game/config/direct_balance_config.gd`) is a new static config that centralizes direct-mode balance numbers instead of scattering magic numbers across `LevelCatalog`, `EnemyScalingResolver`, and tests: `get_moves_for_level(level_number)`, `get_enemy_hp_for_level(base_hp, level_number)`, `get_required_damage_per_move(enemy_hp, moves)`, `get_expected_damage_per_move(level_number)`, `get_balance_checkpoint_levels()` (`[1, 5, 10, 20, 30, 50, 75, 100]`), and `is_wall_level(level_number)`. All formulas are linear/stepwise (no `pow()`/`exp()`).

`EnemyScalingResolver.scale_enemy()` now branches on `FeatureFlags.HERO_SYSTEMS_ENABLED`: when it is false (the default), enemy HP comes from `DirectBalanceConfig.get_enemy_hp_for_level()` — a linear HP target (`40 + 0.6 * (level - 1)`) nudged by each enemy's base HP (clamped to ±15% so level stays the dominant difficulty driver) — and attack is left at the enemy's base value, since enemy actions are neutralized in direct mode. The old hero-mode multiplier curve (`get_hp_multiplier`/`get_attack_multiplier`/`get_wall_level_bonus`) is preserved unchanged for a future hero-mode revisit. `EnemyCatalog` base stats are never mutated.

`LevelCatalog._get_moves_for_level()` now delegates to `DirectBalanceConfig.get_moves_for_level()` (same stepwise curve as before, 24 moves down to a floor of 19 across the 100 levels) instead of holding its own copy of the formula.

`RoundModifierCatalog.get_random_pool_modifiers()` is new: normal random battles now pick only from the 5 single-color surges (`red_x3`, `blue_x3`, `green_x3`, `yellow_x3`, `purple_x3`), making the modifier choice a color-focused strategic pick. `all_x2` is excluded from this random pool but remains fully valid and reachable via `get_default_modifier()` and direct `get_modifier("all_x2")` lookup — it is the default/fallback only. `RoundModifierSelectionResolver` now selects from `get_random_pool_modifiers()` when the catalog provides it, falling back to `get_all_modifiers()` for older catalog shapes, and still falls back to `all_x2` when no valid modifier is found.

Balance checkpoint summary (required damage/move stays below expected damage/move at every checkpoint, so all are clearable with reasonable boosted-color play): level 1 (24 moves, ~40 HP, ~1.7 required vs 4.0 expected — very forgiving), level 10 (22 moves, ~45 HP, ~2.1 vs 4.0), level 20 (22 moves, ~51 HP, ~2.3 vs 4.2), level 30 (21 moves, ~57 HP, ~2.7 vs 4.4), level 50 (21 moves, ~69 HP, ~3.3 vs 4.8), level 75 (20 moves, ~84 HP, ~4.2 vs 5.4), level 100 (19 moves, ~99 HP, ~5.2 vs 5.8 — harder but still plausible). Wall levels (multiples of 10) introduce no extra HP spike beyond the smooth linear curve.

Hero/RPG systems remain fully frozen (unchanged from Stage 32/33): `TeamSelect`, the Heroes/UpgradeScreen flow, `HeroPartyPanel`, hero abilities, hero charge, hero lane damage, and hero upgrades stay inactive in normal gameplay. Direct match damage and Stage 33's color multipliers remain fully active and unaffected. Progression, stars, and locked-zone unlocks (Zone 2 after Level 10, Zone 3 after Level 20) are unchanged since star thresholds are relative to each level's own move count. Balance is intentionally v0.1 and expected to be re-tuned after playtesting. No debuffs, player HP, enemy attacks against the player, new enemies, new levels, asset pipeline, audio, platform SDK, ads, or payments were added.

## Stage 35: Direct LevelSelect Startup and Simplified UX Polish v0.1

Stage 35 is complete. The app now starts directly on `LevelSelectScreen`; `MainMenuScreen` is skipped/inactive in the active flow and retained only as legacy/future code.

Active navigation is now: App startup -> LevelSelect -> GameScreen -> LevelSelect, and LevelSelect -> Settings -> LevelSelect. The LevelSelect top panel has a Settings button, Settings Back returns to LevelSelect, and the GameScreen/ResultOverlay Levels button returns to LevelSelect. LevelSelect still opens GameScreen directly when an unlocked level is selected.

TeamSelect, Heroes/Upgrade flow, `HeroPartyPanel`, hero abilities, hero charge, hero lane damage, and hero upgrades remain inactive. Direct match damage, round modifiers, Stage 34 balance, enemies, levels, moves, stars, progression, locked zones, enemy scaling, backgrounds, and enemy presentation remain active. No new gameplay systems, debuffs, player HP, enemy attacks, enemies, levels, asset pipeline, audio, platform SDK, ads, payments, final art, sound/music assets, particles, or Reset Progress were added.

## Stage 36: ImageSlot Asset Placeholder Pipeline v0.1

Stage 36 is complete. `ImageSlot` (`scripts/ui/image_slot.gd`) is a reusable Control-based image holder that can load a texture through an asset key or accept a `Texture2D` directly. When the key is empty, unknown, or points to a missing file, it clears the texture and shows a configured placeholder color instead of crashing.

`GameAssetCatalog` (`scripts/game/config/game_asset_catalog.gd`) is the central registry for reserved image asset keys and future paths. It covers 5 battle backgrounds, 10 enemies, 5 tiles, 5 UI panel assets, and 5 future/frozen hero portraits. It checks `ResourceLoader.exists()` before loading optional files, returns `null` for missing or non-texture resources, and does not preload missing assets.

Empty asset folders were added under `assets/images/` with `.gitkeep` files only. No real image assets were added. In Stage 36, `ImageSlot` was not mass-integrated into active UI yet; GameScreen backgrounds, EnemyPanel avatar, TileView, LevelSelect panels, BattleResultOverlay, and RoundModifierPanel still used their current placeholder paths.

Active gameplay remained unchanged in Stage 36: LevelSelect startup, Settings from LevelSelect, GameScreen Menu/Back to LevelSelect, direct match damage, round modifiers, Stage 34 balance, progression, stars, zones, enemies, and battle flow all remained active. Hero/RPG systems remained frozen and inactive.

## Stage 37: Asset Loading Integration for Active Imageholders v0.1

Stage 37 is complete. `GameAssetCatalog` now supports cached safe texture loading through `try_load_texture_cached(asset_key)` plus `clear_texture_cache()` for tests. Unknown keys, missing files, and non-texture resources still return `null` safely, and missing keys/paths are cached so optional files are not rechecked excessively during a run.

`AssetKeyResolver` (`scripts/game/config/asset_key_resolver.gd`) maps active config/gameplay identifiers to reserved asset keys: 5 battle backgrounds, the 10 runtime enemy IDs, and the 5 active tile types. The resolver keeps asset-key string mapping outside UI scripts.

`GameScreen` now uses an `ImageSlot` as the battle background layer. `BattleBackgroundConfig` includes `asset_key`, and `BattleBackgroundCatalog` fills it for all 5 placeholder backgrounds. The selected background applies both its asset key and placeholder color to the background slot; because no real background files were added, the current game still shows safe placeholder colors.

`EnemyPanel` now uses `EnemyImageSlot` for the active enemy visual. Enemy IDs resolve through `AssetKeyResolver`, missing enemy images show the neutral placeholder, and direct-mode enemy copy remains unchanged. Tile image rendering is postponed: tile type to asset-key mapping and tests are ready, but `TileView` remains stylebox/button-based so current special markers and animation behavior stay stable.

No real image assets were added. Active gameplay remains unchanged: LevelSelect startup, Settings from LevelSelect, GameScreen Menu/Back to LevelSelect, direct match damage, round modifiers, Stage 34 balance, progression, stars, zones, enemies, and battle flow all remain active. Hero/RPG systems remain frozen and inactive. Next planned stage: Stage 38, AudioManager foundation v0.1.

## How To Open And Run

1. Open Godot 4.x.
2. Import or open this folder as a Godot project.
3. Run the project. The configured main scene is `res://scenes/app/App.tscn`.
4. The project opens directly on LevelSelect.
5. Choose an unlocked zone, then choose an unlocked level to open GameScreen directly (TeamSelect is skipped in the active flow).
6. Check the round modifier panel above the board to see the active battle's color damage buff (e.g. "Red Surge — Red crystals deal x3 damage").
7. Click one tile, then click a neighboring tile to attempt a swap, or drag/swipe from a tile toward a neighbor. Clearing crystals deals direct damage to the enemy, boosted for any color the current round modifier buffs.
8. Win a battle to save completion, earn stars, and unlock the next level.
9. Press Settings in the LevelSelect top panel to open SettingsScreen and toggle Animations, Reduced Motion, Debug Labels, Music, and Sound Effects.
10. Press Levels/Back to return to LevelSelect.

The Heroes button and the TeamSelect/UpgradeScreen flow are hidden from active play while `FeatureFlags.HERO_SYSTEMS_ENABLED` is false; hero code remains in the project for a future revisit.

## Board Core Tests

Run the board core test script with:

```bash
godot --headless --script res://scripts/tests/board_core_test.gd
```

Run the battle core test script with:

```bash
godot --headless --script res://scripts/tests/battle_core_test.gd
```

Run the playable battle smoke test with:

```bash
godot --headless --script res://scripts/tests/playable_battle_smoke_test.gd
```

Run the board input controller test with:

```bash
godot --headless --script res://scripts/tests/board_input_controller_test.gd
```

Run the turn presentation data test with:

```bash
godot --headless --script res://scripts/tests/turn_presentation_data_test.gd
```

Run the ability core test with:

```bash
godot --headless --script res://scripts/tests/ability_core_test.gd
```

Run the ability presentation data test with:

```bash
godot --headless --script res://scripts/tests/ability_presentation_data_test.gd
```

Run the level config test with:

```bash
godot --headless --script res://scripts/tests/level_config_test.gd
```

Run the 100-level campaign test with:

```bash
godot --headless --script res://scripts/tests/campaign_100_levels_test.gd
```

Run the level identity test with:

```bash
godot --headless --script res://scripts/tests/level_identity_test.gd
```

Run the level zone helper test with:

```bash
godot --headless --script res://scripts/tests/level_zone_helper_test.gd
```

Run the LevelSelect zone test with:

```bash
godot --headless --script res://scripts/tests/level_select_zones_test.gd
```

Run the balance curve test with:

```bash
godot --headless --script res://scripts/tests/balance_curve_test.gd
```

Run the battle factory test with:

```bash
godot --headless --script res://scripts/tests/battle_factory_test.gd
```

Run the enemy catalog test with:

```bash
godot --headless --script res://scripts/tests/enemy_catalog_test.gd
```

Run the enemy selection test with:

```bash
godot --headless --script res://scripts/tests/enemy_selection_test.gd
```

Run the enemy scaling test with:

```bash
godot --headless --script res://scripts/tests/enemy_scaling_test.gd
```

Run the battle background catalog test with:

```bash
godot --headless --script res://scripts/tests/battle_background_catalog_test.gd
```

Run the battle background selection test with:

```bash
godot --headless --script res://scripts/tests/battle_background_selection_test.gd
```

Run the battle background presenter integration test with:

```bash
godot --headless --script res://scripts/tests/battle_background_presenter_test.gd
```

Run the asset catalog test with:

```bash
godot --headless --script res://scripts/tests/game_asset_catalog_test.gd
```

Run the asset key resolver test with:

```bash
godot --headless --script res://scripts/tests/asset_key_resolver_test.gd
```

Run the image slot test with:

```bash
godot --headless --script res://scripts/tests/image_slot_test.gd
```

Run the active imageholder integration tests with:

```bash
godot --headless --script res://scripts/tests/battle_background_asset_integration_test.gd
godot --headless --script res://scripts/tests/enemy_panel_image_slot_test.gd
```

Run the upgrade economy test with:

```bash
godot --headless --script res://scripts/tests/upgrade_economy_test.gd
```

Run the reward curve test with:

```bash
godot --headless --script res://scripts/tests/reward_curve_test.gd
```

Run the progression test with:

```bash
godot --headless --script res://scripts/tests/progression_test.gd
```

Run the save manager test with:

```bash
godot --headless --script res://scripts/tests/save_manager_test.gd
```

Run the battle factory progress test with:

```bash
godot --headless --script res://scripts/tests/battle_factory_progress_test.gd
```

Run the level completion test with:

```bash
godot --headless --script res://scripts/tests/level_completion_test.gd
```

Run the special tile test with:

```bash
godot --headless --script res://scripts/tests/special_tile_test.gd
```

Run the color bomb test with:

```bash
godot --headless --script res://scripts/tests/color_bomb_test.gd
```

Run the hero catalog test with:

```bash
godot --headless --script res://scripts/tests/hero_catalog_test.gd
```

Run the team selection test with:

```bash
godot --headless --script res://scripts/tests/team_selection_test.gd
```

Run the battle factory team test with:

```bash
godot --headless --script res://scripts/tests/battle_factory_team_test.gd
```

Run the character upgrade screen data test with:

```bash
godot --headless --script res://scripts/tests/character_upgrade_screen_data_test.gd
```

Run the upgrade screen data test with:

```bash
godot --headless --script res://scripts/tests/upgrade_screen_data_test.gd
```

Run the navigation flow test with:

```bash
godot --headless --script res://scripts/tests/navigation_flow_test.gd
```

Run the direct startup flow test with:

```bash
godot --headless --script res://scripts/tests/direct_startup_flow_test.gd
```

Run the game screen layout test with:

```bash
godot --headless --script res://scripts/tests/game_screen_layout_test.gd
```

Run the settings manager test with:

```bash
godot --headless --script res://scripts/tests/settings_manager_test.gd
```

Run the settings screen data test with:

```bash
godot --headless --script res://scripts/tests/settings_screen_data_test.gd
```

Run the settings flow test with:

```bash
godot --headless --script res://scripts/tests/settings_flow_test.gd
```

Run the battle message formatter test with:

```bash
godot --headless --script res://scripts/tests/battle_message_formatter_test.gd
```

Run the hero card presentation test with:

```bash
godot --headless --script res://scripts/tests/hero_card_presentation_test.gd
```

Run the hero party panel test with:

```bash
godot --headless --script res://scripts/tests/hero_party_panel_test.gd
```

Run the direct match damage test with:

```bash
godot --headless --script res://scripts/tests/direct_match_damage_test.gd
```

Run the hero systems freeze test with:

```bash
godot --headless --script res://scripts/tests/hero_systems_freeze_test.gd
```

Run the round modifier catalog test with:

```bash
godot --headless --script res://scripts/tests/round_modifier_catalog_test.gd
```

Run the round modifier selection test with:

```bash
godot --headless --script res://scripts/tests/round_modifier_selection_test.gd
```

Run the color damage resolver test with:

```bash
godot --headless --script res://scripts/tests/color_damage_resolver_test.gd
```

Run the round modifier presenter test with:

```bash
godot --headless --script res://scripts/tests/round_modifier_presenter_test.gd
```

Run the Stage 34 direct balance tests with:

```bash
godot --headless --script res://scripts/tests/direct_balance_config_test.gd
godot --headless --script res://scripts/tests/direct_enemy_scaling_balance_test.gd
godot --headless --script res://scripts/tests/direct_level_balance_test.gd
godot --headless --script res://scripts/tests/round_modifier_balance_test.gd
```

## Next Planned Stages

- Stage 26-30 block is complete. Stage 31 (hero portrait buttons and ability bars) is complete. Stage 32 (hero systems freeze and direct match damage foundation) is complete. Stage 33 (round modifiers and color damage rules) is complete. Stage 34 (direct match-3 balance pass) is complete. Stage 35 (direct LevelSelect startup and simplified UX polish) is complete. Stage 36 (ImageSlot asset placeholder pipeline) is complete. Stage 37 (asset loading integration for active imageholders) is complete.
- Stage 38: AudioManager foundation v0.1.
- Isolated Yandex Games platform adapter under `scripts/platform/` when explicitly requested.
