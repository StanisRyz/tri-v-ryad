# Tri V Ryad

Tri V Ryad is a Godot 4.x match-3 battle game intended for Yandex Games and Web-first release targets.

The project is currently through Stage 55: Inactive cell visual presentation and pass-through polish v0.1. Inactive cells (holes) now render as clearly not-playable — `TileView.set_cell_active()` drives a persistent "hole" look that no later tile/special/highlight call or transient effect can override — and `BoardView` skips inactive cells for every highlight/preview/effect, leaves them visible (un-ghosted) during overlay-mode animated turns, and fades a falling tile's ghost out/in around an inactive gap instead of sliding it visibly across one. `GravityResolver` treats inactive cells as pass-through gravity corridors instead of walls — a tile can fall straight through one or more inactive cells into the next active cell below, while refill still only ever targets active cells and inactive cells can never store a tile. `holes`-archetype levels generate real, safe, validated inactive-cell masks with shape variety via `BoardMaskGenerator` — `block_2x2`/`block_2x3`/`block_3x2` rectangles plus center-aware `center_diamond`/`center_circle_light` presets — wired into `GeneratedBoardChallenge.board_mask` through `BoardChallengeGenerator`; `normal` and `ice` archetypes still return a full active 9x9 mask. Hero/RPG systems (TeamSelect, hero party UI, hero abilities/charge/lane damage, hero upgrades) remain frozen and hidden from the active flow via `FeatureFlags.HERO_SYSTEMS_ENABLED := false`, and gameplay deals direct match-3 damage to the enemy. Each battle selects one positive round modifier that multiplies damage for matched cells of specific colors, while Stage 34 direct balance controls moves and enemy HP. The active flow remains App startup -> LevelSelect -> GameScreen -> LevelSelect, with Settings opened from the LevelSelect top panel; MainMenu remains in the project as inactive legacy/future code but is skipped by normal startup and play. The app shell, a level-select hub with numbers-only labels for `level_1` through `level_100` grouped into 10 locked zones, a shared 10-enemy base roster with battle-start random enemy selection and direct-mode HP scaling, ImageSlot-backed battle background and enemy visual placeholders, the safe cached `ImageSlot`/`GameAssetCatalog` placeholder image pipeline, the safe cached `AudioAssetCatalog`/`AudioManager` no-op audio foundation, three battle-local boosters (Hammer, Time Freeze, Rocket Barrage) with selected/used states and stronger white affected-cell targeting previews, the Stage 46-49 stepwise board animation pipeline, and the Stage 50 victory/defeat result flow all remain active for a vertical 9:16 game. `AnimatedTurnFlow` is the active owner of stepwise swap, clear, special creation, special activation, gravity/refill, cascade, booster activation/clear, and final-board handoff visuals during animated turns; `TurnFeedbackPresenter` is limited to text/status/enemy feedback for valid animated turns and must not replay board movement, clear, special activation, booster board visuals, highlight, refill, or full-board refresh effects after `AnimatedTurnFlow` has already handled them. Result overlays appear only after board animation, damage particles, enemy hit feedback, cleanup, and progress save/update finish. Hero code, MainMenu, TeamSelect, and UpgradeScreen remain in the project (not deleted) for a future revisit.

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
- A playable battle screen with a top enemy panel, compact Level/Moves/Levels HUD row, widened 9x9 `BoardView`, placeholder `TileView` tiles, hidden inactive hero party panel, status text, result overlay, and clean Next Level, Retry, and Levels result actions.
- Reusable UI components: `BattleHud`, `EnemyPanel`, `HeroPartyPanel`, `HeroCard`, `BattleResultOverlay`, and `ImageSlot`.
- `GameAssetCatalog` maps reserved image asset keys to future `res://assets/images/` paths and loads optional textures safely with a small cache for loaded and missing textures.
- `AssetKeyResolver` maps background IDs, enemy IDs, tile types, special tile types, UI ids, level button states, star states, and booster ids to `GameAssetCatalog` asset keys without scattering string literals through UI code.
- `GameScreen` uses an `ImageSlot` for the active battle background, applying the selected background asset key and placeholder color.
- `EnemyPanel` uses an `ImageSlot` for the active enemy visual, resolving the selected enemy ID to a reserved enemy asset key.
- `TileView` resolves optional tile textures through the cached asset pipeline; missing tile textures preserve the current color placeholders and special `H`/`V`/`B` markers.
- LevelSelect, Settings, battle HUD/status/result panels, and RoundModifierPanel now carry stable reserved UI asset keys for later texture art.
- `BoosterPanel` uses the existing `BoosterButton` icon/state placeholder pipeline for Hammer, Time Freeze, and Rocket Barrage in active combat, including readable selected and used visual states.
- Empty asset folders under `assets/images/backgrounds/`, `assets/images/enemies/`, `assets/images/tiles/`, `assets/images/ui/`, `assets/images/boosters/`, and `assets/images/heroes/` for later real images.
- `AudioAssetCatalog` maps reserved audio keys to future `res://assets/audio/` paths and loads optional streams safely with a small cache for loaded and missing audio.
- `AudioManager` is registered as an autoload singleton, owns one music player and an 8-player SFX pool, and safely no-ops when audio files are missing.
- Empty asset folders under `assets/audio/music/` and `assets/audio/sfx/` for later real audio.
- Music and Sound Effects settings now drive `AudioManager` immediately, while existing settings persistence remains unchanged.
- Minimal UI/battle audio hooks are present for buttons, level select, swap, invalid swap, match, special activation, enemy damage, victory, and defeat.
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
- The victory overlay shows the completed level, stars earned, best stars, moves left, and new next-level/zone-unlock messages when applicable; it does not contain upgrade spending UI in the active direct flow.
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
- `BoardAnimationRequest` and `BoardAnimationSequence` define ordered future board animation events without owning gameplay rules.
- `AnimatedTurnFlow` owns active stepwise board visuals during animated turns: swap, clear, special creation, special activation, gravity/refill, cascade, booster activation/clear, and final board handoff.
- `BoardAnimationController` plays settings-aware board animation requests with `animations_enabled` and `reduced_motion_enabled` support.
- `BoardAnimationSequenceBuilder` builds both per-phase stepwise sequences for `AnimatedTurnFlow` and legacy presentation sequences for older/fallback callers.
- `TurnFeedbackPresenter` must not duplicate board movement, match highlights, clear effects, special activation visuals, refill effects, or full-board refresh animations after `AnimatedTurnFlow` has already played a valid turn. Valid animated turns use text/status feedback only; invalid swaps keep their rejection feedback path.
- Special activation animation is presentation-only inside the stepwise flow: H specials pulse their activation cell and sweep horizontally across affected row cells, V specials pulse and sweep vertically through affected column cells, and B/color bombs pulse the bomb cell and briefly highlight affected cells of the selected/base color before those cells fade.
- Lightweight `TileView` animation helpers for swap pulses, invalid pulses, match fade, refill appear, and visual reset.
- `BoardView` exposes presentation-only animation helpers over existing tile views, including tile lookup, cell centers, cell flashes, and cell pulses.
- Valid animated turns resolve in order: swap -> current match clear/special creation -> gravity/refill -> cascade checks/repeats -> final board handoff -> damage particles/enemy hit -> text/result feedback.
- Invalid swaps get brief rejection feedback on the involved cells and clean their transient visuals afterward.
- Match/cascade/special/booster clears and booster targeting previews clean selected cells, highlights, preview nodes, overlay ghosts, `AnimationLayer` children, tile tint/scale drift, and board particles before result overlays, restart, or LevelSelect return.
- Input locking during turn feedback and after victory/defeat remains tied to `feedback_finished`.
- Swapped cell feedback, invalid swap feedback, match highlights, refill feedback, temporary Hero Lane highlights, and short damage/enemy action status messages.
- The portrait battle board is scaled to match the hero party panel width, and permanent Hero Lane separator/debug grid visuals are removed from the normal board state.
- Live enemy, HUD, and hero updates.
- Victory and defeat overlays with concise result summaries, Retry/Levels actions, and a Next Level action when another unlocked level exists.
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
- Damage particle event builder tests in `scripts/tests/damage_particle_event_builder_test.gd`.
- Battle effect controller tests in `scripts/tests/battle_effect_controller_test.gd`.
- Enemy panel hit feedback tests in `scripts/tests/enemy_panel_hit_feedback_test.gd`.
- Game screen damage effect flow tests in `scripts/tests/game_screen_damage_effect_flow_test.gd`.
- Booster damage effect flow tests in `scripts/tests/booster_damage_effect_flow_test.gd`.
- Board visual snapshot tests in `scripts/tests/board_visual_snapshot_test.gd`.
- Board overlay mode tests in `scripts/tests/board_overlay_mode_test.gd`.
- Board animation cleanup tests in `scripts/tests/board_animation_cleanup_test.gd`.
- Swap no-double-layer tests in `scripts/tests/swap_no_double_layer_test.gd`.
- Cascade visual stability tests in `scripts/tests/cascade_visual_stability_test.gd`.
- Real tile position lock tests in `scripts/tests/real_tile_position_lock_test.gd`.
- Battle effect cleanup tests in `scripts/tests/battle_effect_cleanup_test.gd`.
- Documentation for future implementation rules.

This stage excludes:

- Wrapped bombs, special + special combos, special battle damage, cascade damage beyond the current direct-mode stepwise flow, full falling polish, real tile movement, real/final audio assets, final particle/effect art, and final art.
- Target selection, cooldowns, ability upgrades, gacha, rarity, hero unlocks, hero shards, hero inventory, portraits, final art, drag-and-drop team UI, and complex ability additions.
- One-time rewards, stars-based rewards, level map, chapters, complex economy, reset upgrades, and complex objectives.
- New heroes, hero unlocks, gacha, rarity, shards, ability upgrades, TeamSelectScreen rework, Yandex SDK, cloud save, ads, payments, real/final audio assets, final particle/effect art, and final art.
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

