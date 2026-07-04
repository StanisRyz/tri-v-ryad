# Agent Guidelines

This is a Godot match-3 battle project intended for Yandex Games. The default layout is vertical 9:16 portrait with a 720x1280 base resolution.

The current stage is foundation only. Do not implement gameplay unless a future task explicitly asks for it.

## Project Rules

- Use small or medium focused patches.
- Do not implement unrelated systems.
- Use English file and folder names only.
- Do not use spaces or Russian characters in file paths.
- Prefer Control-based UI, containers, and anchors.
- Keep gameplay logic separate from UI.
- Keep platform SDK logic separate from gameplay.
- Do not add third-party plugins without explicit request.
- Do not add generated heavy files.

## Gameplay Direction

- The game is a match-3 battle game.
- The board will be 9x9.
- The key mechanic is Hero Lanes.
- Hero 1 owns columns 1-3.
- Hero 2 owns columns 4-6.
- Hero 3 owns columns 7-9.
- Future matches will activate heroes based on affected columns.
- Future progression will award upgrade points after battle for hero attack and HP.

## Platform Boundaries

- The game is intended for Yandex Games / Web first.
- Do not add Yandex SDK integration during the foundation stage.
- When Yandex SDK support is added later, isolate it under `scripts/platform/`.
- Gameplay and UI scripts must never call the Yandex SDK directly.
- Use platform adapter scripts or services as the boundary between SDK code and the rest of the project.
- Do not add ads, saves, payments, RuStore, Android-specific code, or monetization during this stage.

## Current Exclusions

- No match detection.
- No tile swapping.
- No board model.
- No battle state.
- No damage, HP, or abilities.
- No save system.
- No ads or monetization.
- No Yandex SDK.
- No final art assets.
