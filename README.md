# Tri V Ryad

Tri V Ryad is a Godot 4.x match-3 battle game intended for Yandex Games and Web-first release targets.

The project is currently through Stage 22: Battle HUD restructure v0.2. It defines the app shell, a MainMenu with Play, Heroes, and Settings entry points, a level-select-only level flow, a pre-battle team confirmation flow, a menu-accessible full roster hero upgrade screen, a persistent Settings screen, a playable 9x9 board with placeholder tiles, hybrid two-click plus drag/swipe swapping, UI-independent board and battle logic, line special tiles, color bombs, damage-only roster ability mappings, local hero upgrades, saved campaign progress, and lightweight swap, clear, special activation, and refill feedback for a vertical 9:16 game.

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
- A MainMenu with Play, Heroes, and Settings buttons.
- A `LevelSelectScreen` with 10 early campaign level buttons, lock/completion/star state, and routing to `TeamSelectScreen`.
- A `TeamSelectScreen` that confirms or edits the saved 3-hero team before starting the selected level.
- A main-menu `UpgradeScreen` route for roster hero upgrades.
- A persistent `SettingsScreen` route for presentation/audio setting toggles.
- A playable battle screen with a top enemy panel, compact Level/Moves/Menu HUD row, widened 9x9 `BoardView`, placeholder `TileView` tiles, hero party panel, status text, result overlay, and a Menu button.
- Reusable UI components: `BattleHud`, `EnemyPanel`, `HeroPartyPanel`, `HeroCard`, and `BattleResultOverlay`.
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
- Data-driven configs under `scripts/game/config/`: `HeroConfig`, `EnemyConfig`, `LevelConfig`, and `LevelCatalog`.
- `LevelCatalog` contains a 10-level early campaign slice from Training Dummy through Gatekeeper.
- Hero roster definitions under `scripts/game/config/` with `HeroCatalog`.
- `HeroConfig` carries immutable base hero stats plus `ability_id`.
- `BattleFactory` creates battle state from level configs or the saved selected team when `PlayerProgress` and `HeroCatalog` are available.
- Selected team order maps to Hero Lanes: slot 1 to lane 0, slot 2 to lane 1, and slot 3 to lane 2.
- Local progression under `scripts/game/progression/`: `PlayerProgress`, `HeroUpgradeState`, `UpgradeResolver`, and `ProgressManager`.
- Saved team selection under `scripts/game/progression/` with `TeamSelectionState` and `TeamSelectionResolver`.
- `PlayerProgress` stores selected team IDs, and `ProgressManager` is the boundary for reading, validating, saving, and normalizing selected team data.
- Saved level progress under `scripts/game/progression/`: `LevelProgressState` and `LevelCompletionResolver`.
- Local save handling under `scripts/game/save/` with `SaveManager`.
- Progress, completion, stars, and hero upgrades are saved locally to `user://save_v1.json`.
- Selected team data is saved locally to `user://save_v1.json`.
- Missing, incomplete, duplicated, or unknown saved team data falls back to the default team: `hero_1`, `hero_2`, `hero_3`.
- Victory grants `LevelConfig.reward_upgrade_points`, and rewards can be earned repeatedly in v0.1.
- Victory saves level completion and stars based on remaining moves.
- Best stars and best remaining moves are preserved across replays.
- Sequential unlocks open each next level after the previous level is completed.
- `LevelSelectScreen` shows locked, open, completed, and star state for each level.
- Upgrade points can raise each hero's attack level or HP level.
- `UpgradeScreen` now acts as the full roster character upgrade screen.
- `UpgradeScreen` shows all 5 `HeroCatalog` heroes, current upgrade points, ability IDs, attack/HP levels, current attack/HP, next attack/HP previews, and +Attack/+HP buttons.
- +Attack/+HP purchases go through `ProgressManager` and `UpgradeResolver`.
- Old saves without `hero_4` or `hero_5` upgrade records are handled safely and create those records when displayed or upgraded.
- The victory overlay only shows reward/stars and links to Heroes; it does not contain upgrade spending UI.
- `BattleFactory` combines base `HeroConfig` data with mutable `PlayerProgress` when creating battle heroes.
- A `BattlePresenter` that coordinates the fixed prototype battle without platform, save, ad, or SDK code.
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
- Progression tests in `scripts/tests/progression_test.gd`.
- Save manager tests in `scripts/tests/save_manager_test.gd`.
- Battle factory progress tests in `scripts/tests/battle_factory_progress_test.gd`.
- Level completion tests in `scripts/tests/level_completion_test.gd`.
- Special tile tests in `scripts/tests/special_tile_test.gd`.
- Documentation for future implementation rules.

This stage excludes:

- Wrapped bombs, special + special combos, special battle damage, cascade damage, full cascade-step animation, full falling animation, real tile movement, particles, sound, and final art.
- Target selection, cooldowns, ability upgrades, gacha, rarity, hero unlocks, hero shards, hero inventory, portraits, final art, drag-and-drop team UI, and complex ability additions.
- One-time rewards, stars-based rewards, level map, chapters, complex economy, max upgrade levels, scaling upgrade costs, reset upgrades, and complex objectives.
- New heroes, hero unlocks, gacha, rarity, shards, ability upgrades, TeamSelectScreen rework, Yandex SDK, cloud save, ads, payments, sound, particles, and final art.
- Cloud saves, ads, payments, Yandex SDK, RuStore, Android-specific code, and monetization.

## Stage 16: Balance and Content Expansion v0.1

Stage 16 is complete. The project now has a 10-level early campaign slice using the existing defeat-the-enemy objective, enemy HP/attack fields, move limits, and repeatable `reward_upgrade_points`.

The curve is intentionally simple: levels 1-2 are forgiving intro fights, levels 3-4 are light challenge, levels 5-6 begin to reward upgrades, levels 7-9 are noticeably harder, and level 10 is an early Gatekeeper mini-boss. Balance is v0.1 and expected to change after playtesting.

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

## How To Open And Run

1. Open Godot 4.x.
2. Import or open this folder as a Godot project.
3. Run the project. The configured main scene is `res://scenes/app/App.tscn`.
4. From MainMenu, press Play to open LevelSelect.
5. Choose an unlocked level to open TeamSelect.
6. Confirm or change your team, then press Start Battle to open GameScreen with that level.
7. Click one tile, then click a neighboring tile to attempt a swap, or drag/swipe from a tile toward a neighbor.
8. Win a battle to earn upgrade points, save completion, earn stars, and unlock the next level.
9. From MainMenu, press Heroes to open UpgradeScreen and spend upgrade points.
10. From MainMenu, press Settings to open SettingsScreen and toggle Animations, Reduced Motion, Debug Labels, Music, and Sound Effects.
11. Press Menu/Back to return to the previous screen.

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

Run the balance curve test with:

```bash
godot --headless --script res://scripts/tests/balance_curve_test.gd
```

Run the battle factory test with:

```bash
godot --headless --script res://scripts/tests/battle_factory_test.gd
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

Run the navigation flow test with:

```bash
godot --headless --script res://scripts/tests/navigation_flow_test.gd
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

## Next Planned Stages

- Stage 23: Level identity cleanup v0.2: numbers only.
- Isolated Yandex Games platform adapter under `scripts/platform/` when explicitly requested.
