# Audio System (Stage 68.1: Audio Manager Integration v0.1)

This document describes the audio architecture added/expanded in Stage 68.1.
It supersedes the Stage 38 "AudioManager Foundation" notes in `README.md` for
anything audio-specific; `README.md`/`AGENTS.md` still hold the authoritative
stage-by-stage project history.

## Overview

- `autoload/AudioManager.gd` is the single autoload (`/root/AudioManager`,
  registered in `project.godot`) that owns all playback: one shared music
  player and a pool of SFX players.
- `scripts/game/audio/audio_config.gd` (`AudioConfig`) is the single source of
  truth for audio file paths and tuning constants (volumes, throttle
  interval).
- `scripts/game/audio/audio_asset_catalog.gd` (`AudioAssetCatalog`) is kept as
  a compatibility key→path lookup layer for any caller that still resolves
  audio by string key (`AudioManager.play_sfx("sfx_button_click")`,
  `AudioManager.play_music("music_main")`). Its map now points at
  `AudioConfig`'s paths, and legacy keys (`sfx_match`, `sfx_special_activate`)
  are aliased onto the new crystal-burst / special-crystal files rather than
  removed, so no existing caller or test breaks.
- All loading goes through `ResourceLoader.exists()` before `load()`, and
  missing streams are cached as "missing" so a repeated call never crashes,
  never logs on every frame, and never blocks the game — this project ships
  with **no real audio binaries**; every path below is a placeholder location
  the user fills in manually.

## Music: one shared shuffled playlist

Music is **common across the whole game** — MainMenu, LevelSelect, Shop,
Settings, and GameScreen all share the same playlist and the same
`AudioStreamPlayer`. Switching screens never stops or restarts it.

Expected files (place manually, `.ogg`):

```
res://assets/audio/music/track_01.ogg
res://assets/audio/music/track_02.ogg
res://assets/audio/music/track_03.ogg
res://assets/audio/music/track_04.ogg
res://assets/audio/music/track_05.ogg
```

Playback uses a **shuffle bag**: at startup (and whenever the bag empties) the
manager builds a randomly-ordered queue of every *valid* (existing) track and
pops from it one at a time, so every track plays once before any repeats, and
the just-played track is swapped out of the very next slot so it never repeats
back-to-back (when more than one valid track exists). When the currently
playing track's `finished` signal fires, the manager automatically advances to
the next track in the bag — no polling, no timers.

Missing tracks are simply skipped when the valid-path list is built; if *all*
five are missing, the manager just does nothing (no crash, no music).

Public methods on `AudioManager`:

- `play_main_music()` — starts the playlist if it isn't already playing.
  Idempotent; safe to call once at app startup and again from Settings when
  music is re-enabled.
- `play_random_music_track()` — plays a track from the shuffle bag now.
- `play_next_music_track()` — advances the playlist (alias of the above; kept
  as its own name to match the requested API and to make call sites read
  clearly).
- `stop_music()`
- `set_music_enabled(enabled: bool)` / `is_music_enabled() -> bool`

`App._apply_audio_settings()` (`scripts/app/app.gd`) calls
`AudioManager.play_main_music()` once, right after applying the loaded
Music/Sound Effects settings, so the playlist starts exactly once per app run
and only if music is enabled.

## SFX

`AudioManager` owns a pool of 16 `AudioStreamPlayer`s (`SfxPlayer1..16`) so
SFX can overlap; if every player is busy, the least-recently-assigned one is
reused rather than dropping the sound.

Expected files (place manually):

```
res://assets/audio/sfx/ui/button_click.ogg
res://assets/audio/sfx/game/crystal_burst.ogg
res://assets/audio/sfx/game/tile_swap.ogg
res://assets/audio/sfx/game/invalid_swap.ogg
res://assets/audio/sfx/game/special_crystal.ogg
res://assets/audio/sfx/game/enemy_hit.ogg
res://assets/audio/sfx/boosters/hammer.ogg
res://assets/audio/sfx/boosters/rocket_barrage.ogg
res://assets/audio/sfx/boosters/freeze_time.ogg
res://assets/audio/sfx/result/victory.ogg
res://assets/audio/sfx/result/defeat.ogg
res://assets/audio/sfx/result/lose_continue.ogg
res://assets/audio/sfx/shop/purchase_success.ogg
res://assets/audio/sfx/shop/purchase_error.ogg
```

