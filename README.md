# Tri V Ryad

Tri V Ryad is a Godot 4.x match-3 battle game foundation intended for Yandex Games and Web-first release targets.

The project is currently in the foundation-only stage. It defines the app shell, simple screen navigation, placeholder UI, project settings, and design direction for a vertical 9:16 game. Gameplay systems are intentionally not implemented yet.

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
- A game screen placeholder with an enemy area, HUD, visual 9x9 board, lane divisions, hero cards, and a Menu button.
- Documentation for future implementation rules.

This stage excludes:

- Match-3 logic.
- Tile swapping.
- Board model/state.
- Battle state, damage, HP, abilities, and progression.
- Saves, ads, payments, Yandex SDK, RuStore, Android-specific code, and final art.

## How To Open And Run

1. Open Godot 4.x.
2. Import or open this folder as a Godot project.
3. Run the project. The configured main scene is `res://scenes/app/App.tscn`.
4. Press Play on the main menu to view the placeholder game screen.
5. Press Menu to return to the main menu.

## Next Planned Stages

- Battle screen and adaptive layout foundation.
- Board model and tile view split.
- Match input and match detection.
- Hero lane activation rules.
- Basic battle loop.
- Isolated Yandex Games platform adapter under `scripts/platform/` when explicitly requested.
