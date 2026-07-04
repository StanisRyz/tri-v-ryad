# Tri V Ryad

Tri V Ryad is a Godot 4.x match-3 battle game intended for Yandex Games and Web-first release targets.

The project is currently in the Level System and Data-Driven Battle Configs stage. It defines the app shell, simple screen navigation, a level select flow, a playable 9x9 board with placeholder tiles, hybrid two-click plus drag/swipe swapping, UI-independent board and battle logic, three starter hero abilities, and data-driven test battles for a vertical 9:16 game.

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

Future match combinations will activate heroes based on the columns involved. Heroes may later charge abilities from matched tiles in their lanes. Upgrade points after battle will later improve hero attack and HP.

## Current Status

This stage includes:

- A Godot project with `scenes/app/App.tscn` as the main scene.
- A minimal screen router.
- A main menu placeholder with a Play button.
- A simple `LevelSelectScreen` with 5 test level buttons.
- A playable battle screen with a HUD, enemy panel, 9x9 `BoardView`, placeholder `TileView` tiles, hero party panel, status text, result overlay, and a Menu button.
- Reusable UI components: `BattleHud`, `EnemyPanel`, `HeroPartyPanel`, `HeroCard`, and `BattleResultOverlay`.
- A lightweight `LayoutManager` for UI-only portrait and landscape layout decisions.
- UI-independent board generation, match detection, swap validation, gravity/refill, and cascade resolution under `scripts/game/board/`.
- UI-independent battle logic under `scripts/game/battle/`: heroes, enemy, battle state, Hero Lane activation, damage, ability charge, enemy intent/action, and turn results.
- Data-driven configs under `scripts/game/config/`: `HeroConfig`, `EnemyConfig`, `LevelConfig`, and `LevelCatalog`.
- `BattleFactory` creates battle state from level configs.
- A `BattlePresenter` that coordinates the fixed prototype battle without platform, save, ad, or SDK code.
- `BattlePresenter.start_level(level_id)` starts selected levels, and Restart preserves the current level.
- Three starter abilities: Power Strike, Line Break, and Rally Heal.
- Ability readiness in `HeroCard`, with ability requests routed through `BattlePresenter`.
- Ability feedback for damage, healing, row clears, and rejected requests.
- Ability use does not consume moves or tick enemy intent.
- Hybrid tile swapping through `BoardInputController`: two-click fallback, mouse drag, and touch/swipe style input.
- Input locking during turn feedback and after victory/defeat.
- Swapped cell feedback, invalid swap feedback, match highlights, Hero Lane highlights, and short damage/enemy action status messages.
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
- Documentation for future implementation rules.

This stage excludes:

- Full cascade animations, real tile movement, particles, sound, and final art.
- Target selection, cooldowns, ability upgrades, hero selection UI, level unlocks, and progression.
- Saved level completion, unlocks, stars, upgrade rewards, and complex objectives.
- Saves, ads, payments, Yandex SDK, RuStore, Android-specific code, and final art.

## How To Open And Run

1. Open Godot 4.x.
2. Import or open this folder as a Godot project.
3. Run the project. The configured main scene is `res://scenes/app/App.tscn`.
4. Press Play on the main menu to open level select.
5. Choose a level to start that battle.
6. Click one tile, then click a neighboring tile to attempt a swap, or drag/swipe from a tile toward a neighbor.
7. Press Menu to return to level select.

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

## Next Planned Stages

- Upgrade points, hero progression, and local save v0.1.
- Improve board animation polish for swap, clear, fall, and refill.
- Isolated Yandex Games platform adapter under `scripts/platform/` when explicitly requested.