Public wrapper methods:

```
play_button_click()
play_crystal_burst()          # one call = one destroyed crystal, see below
play_tile_swap()
play_invalid_swap()
play_special_crystal()
play_enemy_hit()
play_booster_hammer()
play_booster_rocket_barrage()
play_booster_freeze_time()
play_victory()
play_defeat()
play_lose_continue()
play_purchase_success()
play_purchase_error()
```

Compatibility aliases kept for existing callers/tests (unchanged behavior,
same missing-file safety):

```
play_music(audio_key := "music_main")   # old key-based single-track player
play_sfx(audio_key: String)             # old key-based SFX player
play_match()            -> play_crystal_burst()
play_special_activate() -> play_special_crystal()
play_level_select()
play_enemy_damage() -> play_enemy_hit()
set_sound_enabled(enabled: bool) -> set_sound_effects_enabled(enabled)
```

### Crystal burst: one sound per crystal

`play_crystal_burst()` itself does nothing special — it's the *caller* that
determines how many times it fires. `BoardAnimationController._play_request_audio()`
calls it once per cell in the clear request (`TYPE_MATCH_CLEAR`/
`TYPE_SPECIAL_CLEAR`/`TYPE_BOOSTER_CLEAR`), so a 3-match bursts 3 times, a
5-match or a Rocket Barrage clearing a whole color bursts once per crystal in
that clear. The 16-player SFX pool lets these overlap freely — there is no
throttling. The animations-disabled fallback (`GameScreen._play_turn_audio()`/
`_finish_booster_resolution()`) mirrors this by looping
`data.total_tiles_cleared` / `result.cleared_cells` the same way, so the sound
count is the same whether or not board animations are on.

## Settings integration (unchanged contract)

`SettingsScreen`/`SettingsManager`/`App` call the same methods they always
did:

- `AudioManager.set_music_enabled(settings.music_enabled)`
- `AudioManager.set_sound_effects_enabled(settings.sound_effects_enabled)`

`set_music_enabled(true)` now also starts the shared playlist (via
`play_main_music()`) if nothing is playing yet; `set_music_enabled(false)`
stops it. `set_sound_effects_enabled(false)` stops any currently-playing SFX
and suppresses new ones; re-enabling allows SFX again. `SettingsManager`'s
existing bus-mute behavior (`Music`/`SFX` `AudioServer` buses) is untouched.

## Button click auto-binding

`AudioManager.bind_button(button: BaseButton)` and
`AudioManager.bind_buttons_in_tree(root: Node)` recursively find `BaseButton`
nodes and connect their native `pressed` signal to `play_button_click()`.
Binding is idempotent (a `audio_button_bound` node metadata flag prevents
double-connecting) and skips any button with `audio_skip` metadata set to
`true`.

Most of this project's buttons (`PressableTextureButton`) already call
`AudioManager.play_button_click()` manually from their own `delayed_pressed`
handlers — SettingsScreen's toggles/back button, ShopScreen's tabs/back/buy
flow, GameScreen's menu/booster/restart/lose-continue flow, and
LevelSelectScreen's back/popup buttons all do this deliberately (some, like
the level-info popup's Start button, intentionally play a *different* sound —
`sfx_level_select` — instead of a plain click). Calling `bind_buttons_in_tree`
on top of that manual wiring would fire two sounds per press, so auto-binding
is only used where it fills a real gap, and every already-wired button in that
subtree is tagged `audio_skip = true` first:

- **`MainMenuScreen`** — none of its five buttons had any click sound before
  this stage; `bind_buttons_in_tree(self)` is called with no skips needed.
- **`LevelSelectScreen`** — `%BackButton`, the level-info popup's
  `%StartButton`, and `%PopupBackButton` are tagged `audio_skip` (already
  covered), then `bind_buttons_in_tree(self)` picks up the five level map
  buttons and the zone dropdown, which previously had no click sound.