No real image assets were added. Active gameplay remains unchanged: LevelSelect startup, Settings from LevelSelect, GameScreen Menu/Back to LevelSelect, direct match damage, round modifiers, Stage 34 balance, progression, stars, zones, enemies, and battle flow all remain active. Hero/RPG systems remain frozen and inactive.

## Stage 38: AudioManager Foundation v0.1

Stage 38 is complete. `AudioAssetCatalog` (`scripts/game/audio/audio_asset_catalog.gd`) maps reserved audio keys to future audio paths under `assets/audio/`, checks `ResourceLoader.exists()` before loading, returns `null` for unknown/missing/non-audio resources, and caches loaded and missing streams.

`AudioManager` (`autoload/AudioManager.gd`) is registered as an autoload singleton in `project.godot`. It owns one music `AudioStreamPlayer`, an 8-player SFX pool, `music_enabled` and `sound_effects_enabled` state, and wrapper methods for the reserved UI/battle events. Missing audio streams safely no-op, so the game does not crash or block when no real audio files exist.

Empty audio folders were added under `assets/audio/music/` and `assets/audio/sfx/` with `.gitkeep` files only. No real audio files, final music, or final sound design were added.

Music and Sound Effects settings now apply to `AudioManager` on app startup and when toggles change in SettingsScreen. Existing settings persistence remains unchanged and separate from player progress.

Minimal audio hooks were added for LevelSelect Settings/button interactions, level selection, GameScreen swap requests, invalid input/invalid swaps, valid direct-damage turns, special activation when `TurnPresentationData` exposes activated special tiles, enemy damage, victory, and defeat. These hooks respect `sound_effects_enabled` and remain presentation-only.

Active gameplay remains unchanged: LevelSelect startup, Settings from LevelSelect, GameScreen Menu/Back to LevelSelect, direct match damage, round modifiers, Stage 34 balance, progression, stars, zones, ImageSlot-backed imageholders, enemies, and battle flow all remain active. Hero/RPG systems remain frozen and inactive. Next planned stage: Stage 39, Tile and UI asset integration polish v0.1.

## Stage 39: Complete AssetKey Texture Binding v0.1

Stage 39 is complete. `GameAssetCatalog` now reserves safe `res://assets/images/` texture paths for base tiles, special tiles, battle UI panels, LevelSelect visuals, Settings visuals, booster icons, booster button states, stars, and future/frozen hero portraits. `AssetKeyResolver` maps background IDs, enemy IDs, active tile types, special tile types, UI IDs, booster IDs, level button states, and star states to catalog asset keys. Missing optional image files still show placeholders and never crash.

`TileView` resolves optional base tile and special tile asset keys while preserving the current color fallback and `H`/`V`/`B` special markers. LevelSelect, Settings, battle HUD/status/result panels, EnemyPanel, and RoundModifierPanel carry stable reserved UI asset keys. A visual-only `BoosterButton` stub was added for future booster icons and states without gameplay in Stage 39.

Active gameplay remained unchanged in Stage 39. Hero/RPG systems remained frozen and inactive. Next planned stage: Stage 40, Booster system foundation v0.1.

## Stage 40: Booster System Foundation v0.1

Stage 40 is complete. Active combat now has three battle-local boosters in a new `BoosterPanel` that replaces the old hidden hero area while direct mode is active. Hammer clears a clipped 3x3 area around the selected crystal, Time Freeze makes the next 3 successful turns not reduce moves, and Rocket Barrage clears every crystal of the selected color.

Each booster is usable once per battle through `BoosterState`; there is no saved inventory, persistence, economy, cooldown, purchase flow, Yandex SDK integration, particles, or final art. Booster usage itself does not consume moves. Hammer and Rocket read tile colors before clearing, apply direct damage through `DirectMatchDamageResolver`, use the current round modifier when color data is known, then clear/refill the board safely. Booster clears do not trigger extra cascade resolution in v0.1.

Hero/RPG systems remain frozen and inactive: `HeroPartyPanel` stays hidden in active direct-mode combat, and `BoosterPanel` is the visible control row. Next planned stage: Stage 41, Board animation foundation v0.1.

## Stage 41: Board Animation Foundation v0.1

Stage 41 is complete. `BoardAnimationRequest` and `BoardAnimationSequence` now provide a small ordered event model for future board animation work, including swap, invalid swap, match clear, special clear, booster clear, refill, cascade, damage-particle, and enemy-hit request types.

`BoardAnimationController` owns settings-aware playback and safely finishes immediately when animations are disabled, a sequence is empty, or no board view is available. `BoardAnimationSequenceBuilder` translates existing `TurnPresentationData` and `BoosterResolveResult` data into animation sequences without changing board, battle, booster, damage, progression, save, asset, audio, or hero-system rules.

`GameScreen` now routes turn presentation and booster resolution through the animation foundation before continuing existing turn feedback or booster status handling. `BoardView` exposes safe helper methods for tile lookup, cell centers, cell flashes, and cell pulses. This is an architecture foundation only; high-polish swap movement, match clear effects, falling crystals, refill animation, cascades, damage particles, and enemy hit feedback remain future work. Next planned stage: Stage 42, Swap and match clear animations v0.1.

## Stage 42: Swap and Match Clear Animations v0.1

Stage 42 is complete. `BoardAnimationController` now routes swap, invalid swap, match clear, and special clear requests to concrete `BoardView` animation methods instead of generic placeholder flashes.

`BoardView` has an `AnimationLayer` above the tile grid for temporary visual nodes. Valid swaps create two ghost tiles, hide the original tile visuals while the ghosts move toward each other, then restore the originals and clean the layer. Swap board updates are deferred during turn animation so the player sees the currently displayed crystals move before the resolved board is refreshed. Invalid swaps use overlay ghosts for bounce/shake feedback, never move real `TileView` nodes inside `GridContainer`, and do not change board data or consume moves.

Matched cells now use a visible flash/fade/scale clear effect, and special-cleared cells use a stronger gold placeholder clear. `animations_enabled` still skips animation playback at the controller level, while `reduced_motion_enabled` shortens durations and softens TileView scale/motion. Gravity, refill movement, cascade-step animation, damage particles, enemy hit animation, final effects, particles, art, and gameplay-rule changes remain future work. Next planned stage: Stage 43, Gravity, refill and cascade animation flow v0.1.

Stage 42 hotfix: swap timing and visibility were corrected by increasing the default swap request duration and holding resolved board updates until the animation step completes. Invalid swap animation now uses the overlay/ghost path only, with cleanup that restores hidden tiles and clears temporary ghosts.

## Stage 43: Gravity, Refill and Cascade Animation Flow v0.1

Stage 43 is complete. Normal valid player swaps now use an exact `SWAP_ANIMATION_DURATION := 1.0` second swap animation, defined as a constant on `BoardAnimationSequenceBuilder`. `reduced_motion_enabled` still shortens the effective duration through `BoardAnimationController`, and `animations_enabled = false` still skips playback immediately.

`GravityResolver` now returns `fall_movements` (from/to cell, tile type, special data, fall distance) and richer `refill_cells` (spawn index, target cell, tile type, special data) alongside the existing spawned-cell list. `BoardResolveResult` preserves this data per cascade step and exposes aggregated `fall_movements`, `refill_cells`, and ordered `cascade_steps` (matched cells, fall/refill data, and damage per step) instead of only the final board state. `TurnPresentationData` and `BoosterResolveResult` carry the same animation-friendly data forward from `BoardResolver` and `BoosterResolver`.

`BoardAnimationSequenceBuilder` now emits `gravity_fall` and `refill` requests right after clear/special-clear requests when movement or refill data exists, followed by a `cascade_step` request plus its own `gravity_fall`/`refill` requests for every automatic cascade, in resolve order, before the placeholder `enemy_hit` request. Booster clears (Hammer, Rocket Barrage) follow the same `booster_clear` -> `gravity_fall` -> `refill` shape when the booster resolver produces movement data; Time Freeze remains status/audio only.

`BoardView` plays gravity and refill through temporary `AnimationLayer` ghosts: `play_gravity_fall_animation` moves ghost tiles from their source cell to their target cell (slightly slower for a longer fall), `play_refill_animation` drops new ghost tiles from above their target column using `create_tile_ghost_from_data`, and `play_cascade_step_animation` gives cascade matches a short highlight/flash. Real `TileView` nodes inside `GridContainer` are never moved directly; original visuals are hidden only while ghosts animate and are restored afterward, with the `AnimationLayer` cleared once each step finishes. `BoardAnimationController` routes `TYPE_GRAVITY_FALL`, `TYPE_REFILL`, and `TYPE_CASCADE_STEP` requests to these methods, keeping the disabled/reduced-motion paths and the exactly-once finished callback guarantee.

`GameScreen` now defers the resolved board update during the booster-targeting flow the same way it already did for swaps, so Hammer/Rocket gravity and refill animations play over the pre-clear board and the final board is only applied once the whole animation sequence finishes. Damage particles and richer enemy hit feedback remain future work.

## Stage 44: Damage Particles and Enemy Hit Feedback v0.1

Stage 44 is complete. Normal valid swaps now use an exact `BoardAnimationSequenceBuilder.SWAP_ANIMATION_DURATION := 0.4` second animation (down from 1.0 second), still shortened only by `reduced_motion_enabled`, with `animations_enabled = false` still skipping playback immediately.

