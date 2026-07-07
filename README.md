# Tri V Ryad

Tri V Ryad is a Godot 4.x match-3 battle game intended for Yandex Games and Web-first release targets.

The project is currently through Stage 61: Main Menu Restoration v0.1. `MainMenuScreen` is restored as the app's startup screen and top-level hub: App startup now shows MainMenu first instead of jumping straight to LevelSelect. MainMenu has four primary buttons — Играть (Play), Выбрать уровень (Level Select), Магазин (Shop), and Настройки (Settings) — plus the existing hidden Heroes entry (still gated by `FeatureFlags.HERO_SYSTEMS_ENABLED`). Играть resolves the highest currently-unlocked level via a new `PlayLevelResolver` and opens `GameScreen` directly; Выбрать уровень opens `LevelSelectScreen`, which now has a Back button returning to MainMenu; Магазин opens a new placeholder `ShopPlaceholderScreen` ("Магазин" / "Скоро будет доступно" / "Назад", no economy logic); Настройки opens the existing `SettingsScreen`, whose Back button now returns to whichever screen opened it (MainMenu or LevelSelect). See the Stage 61 section below for full navigation wiring details.

The project was previously through Stage 60.1: Fixed Enemy HP and Move Curve v0.1. Direct-mode battles now use a stable fixed baseline instead of Stage 34's per-level curves: every enemy enters a battle with 130 HP (`DirectBattleBalance.FIXED_ENEMY_HP`, applied in `EnemyScalingResolver`, `EnemyCatalog` source data untouched), and moves follow a linear curve (`DirectBattleBalance.get_moves_for_level()`, wired through `LevelCatalog`) starting at 30 on level 1, dropping by 1 per level, and floored at 20 from level 11 onward. See the Stage 60.1 section below for the full config/wiring details; level boosts (color x2, match-size x2/x3, +3 moves) are planned for Stage 60.2/60.3 and are not implemented yet.

The project was previously through Stage 58: Deterministic 500-Level Layout Database v0.1. Levels 1-500 now load a fixed, pre-generated, pre-validated board/ice layout from `data/levels/deterministic_level_layouts.json` (via `LevelLayoutDatabase`) instead of re-rolling procedural generation on every playthrough; `BoardChallengeGenerator.generate()` checks the database first and only falls back to the existing procedural generators (still fully intact, and still what `tools/generate_deterministic_levels.gd` used offline to build every stored layout) for a level outside 1-500. See the Stage 58 section below for the full data model, mask encoding, validation, and loader details.

The project was previously through Stage 57.5: Cell-Anchored Ice Overlays and Per-Step Ice Sync v0.1. Ice is a cell obstacle, not part of a tile, so its overlay-mode visual is now a separate, cell-anchored ghost (`BoardView._overlay_obstacle_ghosts`, built by `_create_obstacle_overlay_ghost()`) rather than a child of the moving tile ghost — previously `IceOverlay`/`IceOverlayInner` lived inside the ghost `create_tile_ghost_from_data()` built for whatever tile occupied that cell, so ice visibly "fell" along with the crystal during gravity/refill even though the underlying obstacle never actually moves. Tile ghosts now carry tile color/icon/special marker only. Ice visuals also now update immediately after each ice event instead of only once the whole animated sequence finishes: `BoardAnimationController._play_ice_event_request()` passes each damaged cell's `new_layers` through to `BoardView.play_ice_damage_animation()`, whose flash tween (real board via `TileView.play_ice_damage(new_layers)`, or overlay via `_play_overlay_ice_damage()`) settles directly into the reduced-layer state in its completion callback — so strong ice visibly becomes weak right after the hit that damages it, and weak ice's overlay disappears right after the hit that breaks it (`play_ice_break()`/`_play_overlay_ice_break()`), across first match clear, cascades, boosters, and special clears alike. New `BoardView.sync_overlay_ice_event()`/`update_cell_obstacle_visual()`/`update_overlay_obstacle_ghost()`/`remove_overlay_obstacle_ghost()` are the sync API this relies on, reusing `TileView.resolve_ice_overlay_color()`/`resolve_ice_overlay_inner_color()` so overlay-mode ice always matches the real board's (and the Stage 57.3 debug filter's) colors with no duplicated color logic. Final board handoff (`apply_board_under_overlay()`/`clear_animation_layer()`) still frees every temporary obstacle ghost and re-syncs real `TileView`s from the authoritative `BoardModel`. Ice generation, rectangular cluster rules, weak/strong variants, and all ice damage rules are unchanged — this is a presentation/animation-synchronization patch only. Building on Stage 57.4 (non-center ice generation places exactly one complete mirrored rectangle per candidate, atomically — see `IcePatternGenerator._build_rectangular_candidate()`/`_analyze_quadrant_rectangles()` — with an optional center seed dropped rather than the rectangle ever truncated, and an enlarged 48-cell absolute cap for a clean single rectangle), Stage 57.3 (`TileView.ICE_DEBUG_VISIBILITY_ENABLED`, a temporary strong white/blue debug overlay for manual density verification), Stage 57.2 (every `ice`-archetype level targets a dense 32-40 frozen-cell layout, split into weak/strong cycle variants by `level_number % 5`), Stage 57.1 (center/symmetric `IceShapePreset` shapes), and Stage 57 (`ice`-archetype levels generate real frozen cells; `normal`/`holes` unchanged, not combined with ice). Building on Stage 56's ice obstacle core: `BoardModel` has a real ice/blocker obstacle layer (`CellObstacleType`, `get_cell_obstacle()`/`set_cell_obstacle()`/`damage_cell_obstacle()`/`clear_cell_obstacle()`/`get_ice_cells()`) kept fully separate from tile type, special tile metadata, and the active/inactive mask — normal ice takes 1 hit, double ice takes 2, an inactive cell can never carry one. A new `IceDamageResolver` damages ice on both a directly cleared iced cell and its orthogonal (non-diagonal) neighbors, deduplicated so one clear event never hits the same ice cell twice, wired into normal/cascade match clears, line specials, color bombs, Hammer, and Rocket Barrage. `TileView`/`BoardView` render a placeholder frost overlay (stronger/thicker for double ice) that never appears on inactive cells, plus dedicated ice damage/break animations that play before the tile clear fade; overlay-mode ghosts and `BoardVisualSnapshot` carry obstacle data too. `holes`-archetype levels can place controlled holes at the exact board center for medium/hard/very_hard difficulty tiers (`center_dot_plus`/`center_diamond_hole`/`center_circle_hole_light`, alongside the existing off-center `center_diamond`/`center_circle_light`/`block_2x2`/`block_2x3`/`block_3x2` presets), with `HoleGenerationRules.for_tier()` relaxing `keep_center_active` per tier so `BoardMaskValidator` still remains the final authority over every generated mask. Hero/RPG systems (TeamSelect, hero party UI, hero abilities/charge/lane damage, hero upgrades) remain frozen and hidden from the active flow via `FeatureFlags.HERO_SYSTEMS_ENABLED := false`, and gameplay deals direct match-3 damage to the enemy. Each battle selects one positive round modifier that multiplies damage for matched cells of specific colors, while Stage 34 direct balance controls moves and enemy HP. The active flow remains App startup -> LevelSelect -> GameScreen -> LevelSelect, with Settings opened from the LevelSelect top panel; MainMenu remains in the project as inactive legacy/future code but is skipped by normal startup and play. The app shell, a level-select hub with numbers-only labels for `level_1` through `level_100` grouped into 10 locked zones, a shared 10-enemy base roster with battle-start random enemy selection and direct-mode HP scaling, ImageSlot-backed battle background and enemy visual placeholders, the safe cached `ImageSlot`/`GameAssetCatalog` placeholder image pipeline, the safe cached `AudioAssetCatalog`/`AudioManager` no-op audio foundation, three battle-local boosters (Hammer, Time Freeze, Rocket Barrage) with selected/used states and stronger white affected-cell targeting previews, the Stage 46-49 stepwise board animation pipeline, and the Stage 50 victory/defeat result flow all remain active for a vertical 9:16 game. `AnimatedTurnFlow` is the active owner of stepwise swap, clear, special creation, special activation, gravity/refill, cascade, booster activation/clear, and final-board handoff visuals during animated turns; `TurnFeedbackPresenter` is limited to text/status/enemy feedback for valid animated turns and must not replay board movement, clear, special activation, booster board visuals, highlight, refill, or full-board refresh effects after `AnimatedTurnFlow` has already handled them. Result overlays appear only after board animation, damage particles, enemy hit feedback, cleanup, and progress save/update finish. Hero code, MainMenu, TeamSelect, and UpgradeScreen remain in the project (not deleted) for a future revisit.

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
- `MainMenuScreen` is the active app startup screen and top-level hub, with Играть, Выбрать уровень, Магазин, and Настройки buttons (plus a hidden Heroes entry gated by `FeatureFlags.HERO_SYSTEMS_ENABLED`).
- A scrollable `LevelSelectScreen` hub with a Back button (to MainMenu), a Settings button, a zone selector for the 100-level campaign, numbers-only labels, lock/completion/star state, and direct routing to `GameScreen`.
- A `ShopPlaceholderScreen` reachable from MainMenu's Магазин button, showing "Магазин" / "Скоро будет доступно" / "Назад" with no economy logic.
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
- Stage 55 remains inactive-cell visual presentation in `BoardView`/`TileView`. Stage 56 adds the ice obstacle core (see the Stage 56 section below).

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

## Stage 55.1: Inactive Overlay Stability and Center-Hole Generation Unlock v0.1

Stage 55.1 is complete. It fixes an overlay-mode visual bug where inactive cells could stretch/merge into tall dark areas during animated turns, and unlocks controlled procedural holes at the board center for medium/hard/very_hard difficulty tiers.