`SettingsScreen`, `ShopScreen`, `GameScreen`, `BattleResultOverlay`, and
`LoseContinuePopup` are not auto-bound: every button in those trees already
has a deliberate, correctly-scoped sound (a plain click, or a purchase
success/error, victory/defeat, etc.) wired through their existing manual
handlers, so there is nothing left to bind without doubling a sound.

## Gameplay hook points

### Animated turns: audio plays live, in sync with each visual step

**Hotfix (post-Stage-68.1):** the first cut of this stage played every sound
for a turn from `GameScreen._on_turn_presentation_ready()`/
`_finish_booster_resolution()`. For an *animated* turn that's the wrong place
— `AnimatedTurnFlow.start_swap_turn()`/`start_booster_clear()` `await` the
entire swap → clear → gravity → cascade animation sequence before either of
those handlers ever runs, so every sound landed bunched up after the visuals
instead of in sync with them (e.g. the swap sound firing only once the whole
turn had already finished animating).

The fix moved the trigger point into
`BoardAnimationController._play_request()` — the one place each individual
animation request actually executes, in real time — via a new
`_play_request_audio(request, board_view)` step that runs right before the
request's visual is played:

| Request type | Sound |
| --- | --- |
| `TYPE_SWAP` | `play_tile_swap()` |
| `TYPE_INVALID_SWAP` | `play_invalid_swap()` |
| `TYPE_MATCH_CLEAR` / `TYPE_SPECIAL_CLEAR` / `TYPE_BOOSTER_CLEAR` | `play_crystal_burst()`, once per cell in the request (see below) |
| `TYPE_SPECIAL_ACTIVATION` | `play_special_crystal()` |
| `TYPE_BOOSTER_ACTIVATION` | `play_booster_hammer()`/`play_booster_rocket_barrage()`/`play_booster_freeze_time()`, by `request.payload["booster_id"]` |

`TYPE_SPECIAL_CREATE` (a new special tile being formed, not activated) has no
sound, matching the "don't play on mere creation" rule below.

`GameScreen._play_turn_audio()`/`_finish_booster_resolution()` still exist,
but `_on_turn_presentation_ready()` now only calls `_play_turn_audio()` when
`_animations_enabled` is false, and `_finish_booster_resolution()` only plays
its own booster/crystal-burst sounds in that same case — with animations off,
`AnimatedTurnFlow` never runs at all (`resolve_accepted_swap_immediately()`/
direct `finalize_booster_turn()` paths), so nothing has played from the
controller and these remain the only place the turn's sounds fire.

### Crystal burst: one sound per destroyed crystal

`BoardAnimationController._play_request_audio()` calls `play_crystal_burst()`
once for every cell in a `TYPE_MATCH_CLEAR`/`TYPE_SPECIAL_CLEAR`/
`TYPE_BOOSTER_CLEAR` request — a 3-match bursts 3 times, a Rocket Barrage
clearing a whole color bursts once per crystal cleared. There is no
throttling; the 16-player SFX pool lets simultaneous bursts overlap freely.
Cascades add more `TYPE_MATCH_CLEAR` requests as separate steps, each
contributing its own per-cell bursts. The animations-disabled fallback
mirrors this by looping `data.total_tiles_cleared` (`_play_turn_audio()`) or
`result.cleared_cells` (`_finish_booster_resolution()`), so the crystal-burst
count is identical whether or not board animations are on.

### Enemy hit

