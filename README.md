# Tri V Ryad

Tri V Ryad is a Godot 4.x match-3 battle game intended for Yandex Games and Web-first release targets.

The project is currently in the Character upgrade screen v0.2 from the menu stage. It defines the app shell, simple screen navigation, a level select flow, a saved 5-hero roster/team selection flow, a menu-accessible full roster hero upgrade screen, a playable 9x9 board with placeholder tiles, hybrid two-click plus drag/swipe swapping, UI-independent board and battle logic, first line special tiles, roster ability mappings, data-driven test battles, local hero upgrades, saved campaign progress, and lightweight swap, clear, and refill feedback for a vertical 9:16 game.

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
- A main menu placeholder with a Play button.
- A simple `LevelSelectScreen` with 5 test level buttons.
- A Team button on `LevelSelectScreen` that opens `TeamSelectScreen`.
- A Heroes button on `LevelSelectScreen` that opens `UpgradeScreen`.
- `TeamSelectScreen` shows 5 placeholder roster heroes and lets the player save exactly 3 unique selected heroes.
- A playable battle screen with a HUD, enemy panel, 9x9 `BoardView`, placeholder `TileView` tiles, hero party panel, status text, result overlay, and a Menu button.
- Reusable UI components: `BattleHud`, `EnemyPanel`, `HeroPartyPanel`, `HeroCard`, and `BattleResultOverlay`.
- A lightweight `LayoutManager` for UI-only portrait and landscape layout decisions.
- UI-independent board generation, match detection, swap validation, gravity/refill, and cascade resolution under `scripts/game/board/`.
- Special tile board logic under `scripts/game/board/`: `SpecialTileType`, `SpecialTileData`, and `SpecialTileResolver`.
- `BoardModel` keeps base tile type storage as the match color/type and stores special tile metadata in a separate layer.
- Match 4+ creates a line special tile at a deterministic match cell.
- Horizontal matches create horizontal line specials, and vertical matches create vertical line specials.
- Activated horizontal line specials clear their row; activated vertical line specials clear their column.
- Special metadata moves with tiles during swaps and gravity, and refilled tiles have no special metadata.
- `TileView` shows simple placeholder `H`/`V` markers for special tiles.
- UI-independent battle logic under `scripts/game/battle/`: heroes, enemy, battle state, Hero Lane activation, damage, ability charge, enemy intent/action, and turn results.
- Data-driven configs under `scripts/game/config/`: `HeroConfig`, `EnemyConfig`, `LevelConfig`, and `LevelCatalog`.
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
- Three starter abilities: Power Strike, Line Break, and Rally Heal.
- Roster heroes use `ability_id` mapping: Warrior and Mage use Power Strike, Guardian and Ranger use Line Break, and Healer uses Rally Heal.
- Ability readiness in `HeroCard`, with ability requests routed through `BattlePresenter`.
- Ability feedback for damage, healing, row clears, and rejected requests.
- Ability use does not consume moves or tick enemy intent.
- Hybrid tile swapping through `BoardInputController`: two-click fallback, mouse drag, and touch/swipe style input.
- `BoardMotionAnimator` coordinates view-only board motion feedback without changing board, battle, progression, or save rules.
- Lightweight `TileView` animation helpers for swap pulses, invalid pulses, match fade, refill appear, and visual reset.
- `BoardView` exposes presentation-only animation helpers over existing tile views.
- Valid swaps get a short visual pulse/flash on the swapped cells.
- Invalid swaps get brief rejection feedback on the involved cells.
- Matched cells highlight and fade before board refresh/refill feedback.
- Board refresh/refill gets lightweight appear feedback; this is not full falling animation.
- Input locking during turn feedback and after victory/defeat remains tied to `feedback_finished`.
- Swapped cell feedback, invalid swap feedback, match highlights, refill feedback, Hero Lane highlights, and short damage/enemy action status messages.
- Live HUD, enemy, and hero updates.
- Basic victory/defeat overlay with restart flow.
- Headless board core tests in `scripts/tests/board_core_test.gd`.
- Headless battle core tests in `scripts/tests/battle_core_test.gd`.
- Playable battle smoke test in `scripts/tests/playable_battle_smoke_test.gd`.
- Board input controller tests in `scripts/tests/board_input_controller_test.gd`.
- Turn presentation data tests in `scripts/tests/turn_presentation_data_test.gd`.
- Ability core tests in `scripts/tests/ability_core_test.gd`.
- Ability presentation data tests in `scripts/tests/ability_presentation_data_test.gd`.
- Level config tests in `scripts/tests/level_config_test.gd`.
- Battle factory tests in `scripts/tests/battle_factory_test.gd`.
- Progression tests in `scripts/tests/progression_test.gd`.
- Save manager tests in `scripts/tests/save_manager_test.gd`.
- Battle factory progress tests in `scripts/tests/battle_factory_progress_test.gd`.
- Level completion tests in `scripts/tests/level_completion_test.gd`.
- Special tile tests in `scripts/tests/special_tile_test.gd`.
- Documentation for future implementation rules.

This stage excludes:

- Color bombs, wrapped bombs, special + special combos, special battle damage, cascade damage, full cascade-step animation, full falling animation, real tile movement, particles, sound, and final art.
- Target selection, cooldowns, ability upgrades, gacha, rarity, hero unlocks, hero shards, hero inventory, portraits, final art, drag-and-drop team UI, and complex ability additions.
- One-time rewards, stars-based rewards, level map, chapters, complex economy, max upgrade levels, scaling upgrade costs, reset upgrades, and complex objectives.
- New heroes, hero unlocks, gacha, rarity, shards, ability upgrades, TeamSelectScreen rework, Yandex SDK, cloud save, ads, payments, sound, particles, and final art.
- Cloud saves, ads, payments, Yandex SDK, RuStore, Android-specific code, and monetization.

## How To Open And Run

1. Open Godot 4.x.
2. Import or open this folder as a Godot project.
3. Run the project. The configured main scene is `res://scenes/app/App.tscn`.
4. Press Play on the main menu to open level select.
5. Choose a level to start that battle.
6. Click one tile, then click a neighboring tile to attempt a swap, or drag/swipe from a tile toward a neighbor.
7. Win a battle to earn upgrade points, save completion, earn stars, and unlock the next level.
8. Open Heroes from level select or the victory overlay.
9. Open Team from level select to choose and save exactly 3 roster heroes.
10. Press Menu to return to level select.

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

## Next Planned Stages

- Define the next 5 medium-sized stages after Character upgrade screen v0.2.
- Isolated Yandex Games platform adapter under `scripts/platform/` when explicitly requested.