`GameScreen.tscn` gained a `BattleEffectLayer` `Control` positioned above the board/enemy UI (input-ignoring `mouse_filter`, cleaned after each effect) and owned by a new `BattleEffectController` (`scripts/game/view/battle_effect_controller.gd`). It flies small `ColorRect` particles from `BoardView.get_cell_global_center(cell)` toward `EnemyPanel.get_hit_target_global_position()`, using tile colors (brighter/larger for boosted cells), respects `animations_enabled`/`reduced_motion_enabled`, caps particle count (16 normal, 6 reduced motion), always calls its finished callback exactly once, and clears its temporary nodes afterward. Missing board view/enemy panel/effect layer, disabled animations, or empty events all finish immediately and safely.

`DamageParticleEventBuilder` (`scripts/game/presentation/damage_particle_event_builder.gd`) turns `TurnPresentationData` and `BoosterResolveResult` into particle event dictionaries (`cell`, `tile_type`, `damage`, `multiplier`, `is_boosted`, `source`). It uses exact per-cell tile-color data from the initial match/booster clear where available and otherwise distributes total damage safely across representative cleared cells. Zero damage and Time Freeze both produce no events. `BoosterResolveResult`/`BoosterResolver` gained `cleared_cell_tile_types` (cell to tile type) so Hammer/Rocket clears carry enough data for accurate particle events.

`EnemyPanel` gained `get_hit_target_global_position()`, `play_hit_feedback(damage)`, `show_floating_damage(damage)`, and `animate_hp_change(current_hp, max_hp)`. A new `HitEffectLayer` overlay hosts floating damage labels that rise and fade, the enemy portrait flashes/shakes briefly on hit (softened/removed under reduced motion), and the HP bar now tweens toward its new value through `configure_presentation(animations_enabled, reduced_motion_enabled)` instead of snapping instantly. All methods stay safe if their backing UI nodes are missing.

`GameScreen` now plays damage particles and enemy hit feedback after each turn's or booster's board animation sequence finishes and before continuing the existing turn/booster feedback, status text, and result-overlay flow; input stays locked the entire time. Enemy-damage audio now fires alongside hit feedback instead of immediately at turn-presentation time, and victory/defeat overlays still only appear after this full feedback chain completes. No board rules, battle rules, booster rules, balance, progression, saves, Yandex SDK, cloud save, ads, payments, final art, or hero-system reactivation were added. Next planned stage: Stage 45, overall gameplay animation polish and reduced-motion support.

## Stage 45: Gameplay Animation Timeline Stabilization v0.1

Stage 45 is complete. It fixes double-board visuals, ghost/final-board overlap, empty-looking cells, and stretched/merged crystals during cascades/refill, rather than adding new visual effects — stability over complex visuals.

`BoardVisualSnapshot` (`scripts/game/view/board_visual_snapshot.gd`) captures a read-only, per-cell copy of `BoardView`'s visible state (tile type, special data, position, size, asset key, placeholder color, marker text) via `BoardVisualSnapshot.from_board_view(board_view)`. It is safe if `board_view` is null, ignores missing cells, and never mutates `BoardView`.

`BoardView` gained an animation overlay mode: `enter_animation_overlay_mode(snapshot)` hides every real `TileView` and builds one full-board ghost per cell in `AnimationLayer` from the snapshot, so there is exactly one visible board layer during animation; `exit_animation_overlay_mode()` clears the ghosts and restores the real tiles; `force_reset_animation_state()` is an emergency cleanup hook that kills active tweens, clears `AnimationLayer`, and resets every real tile's visibility/scale/modulate/position. In overlay mode, swap moves the two matching ghosts directly, match/special/cascade clears fade the matched ghosts out, and refill fades a new ghost into each vacated cell; gravity fall is a documented v0.1 safe fallback (no-op) in overlay mode. Outside overlay mode, direct/legacy callers keep the original ghost-per-animation behavior unchanged.

`GameScreen` now captures a pre-turn snapshot and enters overlay mode at the start of every animated turn (swap, targeted booster, non-targeted booster) through `_begin_animated_turn()`, and a single `_apply_pending_board_for_animation()` choke point exits overlay mode and applies the deferred board exactly once before damage particles play. `_force_cleanup_visual_state()` clears the board animation queue, resets `BoardView`, and clears `BattleEffectLayer`; it runs on every new battle/restart, Menu/Back, and before the result overlay, so stray ghosts or particles can never persist across those transitions.

No board rules, battle rules, booster rules, balance, progression, saves, Yandex SDK, cloud save, ads, payments, final art, or hero-system reactivation were added. Detailed per-tile gravity/refill fall animation remains a documented follow-up for a future stage.

## Stage 46: Stepwise Board Resolution Animation Pipeline v0.1

Stage 46 is complete. It replaces eager full-board precompute with a stepwise, animation-locked resolution pipeline for animated player turns: swap -> check current matches -> clear -> gravity/refill -> check cascades -> repeat until stable -> only then compute damage/battle state.

`StepwiseBoardResolver` (`scripts/game/board/stepwise_board_resolver.gd`) exposes the same match/clear/gravity/special-tile rules as `BoardResolver` one phase at a time (`find_current_matches`, `build_clear_step`, `apply_clear_step`, `apply_gravity_step`, `resolve_next_step`) instead of resolving the whole cascade in one call, returning a `BoardResolveStep` (`scripts/game/board/board_resolve_step.gd`) per phase. `AnimatedTurnFlow` (`scripts/game/presentation/animated_turn_flow.gd`) drives a live turn through these phases against the real `BoardModel`, playing each phase's animation (via new `BoardAnimationSequenceBuilder.build_swap_sequence`/`build_clear_sequence`/`build_gravity_refill_sequence`/`build_booster_clear_sequence` helpers) before applying the next phase's board mutation, and only hands the accumulated `BoardResolveResult` to `BattlePresenter` once the board is fully stable.

`BattlePresenter.request_swap()` now only validates and applies the swap, then emits `swap_accepted` instead of resolving the whole board immediately; `GameScreen` routes an accepted swap into `AnimatedTurnFlow.start_swap_turn()`, which calls the new `BattlePresenter.finalize_swap_turn()` once stable to run `BattleResolver`/`TurnPresentationData`/signal emission exactly as before. `BattlePresenter.request_targeted_booster()` emits `targeted_booster_accepted` the same way, and `AnimatedTurnFlow.start_booster_clear()` now also checks for cascades after Hammer/Rocket's clear+gravity pass (a real behavior addition — Hammer/Rocket clears previously never triggered cascades), accumulating any extra cleared cells/damage before calling `finalize_booster_turn()`.

### Stage 46 hotfix: post-swap overlay ghost mapping