`play_enemy_hit()` fires from `BattleEffectController._play_enemy_hit_audio()`,
called at the very start of `play_damage_particles()` — the instant the
damage particles are launched, before their flight tween even begins — so it
reads as the crystals firing at the enemy rather than a delayed impact cue.
Plays once per hit event (not per particle), whether the damage came from a
normal/cascade match turn (`build_from_turn_presentation()`) or a booster
clear (`build_from_booster_result()`). The particle-landing visual moment
(flash/shake/floating-damage-number, `EnemyPanel.play_hit_feedback()`, via
`_trigger_hit_feedback()`) still happens later, once the particles finish
traveling — only the sound moved earlier, to launch time. If there's nothing
to visually animate (animations off, or a missing board/enemy/effect-layer
node) the hit still happened, so the sound still plays immediately even
though the particle flight and flash are skipped. `GameScreen._play_enemy_damage()`
no longer plays a sound itself — it now only drives
`EnemyPanel.play_damage_feedback()` (a separate damaged-sprite-texture swap),
so a hit is never double-sounded.

### Tile swap / invalid swap

Accepted swaps play `play_tile_swap()` the instant the `TYPE_SWAP` request
starts (i.e. as the crystals visually begin moving); rejected swaps
(no-match, or a swap `SwapResolver.try_swap()` blocks outright — e.g. an
ice-locked cell's `"iced_cell"` reason) play `play_invalid_swap()` the instant
the `TYPE_INVALID_SWAP` shake animation starts. Never both for the same
attempt.

### Special crystal activation

`play_special_crystal()` (via the `TYPE_SPECIAL_ACTIVATION` request) fires the
instant a horizontal/vertical/color-bomb special's activation animation
starts, including a special chain-activated by another special. Creating a
new special tile (`TYPE_SPECIAL_CREATE`, without activating it) never plays
this sound — only activation does.

### Boosters

`hammer`/`rocket_barrage`/`freeze_time` (the exact `BoosterCatalog` ids) map
to their own sound. Hammer/Rocket Barrage are targeted and animated, so their
sound plays live from the `TYPE_BOOSTER_ACTIVATION` request exactly like
everything else above; Time Freeze never animates a clear at all, so its
sound plays immediately in `GameScreen._on_booster_pressed()`'s
direct-activation branch, right when the use is accepted. None of the three
ever double up: `_finish_booster_resolution()` explicitly skips Time Freeze
(`result.freeze_turns_added > 0`) since it already played its sound at press
time, and skips Hammer/Rocket Barrage too unless animations are off. Booster
selection (choosing Hammer/Rocket before tapping a target) only plays the
ordinary button-click sound via the booster button's own wiring; booster
rejection (already used this battle, none left) plays `play_invalid_swap()`.

### Victory / defeat / lose-continue

`GameScreen._show_battle_result()` calls `play_victory()` once when the
victory result opens. `_show_lose_continue_or_defeat()` calls
`play_lose_continue()` once, right before `LoseContinuePopup.show_popup()`,
and does **not** call `play_defeat()`. `play_defeat()` only fires from
`_finalize_defeat_result()` — reached when the player declines/closes the
continue offer, or when `LoseContinuePopup` was never shown at all — so a
continue offer never doubles up with a defeat sound.

### Shop purchases

`ShopScreen._resolve_purchase()` calls `play_purchase_success()` when
`ShopPurchaseResolver.purchase()` returns `accepted == true`, and
`play_purchase_error()` otherwise (not enough gold/gems, invalid item,
external payment/ad not connected, or any other rejection reason). The buy
button's own click sound (from `ShopScreen`'s existing manual wiring) still
plays separately, before the result is known.

## What was not changed

Shop prices, rewards, booster counts, economy, result logic, lose-continue
logic, board/swap/match rules, special tile logic, debug hotkeys (F1-F3/F12),
localization, UI text theme, and save/load are all untouched — this stage
only connects audio to existing systems.

## Tests

No test files were added, updated, touched, or run for this stage, per
explicit instruction. `scripts/tests/audio_manager_test.gd` and
`scripts/tests/audio_settings_integration_test.gd` (both pre-existing) were
read to confirm this stage's `AudioManager` changes keep their assumed API
(`play_music()`, `play_sfx()`, `MusicPlayer`/`SfxPlayer*` node names,
`play_match()`, `play_special_activate()`, `play_level_select()`,
`play_enemy_damage()`, `set_music_enabled`/`set_sound_effects_enabled`)
working exactly as before, but the tests themselves were not run. Manual
verification in the Godot editor is expected.