- **The overlay bug.** Stage 55 left an inactive cell's real `TileView` visible while hiding active real tiles during overlay mode. `GridContainer` recomputes its row/column sizing from only its *visible* children — with most of a row/column hidden (active tiles), the still-visible inactive cell would stretch to absorb the freed space instead of keeping its own cell shape, exactly the "merge into tall dark columns" symptom.
- **The fix.** `hide_real_board_tiles()` now hides every real tile uniformly again (active or inactive), keeping the `GridContainer`'s visible-child set consistent. `build_full_board_ghosts()` gives every cell — including inactive ones — its own ghost in `animation_layer` (a plain absolutely-positioned `Control`, immune to `GridContainer` resizing): active cells get the normal tile ghost as before, and inactive cells get a new stable placeholder (`create_inactive_hole_ghost()`) using the same visual language as `TileView`'s inactive look. Since gravity/refill never target an inactive cell, its placeholder never animates — it just sits in place, stable, for the whole overlay session. `exit_animation_overlay_mode()` now also calls `refresh_all_tiles()` so every real tile (including inactive ones) is guaranteed correctly synced the moment it becomes visible again.
- **Pass-through fall visuals preserved.** The Stage 55 `crosses_inactive_gap` fade-out/jump/drop-in behavior in `_play_overlay_gravity_fall()`/`_animate_overlay_pass_through_fall()` is untouched — it already only ever operates on active-cell ghosts, so it's naturally unaffected by the inactive-ghost fix.
- **Center-hole generation unlock.** `HoleGenerationRules.for_tier(tier)` now also sets `keep_center_active` per tier — `true` for `early` (unchanged), `false` for `medium`/`hard`/`very_hard`. This is what lets new "hole" center shape presets actually validate when the shape pool picks one; rectangular corner/axis-straddling blocks are provably incapable of ever reaching the exact center cell (Stage 54.1 geometry), so the flag has no effect on their behavior — center protection is effectively shape-dependent even though the mechanism is a tier-scoped rule value rather than a per-call override.
- **New center-hole shapes.** `HoleShapePreset` gained three presets that deliberately *do* include the exact center cell `(4, 4)`, each one connected hole cluster (never an isolated single cell): `center_dot_plus` (5 cells — center + its 4 radius-1 orthogonal neighbors), `center_diamond_hole` (9 cells — the same cross extended to radius 2 in each direction), and `center_circle_hole_light` (9 cells — a solid 3x3 block centered on the center cell). The existing `center_diamond`/`center_circle_light` presets are unchanged and still never touch the exact center cell.
- **Shape selection by difficulty.** `BoardMaskGenerator._resolve_shape_pool()`: `early` still has no center shapes at all; `medium` adds a rare `center_diamond_hole` alongside the existing rare `center_diamond`; `hard` adds `center_dot_plus`, `center_diamond_hole`, and `center_circle_hole_light` alongside the existing `center_diamond`/`center_circle_light`; `very_hard` weights the center-hole presets more heavily (duplicated pool entries) so they're more likely to be picked.
- **Validator untouched.** `BoardMaskValidator` was not modified at all — it still rejects disconnected active area, enclosed active pockets, single-cell hole noise, too many holes, and invalid mask shape exactly as before; only the `keep_center_active` value it's handed (via the tier-scoped rules) changed. If a center-hole shape can't find a valid placement, `HoleShapePlacer`/`BoardMaskGenerator`'s existing retry loop and full-active fallback handle it exactly like any other unlucky attempt — center-hole shapes are never forced through.
- **Metadata.** `GeneratedBoardChallenge.metadata` for a `holes` challenge gained `center_cell_inactive` (whether the final mask's exact center cell ended up a hole) and `center_axis_holes_count` (how many distinct cells along the center row/column are holes), alongside the existing `selected_shape_types`, `fallback_used`, and `last_validation_reasons`.
- Board gameplay rules (match/swap logic, gravity board-state logic, booster rules, special tile rules, result flow) are unchanged. Stage 56 adds the ice obstacle core (see below).

## Stage 56: Ice Obstacle Core v0.1

Stage 56 is complete. It adds the core ice/blocker obstacle layer, ice damage rules, presentation, and `frozen_cells` wiring — procedural ice generation and new ice-specific win goals remain future work (Stage 57+).

- **`CellObstacleType`** (`scripts/game/board/cell_obstacle_type.gd`) defines `NONE`/`ICE` as a small, extensible board obstacle type layer for future blockers/crates/chains/locks. Ice is deliberately not a `TileType` — it's a separate layer placed on top of an active cell.
- **`BoardModel` obstacle storage.** Two new sparse dictionaries (`Vector2i -> obstacle type`, `Vector2i -> layer count`), mirroring the existing `_special_tiles` pattern. New API: `get_cell_obstacle(cell)`, `has_cell_obstacle(cell)`, `is_cell_iced(cell)`, `get_cell_obstacle_layers(cell)`, `set_cell_obstacle(cell, obstacle_type, layers := 1)`, `clear_cell_obstacle(cell)`, `damage_cell_obstacle(cell, amount := 1)` (returns `{cell, obstacle_type, previous_layers, new_layers, broken}`, or `{}` if the cell has no obstacle), and `get_ice_cells()`. Normal ice is `layers = 1`, double ice is `layers = 2`; `damage_cell_obstacle()` reduces layers by `amount` and removes the obstacle once it reaches 0. An inactive cell can never carry an obstacle — `set_cell_obstacle()` refuses one, and `set_cell_active(cell, false)` clears any existing obstacle the same way it already clears tile/special data. `duplicate_board()` copies both obstacle dictionaries. Obstacles are pinned to the cell, not the tile: `swap_tiles()`/`GravityResolver` never touch them, so ice never moves, and refilled tiles never create one.
- **`GeneratedBoardChallenge.frozen_cells` wiring.** `BoardModel.apply_frozen_cells(frozen_cells)` accepts either a bare `Vector2i` (1-layer ice) or a `{"cell": Vector2i, "layers": int}` Dictionary per entry, silently ignoring invalid/out-of-bounds/inactive cells. `BattlePresenter.start_level()` calls it right after generating the playable board. `frozen_cells` is still always `[]` today (`BoardChallengeGenerator` doesn't populate it yet), so this stage changes no visible gameplay; Stage 57's procedural ice generator only needs to fill the array, not touch this wiring.
- **`IceDamageResolver`** (`scripts/game/board/ice_damage_resolver.gd`) is the single place ice-damage rules live. For a batch of cleared cells, it collects every cell that is either cleared directly (and iced) or an orthogonal (up/down/left/right only, never diagonal) neighbor of a cleared cell (and iced), deduplicated into one target set — so a cell that qualifies both ways, or is hit by two matches in the same event, only loses one ice layer for that event. `apply_ice_damage(board, cleared_cells)` mutates and returns one event per damaged cell; `preview_ice_damage(board, cleared_cells)` predicts the same outcome without mutating, for presentation flows that must know the result before the board changes.
- **Wired into every clear source.** `BoardResolver` (non-animated resolve) and `BoosterResolver.resolve_targeted_booster()` (Hammer, Rocket Barrage) call `apply_ice_damage()` right after `board.clear_cells()`. `StepwiseBoardResolver.build_clear_step()` calls `preview_ice_damage()` before the board is mutated (so `AnimatedTurnFlow` can play ice feedback before the tile clear fade), and `apply_clear_step()` then calls `apply_ice_damage()` to actually mutate. Since normal matches, cascades, line specials, and color bombs all funnel into the same `cleared_cells` list before reaching `board.clear_cells()`, all of them get ice damage for free through this one wiring.
- **Payload.** `BoardResolveResult`/`BoardResolveStep`/`BoosterResolveResult` all gained an `ice_events` field (each entry: `cell`, `obstacle_type`, `previous_layers`, `new_layers`, `broken`) plus derived `ice_damaged_cells`/`ice_broken_cells` cell lists, included in their `to_dictionary()` output. `TurnPresentationData` carries the first step's `ice_events` the same way it already carries `special_cleared_cells`.
- **Animation request.** A new `BoardAnimationRequest.TYPE_ICE_EVENT` carries an `ice_events` payload; `BoardAnimationSequenceBuilder` queues it immediately before the matching `TYPE_MATCH_CLEAR`/`TYPE_BOOSTER_CLEAR`/`TYPE_CASCADE_STEP` request in every sequence builder (`build_clear_sequence()`, `build_from_turn_presentation()`, `build_from_booster_result()`, `build_booster_activation_and_clear_sequence()`, `_add_cascade_step_requests()`), matching the expected visual order (ice feedback, then tile clear, then gravity/refill). `BoardAnimationController` splits a request's events into "damaged" (still icy) and "broken" (ice removed) cells and calls `BoardView.play_ice_damage_animation()`/`play_ice_break_animation()` respectively. If animations are disabled, `BoardModel`'s obstacle state has already updated synchronously regardless of any animation step.
- **`TileView` ice overlay.** Two child `ColorRect` overlays (drawn on top of the Button's own icon/text since children paint after their parent) render a light blue/white translucent frost for normal ice, with a second inset overlay layered on for double ice so it reads visually "thicker"; both are hidden while the cell is inactive. `set_cell_obstacle(obstacle_type, layers)` syncs the overlay from board state; `play_ice_damage()` flashes it, `play_ice_break()` fades it out — both no-op on an inactive cell and are expected to be called before the caller syncs the new (already-changed) obstacle state, matching how existing `play_match_clear()`/`play_special_clear()` feedback already works.
- **`BoardView` rendering.** `refresh_all_tiles()` — the existing choke point behind initial render, full refresh, restart/next-level/retry, and the post-overlay handoff — now also calls `tile.set_cell_obstacle(board.get_cell_obstacle(cell), board.get_cell_obstacle_layers(cell))`. `create_tile_ghost_from_data()` gained optional `obstacle_type`/`obstacle_layers` parameters that add the same overlay to an animation-layer ghost; `build_full_board_ghosts()` passes obstacle data from the snapshot for every active-cell ghost. `play_ice_damage_animation()`/`play_ice_break_animation()` dispatch to real `TileView`s outside overlay mode, or to overlay-ghost-specific tweens (`_play_overlay_ice_damage()`/`_play_overlay_ice_break()`) in overlay mode — the break variant frees the ghost's overlay node once faded so no stale overlay lingers on a ghost reused by later gravity/refill animation in the same session.
- **`BoardVisualSnapshot`** gained `obstacle_type`/`obstacle_layers` fields per cell (read via new `TileView.get_obstacle_type()`/`get_obstacle_layers()` getters), following the same `has_method()`-guarded optional-field pattern as the existing `is_active` field.
- No procedural ice placement, no new ice-specific win goals, and no changes to enemy damage/stars/result flow/boosters/special tile rules beyond the ice-obstacle interactions above. Stage 57 adds procedural `frozen_cells` generation for ice-archetype levels (see below).

## Stage 57: Procedural Ice Generator v0.1

Stage 57 is complete. `ice`-archetype levels now generate real, readable frozen-cell layouts instead of always returning an empty `frozen_cells` array; `normal` and `holes` archetypes are unchanged, and this stage does not combine holes and ice on the same board.

- **`IceGenerationRules`** (`scripts/game/config/ice_generation_rules.gd`) is a typed rules object, mirroring `HoleGenerationRules`' shape: `min_ice_cells`/`max_ice_cells`, `max_double_ice_cells`, `double_ice_chance`, `cluster_size_min`/`cluster_size_max`, `allowed_pattern_types`, and `validation_attempts`. `IceGenerationRules.for_tier(tier)` is the single source of truth for the tier -> ice-budget mapping: `early` is 3-6 cells, no double ice, `small_cluster` only; `medium` is 5-9 cells, up to 1 double-ice cell at a 15% chance, adds `edge_patch`; `hard` is 7-12 cells, up to 3 double-ice cells at 30%, adds `center_patch`; `very_hard` is 9-16 cells, up to 5 double-ice cells at 45%, adds `diagonal_band`.
- **`IcePatternGenerator`** (`scripts/game/board/ice_pattern_generator.gd`) exposes `generate_frozen_cells(rng, board_mask, difficulty_budget, rules) -> {"frozen_cells", "metadata"}`. It builds a candidate by repeatedly picking a pattern type from `rules.allowed_pattern_types` and placing it until the target ice count (randomized within `min_ice_cells`/`max_ice_cells`) is reached or placement attempts run out, then validates the candidate and retries up to `rules.validation_attempts` times before falling back to no ice at all.
- **Readable patterns, not noise.** Four pattern types, each a small readable shape rather than scattered single cells: `small_cluster` (a short random-walk blob grown orthogonally from a random active anchor), `edge_patch` (a short strip hugging one of the four board edges), `center_patch` (a small patch grown outward from the board center), and `diagonal_band` (a short diagonal line of cells). Early levels only ever pick `small_cluster` with a small cluster size; medium/hard/very_hard add more pattern types, larger cluster sizes, and can place more than one pattern per board, following the same "richer pool at higher tiers" approach `BoardMaskGenerator`'s hole shape pool already uses.
- **Active-cell safety.** Every pattern generator only ever proposes cells present in the board mask's active-cell list; `_build_candidate()` also de-duplicates via a `Dictionary`-as-set so the same cell is never counted twice even if two patterns overlap. `IceGenerationRules`/`IcePatternGenerator` never need holes-style connectivity/enclosed-pocket checks, since ice is an overlay obstacle (Stage 56) that never removes a cell from play the way a hole does.
- **1-layer and 2-layer output.** Output matches `BoardModel.apply_frozen_cells()`'s existing contract exactly: a bare `Vector2i` for 1-layer ice, or `{"cell": Vector2i, "layers": 2}` for double ice. `_assign_double_ice()` rolls `rules.double_ice_chance` per placed cell up to a running `rules.max_double_ice_cells` budget, so double ice never exceeds the cap regardless of how many cells rolled true.
- **Validation and fallback.** Before returning, a candidate is checked for: every cell inside the board and active, no duplicate cells, ice count within `min_ice_cells`/`max_ice_cells`, double-ice count within `max_double_ice_cells`, and total ice cells not exceeding half the active board (a hardcoded saturation ceiling independent of whatever a custom rules object's `max_ice_cells` allows). If no candidate validates within `validation_attempts`, generation returns an empty `frozen_cells` array with fallback metadata rather than ever failing battle startup.
- **`BoardChallengeGenerator` routing.** `normal` -> full active mask, empty `frozen_cells` (unchanged). `holes` -> procedural holes mask via `BoardMaskGenerator`, empty `frozen_cells` (unchanged; holes and ice are not mixed this stage). `ice` -> full active mask via `BoardMaskGenerator.build_full_active_mask()`, plus real `frozen_cells` from `IcePatternGenerator.generate_frozen_cells()`, seeded from a `RandomNumberGenerator` keyed off `generation_seed` (reproducible per seed, matching how `holes` already seeds its mask RNG).
- **Metadata/debug.** `GeneratedBoardChallenge.metadata` for an `ice` challenge gains `generator_version`, `layout_source` (`"procedural_ice"`/`"fallback_no_ice"`), `selected_ice_patterns`, `ice_cell_count`, `double_ice_cell_count`, `ice_attempts_used`, `ice_fallback_used`, and `ice_validation_reasons`. `GeneratedBoardChallenge.get_debug_label()` appends `, ice: X, double: Y` (and `, ice_fallback: true` on fallback) to its existing `Challenge: ice, seed: ..., active: ..., holes: ...` label.
- **Stage 56 ice core unchanged.** Placement only calls `BoardModel.apply_frozen_cells()` (already wired in `BattlePresenter.start_level()`); 1-layer/2-layer break-on-hit counts, direct-clear damage, adjacent orthogonal-clear damage, per-event dedup, and "inactive cells can't carry ice" all still work exactly as Stage 56 built them — this stage only feeds real data into that existing pipeline.
- No new ice-specific win goals, no victory-condition changes, and no changes to stars, rewards, the result overlay, enemy damage, moves, or boosters beyond what Stage 56 already added.
- Stage 58 remains challenge cycle integration and tuning once real archetypes are live across the campaign.

## Stage 57.1: Symmetric Ice Patterns and Stronger Ice Visuals v0.1

Stage 57.1 is complete. It improves Stage 57's ice generation quality (symmetrical, shape-based placement closer to how holes are generated, plus a real chance of center ice) and ice readability (stronger, more distinct normal/double ice colors). Archetype routing and Stage 56's ice damage rules are unchanged.

- **`IceShapePreset`** (`scripts/game/board/ice_shape_preset.gd`) is a new shape-name-and-geometry helper, mirroring `HoleShapePreset`. Center presets are offset lists relative to the exact board center cell, already self-symmetric about that one cell by construction (no `BoardMaskSymmetry` mirroring pass needed, unlike holes' center presets): `center_square_light` (a solid 3x3 square, 9 cells), `center_diamond_light` (center + 4 orthogonal neighbors, 5 cells), `center_square_heavy` (the light square plus 4 radius-2 arm cells, 13 cells), `center_diamond_heavy` (the light diamond's cross extended to radius 2, 9 cells). Mirrored-block presets (`mirrored_block_2x2`/`mirrored_block_2x3`/`mirrored_block_3x2`) are plain rectangle sizes; `IcePatternGenerator` places one copy and mirrors it across a single random axis (horizontal or vertical) rather than `BoardMaskSymmetry`'s full 4-way quadrant mirror, since a full 4-copy mirror would blow past ice's much tighter per-tier cell caps.
- **50% center-ice chance.** `IceGenerationRules.center_ice_chance` (0.35 early, 0.5 medium/hard/very_hard) is rolled once per `generate_frozen_cells()` call; on success, `IcePatternGenerator` tries every shape in `allowed_center_shape_types` (in a seed-reproducible random order) and returns the first whose active-filtered cell count is non-empty and fits under both `max_ice_cells` and the new `max_center_ice_cells` cap. If no allowed center shape fits or validates, generation falls straight through to the symmetric/scattered path below — the roll never blocks a battle from getting ice.
- **Symmetric non-center ice.** When center ice isn't attempted (or fails), `IcePatternGenerator` now prefers `allowed_symmetric_shape_types` (mirrored 2x2/2x3/3x2 blocks) over the original Stage 57 scattered patterns whenever `prefer_symmetry` is set and the pool isn't empty — early tier still has no symmetric shapes configured, so it behaves exactly as Stage 57 did (small, sparse, non-symmetric clusters only); medium adds mirrored 2x2, hard/very_hard add all three mirrored block sizes.
- **Validation and active-cell safety unchanged in spirit.** Both new paths (center shapes and mirrored blocks) still only ever propose active cells, still get deduplicated through the same `Dictionary`-as-set mechanics, and still go through the exact same `_validate()` (in-bounds+active, no duplicates, count caps, double-ice cap, saturation ceiling) as Stage 57's scattered patterns — nothing about validation semantics changed, only what gets validated got richer.
- **1-layer/2-layer output unchanged.** All three generation paths (center, symmetric, scattered) funnel through the same `_assign_double_ice()` used since Stage 57, so output is still a bare `Vector2i` for 1-layer ice or `{"cell": Vector2i, "layers": 2}` for double ice, still capped by `max_double_ice_cells`.
- **Stronger, more distinct ice visuals.** `TileView.ICE_OVERLAY_COLOR` is now a strong near-white frost (readable on every tile color instead of a light, easy-to-miss tint); `TileView.ICE_OVERLAY_COLOR_DOUBLE`/`ICE_OVERLAY_INNER_COLOR` are now a strong, clearly blue frost — a distinct hue change from normal ice, not just more opacity — while keeping the existing thicker second-overlay-layer treatment for double ice. Inactive cells still never show an ice overlay; the overlay is still fully separate from tile color and the special H/V/B marker. `BoardView`'s overlay-mode ghost ice rendering automatically picks up the same updated colors since it reads the same `TileView` constants.
- **Metadata/debug.** `GeneratedBoardChallenge.metadata` for an `ice` challenge gains `selected_ice_shape_types` (alongside the existing `selected_ice_patterns`), `center_ice_roll`, `center_ice_used`, `center_ice_cell_count`, and `symmetric_ice_used`, on top of Stage 57's `ice_cell_count`/`double_ice_cell_count`/`ice_attempts_used`/`ice_fallback_used`/`ice_validation_reasons`.
- **Archetype routing unchanged.** `normal` -> full active board, no ice. `holes` -> procedural holes, no ice. `ice` -> full active board, procedural ice (now symmetric/center-aware). Holes and ice are still not combined in this stage.
- Stage 58 remains challenge cycle integration and tuning.

## Stage 57.2: Ice Density and Cycle Variant Rules v0.1

Stage 57.2 is complete. Ice-archetype levels are now dense, clearly symmetric, and split by cycle position into weak/strong variants; archetype routing and Stage 56's ice damage rules are unchanged.

- **32-40 frozen cells, every ice level.** `IceGenerationRules.MIN_ICE_CELLS`/`MAX_ICE_CELLS` (32/40) replace Stage 57/57.1's tier-scaled counts — every tier now targets the same dense range (40/81 stays safely under the saturation guard's 50% ceiling). `IcePatternGenerator` picks a random target within that range per generation call and validates against it directly.
- **Weak/strong cycle variants.** New `IceVariant` (`scripts/game/config/ice_variant.gd`: `WEAK`/`STRONG`/`NONE`) and `IceVariantResolver` (`scripts/game/config/ice_variant_resolver.gd`) resolve a variant from `level_number % 5` using the same 5-level cycle `ChallengeArchetypeResolver` already uses: `== 2` -> weak (every generated cell forced to 1-layer ice, no double ice at all), `== 4` -> strong (every generated cell forced to 2-layer ice). This is a variant *inside* the existing `ice` archetype, not a new archetype — `BoardChallengeGenerator` resolves it via `IceVariantResolver` and stores it on the `IceGenerationRules` object it builds (`IceGenerationRules.for_tier(tier, variant)`), and it flows straight into `GeneratedBoardChallenge.metadata["ice_variant"]`.
- **Center shapes now seed instead of finish.** Stage 57.1's center-shape path used to return immediately with just the shape's 5-13 cells. `IcePatternGenerator._pick_center_shape_cells()` now only picks the shape's cell set; `_build_symmetric_candidate()` always uses it as a starting seed and keeps adding cells until the randomized 32-40 target is reached, then validates the *full* candidate — a center square/diamond marks where the layout starts, it no longer defines the whole layout.
- **True 4-way symmetric placement.** Non-center top-up now mirrors a 2x2/2x3/3x2 block across all four quadrants — `(x, y)`, `(8-x, y)`, `(x, 8-y)`, `(8-x, 8-y)` on a 9x9 board — by anchoring the block strictly inside the upper-left quadrant and reusing `BoardMaskSymmetry.get_mirrored_block_cells()`, the same mirroring `BoardMaskGenerator` uses for holes. This replaces Stage 57.1's single-axis 2-copy mirror (8/12 cells per placement, too small for the new density target) with a proper 4-copy mirror (16/24 cells per placement), so 1-2 placements alone comfortably reach 32-40 cells with roughly even quadrant distribution (~8 cells/quadrant for a 32-cell non-center layout).
- **Deterministic ice fallback.** If no randomized candidate validates within the attempt budget, `_build_deterministic_fallback_cell_set()` places two fixed (non-random) quadrant-mirrored 2x2 blocks that always total exactly 32 active cells on a full board, then assigns layers per the resolved variant (all-weak or all-strong) — an ice level can no longer end up with an empty `frozen_cells` array.
- **Validation.** Every candidate (randomized or fallback) still checks: all cells inside the board and active, no duplicates, ice count within `min_ice_cells`/`max_ice_cells` (32-40), and board saturation under the 50% ceiling — plus new variant checks: a weak-variant candidate must have zero strong (2-layer) cells, a strong-variant candidate must have zero weak (1-layer) cells.
- **Metadata/debug.** `GeneratedBoardChallenge.metadata` for an `ice` challenge gains `ice_variant`, `target_ice_count`, `weak_ice_cell_count`, `strong_ice_cell_count`, and `fallback_symmetric_used`, alongside Stage 57/57.1's existing `ice_cell_count`/`center_ice_used`/`center_ice_cell_count`/`symmetric_ice_used`/`selected_ice_shape_types`/`ice_attempts_used`/`ice_fallback_used`/`ice_validation_reasons`. `GeneratedBoardChallenge.get_debug_label()` now appends `, ice_variant: <weak|strong>, ice: <count>, weak: <count>, strong: <count>` instead of Stage 57's single double-ice count.
- **Unchanged.** The archetype cycle (1 normal, 2 ice, 3 holes, 4 ice, 5 holes) and routing (`normal`/`holes` untouched, no holes+ice mixing) are exactly as before; Stage 56's ice damage rules (direct clear, adjacent orthogonal clear, per-event dedup, 1-hit-breaks-weak/2-hits-breaks-strong) are completely unchanged.
- Stage 58 remains challenge cycle integration and tuning.

## Stage 57.3: Debug Ice Visibility Filter v0.1

Stage 57.3 is complete. It adds a temporary, strongly visible debug overlay for iced cells so Stage 57.2's dense procedural ice generation can be confirmed by eye during manual testing, without touching any generation or gameplay logic. This is a placeholder visual aid, not final art, and is designed to be trivially removed or disabled later.

- **`TileView.ICE_DEBUG_VISIBILITY_ENABLED`** (default `true`) is the toggle. While enabled, every iced cell — weak or strong — renders `ICE_DEBUG_OVERLAY_COLOR` (`Color(1.0, 1.0, 1.0, 0.78)`), a strong white overlay as bold as `BoardView.BOOSTER_TARGET_PREVIEW_COLOR`, instead of Stage 57.1's much subtler frost tint.
- **Weak/strong distinction preserved.** Strong (2-layer) ice keeps its existing inner inset `ColorRect` layer, now recolored to `ICE_DEBUG_OVERLAY_COLOR_DOUBLE_INNER` (a strong blue) whenever debug mode is on, so double ice still reads as clearly distinct from weak ice rather than losing its identity under the flat white filter.
- **Single source of truth.** New `TileView.resolve_ice_overlay_color(layers)`/`resolve_ice_overlay_inner_color()` static helpers decide the color once; both `TileView._apply_ice_overlay()` (real board tiles) and `BoardView.create_tile_ghost_from_data()` (overlay-mode animation ghosts) call the same helpers, so the debug filter automatically appears everywhere a tile can render: initial board render, `refresh_all_tiles()`, animation overlay ghosts, post-animation board handoff, retry/next-level/restart refresh, and with animations disabled or reduced motion — no per-call-site special-casing needed. Overlay-mode ghosts previously never rendered the inner double-ice layer at all; they now build it the same way real tiles do, so strong ice looks identical whether or not overlay mode is active. `_play_overlay_ice_break()` was extended to also fade and free the ghost's inner overlay node (not just the outer one) so nothing goes stale after a strong-ice cell fully breaks.
- **Booster previews unaffected.** Booster target/impact previews are separate `ColorRect` nodes added directly to `animation_layer` and explicitly `move_to_front()`-ed, entirely independent of the ice overlay nodes living inside each tile/ghost — no changes were needed for them to keep drawing above ice, and `clear_booster_target_preview()` still only ever touches its own preview node list.
- **No gameplay changes.** Ice generation (patterns, density, center-seeding, symmetric placement, deterministic fallback), the weak/strong variant rules, direct/adjacent ice damage, `BoardResolver`/`StepwiseBoardResolver` logic, boosters, and the result flow are all completely untouched — this stage only changes what color the existing overlay nodes render.
- Stage 58 remains challenge cycle integration and tuning.

## Stage 57.4: Rectangular Ice Clusters and Symmetry Completion v0.1

Stage 57.4 is complete. It fixes "stair-step"/partial-rectangle ice layouts by making non-center ice generation place exactly one complete mirrored rectangle per candidate, atomically, and adds a defensive completion pass plus a center-shape budget rule so a rectangle is never truncated to make room for a center shape. Weak/strong variant rules, ice damage rules, and the Stage 57.3 debug visibility filter are all unchanged.

- **Why partial/stair-step clusters happened.** Stage 57.1-57.2's `_build_symmetric_candidate()` added pattern cells one cell at a time, breaking out of the loop the moment `cell_set.size()` reached `target_count`/`max_ice_cells` — including mid-way through adding a mirrored-block shape's cells. A mirrored rectangle cut off partway through reads as an incomplete, asymmetric cluster instead of a clean shape.
- **Atomic shape placement.** `IcePatternGenerator._build_rectangular_candidate()` replaces that incremental loop: it generates a shape's *entire* mirrored cell set up front (`_generate_mirrored_block_cells()`, unchanged) and only ever accepts it as a whole — a shape that doesn't fit under the applicable cap is skipped entirely and a different shape/size is tried, never truncated.
- **Rectangular cluster validation.** New `_analyze_quadrant_rectangles()` groups the non-center cells of a candidate into the board's four quadrants (relative to the exact center), computes each quadrant's bounding rectangle, and checks that every cell inside that bounding rectangle is actually iced (no gaps) and that all non-empty quadrants share the same rectangle size (true 4-way congruence, not four different shapes). Center-shape cells are excluded before this check runs — they're handled separately and are never treated as a quadrant rectangle.
- **Completion pass.** `_complete_rectangle_gaps()` fills any active, missing cells inside each quadrant's own bounding rectangle. Because atomic placement already produces a clean rectangle by construction, this mostly acts as a defensive safety net (e.g. against a future combined archetype's inactive cells punching a hole in a shape) rather than something exercised every generation — but it's real, functioning logic, not a stub.
- **Center shape is optional, rectangles are not.** `_build_rectangular_candidate()` tries pairing the (optional) center seed with each candidate rectangle first; if the combined cell count doesn't fit under the normal `max_ice_cells` (40), the center seed is dropped entirely — never the rectangle — and the rectangle alone is used instead, freeing it to use the enlarged absolute cap if needed.
- **New rectangle sizes.** `IceShapePreset` grew from 3 mirrored-block sizes (2x2/2x3/3x2) to 8, adding 2x4/4x2/3x3/4x3/3x4; per-quadrant cell counts are 4/6/6/8/8/9/12/12, so mirrored 4-quadrant totals are 16/24/24/32/32/36/48/48. Every tier's `allowed_symmetric_shape_types` includes the full set (unchanged tier-uniform approach from Stage 57.2).
- **48-cell absolute cap.** `IceGenerationRules.ABSOLUTE_RECTANGULAR_MAX_ICE_CELLS` (48) may only be used when the non-center cells validate as one complete, 4-way-symmetric mirrored rectangle (checked in `_validate()`); anything else — including a rectangle-plus-center combo — stays bound by the normal `max_ice_cells` (40). `min_ice_cells` remains 32.
- **Rectangular fallback.** The deterministic fallback (used when no randomized candidate validates within the attempt budget) now places one clean mirrored 2x4 rectangle (32 cells total) instead of Stage 57.2's two-separate-block-anchor approach — simpler, and a clean rectangle by construction. It still honors the resolved ice variant (all-weak or all-strong).
- **Metadata/debug.** `GeneratedBoardChallenge.metadata` for an `ice` challenge gains `rectangular_completion_used`, `center_shape_removed_for_completion`, `incomplete_rectangles_detected`, `completed_rectangle_count`, `rectangle_shapes_used`, `absolute_rectangular_cap_used`, and `final_ice_cell_count`, alongside all existing Stage 57/57.1/57.2 fields.
- **Unchanged.** Weak/strong variant rules (`level_number % 5 == 2` weak-only, `== 4` strong-only), direct/adjacent-orthogonal ice damage, `BoardResolver`/`StepwiseBoardResolver` logic, the archetype cycle/routing, and the Stage 57.3 debug visibility filter are all completely untouched — this patch only changes ice layout generation quality.
- Stage 58 remains challenge cycle integration and tuning.

## Stage 57.5: Cell-Anchored Ice Overlays and Per-Step Ice Sync v0.1

Stage 57.5 is complete. It fixes two ice presentation bugs: ice visually "falling" with a tile ghost during gravity/refill, and ice visuals only catching up to the true post-clear state once the entire animated sequence finished instead of after each individual clear/cascade/booster step. Ice generation, rectangular cluster rules, weak/strong variants, and every ice damage rule are unchanged — this is a presentation/animation-synchronization patch only.

- **Why ice appeared to fall.** `BoardView.create_tile_ghost_from_data()` used to build `IceOverlay`/`IceOverlayInner` as child nodes of the moving tile ghost it returned. Since gravity/refill/swap animate that ghost's `position` directly, any ice overlay attached to it moved right along with the falling crystal — even though ice is a cell obstacle that never actually moves with `BoardModel.swap_tiles()`/`GravityResolver`.
- **Tile ghosts and obstacle overlays separated.** `create_tile_ghost_from_data()` no longer takes or builds any obstacle visual — it only ever renders tile color/icon and the special H/V/B marker. A new, standalone `_create_obstacle_overlay_ghost()` builds the ice visual (a `ColorRect` plus an inset `ColorRect` child for strong/double ice) as its own node, added directly to `animation_layer` at a fixed board-cell position, entirely independent of whichever tile ghost currently occupies that cell.
- **Cell-anchored storage.** A new `BoardView._overlay_obstacle_ghosts: Dictionary` (`Vector2i -> Control`) — deliberately separate from `_overlay_ghosts` (the moving tile ghosts) — tracks these obstacle ghosts by board cell. `build_full_board_ghosts()` populates it once per turn for every active, iced cell from the `BoardVisualSnapshot`'s existing `obstacle_type`/`obstacle_layers` fields; an active cell with no ice never gets an entry, and inactive cells still only ever get the existing hole placeholder.
- **Gravity/refill move crystals only.** Since `_play_overlay_gravity_fall()`/`_play_overlay_refill()`/`play_gravity_fall_animation()`/`play_refill_animation()` only ever read/write `_overlay_ghosts` (tile ghosts), and never touch `_overlay_obstacle_ghosts`, cell-anchored ice overlays now stay stationary through every gravity/refill animation automatically, with no per-movement obstacle logic needed. A new `_keep_obstacle_ghost_on_top()` re-raises a destination cell's obstacle ghost above any newly landed/created tile ghost there (new ghosts are appended as `animation_layer`'s last child, which would otherwise briefly draw over a pre-existing ice overlay), called after gravity fall, refill, and the special-creation fallback ghost path.
- **Per-step ice sync.** `BoardAnimationController._play_ice_event_request()` now also collects each damaged (non-broken) cell's `new_layers` from its `ice_events` payload (already carrying `cell`/`obstacle_type`/`previous_layers`/`new_layers`/`broken` since Stage 56 — no source-data changes needed) and passes it to `BoardView.play_ice_damage_animation(cells, new_layers_by_cell)`. `TileView.play_ice_damage(new_obstacle_layers)`'s flash tween now applies that new layer count inside its own completion callback right before re-rendering the overlay, so the flash plays first and then settles directly into the reduced-layer look — strong ice visibly becomes weak immediately after the hit that damages it, without waiting for the rest of the cascade or the final board handoff. `play_ice_break()`'s completion callback likewise now clears the tile's internal obstacle state directly, so weak ice's overlay reads as gone immediately after it breaks. The overlay-mode equivalents (`_play_overlay_ice_damage()`/`_play_overlay_ice_break()`) do the same against the cell-anchored obstacle ghost instead of a tile-ghost child. This works identically for first match clears, cascades, boosters, and special clears, since they all funnel through the same `TYPE_ICE_EVENT` request/`ice_events` payload.
- **New BoardView sync API.** `sync_overlay_ice_event(event)` (a convenience wrapper for a raw ice event dictionary), `update_cell_obstacle_visual(cell, obstacle_type, layers)` (real `TileView.set_cell_obstacle()` outside overlay mode, or the overlay ghost when in overlay mode), `update_overlay_obstacle_ghost(cell, obstacle_type, layers)`, and `remove_overlay_obstacle_ghost(cell)` are the reusable building blocks the animation methods above call into. All of them reuse `TileView.resolve_ice_overlay_color()`/`resolve_ice_overlay_inner_color()` rather than duplicating color logic, so overlay-mode ice always matches the real board's colors — including the Stage 57.3 debug visibility filter, unchanged and still active.
- **Final handoff stays safe.** `apply_board_under_overlay()`'s existing `exit_animation_overlay_mode()` -> `clear_animation_layer()` call already frees every `animation_layer` child unconditionally; `clear_animation_layer()` now also clears the `_overlay_obstacle_ghosts` dictionary (alongside the existing `_overlay_ghosts.clear()`), so no stale ice overlay node or dangling reference survives the handoff, and `refresh_all_tiles()` re-syncs every real `TileView`'s obstacle state from the authoritative final `BoardModel`.
- **Unchanged.** Ice generation (`IcePatternGenerator`, `IceGenerationRules`, `IceShapePreset`), rectangular cluster rules (Stage 57.4), weak/strong variant resolution (Stage 57.2), direct/adjacent-orthogonal ice damage (`IceDamageResolver`), and `BoardResolver`/`StepwiseBoardResolver`/`BoosterResolver`/result-flow logic are all completely untouched.
- Stage 58 remains challenge cycle integration and tuning.

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

## Stage 58: Deterministic 500-Level Layout Database v0.1

Stage 58 is complete. Levels 1-500 now load a fixed, pre-generated, pre-validated board/ice layout instead of re-rolling procedural generation on every playthrough. The existing procedural holes/ice generators are unchanged and remain the source of truth — they are what built every stored layout offline, and they remain the runtime fallback for any level without a saved layout.

- **Data model.** `LevelLayout` (`scripts/game/config/level_layout.gd`) holds `level_number`, `archetype`, `variant`, `cycle_position`, `board_mask`, `ice_mask`, `generation_seed`, `generator_version`, and `metadata`. Board size is fixed at 9x9 (81 cells).
- **Mask encoding.** `LevelLayoutMaskCodec` (`scripts/game/config/level_layout_mask_codec.gd`) is the single place that encodes/decodes masks: `board_mask` is an 81-character, row-major (`index = y*9+x`) string with `"1"` = active cell and `"0"` = inactive/hole cell; `ice_mask` uses the same indexing with `"0"` = no ice, `"1"` = weak (1-layer) ice, `"2"` = strong (2-layer) ice. Ice is never encoded on an inactive cell. The codec converts directly to/from the `Array`/`Vector2i` shapes `BoardModel.set_active_mask()`/`apply_frozen_cells()` already expect, so no board-core code changed.
- **Database file.** `data/levels/deterministic_level_layouts.json` (`version`, `board_size`, `generator_version`, `levels[]`) holds all 500 levels as compact mask strings plus metadata — roughly 420KB total, no per-tile verbose dictionaries and no per-level scenes/resources.
- **Generator tool.** `tools/generate_deterministic_levels.gd` builds the database by driving the existing `BoardMaskGenerator` (holes) and `IcePatternGenerator` (ice) with a stable per-level seed (`base_seed + level_number`, with a deterministic seed-stride retry loop so a holes level can never end up with zero holes from a fallback), preserving the existing `ChallengeArchetypeResolver`/`IceVariantResolver` 5-level cycle: `%5==1` normal, `%5==2` ice weak, `%5==3` holes (`holes_a`), `%5==4` ice strong, `%5==0` holes (`holes_b`). Run it headless: `godot --headless --script res://tools/generate_deterministic_levels.gd`. Holes and ice are never mixed in this stage — normal levels are a full active board with no ice, ice levels are a full active board with only the resolved weak/strong ice variant, holes levels have a generated inactive-cell mask with no ice.
- **Validation.** `LevelLayoutValidator` (`scripts/game/config/level_layout_validator.gd`) checks exactly 500 unique/continuous levels, valid 81-character masks with only allowed characters, each archetype matching its expected board/ice shape, ice never placed on an inactive cell, holes masks re-validated through the same `BoardMaskValidator`/tier-scoped `HoleGenerationRules` the generator itself validated against, ice density checked against `IceGenerationRules`, and required metadata keys (`archetype`, `variant`, `cycle_position`, `generation_seed`, `layout_source`) present — returning a structured `{valid, errors, warnings, total_levels, counts_by_archetype, counts_by_variant}` result. The generated database currently validates with 0 errors and 0 warnings (100 normal, 200 ice, 200 holes; 100 `default`, 100 `weak`, 100 `strong`, 100 `holes_a`, 100 `holes_b`).
- **Loader.** `LevelLayoutDatabase` (`scripts/game/config/level_layout_database.gd`) loads the JSON once and exposes `has_layout(level_number)`/`get_layout(level_number)`; a missing or invalid database file simply leaves every `has_layout()` call `false` rather than blocking gameplay.
- **BoardChallengeGenerator wiring.** `BoardChallengeGenerator.generate()` now checks the database first: on a hit, it decodes the stored `board_mask`/`ice_mask` directly into `GeneratedBoardChallenge.board_mask`/`frozen_cells` (no RNG, no procedural generator call) and tags `metadata["layout_source"] = "deterministic_database"`; on a miss it falls through to the unchanged Stage 51-57.5 procedural path, so any level outside 1-500 (or a corrupted/missing database) still generates a valid board exactly as before.
- **Debug labels.** `GeneratedBoardChallenge.get_debug_label()` now leads with the level number and layout source, e.g. `"Challenge: normal deterministic, level: 1, seed: 9000001, active: 81/81, holes: 0"` or `"Challenge: ice weak deterministic, level: 2, seed: 9000002, active: 81/81, holes: 0, ice_variant: weak, ice: 37, weak: 37, strong: 0"` for a database hit, versus `procedural` for any fallback-generated level.
- **Unchanged.** Match/swap rules, gravity/refill, ice damage rules, holes rules, boosters, victory/defeat flow, enemy damage, stars/rewards, and `LevelSelectScreen` are all untouched. Procedural holes/ice generation remains fully intact for tools, fallback, and future modes.

## Stage 59: Deterministic Layout QA and No-Move Shuffle Protection v0.1

Stage 59 is complete. Two independent additions: deeper offline QA over the Stage 58 deterministic database (still 0 errors/0 warnings, now also 0 review candidates), and a runtime safety net that guarantees the settled board always has at least one available move. Neither changes the deterministic database format, the 5-level cycle, holes/ice generation rules, damage formulas, booster behavior, or victory/defeat flow.

- **Deeper database validation.** `LevelLayoutValidator` (`scripts/game/config/level_layout_validator.gd`) keeps every Stage 58 structural error check unchanged and adds QA-only, non-failing `review_candidates`: holes layouts with fewer than 8 or more than 24 inactive cells, ice layouts outside the existing `IceGenerationRules` density range, duplicate `board_mask`/`ice_mask` strings reused across holes/ice levels, any layout whose metadata carries `fallback_used = true`, and metadata whose `archetype`/`variant`/`cycle_position`/`generation_seed` disagrees with the layout's own fields. `valid` still keys off `errors` only, so these never fail validation — they are advisory.
- **QA report.** `LevelLayoutValidator.build_report(database)` wraps `validate_database()`'s result with `generator_version`/`generated_at` and is written to `data/levels/deterministic_level_layout_report.json` — `valid`, `errors`, `warnings`, `review_candidates`, `total_levels`, `counts_by_archetype`, `counts_by_variant`, `hole_count_stats`/`ice_count_stats` (`min`/`max`/`avg`), `fallback_layout_count`, and `duplicate_layout_warnings`.
- **Standalone validation tool.** `tools/validate_deterministic_levels.gd` loads the existing `deterministic_level_layouts.json`, runs `LevelLayoutValidator`, writes the QA report, and prints a compact summary — it never regenerates or mutates the database. Run headless: `godot --headless --script res://tools/validate_deterministic_levels.gd`. `tools/generate_deterministic_levels.gd` now writes the same report file after generation.
- **Runtime deterministic layout fallback.** `BoardChallengeGenerator.generate()` no longer trusts a database hit blindly: the single matched `LevelLayout` is run through `LevelLayoutValidator.validate_layout()` (one layout, not the full 500-level sweep) before use. An invalid layout falls back to the same procedural generation path used for levels outside the database, tagging `metadata["layout_source"] = "procedural_fallback_invalid_layout"`, `deterministic_layout_used = false`, and `invalid_layout_reasons`. A database that failed to load at all falls back the same way, tagging `"procedural_fallback_database_error"` and `database_load_error`. The deterministic-first flow (try deterministic for levels 1-500, else procedural) is otherwise unchanged.
- **Available move detection.** `AvailableMoveFinder` (`scripts/game/board/available_move_finder.gd`) is a read-only helper that scans every active cell's right/down neighbor and reuses the real `SwapResolver`/`MatchFinder` (against a duplicated `BoardModel`, never the live board) to answer "does at least one valid swap exist?" — the same logic `BattlePresenter._has_valid_move()` already used for initial board generation, now reusable at runtime.
- **No-move shuffle resolver.** `BoardShuffleResolver` (`scripts/game/board/board_shuffle_resolver.gd`) collects tile payloads (`tile_type` + `special_data`) from active cells only, Fisher-Yates shuffles them, and retries (up to 40 attempts) until the result has an available move and no immediate match, falling back to a bounded deterministic rotation if every random attempt fails. Inactive cells and the ice/obstacle layer (cell-anchored, independent of tile payload — see Stage 56) are never touched, so holes and ice never move.
- **Runtime no-move check.** `GameScreen._maybe_resolve_no_move_shuffle()` runs `AvailableMoveFinder` once the board is fully settled — after a swap's cascade/gravity/refill sequence, after a booster resolve sequence, and after the overlay hands the final board back to the real `BoardView` — always right before player input is re-enabled for the next turn, never mid-animation. If no move exists, it plays a brief fade-out on active crystal tiles (`BoardView.play_shuffle_fade_out`/`TileView.play_shuffle_fade_out`), shuffles, refreshes the real board tiles, then fades back in (`play_shuffle_fade_in`). Holes/ice visuals are untouched since the fade only targets active `TileView`s and the shuffle never mutates obstacle state.
- **Shuffle debug tracking.** Each shuffle updates `GameScreen._last_shuffle_debug_info` (`no_move_detected`, `shuffle_count`, `shuffle_attempts_used`, `shuffle_fallback_used`, `available_move_after_shuffle`) and, when debug labels are enabled, briefly surfaces a compact status line.
- **Unchanged.** Deterministic database format, the 5-level cycle, holes/ice generation rules, ice direct/adjacent damage rules, booster behavior, damage formulas, victory/defeat flow, and `LevelSelectScreen` are all untouched.

## Stage 59.1: No-Move Shuffle Integration and QA Report Finalization v0.1

Stage 59.1 is complete. Finishes Stage 59: the no-move shuffle check was already wired into `GameScreen` at both settle points, so this pass hardens that wiring against presentation settings and finalizes the QA report policy left open by Stage 59.

- **Settled-turn integration confirmed.** `GameScreen._maybe_resolve_no_move_shuffle()` runs at the tail of `_on_feedback_finished()` (every settled swap turn — full clear/gravity/refill/cascade sequence plus the overlay->real `BoardView` handoff already complete) and `_finish_booster_resolution()` (every settled targeted/direct booster turn). Both call sites only reach the shuffle check once `_pending_battle_status == -1`, i.e. the turn did not end the battle — a victory/defeat turn never triggers a shuffle and the result overlay is never delayed by shuffle behavior.
- **Presentation-aware fade.** New `GameScreen._shuffle_fade_duration()` mirrors `TileView._adjust_duration()`'s "disabled animations collapse to instant" rule: with animations disabled it returns `0.0`, so the shuffle skips the fade tween and any `await` entirely and updates the board immediately; with reduced motion enabled it scales the base 0.16s fade by `BoardAnimationController.REDUCED_MOTION_SCALE` (0.35) instead of always waiting the full duration. Holes/inactive visuals and ice overlays are still never touched by the fade — it only ever targets active-cell `TileView`s.
- **Debug data gains `immediate_match_after_shuffle`.** `BoardShuffleResolver.shuffle()` already returned `has_immediate_match`; `GameScreen._last_shuffle_debug_info` now also stores it as `immediate_match_after_shuffle`, alongside the existing `no_move_detected`, `shuffle_count`, `shuffle_attempts_used`, `shuffle_fallback_used`, `available_move_after_shuffle`.
- **Input stays blocked throughout.** Both call sites `await _maybe_resolve_no_move_shuffle()` before `_input_controller.set_input_enabled(true)`, so booster targeting and swap selection cannot start until the no-move check (and any shuffle animation) has fully finished — unchanged from Stage 59, confirmed here as part of the integration review.
- **QA report policy: not committed.** `data/levels/deterministic_level_layout_report.json` is a locally regenerated artifact — `tools/generate_deterministic_levels.gd` and `tools/validate_deterministic_levels.gd` both (re)write it on demand from the committed `deterministic_level_layouts.json`, so committing it would just be a stale snapshot that immediately diverges. It is listed in `.gitignore` and is not required in the repository; regenerate it locally whenever you want an up-to-date QA read.
- **Unchanged.** Deterministic database format, the 5-level cycle, holes/ice generation rules, `LevelLayoutValidator`'s error/warning/review-candidate rules, `AvailableMoveFinder`/`BoardShuffleResolver`'s shuffle algorithm, booster behavior, damage formulas, and victory/defeat flow are all untouched — this stage only hardens wiring and finalizes policy.

## Stage 60.1: Fixed Enemy HP and Move Curve v0.1

Stage 60.1 is complete. Direct-mode battles move off Stage 34's per-level HP/moves curves onto a stable fixed baseline, preparing for the level-boost system planned in Stage 60.2/60.3.

- **New config.** `DirectBattleBalance` (`scripts/game/config/direct_battle_balance.gd`): `FIXED_ENEMY_HP = 130`, `STARTING_MOVES = 30`, `MIN_MOVES = 20`, `get_moves_for_level(level_number)` = `max(MIN_MOVES, STARTING_MOVES + 1 - max(1, level_number))` — level 1 -> 30, level 2 -> 29, level 3 -> 28, ..., level 10 -> 21, level 11 -> 20, and levels 12 through 500+ stay floored at 20. `get_debug_label()` gives a compact `enemy_hp`/`base_moves_for_level`/`final_moves_before_boosts` string for dev inspection.
- **Fixed enemy HP.** `EnemyScalingResolver._scale_enemy_direct()` now hardcodes `max_hp` to `DirectBattleBalance.FIXED_ENEMY_HP` instead of calling the old `DirectBalanceConfig.get_enemy_hp_for_level()` curve. `EnemyCatalog`'s base roster `max_hp` values are never mutated — a fresh `EnemyConfig` is built per battle, same pattern as before.
- **Move curve.** `LevelCatalog._get_moves_for_level()` now delegates to `DirectBattleBalance.get_moves_for_level()`. `LevelConfig.moves` still flows unchanged through `BattleFactory.create_state()` into `BattleState.moves_left` — no changes needed in `BattlePresenter`/`BattleFactory` themselves.
- **`DirectBalanceConfig` retained, narrowed.** Its damage-related helpers (`get_expected_damage_per_move()`, `get_required_damage_per_move()`, `get_balance_checkpoint_levels()`, `is_wall_level()`) are untouched and still used by tests; its old `get_moves_for_level()`/`get_enemy_hp_for_level()` are simply no longer called from the active flow. Direct match damage calculation (`DirectMatchDamageResolver`) is unchanged.
- **Deterministic layouts unchanged.** Board masks, ice masks, holes generation, and no-move shuffle behavior are untouched — this stage only changes battle HP and moves.
- **Level boosts deferred.** One-color x2 damage, match-size-4 x2, match-size-5+ x3, and +3 moves are planned for Stage 60.2/60.3, not implemented here.
- **Tests updated, not run.** `direct_level_balance_test.gd`/`direct_enemy_scaling_balance_test.gd` now assert the fixed baseline; `direct_balance_config_test.gd` needed no changes (it tests `DirectBalanceConfig` directly, unchanged). No automated tests were run — manual verification in the Godot editor is expected.

## Stage 60.2: Level Boost System Foundation v0.1

Stage 60.2 is complete. This stage adds the architecture and runtime wiring for deterministic per-level boosts on top of Stage 60.1's fixed baseline, without adding the deterministic 500-level boost database yet (planned for Stage 60.3). Every level currently resolves to the `none` boost, so numeric gameplay (HP, moves, damage) is unchanged from Stage 60.1.

- **New boost type layer.** `LevelBoostType` (`scripts/game/config/level_boost_type.gd`) defines `NONE`, `COLOR_DAMAGE_MULTIPLIER`, `LARGE_MATCH_MULTIPLIER`, and `EXTRA_MOVES`, plus `get_all_types()`/`is_valid_type()`/`get_type_name()` helpers.
- **New `LevelBoostConfig`.** `scripts/game/config/level_boost_config.gd` is a plain, JSON-database-friendly data record (`boost_id`, `boost_type`, `display_name`, `description`, `tile_type`, `color_multiplier`, `match_4_multiplier`, `match_5_multiplier`, `extra_moves`) with `is_none()`/`is_valid()` and static factories `none()`, `color_damage(tile_type, multiplier := 2.0)`, `large_match(match_4 := 2.0, match_5 := 3.0)`, `extra_moves_boost(bonus := 3)`. All rule logic lives outside this class so it stays a pure data record.
- **New `LevelBoostResolver`.** `scripts/game/config/level_boost_resolver.gd` owns boost rules: `get_boost_for_level(level_number)` always returns `LevelBoostConfig.none()` in Stage 60.2 (Stage 60.3 replaces this with a deterministic 500-level database lookup, same contract); `apply_moves_bonus(base_moves, boost)` adds `boost.extra_moves` only for an `EXTRA_MOVES` boost; `get_damage_multiplier_for_tile(tile_type, match_size, boost)` returns `boost.color_multiplier` when `tile_type` matches a `COLOR_DAMAGE_MULTIPLIER` boost's `tile_type`, `boost.match_5_multiplier`/`boost.match_4_multiplier` for a `LARGE_MATCH_MULTIPLIER` boost at match size 5+/4, and x1 for every other case (including `none`/null).
- **New `LevelBoostFormatter`.** `scripts/game/presentation/level_boost_formatter.gd` builds debug/status/UI labels ("No Boost", "Red x2"/"Blue x2"/etc., "Match 4 x2 / Match 5+ x3", "+3 Moves") and a compact `format_debug_label()` for dev inspection, kept separate from the data/rule classes so display text can change independently.
- **`BattlePresenter` wiring.** `start_level()` extracts the level number from `current_level_id`, resolves `current_level_boost` via `LevelBoostResolver.get_boost_for_level()` right after enemy/background/round-modifier selection, applies it to moves with `state.moves_left = LevelBoostResolver.apply_moves_bonus(current_level_config.moves, current_level_boost)` (battle-time only — `LevelCatalog`/`LevelConfig.moves`/`DirectBattleBalance` are never mutated), and emits a new `level_boost_changed(boost)` signal alongside the existing level/board/state/background/round-modifier signals. `get_current_level_boost()` exposes it for UI/debug/tools.
- **Random round modifiers disconnected from active damage.** `current_round_modifier` is still selected, stored, and emitted every `start_level()` call purely to keep the existing legacy `RoundModifierPanel` display and `round_modifier_presenter_test.gd` working, but it no longer feeds direct-mode damage: `BattlePresenter._finalize_swap()` now calls `_battle_resolver.set_level_boost(current_level_boost)` instead of `set_round_modifier(current_round_modifier)`; `request_targeted_booster()` and `AnimatedTurnFlow._apply_cascade_damage()` now pass `current_level_boost` (not `current_round_modifier`) into `BoosterResolver.resolve_targeted_booster()`/`DirectMatchDamageResolver.calculate_damage_for_typed_cells()`. `RoundModifierCatalog`, `RoundModifierConfig`, `RoundModifierSelectionResolver`, and `BattleResolver.set_round_modifier()` all remain in the project as legacy/future code — still directly usable/testable (e.g. `hero_systems_freeze_test.gd`, `color_damage_resolver_test.gd`, `booster_damage_test.gd` call them directly and are unaffected) — they are simply no longer wired into the active battle flow's damage.
- **Moves pipeline.** `BattleFactory.create_state()`/`BattleState` are unchanged; `BattlePresenter` overwrites `state.moves_left` right after battle-state creation with the boosted value. With the Stage 60.2 `none` default, `final_moves == base_moves == DirectBattleBalance.get_moves_for_level(level_number)`, exactly matching Stage 60.1. `EXTRA_MOVES` boosts are fully wired and ready for Stage 60.3 to assign.
- **Direct damage calculation.** `BattleResolver` gained `set_level_boost()`/`_level_boost` alongside the existing `set_round_modifier()`/`_round_modifier`, threading `current_level_boost` into `DirectMatchDamageResolver`. `DirectMatchDamageResolver.calculate_damage_for_matches()`, `calculate_damage_for_typed_cells()`, `calculate_damage_for_board_result()`, `build_damage_breakdown()`, and `calculate_damage_from_turn_result()` all gained an optional trailing `level_boost` parameter that takes priority over `round_modifier` whenever it is non-none. Multiplier lookup now uses each match's real `tile_type` and match size (`MatchResult.length()` for initial matches; each cascade step's own match data for cascades), so `color_damage_multiplier` applies per matching tile color and `large_match_multiplier` applies x2 at match size 4 and x3 at match size 5+; cells with no owning match (booster clears, special-tile activation clears) default to match size 1, so only a color boost (never a match-size boost) can apply to them, and x1 applies whenever no boost/modifier rule matches — this exactly preserves Stage 32/33 behavior when `level_boost`/`round_modifier` are both null.
- **Damage breakdown for debugging.** The damage breakdown built by `DirectMatchDamageResolver` is now grouped by `(tile_type, match_size)` instead of `tile_type` alone (so a size-3 and size-4 match of the same color no longer collapse into one misleading multiplier), and each entry gained `match_size`, `boost_id`, and `boost_type` fields alongside the existing `tile_type`/`tile_count`/`multiplier`/`damage`.
- **Debug status.** `GameScreen` connects to `level_boost_changed`, stores `_current_level_boost`, and appends `LevelBoostFormatter.format_debug_label()` to the existing Debug Labels status line (alongside the generated-challenge and `DirectBattleBalance` debug labels).
- **Stage 60.1 baseline preserved.** Fixed enemy HP (130), the 30-down-to-20 move curve, deterministic layouts, holes, ice, no-move shuffle, and victory/defeat flow are all untouched.
- **500-level boost database not added yet.** `LevelBoostResolver.get_boost_for_level()` always returns `none()` in this stage; Stage 60.3 will replace its body with a deterministic per-level lookup (by `level_number` -> `boost_id`/boost fields), without changing its signature or any calling code.
- **No automated tests were run.** Existing tests (`hero_systems_freeze_test.gd`, `color_damage_resolver_test.gd`, `booster_damage_test.gd`, `round_modifier_presenter_test.gd`, `direct_match_damage_test.gd`, `round_modifier_balance_test.gd`) call the touched functions with their original positional arguments (the new `level_boost` parameter is optional/defaults to `null`), so existing behavior is expected to be unaffected, but this was not verified by running them — manual verification in the Godot editor is expected.

