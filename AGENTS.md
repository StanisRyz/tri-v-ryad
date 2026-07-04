# Agent Guidelines

This is a Godot match-3 battle project intended for Yandex Games. The default layout is vertical 9:16 portrait with a 720x1280 base resolution.

The current stage is a playable battle prototype with board animation polish, saved level completion, stars, sequential unlocks, upgrade points, hero progression, and local save v0.1. `GameScreen` is allowed to wire `BattlePresenter`, `BoardView`, `BoardInputController`, `TurnFeedbackPresenter`, `AbilityFeedbackPresenter`, and result-flow reward/completion calls through `ProgressManager`, but the board core, battle core, config layer, progression layer, and save layer must remain separate from UI implementation details.

## Project Rules

- Use small or medium focused patches.
- Do not implement unrelated systems.
- Use English file and folder names only.
- Do not use spaces or Russian characters in file paths.
- Prefer Control-based UI, containers, and anchors.
- Keep gameplay logic separate from UI.
- Keep battle UI components separate from gameplay logic.
- Keep platform SDK logic separate from gameplay.
- Do not add third-party plugins without explicit request.
- Do not add generated heavy files.
- `GameScreen` may use `BattlePresenter`, but must not directly own board or battle rule details.

## Gameplay Direction

- The game is a match-3 battle game.
- The board will be 9x9.
- The key mechanic is Hero Lanes.
- Hero 1 owns columns 1-3.
- Hero 2 owns columns 4-6.
- Hero 3 owns columns 7-9.
- Future matches will activate heroes based on affected columns.
- Progression awards upgrade points after victory for hero attack and HP.
- `BoardFrame` is only a placeholder visual frame, not the match-3 board model.
- Future board logic belongs under `scripts/game/board/`.
- Board logic must remain UI-independent.
- `MatchResult` must keep exact cell coordinates for future Hero Lanes.
- `SwapResolver` must not handle damage, heroes, or visual animation.
- `BoardResolver` must not know about battle state.
- Special tile logic lives under `scripts/game/board/`.
- Base tile type remains the match color/type.
- Special tile metadata must stay separate from UI.
- `MatchFinder` must match by base tile type.
- Special metadata must move with swap and gravity.
- Special-cleared cells must not add hero damage or ability charge in v0.1.
- Battle logic lives under `scripts/game/battle/`.
- Battle logic must remain UI-independent.
- `BattleResolver` consumes `MatchResult` data but must not use `BoardModel` directly.
- `HeroLaneResolver` owns Hero Lane column mapping rules.
- `DamageResolver` must not implement UI animation.
- `AbilityChargeResolver` must not implement real abilities yet.
- `EnemyActionResolver` must stay deterministic and simple for now.
- `BoardView` presents `BoardModel` but must not implement match rules.
- `TileView` may detect pointer/touch gestures and display a special marker, but must not validate gameplay or special rules.
- `BoardView` forwards input events and presents board state only.
- `BoardView` may forward special metadata to `TileView` but must not create or activate specials.
- `BoardInputController` owns click/drag selection logic, not swap validation.
- `GameScreen` wires signals but must not implement input rules.
- Drag/swipe input must not duplicate swap requests.
- Input must be locked during turn processing.
- `BattlePresenter` coordinates prototype flow but must keep SDK, direct save access, ads, and payments out.
- Cascade damage is future work and must not be added unless explicitly requested.
- `TurnPresentationData` is presentation-only and must not change core battle rules.
- `TurnFeedbackPresenter` owns feedback sequencing.
- `GameScreen` must not contain long animation sequences.
- Input unlock must happen after feedback completes.
- `TileView` visual feedback must remain lightweight.
- `BoardMotionAnimator` is view/presentation-only.
- `BoardMotionAnimator` must not mutate `BoardModel`.
- `BoardMotionAnimator` must not call board, battle, progression, save, platform, ad, or payment resolvers/services.
- `TileView` animation helpers must remain lightweight tween feedback only.
- `BoardView` animation helpers must not implement gameplay rules.
- `BoardView` animation helpers must not mutate `BoardModel`.
- `TurnFeedbackPresenter` may sequence visual feedback, but must not change gameplay outcomes.
- Input unlock must remain tied to `feedback_finished`.
- Do not implement full cascade animations unless explicitly requested.
- Do not implement full manual board layout rewrite or full falling animation unless explicitly requested.
- Do not add color bombs, wrapped bombs, or special combos unless explicitly requested.
- Do not add sound, particles, or final art in this stage.
- Ability logic lives under `scripts/game/battle/`.
- `AbilityResolver` must remain UI-independent.
- `HeroCard` only emits ability requests and must not apply effects.
- `HeroPartyPanel` only forwards ability requests.
- `GameScreen` wires ability signals but must not implement ability rules.
- `BattlePresenter` coordinates ability flow.
- Ability use must not reduce `moves_left` in v0.1.
- Ability use must not tick enemy intent in v0.1.
- Ability-cleared tiles must not grant charge or hero damage unless explicitly requested later.
- Configs live under `scripts/game/config/`.
- Config classes must remain UI-independent.
- Hero roster definitions live in `HeroCatalog` under `scripts/game/config/`.
- `BattleFactory` creates `BattleState` from configs.
- Progression logic lives under `scripts/game/progression/`.
- Team selection state lives under `scripts/game/progression/`.
- `TeamSelectionResolver` owns team validation rules.
- `PlayerProgress` stores selected team.
- Level progress logic belongs under `scripts/game/progression/`.
- Save logic lives under `scripts/game/save/`.
- Screens must not read or write save files directly.
- Use `ProgressManager` for progress operations.
- `ProgressManager` is the boundary for level completion operations.
- `ProgressManager` is the boundary for reading/writing selected team.
- `TeamSelectScreen` must not save files directly.
- `TeamSelectScreen` must not create `BattleState`.
- `SaveManager` is local-only in v0.1.
- `PlayerProgress` is mutable player data.
- `LevelProgressState` stores saved level result data.
- `LevelCompletionResolver` owns star and unlock rules.
- `HeroConfig` remains immutable base data.
- `BattleFactory` combines `HeroConfig` with `PlayerProgress`.
- `BattleFactory` maps selected team order to lanes 0, 1, 2.
- Do not mutate `HeroConfig` for player upgrades.
- Do not mutate `HeroConfig` when assigning selected team lanes.
- `BattlePresenter` starts levels but must not store hardcoded enemy or hero definitions.
- `LevelSelectScreen` only selects `level_id`, displays level progress, and must not create `BattleState`.
- `LevelSelectScreen` must not own unlock rules.
- Rewards remain repeatable in v0.1.
- Do not add one-time rewards, stars-based rewards, level map, chapters, or complex economy unless explicitly requested.
- UpgradeScreen rework is future work and must not be mixed into campaign progression patches.
- UpgradeScreen rework remains future work and must not be mixed into hero roster/team selection patches.

## Platform Boundaries

- The game is intended for Yandex Games / Web first.
- Do not add Yandex SDK integration during the foundation stage.
- Do not add Yandex cloud save until explicitly requested.
- When Yandex SDK support is added later, isolate it under `scripts/platform/`.
- Gameplay and UI scripts must never call the Yandex SDK directly.
- Use platform adapter scripts or services as the boundary between SDK code and the rest of the project.
- Do not add ads, cloud saves, payments, RuStore, Android-specific code, or monetization during this stage.

## Current Exclusions

- No full cascade animations.
- No full manual board layout rewrite.
- No full falling animation.
- No color bombs, wrapped bombs, or special combos.
- No sound or particles.
- No target selection, cooldowns, ability upgrades, or hero selection.
- No one-time rewards, stars-based rewards, level map, chapters, complex economy, or complex objectives.
- No cloud save.
- No ads or monetization.
- No Yandex SDK.
- No final art assets.
