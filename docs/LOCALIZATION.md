# Localization

Stage 66.1: Localization Foundation v0.1. This is a foundation only — it does not integrate any platform SDK and does not add a language selector UI. Both are planned for future stages.

## Source file

- **`res://localization/game_text.csv`** is the editable source of truth for all localized UI text.
- Columns, in order: `key,en,ru,context,notes`.
  - `key` — the stable id code looks up (e.g. `ui.shop.feedback.not_enough_gold`). Never change an existing key without updating every call site.
  - `en` — the English source text. Always required.
  - `ru` — the Russian translation. If left empty, the English text is used instead (see Fallback behavior below).
  - `context` — a short note on where the text is used (screen/component), for translators.
  - `notes` — free-form translator hints (placeholder meaning, tone, character limits, etc.).
- The first row must be the header: `key,en,ru,context,notes`.

## Supported languages

- `en` (default) and `ru`.
- `LocalizationManager.get_available_languages() -> Array[String]` returns `["en", "ru"]`.
- `LocalizationManager.normalize_supported_language(code)` maps any unrecognized code to `"en"`.

## Fallback behavior

For `tr_key(key)`, in order:
1. Use the current language's text if the key exists and the text is non-empty.
2. Otherwise use the English text if the key exists and is non-empty.
3. Otherwise return the raw key itself.

In debug builds, a missing key triggers a `push_warning` so untranslated keys are easy to spot during development.

An empty `ru` cell in `game_text.csv` is equivalent to a missing Russian translation for that key — it falls back to English per the same rule.

## LocalizationManager (autoload)

`res://scripts/game/localization/localization_manager.gd`, registered in `project.godot` as the `LocalizationManager` autoload singleton (`extends Node`).

Load order on `_ready()`:
1. Load the built-in translations from `LocalizationData.get_translations()` (`res://scripts/game/localization/localization_data.gd`).
2. Try to read and parse `res://localization/game_text.csv`. Any non-empty cell in the CSV overrides the corresponding built-in value.
3. If the CSV is missing or fails to open, the built-in data from step 1 remains active untouched — nothing crashes and no translations are lost.

### Public API

- `tr_key(key: String) -> String` — looks up a single localized string, with fallback per the rules above.
- `format_key(key: String, values: Dictionary = {}) -> String` — calls `tr_key(key)` and replaces `{placeholder}` tokens with values from `values` (e.g. `format_key("ui.game.moves", {"moves": 5})` on `"Moves: {moves}"` → `"Moves: 5"`). Placeholders with no matching value are left as-is (safe no-op), never causing an error.
- `set_language(language_code: String) -> void` — switches the active language (normalized through `normalize_supported_language`) and emits `language_changed` if it actually changed.
- `get_language() -> String` — the current language code.
- `get_available_languages() -> Array[String]` — `["en", "ru"]`.
- `normalize_supported_language(language_code: String) -> String` — maps any code to a supported one, defaulting to `"en"`.
- `has_loaded_translations() -> bool` — `true` if the CSV override was successfully loaded this session.
- `get_loaded_translation_count(language_code: String = "en") -> int` — number of keys currently loaded for a language (built-in + CSV merged).
- `signal language_changed` — emitted whenever `set_language()` actually changes the active language. UI screens connect to this in `_ready()` and re-run their own `_localize_ui()` to refresh visible text without rebuilding the screen.

### CSV parsing

The manager includes a small, local CSV parser (not a shared utility) that handles:
- comma-separated fields;
- quoted fields (`"..."`);
- escaped double quotes inside quoted fields (`""`);
- blank lines (skipped);
- the header row (skipped).

This is intentionally minimal — enough for `game_text.csv`, nothing more.

## Generated fallback data

`res://scripts/game/localization/localization_data.gd` is a **generated, committed file**. It exposes:

```gdscript
static func get_translations() -> Dictionary:
    return {"en": {...}, "ru": {...}}
```

This dictionary mirrors `game_text.csv` at the time it was last generated, and is what `LocalizationManager` uses if the CSV can't be read at runtime (for example, in a build that doesn't ship `res://localization/`). Do not hand-edit this file — regenerate it instead (see below).

## Regenerating LocalizationData

After editing `res://localization/game_text.csv`, regenerate the built-in fallback with:

```
godot --headless --script res://scripts/tools/GenerateLocalizationData.gd
```

This runs `res://scripts/tools/GenerateLocalizationData.gd` (a `SceneTree` entry point), which calls `LocalizationDataGenerator.generate()` (`res://scripts/tools/LocalizationDataGenerator.gd`) to re-read the CSV and rewrite `res://scripts/game/localization/localization_data.gd`. Commit the regenerated file alongside the CSV change.

No editor plugin or export-time automation runs this yet — it is a manual step for this patch. An editor/export plugin that runs it automatically is a possible future patch.

## Using localization in UI scripts

```gdscript
var localization_manager := get_node_or_null("/root/LocalizationManager")
if localization_manager != null:
    my_label.text = localization_manager.tr_key("ui.common.back")
```

For screens with localized text, connect to `language_changed` once in `_ready()` and refresh through a dedicated `_localize_ui()` method:

```gdscript
func _ready() -> void:
    ...
    _localize_ui()
    var localization_manager := get_node_or_null("/root/LocalizationManager")
    if localization_manager != null:
        localization_manager.language_changed.connect(_localize_ui)

func _localize_ui() -> void:
    var localization_manager := get_node_or_null("/root/LocalizationManager")
    if localization_manager == null:
        return
    my_label.text = localization_manager.tr_key("ui.common.back")
```

For `PressableTextureButton`/`ShopTabButton` buttons whose visible text lives in a child overlay Label, always set the button's exported `button_text` property (which drives the Label internally) — never write to the hidden `Button.text` directly, since it is not what's visible on screen.

## What is not localized

By design, this system never generates localization keys for internal identifiers: save data field names, asset keys, booster/enemy/level/config ids, analytics/log keys, debug-only console output, or file paths. It also does not (yet) cover `BattleMessageFormatter`'s in-battle status strings, the "no new rewards" line, or a language-selector UI — those are candidates for a future stage.

## Yandex SDK integration (planned, not implemented)

This patch does not integrate the Yandex Games SDK. `LocalizationManager.set_language(language_code)` is ready for a future platform/Yandex adapter to call directly once that integration lands:

```gdscript
LocalizationManager.set_language("ru")
LocalizationManager.set_language("en")
```

Any unsupported/unrecognized language code passed to `set_language()` normalizes to `"en"`.

## Tests

No automated tests were added, updated, touched, or run as part of Stage 66.1. Manual verification in the Godot editor is expected for this stage.