## Stage 60.3: Deterministic 500-Level Boost Database v0.1

Stage 60.3 is complete. Every level from 1 to 500 now receives a fixed, reproducible level boost loaded from a new deterministic database, replacing Stage 60.2's always-`none` placeholder. Fixed enemy HP, the Stage 60.1 move curve, deterministic layouts, holes, ice, no-move shuffle, boosters, and victory/defeat/result flow are all unchanged.

- **New boost database file.** `data/levels/deterministic_level_boosts.json` (`version`, `generator_version`, `level_count`, `levels[]`) holds exactly 500 entries (`level_number` + `boost`, using `LevelBoostConfig.to_dict()`'s compact shape — only the fields relevant to that boost's `boost_type` are written). Distribution follows a simple, predictable pattern: `level_number % 3 == 1` -> `color_damage_multiplier` (x2, tile color cycling red/blue/green/yellow/purple across those levels — level 1 red, level 4 blue, level 7 green, level 10 yellow, level 13 purple, level 16 red again, ...), `== 2` -> `large_match_multiplier` (match 4 x2, match 5+ x3), `== 0` -> `extra_moves` (+3). Matches the required examples exactly: level 1 "Red x2", level 2 "Match 4 x2 / Match 5+ x3", level 3 "+3 Moves", level 4 "Blue x2", level 5 "Match 4 x2 / Match 5+ x3", level 6 "+3 Moves". Final counts: 167 color-damage levels (34 red/34 blue/33 green/33 yellow/33 purple), 167 large-match levels, 166 extra-moves levels.
- **`LevelBoostConfig` gained JSON parsing helpers.** `from_dict(data)`/`to_dict()` bridge the JSON entries and `LevelBoostConfig` instances; `boost_type_from_string()`/`boost_type_to_string()` accept/produce `"none"`/`"color_damage_multiplier"`/`"large_match_multiplier"`/`"extra_moves"`, and `tile_type_from_string()`/`tile_type_to_string()` accept/produce `"red"`/`"blue"`/`"green"`/`"yellow"`/`"purple"` (unknown strings safely fall back to `NONE`/`-1`).
- **New `LevelBoostDatabase`.** `scripts/game/config/level_boost_database.gd` (mirrors `LevelLayoutDatabase`'s shape) loads `data/levels/deterministic_level_boosts.json` once, parses each entry through `LevelBoostConfig.from_dict()`, skips/ignores any entry that fails `is_valid()`, and indexes valid boosts by `level_number`. Exposes `is_loaded()`, `get_load_error()`, `has_boost(level_number)`, `get_boost(level_number)` (returns `LevelBoostConfig.none()` for a missing/invalid level rather than `null`), `get_boost_count()`, `get_all_level_numbers()`. A missing file, unreadable file, invalid JSON, missing `levels` array, or an empty parsed result all set a load error and simply leave `is_loaded() == false` — never a crash, never a blocked battle start.
- **New `LevelBoostDatabaseValidator`.** `scripts/game/config/level_boost_database_validator.gd` (mirrors `LevelLayoutValidator`'s shape) checks: exactly 500 levels, unique level numbers, continuous 1-500 coverage, every level has a boost, every `boost_type` is a known `LevelBoostType`, `color_damage_multiplier` has a valid tile color and `color_multiplier == 2.0`, `large_match_multiplier` has `match_4_multiplier == 2.0` and `match_5_multiplier == 3.0`, `extra_moves` has `extra_moves == 3`. `validate_database(database)` returns `{valid, errors, warnings, total_levels, counts_by_boost_type, counts_by_color}` (`valid` keyed off `errors` only); a distribution far outside the expected roughly-even three-way split is a warning, not an error, so a future hand-tuned database isn't blocked by this heuristic. `build_report(database)` adds `generator_version`/`generated_at` for the QA report tools.
- **New generation tool.** `tools/generate_deterministic_level_boosts.gd` builds the full 500-level database from the Stage 60.3 distribution rule using `LevelBoostConfig`'s own `color_damage()`/`large_match()`/`extra_moves_boost()` factories (so the tool and runtime code can never drift), writes it to `data/levels/deterministic_level_boosts.json`, then runs `LevelBoostDatabaseValidator.build_report()` against the freshly written file, writes `data/levels/deterministic_level_boost_report.json`, and prints a compact valid/errors/warnings/counts summary. Run headless: `godot --headless --script res://tools/generate_deterministic_level_boosts.gd`.
- **New validation tool.** `tools/validate_deterministic_level_boosts.gd` is the read-only counterpart — loads the existing database, validates it, writes/prints the same report, never regenerates or mutates the database. Run headless: `godot --headless --script res://tools/validate_deterministic_level_boosts.gd`. Both reports are QA-only, locally regenerated artifacts (`data/levels/deterministic_level_boost_report.json` is `.gitignore`d, same policy as Stage 59.1's layout report); the database JSON itself **is** committed since it's loaded at runtime.
- **`LevelBoostResolver` now backed by the database.** `get_boost_for_level(level_number)` keeps its exact Stage 60.2 signature/return type — no `BattlePresenter` rewrite needed — but now lazily constructs a `LevelBoostDatabase` on first use and queries `has_boost()`/`get_boost()`, falling back to `LevelBoostConfig.none()` whenever the database isn't loaded, the level is missing, or the stored boost fails `is_valid()`. New `was_fallback_used(level_number)`, `is_database_loaded()`, `get_database_load_error()` expose that state for debug/status. The `DirectMatchDamageResolver`-owned `LevelBoostResolver` instance never touches disk since it only calls `get_damage_multiplier_for_tile()`, not `get_boost_for_level()`.
- **Moves/damage integration unchanged, now with real data.** `BattlePresenter.start_level()`'s existing `state.moves_left = LevelBoostResolver.apply_moves_bonus(current_level_config.moves, current_level_boost)` call is untouched — color/large-match boost levels keep Stage 60.1's base moves unchanged (`apply_moves_bonus()` only adds for `EXTRA_MOVES`), and extra-moves levels now genuinely get `base_moves + 3`. `BattleResolver`/`DirectMatchDamageResolver`'s existing `current_level_boost`-aware damage path (Stage 60.2) needed no changes either: color boost levels apply x2 to the selected color, large-match levels apply x2/x3 at match size 4/5+, extra-moves levels have no damage effect, and a `none`/fallback boost still gives x1.
- **Level boost panel replaces the round modifier display.** `GameScreen`'s existing `RoundModifierPanel`/`ModifierNameLabel`/`ModifierDescriptionLabel` (same scene nodes, same reserved asset key) are now driven by `_on_level_boost_changed()` using `LevelBoostFormatter.format_label()` and the boost's own `description`, instead of the legacy random round modifier; `_on_round_modifier_changed()` is now a no-op (kept only because `BattlePresenter` still emits `round_modifier_changed` for `round_modifier_presenter_test.gd`). A `none`/fallback boost hides the panel, exactly like the old null-modifier behavior — since every level 1-500 now resolves to a real boost, the panel is visible in normal play.
- **Debug/status info.** `BattlePresenter.get_current_level_boost_debug_info()` returns `{boost_source, boost_id, boost_type, boost_label, boost_database_loaded, boost_fallback_used, boost_load_error}`; `LevelBoostFormatter.format_debug_info_label()` renders it into one compact line, and `GameScreen` appends it to the existing Debug Labels status line, making it easy to confirm which boost any given level (1, 2, 3, ...) actually received.
- **Everything else preserved.** Fixed 130 enemy HP, the 30-down-to-20 move curve, the deterministic 500-level layout database, holes/ice generation, no-move shuffle, boosters, victory/defeat flow, the result overlay, and progression save/unlock are all untouched.
- **No automated tests were run.** `LevelBoostResolver.get_boost_for_level()`'s unchanged signature/return type means no existing caller needed a rewrite; manual verification in the Godot editor is expected.

## Stage 61: Main Menu Restoration v0.1

Stage 61 is complete. `MainMenuScreen` is restored as the app's default startup screen and top-level hub, replacing the Stage 35 direct-to-LevelSelect startup flow. Every existing gameplay system (deterministic layouts, level boosts, fixed enemy HP/move curve, holes, ice, no-move shuffle, boosters, battle result flow, progress save/unlock, settings values) is unchanged.

- **Startup flow.** `App._ready()` now calls `_show_main_menu()` instead of `_show_level_select()`. MainMenu no longer auto-opens LevelSelect or GameScreen on its own — it only reacts to button presses.
- **MainMenu buttons.** `MainMenuScreen` (`scripts/screens/main_menu_screen.gd`, `scenes/screens/MainMenuScreen.tscn`) gained `level_select_pressed` and `shop_pressed` signals alongside the existing `play_pressed`, `heroes_pressed`, `settings_pressed`. Visible buttons: Играть, Выбрать уровень, Магазин, Настройки (Heroes stays hidden behind `FeatureFlags.HERO_SYSTEMS_ENABLED`, unchanged from before).
- **Play level resolution.** New `PlayLevelResolver` (`scripts/game/progression/play_level_resolver.gd`) implements `resolve_play_level_id(progress_manager, level_catalog)`: walks the catalog's ordered levels and returns the highest one for which `progress_manager.is_level_unlocked()` is true, falling back to `level_catalog.get_default_level_id()` (`"level_1"`) whenever progress/catalog data is missing or the resolved id isn't in the catalog. There is no persisted "last played level" field yet (`PlayerProgress` has none) — that is deferred to a future patch, as called out in the task; Играть always recomputes from unlock state today. `App._on_main_menu_play_pressed()` calls this resolver and opens `GameScreen` for the result.
- **Level Select flow.** MainMenu's Выбрать уровень opens `LevelSelectScreen` unchanged. `LevelSelectScreen` gained a `back_pressed` signal and a `%BackButton` ("Назад") in its top bar; `App` wires it to return to MainMenu. Level buttons, zone selector, lock/completion/star state, and routing straight to `GameScreen` on selection are all unchanged.
- **Shop placeholder.** New `ShopPlaceholderScreen` (`scripts/screens/shop_placeholder_screen.gd`, `scenes/screens/ShopPlaceholderScreen.tscn`) shows title "Магазин", message "Скоро будет доступно", and a "Назад" button that emits `back_pressed`. No economy, currency, product, purchase, ad, or reward logic was added. `App._show_shop_placeholder()`/`_on_shop_placeholder_back_pressed()` wire MainMenu's Магазин button to it and its Назад button back to MainMenu.
- **Settings reuse.** MainMenu's Настройки and LevelSelect's Settings both open the existing `SettingsScreen` — no duplicate settings implementation. `App` now tracks `_settings_return_screen` ("main_menu" or "level_select"), set by `_on_main_menu_settings_pressed()`/`_on_level_select_settings_pressed()` right before showing Settings, so Settings' Back button returns to whichever screen actually opened it instead of always landing on LevelSelect.
- **GameScreen unchanged.** `GameScreen`'s Menu/Back button and `BattleResultOverlay`'s Next Level/Retry/Levels actions still route back to LevelSelect (`App._on_game_back_pressed()`), per this stage's scope — GameScreen itself was not asked to route to MainMenu.
- **Navigation ownership.** All new navigation is signal-based (`play_pressed`, `level_select_pressed`, `shop_pressed`, `settings_pressed`, `back_pressed`) and wired centrally in `App` (`scripts/app/app.gd`), consistent with the existing `ScreenRouter` pattern — no cross-screen business logic was added to button scripts themselves.
- **Tests updated, not run.** `direct_startup_flow_test.gd`, `navigation_flow_test.gd`, `settings_flow_test.gd`, `audio_settings_integration_test.gd`, and `hero_systems_freeze_test.gd` were updated to assert the new MainMenu-first navigation graph (startup screen, new signals/buttons, Settings return-target behavior). No automated tests were run — manual verification in the Godot editor is expected.

## Stage 62.1: Player Wallet and Booster Inventory Foundation v0.1

Stage 62.1 is complete. It adds the persisted data/API foundation for the player economy — gold, gems, and a global cross-battle booster inventory — with no gameplay wiring yet. Battle booster spending, star milestone rewards, shop catalog/purchase logic, and shop UI tabs are deferred to Stages 62.2-62.5. Deterministic layouts, level boosts, fixed enemy HP/move curve, holes, ice, no-move shuffle, current per-battle booster behavior, battle result flow, and settings are all unchanged.

- **Currency identifiers.** New `CurrencyType` (`scripts/game/economy/currency_type.gd`) defines stable string IDs `GOLD := "gold"` and `GEMS := "gems"`, with `ALL_IDS`/`is_valid()` helpers.
- **Booster inventory reuses existing catalog IDs.** The inventory is keyed by `BoosterCatalog`'s own IDs — `hammer`, `freeze_time` (the catalog's actual constant; the task's suggested "time_freeze" isn't the real ID), `rocket_barrage` — via `PlayerProgress.get_default_booster_ids()` delegating to `BoosterCatalog.new().get_default_booster_ids()`, so future boosters need no save-format change.
- **`PlayerProgress` wallet fields.** New `gold`/`gems` int fields (default `0`) plus `get_currency()`, `add_currency()`, `can_spend_currency()`, `spend_currency()`. Values never go negative; unknown currency IDs and non-positive amounts fail/are ignored safely.
- **`PlayerProgress` booster inventory.** New `booster_inventory: Dictionary` (booster_id -> count, defaulting every catalog booster to `0`) plus `get_booster_count()`, `add_booster()`, `has_booster()`, `spend_booster()`. Counts never go negative; unknown IDs read back as `0`; spending more than available fails safely and leaves the inventory untouched.
- **Save migration.** `PlayerProgress.from_dictionary()` reads `currencies`/`booster_inventory` from saved data, sanitizes every value to a safe non-negative int, and backfills missing gold/gems/booster entries to `0` — older saves load without any manual reset.
- **Serialization.** `to_dictionary()` gained `"currencies": {"gold", "gems"}` and `"booster_inventory": {...}`, persisted through the existing unchanged `SaveManager` JSON pipeline.
- **`ProgressManager` wrapper methods.** New `get_currency()`, `add_currency()`, `can_spend_currency()`, `spend_currency()`, `get_booster_count()`, `add_booster()`, `has_booster()`, `spend_booster()`, each mutating call saving through the existing `save()` pipeline just like `add_victory_reward()`/`complete_level()`.
- **Debug visibility.** New `PlayerProgress.get_economy_debug_summary()`/`ProgressManager.get_economy_debug_summary()` return a compact `"gold=0, gems=0, hammer=0, freeze_time=0, rocket_barrage=0"`-style string for ad-hoc debug use; no dedicated UI yet.
- **No gameplay wiring.** `BoosterState`/`BoosterResolver` battle-time booster uses are unchanged (still unlimited per-battle uses via the catalog, no currency cost, no inventory check); `GameScreen`/`LevelSelectScreen` don't call any new economy methods this stage.
- **No automated tests were run.** Code and documentation only — manual verification in the Godot editor is expected.

## Stage 62.2: Global Booster Spending v0.1

Stage 62.2 is complete. It connects the Stage 62.1 global booster inventory to the actual battle booster flow: counts are shown in battle, a zero-count booster can't be activated, and exactly one global booster is spent per successful use, saved through `ProgressManager`. Battle-local `BoosterState` (selection, per-battle uses-left, Time Freeze turns) is unchanged; `PlayerProgress.booster_inventory` is the separate cross-battle resource count. Star rewards, shop catalog/purchases, and shop UI tabs remain unimplemented; gold/gems storage, deterministic layouts, level boosts, fixed enemy HP/move curve, holes, ice, no-move shuffle, and victory/defeat/result flow are all unchanged.

- **Booster counts shown in battle.** `BoosterPanel` gained `set_booster_counts(counts: Dictionary)` (e.g. `{"hammer": 3, "freeze_time": 1, "rocket_barrage": 0}`). Each button's numeric label now shows the global inventory count (e.g. "Hammer x3") instead of the battle-local uses-left. A button is disabled when either the battle-local uses-left is 0 or the global count is 0.
- **`GameScreen` inventory helpers.** New `_get_booster_inventory_counts()`, `_has_global_booster(booster_id)`, `_spend_global_booster(booster_id)`, `_refresh_booster_inventory_ui()`, all built on `ProgressManager.get_booster_count()`/`has_booster()`/`spend_booster()`. Every one fails safely to zero/`false` when no `ProgressManager` is attached, never crashing.
- **Inventory gate before activation.** `_on_booster_pressed()` checks `_has_global_booster(booster_id)` right after the existing battle-local `can_use()` check, before either the Time Freeze activation call or Hammer/Rocket Barrage targeting mode is entered. A blocked press shows `"No boosters left."` and never reaches the resolver. Selecting a booster, entering targeting mode, and cancelling targeting never spend inventory.
- **Spend only on successful use, exactly once.** `_on_booster_resolved(result)` is the single point every valid booster result (Time Freeze, Hammer, Rocket Barrage alike) funnels through exactly once, so `_spend_global_booster(result.booster_id)` fires exactly once per successful use and never for an invalid/failed/cancelled attempt.
- **UI refresh and save-through.** The booster panel refreshes immediately after a successful spend (locking the button if the count hits 0); `ProgressManager.spend_booster()` already saves through `SaveManager` on success, so spending persists immediately rather than only at victory/defeat. An unexpected spend failure (defensive-only) appends `" (booster spend failed)"` to the final status text instead of being silently dropped.
- **Tests updated.** `booster_panel_test.gd`, `game_screen_booster_flow_test.gd`, `booster_animation_flow_test.gd`, `booster_gravity_refill_animation_test.gd`, and `booster_damage_effect_flow_test.gd` now wire a real `ProgressManager` with inventory before pressing booster buttons (activation requires it now); `game_screen_booster_flow_test.gd` also covers the no-`ProgressManager` fails-safely case. No automated tests were run as project policy — manual verification in the Godot editor is expected.

## Stage 62.1.1: Ice Blocks Player Swaps Hotfix v0.1

Stage 62.1.1 is complete. It fixes a critical gameplay bug where a crystal sitting on an iced cell could still be used as a valid player swap endpoint. Ice is a cell obstacle/debuff, not just a visual overlay, and a swap must be rejected if either endpoint is iced. `SwapResolver` is the single shared enforcement point, so normal player swaps, `AvailableMoveFinder`'s available-move scan, and `BoardShuffleResolver`'s post-shuffle move check all inherit the same rule automatically. Gravity/refill, `BoardModel.swap_tiles()`, the obstacle layer, and ice damage rules are unchanged.

- **`SwapResolver.try_swap()` rejects iced endpoints.** A new check, `board.is_cell_iced(from_cell) or board.is_cell_iced(to_cell)`, returns `SwapResult.new(false, from_cell, to_cell, [], "iced_cell")`. It runs after the existing `out_of_bounds`/`inactive_cell` checks and before `not_adjacent`/`no_match`, giving the deterministic validation order `out_of_bounds` -> `inactive_cell` -> `iced_cell` -> `not_adjacent` -> `no_match`. It reuses the existing `BoardModel.is_cell_iced(cell)` helper; no new board API was added.
- **`AvailableMoveFinder` inherits the rule for free.** `has_available_move()` runs every trial swap through `SwapResolver.try_swap()` on a duplicated board, so a candidate swap into or out of an iced cell is now rejected the same way a real player swap is and is never reported as an available move. Its doc comment was updated to say so explicitly.
- **`BoardShuffleResolver` unaffected by design.** Shuffling only rearranges crystal payloads (`tile_type`/`special_data`) on active cells; it never touches the obstacle/ice layer, so ice stays exactly where it was before and after a shuffle. After a shuffle attempt, `AvailableMoveFinder` evaluates the result using the new ice-blocked swap rule like everywhere else.
- **Player-facing message.** `BattleMessageFormatter.format_invalid_swap_message()` gained `"iced_cell"` -> `"Frozen cells cannot be swapped."`, alongside the existing `no_match`/`not_adjacent` mappings, so a blocked-by-ice swap attempt shows readable text instead of falling through to the generic "That swap doesn't work" case.
- **Tests added.** `board_core_test.gd` gained `_test_swap_from_iced_cell_rejected()`, `_test_swap_to_iced_cell_rejected()` (both assert `reason == "iced_cell"` and that the board state is left unapplied), and `_test_inactive_cell_rejected_before_iced_cell()` (confirms `inactive_cell` still wins when a swap endpoint is both inactive and the paired cell is iced). `battle_message_formatter_test.gd` gained a case for the new `"iced_cell"` message. No automated tests were run as project policy — manual verification in the Godot editor is expected.
- **Unchanged by design.** `BoardModel.swap_tiles()`, gravity, refill, obstacle layer storage, ice damage rules (direct clear + orthogonal neighbor damage, weak-breaks-in-one-hit, strong-becomes-weak), ice generation/layouts, deterministic layouts, level boosts, fixed enemy HP/move curve, holes, no-move shuffle algorithm, boosters, economy, star rewards, shop systems, and victory/defeat/result flow are all untouched.

## Stage 62.3: Star Milestone Rewards v0.1

Stage 62.3 is complete. It adds one-time rewards for star milestones on level completion, built on the Stage 62.1 wallet/booster inventory and the Stage 62.2 global booster spending: 1 star unlocks the next level, 2 stars grants +10 gold, and 3 stars grants one random booster — each granted only the first time a level crosses that star threshold. The shop (spending this currency) remains planned for Stages 62.4/62.5.

- **New `LevelStarRewardResolver`** (`scripts/game/progression/level_star_reward_resolver.gd`). Pure resolver: `resolve_milestone_rewards(previous_stars, new_stars, next_level_id, rng)` compares the level's stars before and after this completion and returns a reward only for thresholds newly crossed (`previous_stars < N and new_stars >= N`), so replaying an already-earned milestone (e.g. `3 -> 3`) returns no rewards. The 1-star unlock reward is only included if `next_level_id` is non-empty (no reward text for the final level). The 3-star reward picks one random booster id from `get_booster_reward_pool()` (`BoosterCatalog.HAMMER`/`FREEZE_TIME`/`ROCKET_BARRAGE` — reusing the catalog's real IDs, no duplicated strings) via an injected `RandomNumberGenerator`.
- **Structured reward data.** Each reward is a `Dictionary` with a `type` (`"unlock_level"`, `"currency"`, `"booster"` — exposed as resolver constants), a `milestone_star` (1/2/3), and type-specific fields (`level_id` for unlocks, `currency_id`/`amount` for currency, `booster_id`/`amount` for boosters).
- **`ProgressManager.complete_level_with_rewards(level_config, moves_left, level_catalog) -> Dictionary`.** Reads `previous_stars` via the existing `get_level_stars()` before applying the victory result (so the pre-completion value is captured correctly), applies `LevelCompletionResolver.apply_victory_result()` exactly as `complete_level()` already did, resolves milestone rewards, applies currency/booster rewards directly against `progress` (bypassing the `add_currency()`/`add_booster()` wrapper methods' own `save()` calls), then calls `save()` once at the end — one victory now saves exactly once instead of stacking a save per reward. Returns `level_progress_state`, `previous_stars`, `new_stars`, `rewards`, `unlocked_next_level`, `gold_awarded`, `booster_awarded`. The older `complete_level()` method is unchanged and still used by existing tests.
- **`GameScreen._save_victory_completion_once()`** now calls `complete_level_with_rewards()` instead of `complete_level()`, passing `_level_catalog` through, and threads the returned `rewards` array into `_build_victory_result_data()`'s new `"milestone_rewards"` key. `_refresh_booster_inventory_ui()` is called right after, so a 3-star booster reward is reflected in the booster panel immediately. Existing next-level/zone-unlock detection (already computed from before/after `is_level_unlocked()`/`_is_zone_unlocked_for_level()` snapshots) is untouched — the 1-star reward entry is purely informational for the result overlay and does not duplicate or replace that unlock logic.
- **New `LevelRewardFormatter`** (`scripts/game/presentation/level_reward_formatter.gd`). `format_rewards_text(rewards: Array) -> String` turns a rewards array into display lines ("Next level unlocked", "+10 Gold", "+1 Hammer", "+1 Time Freeze", "+1 Rocket Barrage"), falling back to `"No new rewards"` when the array is empty. Booster labels come from `BoosterCatalog.get_booster(id).display_name`, not hardcoded strings.
- **`BattleResultOverlay` reward summary.** New `%MilestoneRewardLabel` node in `BattleResultOverlay.tscn` (between `UnlockLabel` and the button row) and a `milestone_reward_label` binding in the script; `show_victory_result()` sets its text from `LEVEL_REWARD_FORMATTER_SCRIPT.format_rewards_text(data.get("milestone_rewards", []))`. Hidden (empty text) on defeat.
- **Unchanged by design.** Global booster spending in battle, gold/gems storage, booster inventory storage, the shop placeholder, deterministic layouts/boosts, fixed enemy HP/move curve, holes, ice, no-move shuffle, and the overall victory/defeat/result flow structure are all untouched.
- **No automated tests were added, updated, touched, or run.** Manual verification in the Godot editor is expected.

## Next Planned Stages

- Stage 26-30 block is complete. Stage 31 (hero portrait buttons and ability bars) is complete. Stage 32 (hero systems freeze and direct match damage foundation) is complete. Stage 33 (round modifiers and color damage rules) is complete. Stage 34 (direct match-3 balance pass) is complete. Stage 35 (direct LevelSelect startup and simplified UX polish) is complete. Stage 36 (ImageSlot asset placeholder pipeline) is complete. Stage 37 (asset loading integration for active imageholders) is complete. Stage 38 (AudioManager foundation) is complete. Stage 39 (Complete AssetKey texture binding) is complete. Stage 40 (Booster system foundation) is complete. Stage 41 (Board animation foundation) is complete. Stage 42 (Swap and match clear animations) is complete. Stage 43 (Gravity, refill and cascade animation flow) is complete. Stage 44 (Damage particles and enemy hit feedback) is complete. Stage 45 (Gameplay animation timeline stabilization) is complete. Stage 46 (Stepwise board resolution animation pipeline) is complete. Stage 47 (Animation QA and board visual stability pass) is complete. Stage 48 (Special tile activation animations) is complete. Stage 49 (Booster targeting and booster animation polish) is complete. Stage 49.1 (Stronger booster affected-cell preview) is complete. Stage 50 (Result screen and level flow UX polish) is complete. Stage 51 (Procedural challenge archetype foundation) is complete. Stage 52 (Active cell mask core) is complete. Stage 53 (Gravity and refill for masked boards) is complete. Stage 53.1 (Procedural hole generation rules foundation) is complete. Stage 54 (Procedural holes generator) is complete. Stage 54.1 (Hole shape variety and center-aware generation) is complete. Stage 54.2 (Gravity pass-through for inactive cells) is complete. Stage 55 (Inactive cell visual presentation and pass-through polish) is complete. Stage 55.1 (Inactive overlay stability and center-hole generation unlock) is complete. Stage 56 (Ice obstacle core) is complete. Stage 57 (Procedural ice generator) is complete. Stage 57.1 (Symmetric ice patterns and stronger ice visuals) is complete. Stage 57.2 (Ice density and cycle variant rules) is complete. Stage 57.3 (Debug ice visibility filter) is complete. Stage 57.4 (Rectangular ice clusters and symmetry completion) is complete. Stage 57.5 (Cell-anchored ice overlays and per-step ice sync) is complete. Stage 58 (Deterministic 500-level layout database) is complete. Stage 59 (Deterministic layout QA and no-move shuffle protection) is complete. Stage 59.1 (No-move shuffle integration and QA report finalization) is complete. Stage 60.1 (Fixed enemy HP and move curve baseline) is complete. Stage 60.2 (Level boost system foundation) is complete. Stage 60.3 (Deterministic 500-level boost database) is complete. Stage 61 (Main menu restoration) is complete. Stage 62.1 (Player wallet and booster inventory foundation) is complete. Stage 62.2 (Global booster spending) is complete. Stage 62.1.1 (Ice blocks player swaps hotfix) is complete. Stage 62.3 (Star milestone rewards) is complete.
- Next roadmap stages (not yet started): challenge cycle balance passes once `normal`/`ice`/`holes` all affect difficulty across the full campaign, new ice-related win goals, richer generated-challenge validation/retry beyond the current full-board fallback, UX polish for archetype-specific board presentation (including retiring the Stage 57.3 debug ice filter once final ice art ships), hand-authored/tuned overrides for individual deterministic levels/boosts on top of the Stage 58/60.3 databases, a real `LevelBoostPanel`-specific UI (icon/art) beyond reusing the round modifier panel's nodes, persisted "last played level" progress for Играть, icon/art for star milestone rewards, Stage 62.4 (shop catalog and purchase logic spending the gold from Stage 62.3), and Stage 62.5 (shop UI tabs replacing the Stage 61 `ShopPlaceholderScreen`).
- Isolated Yandex Games platform adapter under `scripts/platform/` when explicitly requested.