Fixed post-swap overlay ghost mapping in `BoardView` (`scripts/game/view/board_view.gd`): `_play_overlay_swap()` was only reassigning `_overlay_ghosts[from_cell]`/`_overlay_ghosts[to_cell]` inside the swap tween's `finished` callback, but `BoardAnimationController._play_requests_async()` advances to the next queued request (e.g. a match-clear request) after a fixed timer duration, not after the tween's `finished` signal, so a match-clear request could run against the stale pre-swap mapping and fade the wrong ghost — visually, the swapped-away source crystal instead of the newly-matched destination crystal. `_play_overlay_swap()` now flips the mapping immediately via a new `_swap_overlay_ghost_mapping()` helper as soon as the swap tween starts (the board model is already post-swap at that point), so `_overlay_ghosts[cell]` always reflects "the ghost currently representing this board cell after the swap," and match clear animation now targets the correct post-swap cells. A new `_finalize_overlay_swap()` runs in the tween's `finished` callback purely to prune ghosts that were freed/invalidated mid-tween (overlay cancelled, animation interrupted); it no longer performs the mapping swap itself. `BoardAnimationController` also calls a new `BoardView.finalize_pending_overlay_swap()` after a swap request's timer elapses, as an extra safety net. The visible swap tween (both ghosts sliding to each other's positions) is unchanged, and stepwise board resolution (matches are still found against the live post-swap `BoardModel`, not a stale precomputed set) was not touched.

Because the board only mutates one phase at a time, match-clear animations now always target the current, post-swap board state instead of a precomputed final result, and gravity/refill animation plays and completes before the next cascade check runs — `BoardView` gained a real overlay-mode gravity fall animation (`_play_overlay_gravity_fall`, relocating the falling ghost instead of the previous v0.1 no-op fallback) to support this. `animations_enabled = false` still resolves a turn immediately and synchronously through the original `BoardResolver.resolve_board()` path (`BattlePresenter.resolve_accepted_swap_immediately()`), unchanged from before. No board rules, damage formulas, booster targeting rules, balance, progression, saves, Yandex SDK, cloud save, ads, payments, final art, or hero-system reactivation were added.

### Stage 46 polish hotfix: board animation handoff and invalid swap polish v0.1

Four remaining gameplay-animation polish issues in `BoardView` (`scripts/game/view/board_view.gd`) and `GameScreen` (`scripts/screens/game_screen.gd`) were fixed:

- **Refill crystals now fall from above in overlay mode.** `_play_overlay_refill()` previously created each new ghost directly at its target cell and only faded it in. It now reuses the same start-position math as the non-overlay `play_refill_animation()` (`to_position - Vector2(0, cell_size * (spawn_index + 1))`, stacking same-column spawns above each other) and tweens `position` from that start point down to the target cell (with a short fade-in layered on top), so refilled crystals visibly fall into place instead of appearing in place.
- **Final board handoff no longer blinks.** `BoardView` gained `apply_board_under_overlay(board)`: it updates `_board` and calls `refresh_all_tiles()` while the real `TileView` nodes are still hidden behind the overlay ghosts, and only then calls `exit_animation_overlay_mode()` to reveal them — so the real board is always already showing the correct final data the instant it becomes visible, with no frame where it's stale or blank. `GameScreen._apply_pending_board_for_animation()` now calls this when a pending board exists and the view is still in overlay mode, instead of calling `exit_animation_overlay_mode()` and `set_board()` back to back.
- **Invalid swap now swaps and returns.** `play_invalid_swap_animation()` moves the two involved crystals to each other's positions and back (half the total duration each way) using `AnimationLayer` ghosts, in both overlay mode (a new `_play_overlay_invalid_swap()`, animating the existing full-board ghosts without touching `_overlay_ghosts`, since the board model never changes on an invalid swap) and non-overlay mode (temporary ghosts over hidden real tiles, restored after). `BoardAnimationSequenceBuilder.INVALID_SWAP_ANIMATION_DURATION` is now `0.24`s (up from `0.12`s) to give the swap-and-return room to read clearly; a `_play_invalid_swap_bounce()` fallback keeps the old small-bounce behavior for single-cell invalid input with no valid neighbor.
- **Cascade/match highlights no longer stay lit after the flow ends.** `play_cascade_step_animation()` no longer calls `highlight_cells()` for its non-overlay flash (which left `_highlighted_cells` set with nothing to clear it); it only plays a temporary `TileView.play_flash()`. `GameScreen._on_feedback_finished()` and `_finish_booster_resolution()` now call `board_view.clear_cell_highlights()` once their flow completes (the booster path also switched from a persistent `highlight_cells()` to a temporary `flash_cells()`), and `_force_cleanup_visual_state()` clears highlights too as a safety net.

Stepwise board resolution (swap -> check matches -> clear -> gravity/refill -> check cascades -> repeat until stable -> final handoff -> particles/feedback/result) remains unchanged and active; only the visual presentation around it was touched.

### Stage 46 polish hotfix 2: remove duplicate feedback and add special creation animation v0.1

The previous polish hotfix fixed the overlay-to-real-board handoff itself, but the whole-board blink and yellow highlight persisted from a different source: after `AnimatedTurnFlow` finished playing the real swap/clear/gravity/refill/cascade animation live and the final board was applied, `GameScreen._play_turn_feedback_after_animation()` still called `TurnFeedbackPresenter.play_turn_feedback()`, which for valid turns ran `_play_valid_feedback()` — a second, older full-board feedback pass (`play_swap_feedback`, `board_view.highlight_cells(data.matched_cells)`, `play_match_clear_feedback`, `play_special_clear_feedback`, and `BoardMotionAnimator.play_board_refresh_feedback()`, which calls `board_view.play_refill_feedback()` with no cells — i.e. a refill-appear pulse across *every* tile on the board) on top of the already-final, already-displayed board. That second pass was the real cause of the end-of-turn blink, and its `highlight_cells()` call was the real cause of the lingering yellow border (only cleared several awaited steps later, after the blink had already been visible).

- `TurnFeedbackPresenter` gained `play_turn_text_feedback_only(data, board_view, status_callback)`, which only plays lane/status/special-activation/damage/enemy-action text messages and still calls `clear_lane_highlights()`/`clear_cell_highlights()` at the end — no swap pulse, no `highlight_cells()`, no match/special clear fade, no board refresh feedback. `GameScreen._play_turn_feedback_after_animation()` now calls this for `data.is_valid == true` (turns that already animated live through `AnimatedTurnFlow`) and keeps calling the original `play_turn_feedback()` (→ `_play_invalid_feedback()`) for invalid swaps, which is unchanged. The old `_play_valid_feedback()`/`BoardMotionAnimator.play_board_refresh_feedback()` path is no longer reachable from a valid turn in the active flow.
- **Match clear now targets `step.cleared_cells`, not `step.matched_cells`.** `StepwiseBoardResolver.build_clear_step()` already protects a special-creation cell from being cleared (it stays in `step.matched_cells` for damage/statistics purposes but is excluded from `step.cleared_cells`). `BoardAnimationSequenceBuilder.build_clear_sequence()` was building its `TYPE_MATCH_CLEAR` request from `step.matched_cells`, so the creation cell's ghost/tile got faded out by the clear animation even though it was supposed to survive and turn into a special tile — leaving that cell visually empty until the whole animation flow finished. It now uses `step.cleared_cells`.
- **Added a special-tile creation animation.** A new `BoardAnimationRequest.TYPE_SPECIAL_CREATE` request type is emitted by `build_clear_sequence()` right after the match-clear request whenever `step.created_special_tiles` is non-empty (payload: `created_special_tiles`, each `{cell, special_type}`). `BoardAnimationController` routes it to a new `BoardView.play_special_create_animation(created_special_tiles, duration)`: in overlay mode, `_play_overlay_special_create()` looks up the creation cell's existing overlay ghost (never faded now, per the fix above), sets its marker text (`H`/`V`/`B`) and pulses its scale/modulate, with `_spawn_fallback_special_ghost()` as a safety net if the ghost was somehow missing; outside overlay mode it calls `TileView.set_special_tile()` + `play_special_flash()` on the real tile. The creation cell stays visually occupied for the whole clear -> special-create -> gravity/refill sequence instead of popping in only after all animation finished.

Stepwise board resolution and the improved invalid-swap (swap-and-return) behavior are unchanged.

### Stage 46 polish hotfix 3: special creation gather animation and preferred spawn cell v0.1

The previous hotfix kept a special's creation cell visually occupied but the special tile still just appeared there after a flat pulse; this hotfix makes the matched crystals visibly gather into the creation cell first, and makes player-created specials land on the cell the player actually swapped rather than a fixed match-center cell.

- **Matched crystals gather into the creation cell.** `StepwiseBoardResolver.build_clear_step()` now records `source_cells` (the full matched-cell list) and `tile_type` on each `created_special_tiles` entry. `BoardAnimationSequenceBuilder.build_clear_sequence()` excludes those source cells from the plain `TYPE_MATCH_CLEAR` fade so they don't just fade in place. `BoardView._play_overlay_special_create()` now slides, shrinks, and fades each gathered ghost into the creation-cell ghost's position before the existing marker-update/pulse plays; the non-overlay real-tile fallback cannot move real `TileView` nodes inside `GridContainer`, so it instead fades the source tiles in place via `play_match_clear()` while the creation tile still gets its marker + flash.
- **Player-created specials prefer the swapped cell.** A new `SpecialTileResolver.choose_special_cell_for_match(match_result, preferred_cells)` tries each cell in `preferred_cells` in order (returning the first one that's part of the match) before falling back to the existing deterministic center-cell `choose_special_cell()`. `StepwiseBoardResolver.build_clear_step()` gained an optional `preferred_cells` parameter that's threaded through to this new chooser. `AnimatedTurnFlow.start_swap_turn()` passes `[to_cell, from_cell]` as `preferred_cells` only for the very first resolve step (`cascade_index == 0`) right after a player swap, so a match created directly by that swap spawns its special on the swapped-into cell if it's part of the match, else the swapped-from cell, else the old center cell.
- **Cascade/gravity-created specials are unaffected.** No preferred cells are passed for any cascade step after the first, so specials created by falling/refilled matches keep the unchanged center-cell placement.

Stepwise board resolution, the swap-and-return invalid-swap behavior, and prior overlay/handoff fixes are unchanged.

## Stage 47: Animation QA and Board Visual Stability Pass v0.1

Stage 47 is complete. It stabilizes the existing Stage 46 stepwise board animation pipeline rather than adding new mechanics or new visual feature work.

- `AnimatedTurnFlow` remains the only active owner of stepwise board visuals during an animated turn: swap, match clear, special creation, gravity/refill, cascade, booster clear, and final board handoff all run there before damage/result feedback starts.
- `TurnFeedbackPresenter.play_turn_text_feedback_only()` is the valid-turn path after `AnimatedTurnFlow`; it is intentionally text/status/enemy feedback only and must not replay board movement, match highlights, clear effects, refill effects, or whole-board refresh animation. The old board-visual feedback path remains only for invalid swaps or legacy non-stepwise callers.
- Booster clear requests now route through `BoardView.play_booster_clear_animation()`. In overlay mode this fades/removes the cleared booster ghosts before gravity/refill adds new ghosts, preventing duplicate or leftover board layers after Hammer/Rocket flows.
- `BoardView.clear_transient_visual_state()` centralizes cleanup for selected-cell state, match/cascade/special/booster highlights, invalid highlights, lane highlights, temporary `TileView` tint/scale drift, and idempotent tile refresh safety without touching `GridContainer` child positions.
- `GameScreen` now clears transient board visuals before final board handoff, after valid feedback, after booster feedback, on booster targeting cancel, when animations are disabled mid-flow, before result overlay, on restart, and on Menu/Back return to LevelSelect.
- `BattleEffectController.clear_effects()` now cancels in-flight particle playback, clears effect nodes immediately, and suppresses stale finished callbacks after forced cleanup.
- `AnimatedTurnFlow.cancel()` releases any pending step await so restart/menu/result cleanup cannot leave a suspended turn flow behind.
- Final board handoff still uses `BoardView.apply_board_under_overlay(board)`: the real `TileView` data is updated while overlay ghosts cover the board, then the overlay is removed only after the real board is ready. Newly created special tiles remain visible because the special creation cell is protected during clear and the final board refresh preserves the special metadata.
- Damage particles and enemy hit feedback start only after stepwise board animation is complete, transient highlights are cleared, overlay ghosts are removed, and the final board is applied. Result overlay display remains after that full feedback chain.
- Normal, reduced-motion, and disabled-animation paths preserve the same logical order; disabled animations resolve immediately and clean stale overlay/highlight/effect state safely.

No board rules, damage formulas, booster targeting rules, balance, progression, saves, Yandex SDK, cloud save, ads, payments, final art, or hero-system reactivation were added.

## Stage 48: Special Tile Activation Animations v0.1

Stage 48 is complete. It adds lightweight, presentation-only activation reads for existing H/V/B special tiles inside the current `AnimatedTurnFlow` stepwise board animation sequence.

- `StepwiseBoardResolver` and the disabled-animation `BoardResolver` now preserve activation payload data: activated special cell, special type, affected cells, and `base_tile_type` for color bombs when available.
- `BoardAnimationRequest.TYPE_SPECIAL_ACTIVATION` is emitted before the special clear fade for each activation step, so the player sees the H/V/B activation before gravity/refill begins.
- `BoardAnimationController` routes H specials to horizontal activation, V specials to vertical activation, and B/color bombs to color-bomb activation, falling back to the existing special-clear animation if the payload is incomplete or unknown.
- `BoardView.play_horizontal_line_special_activation()`, `play_vertical_line_special_activation()`, and `play_color_bomb_special_activation()` provide the v0.1 visuals: activation-cell pulse, horizontal row sweep, vertical column sweep, or selected/base-color affected-cell highlight, followed by the existing fade/clear.
- In overlay mode, activation visuals use overlay ghosts and temporary `AnimationLayer` highlights only; real board tiles stay hidden until final handoff. Outside overlay mode, the fallback pulses/highlights existing `TileView` controls without manually moving real `GridContainer` children.
- Cleanup remains unchanged through the existing final handoff and transient-state cleanup; reduced motion keeps the same order with shorter/lighter playback, and disabled animations finish immediately through the controller.
- `TurnFeedbackPresenter` remains text/status/enemy feedback only after valid animated turns and must not replay special board visuals.

No board rules, damage formulas, progression, battle state, saves, Yandex SDK, cloud save, ads, payments, final art, or hero-system reactivation were changed.

## Stage 49: Booster Targeting and Booster Animation Polish v0.1

Stage 49 is complete. It improves active direct-mode booster UX without changing booster rules, damage formulas, balance, progression, saves, platform code, art assets, or hero-system behavior.

- Hammer and Rocket Barrage now use a preview-confirm targeting flow: select the booster, tap a crystal to preview affected cells, then tap that same crystal again to apply. Pressing the same selected booster cancels targeting.
- Hammer previews the clipped 3x3 area around the selected crystal, including edge and corner targets, and then plays a target pulse plus full-cell impact flash before the existing booster clear/gravity/refill/cascade flow.
- Rocket Barrage previews all currently visible cells that match the selected crystal's tile type and then pulses the target plus briefly flashes the same-color group before the existing clear flow.
- Time Freeze remains non-board feedback only: it activates immediately, pulses the booster button/status path, adds free turns, and does not request board clear animation when no cells are cleared.
- Used boosters stay visibly unavailable through dimmed/disabled-looking button state, but pressing them still gives a short "already used" response instead of silently doing nothing. Selected booster state is cleared after cancel/apply/use.
- `BoardView.show_booster_target_preview()` and `clear_booster_target_preview()` own presentation-only preview nodes on `AnimationLayer`. Preview/effect cleanup runs on booster apply, cancel, selected-booster changes, disabled-animation cleanup, result overlay, restart, and LevelSelect return.
- `BoardAnimationRequest.TYPE_BOOSTER_ACTIVATION` plays before `TYPE_BOOSTER_CLEAR` inside the existing `AnimatedTurnFlow` booster path, so damage particles and result overlays still wait until board animation and cleanup finish.

## Stage 49.1: Stronger Booster Affected-Cell Preview v0.1

Stage 49.1 is complete. Hammer and Rocket targeting previews now use a stronger near-white overlay on affected cells so the hit area is immediately readable on all tile colors. Booster rules, targeting logic, activation order, damage, cleanup paths, and Time Freeze behavior are unchanged.

- Hammer still previews the clipped 3x3 area around the target crystal, but every affected cell now gets a bright white inset overlay before apply.
- Rocket Barrage still previews all currently visible cells matching the target crystal's tile type, now with the same strong white affected-cell overlay.
- The preview remains presentation-only through `BoardView.show_booster_target_preview()` and still clears on apply, cancel, selected-booster changes, disabled-animation cleanup, result overlay, restart, and LevelSelect return.

## Stage 50: Result Screen and Level Flow UX Polish v0.1

Stage 50 is complete. Battle results now build structured display data in `GameScreen` after the existing reward/completion save flow, then pass that data to `BattleResultOverlay` for display only.

- Victory data includes `level_id`, display label, stars earned, best stars, moves left, reward amount for compatibility, next level id when launchable, whether the next level was newly unlocked, and whether a new zone was unlocked.
- Defeat data includes `level_id`, display label, moves left when useful, and a short retry suggestion.
- Victory shows a compact summary: Victory title, completed level, stars earned and best stars, moves left, plus next-level and zone-unlock messages only when they are newly earned. Replaying an already completed level does not show false unlock messages.
- Defeat shows a simple failed-level summary and retry suggestion.
- Victory actions are Next Level, Retry, and Levels. Defeat actions are Retry and Levels. Next Level is visible/enabled only when another unlocked campaign level exists.
- Next Level hides the overlay, clears transient board/booster/effect state, switches `_current_level_id`, and reuses the normal battle start path so HUD, enemy, board, boosters, background, modifier, and input state are rebuilt.
- Retry hides the overlay and reuses the same battle start path for the current level, resetting board, battle state, boosters, HUD, and input.
- Levels returns to `LevelSelectScreen`; `App` calls `refresh_progress_state()` after wiring managers so completed levels, stars, next-level unlocks, and zone availability are visible immediately.
- Result overlay display still waits for board animation, booster/special animation, damage particles, enemy hit feedback, transient cleanup, and progress save/update. Cleanup clears booster previews/selection, highlights, animation layer nodes, pending board state, and particles before result display and again before retry, next level, or LevelSelect return.

## Stage 51: Procedural Challenge Archetype Foundation v0.1

Stage 51 is complete. It adds the architecture and data flow for procedural level challenges without changing current playable behavior: the board a player sees is still a full, normal 9x9 board.

- `ChallengeArchetype` (`scripts/game/config/challenge_archetype.gd`) defines the three archetype ids: `normal`, `ice`, `holes`.
- `ChallengeArchetypeResolver` (`scripts/game/config/challenge_archetype_resolver.gd`) maps level number to archetype on a repeating 5-level cycle: `%5==1` -> normal, `%5==2` -> ice, `%5==3` -> holes, `%5==4` -> ice, `%5==0` -> holes. Example: level_1 normal, level_2 ice, level_3 holes, level_4 ice, level_5 holes, level_6 normal.
- `DifficultyBudget` (`scripts/game/config/difficulty_budget.gd`) and `DifficultyBudgetResolver` (`scripts/game/config/difficulty_budget_resolver.gd`) derive a `difficulty_score` and `difficulty_tier` (`early`/`medium`/`hard`/`very_hard`) from level number, plus placeholder-ready `ice_density`, `hole_count`, `blocker_count`, `validation_attempts`, and `layout_complexity` values that later generators can read. Early levels stay gentle; values scale up gradually toward the end of the 100-level campaign.
- `GeneratedBoardChallenge` (`scripts/game/board/generated_board_challenge.gd`) is the data object produced at battle start: `archetype`, `level_id`, `level_number`, `difficulty_score`, `difficulty_tier`, `generation_seed`, `board_mask`, `frozen_cells`, and a `metadata` debug dictionary.
- `BoardChallengeGenerator` (`scripts/game/board/board_challenge_generator.gd`) builds a `GeneratedBoardChallenge` from level id/number, archetype, difficulty budget, and seed. For this stage every archetype returns the same full 9x9 `board_mask` placeholder (all cells active) and empty `frozen_cells`; only `archetype` and debug metadata differ. Real hole/ice layout generation is a later stage.
- `BattlePresenter` generates a new `GeneratedBoardChallenge` on every `start_level()` call (new battle, Retry, and Next Level all route through `start_level()`), using a seeded `_challenge_rng` so a fresh `generation_seed` is produced each time; the result is stored on `current_generated_challenge` and exposed via `get_current_generated_challenge()` plus a `generated_challenge_changed` signal for `GameScreen` and future consumers.
- `GameScreen` listens for `generated_challenge_changed` and, only when Debug Labels are enabled in Settings, appends `Challenge: <archetype>, seed: <seed>` to the status label. Normal gameplay is unaffected when Debug Labels are off.
- Nothing about current board generation, gameplay, damage, progression, saves, or UI changed for players; this stage is foundation-only.

## Stage 52: Active Cell Mask Core v0.1

Stage 52 is complete. It adds real active/inactive cell mask support to the board core so future holes can be genuine gameplay cells, while current gameplay remains visually unchanged because generated masks are still full 9x9 placeholders (Stage 51 behavior).

- `BoardModel` now tracks per-cell active state (board size stays 9x9, all cells active by default). New methods: `is_cell_active(cell)`, `set_cell_active(cell, active)`, `set_active_mask(mask)`, `get_active_cells()`, `get_inactive_cells()`, and `is_playable_cell(cell)` (bounds AND active). `is_inside(cell)` remains a bounds-only check — gameplay code must use `is_playable_cell()` instead. Deactivating a cell always forces its tile back to `EMPTY` and drops special tile metadata immediately; `set_tile()`/`set_special_tile()`/`swap_tiles()` all guard against inactive cells so "inactive cells always store EMPTY" holds everywhere. `duplicate_board()` copies tile data, special tile data, and the active mask. `has_empty_cells()` now only checks active cells so a masked board with holes doesn't look "broken" to `BoardResolver`.
- `set_active_mask(mask)` validates the mask against the `GeneratedBoardChallenge.board_mask` shape (an Array of `height` rows, each an Array of `width` bool-ish values); any mismatched/invalid mask safely falls back to a fully active board instead of corrupting state.
- `BoardGenerator.generate(width, height, mask)` gained an optional `mask` argument (plus a `generate_with_mask(mask, ...)` convenience wrapper): active cells receive generated tile types as before, inactive cells stay empty, and starting-match avoidance only looks at active neighbor cells. Calling `generate()` with no mask behaves exactly as before.
- `MatchFinder` now treats an inactive cell exactly like a boundary: it breaks the current horizontal/vertical run and is never added to a `MatchResult`, so matches can never "see through" a hole.
- `SwapResolver.try_swap()` rejects a swap when either cell is inactive, returning reason `"inactive_cell"` (out-of-bounds and non-adjacent rejections are unchanged).
- `SpecialTileResolver.get_line_clear_cells()` / `get_color_bomb_clear_cells()` / `collect_special_activation_cells()` all filter to `is_playable_cell()`, so line/color-bomb activation can never sweep through or activate a hole; `BoardResolver`/`StepwiseBoardResolver` special-creation now checks `is_playable_cell(creation_cell)` instead of just bounds. `BoosterResolver.get_hammer_cells()`/`get_rocket_cells()` do the same, and `resolve_targeted_booster()` rejects an inactive target cell up front.
- `BattlePresenter.start_level()` now generates `current_generated_challenge` before generating the board, and passes `current_generated_challenge.board_mask` into board generation: resolve level config -> generate `GeneratedBoardChallenge` -> generate `BoardModel` from its `board_mask` -> create battle state -> emit `generated_challenge_changed`. Since Stage 51 masks are still full 9x9, visible gameplay is unchanged.
- The debug status line now includes active-cell count, e.g. `Challenge: holes, seed: 12345, active: 81/81`, via `GeneratedBoardChallenge.get_debug_label()`.
- Gravity/refill for masked (non-rectangular) boards and real inactive-cell visuals are intentionally out of scope for this stage; `GravityResolver`/`BoardView` are unchanged.

## Stage 53: Gravity and Refill for Masked Boards v0.1

Stage 53 is complete. `GravityResolver` now makes inactive cells behave like walls for gravity/refill, while current full 9x9 gameplay stays visually identical because generated masks are still full-board placeholders.

- `GravityResolver.apply_gravity_and_refill()` no longer treats a column as one fall lane. For each column it first finds contiguous active-cell segments via `_get_active_segments_for_column(board, x)` (groups contiguous active cells top-to-bottom; an inactive cell always ends the current segment; only non-empty segments are returned, in top-to-bottom order), then resolves gravity and refill independently inside each segment via `_resolve_segment()`.
- Inside a segment, gravity collects non-empty tiles (and their special metadata) from that segment only, clears only that segment's cells, and writes the collected tiles back starting from the segment's bottom — preserving the same fall order as before. Tiles never move across an inactive cell or into another segment.
- Refill fills only the remaining empty cells at the top of that same segment, stopping at the segment's top edge; refilled tiles always get `special_data: null`. Inactive cells are never read from or written to by gravity/refill, so they stay `EMPTY` with no special metadata the whole time.
- `fall_movements` keeps its existing fields (`from`, `to`, `tile_type`, `special_data`, `fall_distance`) unchanged, and `refill_cells` keeps its existing fields (`spawn_index`, `to`, `tile_type`, `special_data`) unchanged, so `BoardAnimationSequenceBuilder`/`BoardView` need no changes. Both dictionaries also gained optional `segment_index`/`segment_top`/`segment_bottom` (and `refill_cells` a `segment_spawn_index`) for future segment-aware animation; existing readers ignore the extra keys.
- With today's always-full-9x9 mask, every column is exactly one segment spanning the whole board, so the segmented algorithm reduces to exactly the pre-Stage-53 whole-column algorithm — gravity, refill, and animation payloads are byte-for-byte equivalent and current gameplay does not change.
- No procedural holes, inactive-cell visuals, or ice mechanics were added in this stage; `BoardChallengeGenerator` still returns full 9x9 masks (Stage 54/55/56 remain future stages).

## Stage 53.1: Procedural Hole Generation Rules Foundation v0.1

Stage 53.1 is complete. It adds the rules, symmetry, placement, and validation layer Stage 54 will use to generate real procedural holes — nothing here enables real generated holes yet; `GeneratedBoardChallenge.board_mask` still returns full 9x9 masks.

- `HoleGenerationRules` (`scripts/game/config/hole_generation_rules.gd`) is a typed rules object: `min_block_width`/`min_block_height` (default 2/2), `max_block_width`/`max_block_height` (default 3/3), `min_active_cells` (default 65 of 81), `max_hole_cells` (default 16), `symmetry_mode` (default `"quadrant_mirror"`), `keep_center_active`, `require_connected_active_area`, `reject_enclosed_active_pockets`, and `reject_single_cell_holes` (all default `true`).
- `BoardMaskSymmetry` (`scripts/game/board/board_mask_symmetry.gd`) mirrors a cell `(x, y)` on a `width x height` board to `(x, y)`, `(width-1-x, y)`, `(x, height-1-y)`, `(width-1-x, height-1-y)` under `quadrant_mirror`, deduplicated; `get_mirrored_block_cells()` mirrors every cell of a rectangular block (not just its corner) so a whole hole block mirrors correctly into all four quadrants.
- `HoleBlockPlacer` (`scripts/game/board/hole_block_placer.gd`) exposes `try_place_hole_block(mask, top_left, block_width, block_height, rules)`, which safely punches a block and its mirrored copies into a `board_mask`-shaped Array only if: the block size respects `min_block_width/height`..`max_block_width/height`; the block and every mirrored copy stay inside bounds; the center cell stays active when `keep_center_active` is set; the projected active-cell count stays `>= min_active_cells`; the projected hole count stays `<= max_hole_cells`; and the board never goes all-hole. It mutates the mask in place and returns `true` only on success, leaving the mask untouched otherwise.
- `BoardMaskValidator` (`scripts/game/board/board_mask_validator.gd`) validates a mask against `HoleGenerationRules` and returns a `BoardMaskValidationResult` (`scripts/game/board/board_mask_validation_result.gd`) with `valid`, `reasons`, `active_cell_count`, `hole_cell_count`, `connected_component_count`, and `enclosed_active_cell_count`. It checks: mask shape is exactly 9x9; active/hole counts against `min_active_cells`/`max_hole_cells`; center-cell activity when `keep_center_active`; a single connected active component (4-neighbor up/down/left/right flood fill) when `require_connected_active_area`; no enclosed active pockets (active cells unreachable by flood fill from any board edge) when `reject_enclosed_active_pockets` — rejected with a reason, never auto-fixed; and no single-cell hole noise (a hole cell with no adjacent hole neighbor) when `reject_single_cell_holes`.
- `BoardMaskGenerator` (`scripts/game/board/board_mask_generator.gd`) exposes the Stage-54-facing `generate_holes_mask(rng, difficulty_budget, rules)` API. For this stage it always returns a validated full-active 9x9 mask; `rng`/`difficulty_budget` are accepted now so Stage 54 can start real block placement without a signature change.
- Nothing wires this new layer into `BattlePresenter`/`BoardChallengeGenerator`; `GeneratedBoardChallenge.board_mask` is untouched and battle generation behaves exactly as before this stage.

## Stage 54: Procedural Holes Generator v0.1

Stage 54 is complete. `holes`-archetype levels now generate real, safe, symmetrical inactive-cell masks using the Stage 53.1 rules/validator layer; `normal` and `ice` archetypes still return a full active 9x9 mask.

- `BoardMaskGenerator.generate_holes_mask_with_metadata(rng, difficulty_budget, rules)` (`generate_holes_mask()` remains a thin mask-only wrapper) builds a full active mask, then repeatedly builds a candidate by placing quadrant-mirrored hole blocks and validating it through `BoardMaskValidator`, returning the first valid candidate; if none validates within the attempt budget it falls back to a full active mask. `HoleGenerationRules` stays the single source of truth — the generator never hardcodes block sizes, cell limits, or symmetry mode outside what the rules object provides.
- Candidate blocks are 2x2, 2x3, or 3x2 (clamped to the rules' min/max block size), anchored only inside the board's upper-left quadrant (`x, y` in `[0, width/2)`), and mirrored via `BoardMaskSymmetry`/`HoleBlockPlacer` under `quadrant_mirror`. Anchoring strictly inside that quadrant means the mirrored copies can never reach the center row/column, so cell `(4, 4)` stays active by construction as well as by `HoleBlockPlacer`'s own `keep_center_active` check.
- Difficulty awareness: attempt budget comes from `difficulty_budget.validation_attempts` (falls back to 20), and the number of mirrored blocks attempted follows `difficulty_tier`/`layout_complexity` — early 1, medium 1-2, hard 2, very_hard 2-3. Rules always win: `HoleBlockPlacer` and `BoardMaskValidator` still enforce `min_active_cells`/`max_hole_cells` regardless of how many blocks difficulty asked for, so a requested block that would break a limit is simply skipped rather than applied.
- Fallback: if no candidate validates within the attempt budget, generation returns a full active 9x9 mask (also run through the validator) so battle startup can never receive a broken or invalid mask.
- `BoardChallengeGenerator.generate()` now routes by archetype: `normal`/`ice` build a full active mask via `BoardMaskGenerator.build_full_active_mask()`; `holes` seeds a `RandomNumberGenerator` from `generation_seed` (so a given seed reproduces the same hole layout) and calls `generate_holes_mask_with_metadata()`, writing the returned mask into `GeneratedBoardChallenge.board_mask` and the returned metadata into `GeneratedBoardChallenge.metadata`.
- Metadata now includes `generator_version`, `layout_source` (`"procedural_holes"` on success, `"fallback_full_board"` on fallback), `attempts_used`, `fallback_used`, `active_cell_count`, `hole_cell_count`, and `last_validation_reasons`.
- `GeneratedBoardChallenge.get_debug_label()` now reports hole count and fallback state too, e.g. `Challenge: holes, seed: 12345, active: 69/81, holes: 12` (with `, fallback: true` appended only when generation fell back to a full board).
- Board safety relies entirely on the existing Stage 52/53 core: inactive cells stay `EMPTY` with no special metadata, `MatchFinder`/`SwapResolver` ignore/reject them, `GravityResolver` treats them as walls, and `BoardGenerator` only fills active cells — nothing in the board core changed for this stage.
- Inactive-cell visuals remain minimal: `BoardView`/`TileView` already render an inactive `EMPTY` cell safely today (dark placeholder box, no icon, no crash) via existing `Dictionary.get()`-with-default lookups, so no visual code changed. Proper inactive-cell presentation is Stage 55.

## Stage 54.1: Hole Shape Variety and Center-Aware Generation v0.1

Stage 54.1 is complete. It fixes Stage 54's generator effectively only ever producing 2x2 corner blocks, and adds real 2x3/3x2 blocks plus center-aware shape presets. `BoardChallengeGenerator` archetype routing is unchanged (`normal`/`ice` full active, `holes` procedural) — this is a generation-quality patch, not a routing change.

- **Why Stage 54 mostly produced 2x2 layouts.** The default `max_hole_cells` was 16. A quadrant-mirrored 2x2 block anchored off-axis already produces 4 distinct mirrored copies (4 x 4 = 16 cells) — exactly the whole budget — so any second block, or any 2x3/3x2 block (4 x 6 = 24 cells), always exceeded `max_hole_cells` and was rejected by `HoleBlockPlacer`. The upper-left-quadrant-only anchor also never touched the center row/column, so no shape could ever appear near the board center.
- **Hole shape presets.** `HoleShapePreset` (`scripts/game/board/hole_shape_preset.gd`) defines five shape types as simple cell patterns (not art assets): `block_2x2`, `block_2x3`, `block_3x2`, `center_diamond`, `center_circle_light`. Block presets are plain rectangle sizes; center presets are small offset lists relative to the board center.
- **Real usable 2x3/3x2 generation.** `HoleGenerationRules.for_tier(tier)` (new) is the single source of truth for tier-scoped safe caps — `max_hole_cells`/`min_active_cells` now grow with difficulty tier (early 16/65, medium 20/61, hard 24/57, very_hard 28/53) instead of one fixed default. On top of that, `BoardMaskGenerator` places `block_2x2` with the original corner-quadrant anchor (4 mirrored copies, 16 cells — already fits every tier), but places `block_2x3`/`block_3x2` anchored to straddle a symmetry axis on their odd (3-cell) dimension instead: that axis's mirror maps the block onto itself, halving the mirrored footprint from 4 copies (24 cells) to 2 (12 cells), which comfortably fits even the early-tier budget.
- **Center-aware patterns.** `center_diamond` (a compact 4-cell "bowtie": a 2-cell north arm mirrored into a matching south arm) and `center_circle_light` (a rounder 12-cell accent: a wider north band mirrored into a matching south band) are built from a handful of offsets relative to `(4, 4)`, mirrored via the existing `BoardMaskSymmetry.get_mirrored_cells()` and applied via the new `HoleShapePlacer.try_place_shape(mask, cells, rules)` (a generalization of `HoleBlockPlacer` for arbitrary, non-rectangular cell lists). Both presets deliberately only touch the center cell's north/south orthogonal neighbors, never all four at once, so the center cell can sit inside the shape's silhouette while staying active (via `keep_center_active`) and connected to the rest of the board (no enclosed pocket, no disconnected island) — the exact center cell itself is never included in a shape for v0.1.
- **Difficulty-based shape pools.** `BoardMaskGenerator._resolve_shape_pool(tier)` weights shape choice by tier: early is mostly `block_2x2` with occasional `block_2x3`/`block_3x2`; medium adds `block_2x2`/`2x3`/`3x2` plus a rare `center_diamond`; hard includes both center presets alongside the blocks; very_hard leans further into `center_circle_light`, making combined multi-shape candidates (multiple shapes per candidate, validated as a whole) more likely.
- **Validator remains the final authority.** Every candidate — whatever mix of blocks/center shapes it contains — still goes through the unchanged `BoardMaskValidator`: 9x9 shape, active/hole cell counts, center-cell activity, single connected active area (4-neighbor flood fill), no enclosed active pockets, and no single-cell hole noise. Nothing about validation logic changed; only what gets validated got richer.
- **Metadata.** `GeneratedBoardChallenge.metadata` for a `holes` challenge now also includes `requested_shape_count` and `selected_shape_types` (the shape type strings actually placed successfully) alongside the existing `generator_version`, `layout_source`, `attempts_used`, `fallback_used`, `active_cell_count`, `hole_cell_count`, and `last_validation_reasons`.
- Stage 55 remains inactive-cell visual presentation in `BoardView`/`TileView`. Stage 56 remains the ice obstacle core.

## Stage 54.2: Gravity Pass-Through for Inactive Cells v0.1

Stage 54.2 is complete. `GravityResolver` no longer treats inactive cells as walls that split a column into independent segments (Stage 53 behavior); inactive cells are now pass-through gravity corridors — tiles fall straight through them into the next active cell below, but a tile can never come to rest inside one. Hole shape generation and archetype routing are unchanged; this stage only changes how gravity/refill behaves over an already-generated mask.

- `GravityResolver.apply_gravity_and_refill()` scans each column bottom-to-top, skipping inactive cells entirely (never read, never written — they are already guaranteed `EMPTY` by `BoardModel`'s own invariants) and collecting every active cell's tile/special data in order. Falling tiles are written back starting at the column's lowest active cell, so a tile above one or more inactive cells falls all the way down into the next active cell below the gap; remaining active cells nearer the top are refilled with brand-new tiles. Example: active `y0`(red)/inactive `y1`/inactive `y2`/active `y3`(cleared) resolves to red landing at `y3`, `y0` refilled, and `y1`/`y2` staying inactive and empty — exactly the pass-through behavior the stage asked for.
- Inactive cells stay safe throughout: they're never targeted by a fall or a refill, so they remain inactive, `EMPTY`, and free of special metadata after every gravity pass; `spawned_cells`/`refill_cells`/`fall_movements` can only ever reference active cells.
- Special tile metadata (H/V/B) moves with a falling tile exactly as before, including across an inactive gap: the source active cell is cleared, the target active cell receives the same special data, and refilled tiles always get `special_data: null`.
- `fall_movements` keeps its existing fields (`from`, `to`, `tile_type`, `special_data`, `fall_distance`) and gains two new optional ones: `crossed_inactive_cells` (the inactive cells strictly between `from` and `to` in that column) and `crosses_inactive_gap` (true when that list is non-empty) — prep for a later BoardView pass that hides a falling ghost while it crosses a hole instead of visibly sliding over it.
- `refill_cells` keeps its existing fields (`spawn_index`, `to`, `tile_type`, `special_data`) and gains `column_active_index`/`column_spawn_index` for future animation use. The Stage 53 `segment_index`/`segment_top`/`segment_bottom`/`segment_spawn_index` fields are removed (nothing read them, confirmed before removal) since "segment" is no longer the right mental model once inactive cells are pass-through rather than walls.
- With a full active mask (today's normal/ice gameplay, and still most of holes since masks stay small), every column has zero inactive cells, so the new algorithm reduces to exactly the original whole-column algorithm — gravity, refill, and animation payloads are unchanged for existing gameplay.
- Stage 55 will add inactive-cell visuals and pass-through fall animation polish (using `crossed_inactive_cells`/`crosses_inactive_gap` to hide the ghost mid-gap); hole shape generation and `normal`/`ice`/`holes` archetype routing were not touched in this stage.

## Stage 55: Inactive Cell Visual Presentation and Pass-Through Polish v0.1

Stage 55 is complete. Inactive cells (holes) now read as clearly not-playable instead of looking like ordinary empty tiles, no highlight/preview/effect ever renders on one, and a falling tile that crosses an inactive gap no longer visibly slides over it. Board/battle logic (hole generation, archetype routing, match/swap/booster/special rules, gravity/refill board state) is untouched — this stage is presentation-only.

- `TileView.set_cell_active(active: bool)` is the new persistent inactive-visual switch. While inactive, `_apply_visuals()` always renders the "hole" look — a mostly-transparent dark inset, no border, no icon, no marker text — regardless of `tile_type`/`special_tile_data`/selected/highlighted/invalid-feedback state, so no later `set_tile()`/`set_special_tile()`/`set_highlighted()`/etc. call can accidentally make an inactive cell look active again. Every transient `play_*` effect method (`play_flash`, `play_match_clear`, `play_special_clear`, `play_invalid_*`, `play_refill_appear`, ...) also no-ops while inactive, even if a caller targets one directly. Deactivating clears selection/highlight/invalid-feedback state, stops any in-flight tween, and sets `mouse_filter` to `MOUSE_FILTER_IGNORE`; `_on_gui_input()`/`_on_pressed()` also explicitly refuse to fire `tile_pressed`/`tile_drag_released` while inactive, so an inactive cell can never be tapped, selected, or dragged from — closing off misleading input feedback at the source rather than needing changes in `BoardInputController` or `GameScreen`. The 9x9 `GridContainer` layout is untouched (`visible` stays `true`; only the styling/icon/text change).
- `BoardView.refresh_all_tiles()` — the single choke point behind initial render, full refresh, restart/next-level/retry, and the post-overlay handoff in `apply_board_under_overlay()` — now calls `tile.set_cell_active(board.is_cell_active(cell))` before syncing tile/special/selected/highlighted/invalid state, so every render path picks up the mask automatically. A full active 9x9 board looks exactly as before.
- `BoardView.get_tile_views(cells)` now filters out inactive cells, which alone protects every caller that gathers tiles this way: selected/match/cascade/special-activation highlights, invalid-swap feedback, swap/match/special/refill feedback, and booster/special clear flashes. `flash_cells()` was switched to route through it too. Booster preview (`show_booster_target_preview()`) and booster impact-flash (`_play_booster_impact_flash()`) — which build independent `ColorRect` overlays rather than going through `TileView` — got their own explicit inactive-cell filters, so Hammer's 3x3 preview and Rocket's same-color preview never draw over a hole even though their source cell lists aren't pre-filtered.
- Overlay mode (the primary animated-turn rendering path) now leaves an inactive cell's real `TileView` visible instead of hiding it (`hide_real_board_tiles()`), and never builds a ghost for it (`build_full_board_ghosts()`, using a new `is_active` field on `BoardVisualSnapshot`) — since gravity/refill never target an inactive cell, its real "hole" look just stays correctly in place for the whole overlay session with no extra bookkeeping.
- Pass-through fall visuals: `_play_overlay_gravity_fall()` reads the Stage 54.2 `crosses_inactive_gap`/`crossed_inactive_cells` metadata, and any movement crossing a gap gets its own fade-out/jump/drop-in tween (`_animate_overlay_pass_through_fall()`) instead of a straight-line slide — the ghost fades out near the source, jumps straight to just above the target, then drops/fades in, so it's never drawn over the hole. Movements that don't cross a gap are completely unchanged. (The non-overlay `play_gravity_fall_animation()` fallback path — not used by the active animated-turn flow — was left as-is, since `GravityResolver` already guarantees it never receives inactive-cell data.)
- Refill visuals get a defensive check too: both `_play_overlay_refill()` and `play_refill_animation()` skip a refill entry whose target is inactive, even though `GravityResolver` already guarantees that never happens.
- Cleanup paths are unaffected: `clear_transient_visual_state()`/`force_reset_animation_state()` already end by calling `refresh_all_tiles()`, which re-applies the correct active state on every tile, so inactive-cell presentation survives valid turns, cascades, booster use, result overlay, retry, next level, return to LevelSelect, disabled animations, and reduced motion without any special-casing.
- Stage 56 remains the ice obstacle core.

## How To Open And Run

1. Open Godot 4.x.
2. Import or open this folder as a Godot project.
3. Run the project. The configured main scene is `res://scenes/app/App.tscn`.
4. The project opens directly on LevelSelect.
5. Choose an unlocked zone, then choose an unlocked level to open GameScreen directly (TeamSelect is skipped in the active flow).
6. Check the round modifier panel above the board to see the active battle's color damage buff (e.g. "Red Surge — Red crystals deal x3 damage").
7. Click one tile, then click a neighboring tile to attempt a swap, or drag/swipe from a tile toward a neighbor. Clearing crystals deals direct damage to the enemy, boosted for any color the current round modifier buffs.
8. Use the booster panel under the board: Hammer and Rocket enter targeting mode, tap a crystal to preview affected cells, then tap the same crystal again to apply; pressing the same selected booster cancels targeting. Time Freeze activates immediately with non-board feedback.
9. Win a battle to save completion, earn stars, see moves-left/unlock feedback, then choose Next Level, Retry, or Levels.
10. Press Settings in the LevelSelect top panel to open SettingsScreen and toggle Animations, Reduced Motion, Debug Labels, Music, and Sound Effects.
11. Press Levels/Back to return to LevelSelect and refresh saved completion, stars, next-level unlocks, and zones.

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

Run the Stage 39 asset binding tests with:

```bash
godot --headless --script res://scripts/tests/tile_view_asset_slot_test.gd
godot --headless --script res://scripts/tests/ui_asset_key_binding_test.gd
godot --headless --script res://scripts/tests/booster_button_asset_stub_test.gd
```

Run the active imageholder integration tests with:

```bash
godot --headless --script res://scripts/tests/battle_background_asset_integration_test.gd
godot --headless --script res://scripts/tests/enemy_panel_image_slot_test.gd
```

Run the audio foundation tests with:

```bash
godot --headless --script res://scripts/tests/audio_asset_catalog_test.gd
godot --headless --script res://scripts/tests/audio_manager_test.gd
godot --headless --script res://scripts/tests/audio_settings_integration_test.gd
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

Run the Stage 40 booster tests with:

```bash
godot --headless --script res://scripts/tests/booster_catalog_test.gd
godot --headless --script res://scripts/tests/booster_state_test.gd
godot --headless --script res://scripts/tests/booster_resolver_test.gd
godot --headless --script res://scripts/tests/booster_damage_test.gd
godot --headless --script res://scripts/tests/time_freeze_moves_test.gd
godot --headless --script res://scripts/tests/booster_panel_test.gd
godot --headless --script res://scripts/tests/game_screen_booster_flow_test.gd
```

Run the Stage 41 board animation foundation tests with:

```bash
godot --headless --script res://scripts/tests/board_animation_request_test.gd
godot --headless --script res://scripts/tests/board_animation_sequence_test.gd
godot --headless --script res://scripts/tests/board_animation_controller_test.gd
godot --headless --script res://scripts/tests/board_animation_sequence_builder_test.gd
godot --headless --script res://scripts/tests/game_screen_animation_flow_test.gd
godot --headless --script res://scripts/tests/booster_animation_flow_test.gd
```

Run the Stage 42 swap and match clear animation tests with:

```bash
godot --headless --script res://scripts/tests/board_swap_animation_test.gd
godot --headless --script res://scripts/tests/board_invalid_swap_animation_test.gd
godot --headless --script res://scripts/tests/board_match_clear_animation_test.gd
```

Run the Stage 43 gravity, refill and cascade animation flow tests with:

```bash
godot --headless --script res://scripts/tests/board_gravity_animation_data_test.gd
godot --headless --script res://scripts/tests/board_refill_animation_data_test.gd
godot --headless --script res://scripts/tests/board_cascade_animation_sequence_test.gd
godot --headless --script res://scripts/tests/board_gravity_animation_test.gd
godot --headless --script res://scripts/tests/board_refill_animation_test.gd
godot --headless --script res://scripts/tests/game_screen_cascade_animation_flow_test.gd
godot --headless --script res://scripts/tests/booster_gravity_refill_animation_test.gd
```

Run the Stage 44 damage particle and enemy hit feedback tests with:

```bash
godot --headless --script res://scripts/tests/damage_particle_event_builder_test.gd
godot --headless --script res://scripts/tests/battle_effect_controller_test.gd
godot --headless --script res://scripts/tests/enemy_panel_hit_feedback_test.gd
godot --headless --script res://scripts/tests/game_screen_damage_effect_flow_test.gd
godot --headless --script res://scripts/tests/booster_damage_effect_flow_test.gd
```

Run the Stage 34 direct balance tests with:

```bash
godot --headless --script res://scripts/tests/direct_balance_config_test.gd
godot --headless --script res://scripts/tests/direct_enemy_scaling_balance_test.gd
godot --headless --script res://scripts/tests/direct_level_balance_test.gd
godot --headless --script res://scripts/tests/round_modifier_balance_test.gd
```

Run the Stage 45-47 animation timeline and visual stability tests with:

```bash
godot --headless --script res://scripts/tests/board_visual_snapshot_test.gd
godot --headless --script res://scripts/tests/board_overlay_mode_test.gd
godot --headless --script res://scripts/tests/board_animation_cleanup_test.gd
godot --headless --script res://scripts/tests/swap_no_double_layer_test.gd
godot --headless --script res://scripts/tests/cascade_visual_stability_test.gd
godot --headless --script res://scripts/tests/real_tile_position_lock_test.gd
godot --headless --script res://scripts/tests/battle_effect_cleanup_test.gd
godot --headless --script res://scripts/tests/game_screen_damage_effect_flow_test.gd
godot --headless --script res://scripts/tests/booster_damage_effect_flow_test.gd
```

## Next Planned Stages

- Stage 26-30 block is complete. Stage 31 (hero portrait buttons and ability bars) is complete. Stage 32 (hero systems freeze and direct match damage foundation) is complete. Stage 33 (round modifiers and color damage rules) is complete. Stage 34 (direct match-3 balance pass) is complete. Stage 35 (direct LevelSelect startup and simplified UX polish) is complete. Stage 36 (ImageSlot asset placeholder pipeline) is complete. Stage 37 (asset loading integration for active imageholders) is complete. Stage 38 (AudioManager foundation) is complete. Stage 39 (Complete AssetKey texture binding) is complete. Stage 40 (Booster system foundation) is complete. Stage 41 (Board animation foundation) is complete. Stage 42 (Swap and match clear animations) is complete. Stage 43 (Gravity, refill and cascade animation flow) is complete. Stage 44 (Damage particles and enemy hit feedback) is complete. Stage 45 (Gameplay animation timeline stabilization) is complete. Stage 46 (Stepwise board resolution animation pipeline) is complete. Stage 47 (Animation QA and board visual stability pass) is complete. Stage 48 (Special tile activation animations) is complete. Stage 49 (Booster targeting and booster animation polish) is complete. Stage 49.1 (Stronger booster affected-cell preview) is complete. Stage 50 (Result screen and level flow UX polish) is complete. Stage 51 (Procedural challenge archetype foundation) is complete. Stage 52 (Active cell mask core) is complete. Stage 53 (Gravity and refill for masked boards) is complete. Stage 53.1 (Procedural hole generation rules foundation) is complete. Stage 54 (Procedural holes generator) is complete. Stage 54.1 (Hole shape variety and center-aware generation) is complete. Stage 54.2 (Gravity pass-through for inactive cells) is complete. Stage 55 (Inactive cell visual presentation and pass-through polish) is complete.
- Next roadmap stages (not yet started): Stage 56 an ice obstacle core (frozen cell state, unfreeze-on-match rules), generated challenge validation with retry/fallback generation beyond the current full-board fallback, UX polish for archetype-specific board presentation, and balance passes once real archetypes affect difficulty.
- Isolated Yandex Games platform adapter under `scripts/platform/` when explicitly requested.
