# UI Theme

Stage 66.2: UI Font Theme and Text Style Blocks v0.1. This patch only affects typography: font, font size, outline size, outline color, and optional font color. It does not touch layouts, anchors, offsets, textures, localization keys, gameplay, shop logic, rewards, result flow, debug hotkeys, or save/load behavior.

## Global theme

- **`res://themes/main_theme.tres`** — a project-wide `Theme` resource defining base typography for `Label`, `Button`, `OptionButton`, `SpinBox`, and `LineEdit`: white font color, black outline color, a reasonable default outline size, and a reasonable default font size per control type.
- Applied at `res://scenes/app/App.tscn`'s root `App` `Control` node (`theme = ExtResource(...)`). Every screen hosted under `App` (via `%ScreenHost`) inherits it automatically — no per-screen theme assignment needed.
- The theme does **not** reference any font resource, so it always falls back to Godot's built-in default font. This is intentional: no font binary ships in this patch (see below), and a `.tres` referencing a missing external font file would be a broken resource.

## Font folder

- **`res://assets/fonts/`** — new, currently empty except for `.gitkeep`.
- Expected custom font filename: **`res://assets/fonts/main_font.ttf`** or **`res://assets/fonts/main_font.otf`**.
- **No font file is included in this patch.** Placing a real font here and wiring it into the theme is a manual step (see below).

### Manual custom font setup

1. Place your font file at `res://assets/fonts/main_font.ttf` (or `.otf`).
2. Open `res://themes/main_theme.tres` in the Godot editor.
3. Assign the font to the theme's default font, and/or to each control type's font slot (`Label`, `Button`, `OptionButton`, `SpinBox`, `LineEdit`) if automatic/default-font assignment doesn't pick it up.
4. Save the theme resource.
5. If Godot doesn't visually refresh immediately, close and reopen the affected scene(s), or restart the editor.

## Text style catalog

- **`res://scripts/ui/text/text_style_catalog.gd`** (`TextStyleCatalog`) is a plain `Dictionary`-based catalog, easy to hand-edit. Each style block may define:
  - `font_size: int`
  - `outline_size: int`
  - `font_color: Color` (optional)
  - `outline_color: Color` (optional)
- `TextStyleCatalog.get_style(style_id: String) -> Dictionary` always returns a usable style — unknown ids fall back to `DEFAULT_STYLE` — so callers never need a null check.
- `TextStyleCatalog.has_style(style_id: String) -> bool` reports whether a style_id is explicitly defined.

### Available style block ids

| Area | Ids |
| --- | --- |
| Global/common | `global.label`, `global.button`, `global.popup_title`, `global.popup_body`, `global.small_hint` |
| Main menu | `main_menu.title`, `main_menu.button`, `main_menu.currency` |
| Settings | `settings.title`, `settings.option_label`, `settings.option_value`, `settings.button` |
| Shop | `shop.wallet`, `shop.tab`, `shop.tile_quantity`, `shop.tile_price_button`, `shop.tile_product_button`, `shop.feedback`, `shop.offer_placeholder` |
| Level select | `level_select.zone_dropdown`, `level_select.level_button`, `level_select.back_button`, `level_select.popup_title`, `level_select.popup_stars`, `level_select.popup_button` |
| Game HUD | `game_hud.level`, `game_hud.moves`, `game_hud.menu_button`, `game_hud.hp`, `game_hud.modifier`, `game_hud.booster_count` |
| Result UI | `result.title`, `result.reward`, `result.reward_gold`, `result.button` |
| Lose continue popup | `lose_continue.title`, `lose_continue.description`, `lose_continue.button`, `lose_continue.feedback`, `lose_continue.gem_cost` |
| Currency (Stage 67.2) | `currency.inline_gold`, `currency.inline_gems` |
| Debug/dev | `debug.message`, `debug.small` |

A few ids are defined but currently unused because no matching UI node exists yet in the live scenes (`shop.tile_quantity` — booster tiles have no quantity control; `shop.offer_placeholder` — Offers tab is fully populated with real tiles, not placeholder text; `level_select.popup_stars` — stars are conveyed via the popup window texture, not text; `main_menu.title`/`settings.option_value` — no such label exists yet; `lose_continue.description` — no separate description label exists; `currency.inline_gold`/`currency.inline_gems` — generic ids kept for future standalone currency amounts elsewhere, not wired to any node yet since `result.reward_gold`/`lose_continue.gem_cost` cover the two Stage 67.2 usages directly). They're kept in the catalog so a future node can adopt them without inventing a new id.

## Text style applier

- **`res://scripts/ui/text/text_style_applier.gd`** (`TextStyleApplier`) reads a style from `TextStyleCatalog` and applies it as `theme_override_*` properties only:
  - `theme_override_font_sizes/font_size`
  - `theme_override_constants/outline_size`
  - `theme_override_colors/font_outline_color`
  - `theme_override_colors/font_color`
- API:
  - `apply(control: Control, style_id: String) -> void` — dispatches to `apply_to_label`/`apply_to_button` based on the control's type; a safe no-op for other control types.
  - `apply_to_label(label: Label, style_id: String) -> void`
  - `apply_to_button(button: Button, style_id: String) -> void`
  - `apply_to_child_label(root: Node, label_node_name: String, style_id: String) -> void` — looks up `root.get_node_or_null(label_node_name)` and styles it if it's a `Label`.
- Fails safely: a `null` control/root, or a label lookup miss, is a no-op — never an error.
- Never modifies anchors, offsets, `layout_mode`, alignment, scale, textures, node position/size/visibility, or text content (including localized text).

### Custom texture-button labels

`PressableTextureButton`, `ShopTabButton`, and `LevelMapButton` render their visible text through a child `Label` overlay (`TextMargin/Label`), not the native `Button.text` (which those scripts force empty). `TextStyleApplier.apply_to_child_label(button, "TextMargin/Label", style_id)` is used everywhere for these buttons — including `LevelInfoPopup`'s Start/Back buttons, `BattleResultOverlay`'s Retry/Next/Menu buttons, and `LoseContinuePopup`'s three buttons — so styling always lands on the pixels actually drawn on screen. `BoosterTextureButton`'s `%CountLabel` (used both in the in-game booster panel and, by the same script, anywhere else it's reused) is styled directly since it's a plain `Label`.

## What received style blocks

- **MainMenu** (`main_menu_screen.gd`): Play/Level Select/Shop/Settings button labels (`main_menu.button`), gold/gems labels (`main_menu.currency`).
- **Settings** (`settings_screen.gd`): title (`settings.title`), the 4 toggle row labels (`settings.option_label`), back button (`settings.button`).
- **Shop** (`shop_screen.gd`, `shop_booster_tile.gd`, `shop_product_tile.gd`): wallet labels (`shop.wallet`), tab labels (`shop.tab`), feedback label (`shop.feedback`), back button (`global.button`), booster tile buy buttons (`shop.tile_price_button`), gem/bundle/offer tile buy buttons (`shop.tile_product_button`).
- **Level Select** (`level_select_screen.gd`): zone dropdown (`level_select.zone_dropdown`), the 5 level button labels (`level_select.level_button`), back button (`level_select.back_button`), `LevelInfoPopup` title (`level_select.popup_title`) and Start/Back buttons (`level_select.popup_button`).
- **Game HUD** (`battle_hud.gd`, `enemy_panel.gd`, `game_screen.gd`, `booster_texture_button.gd`): level/moves labels (`game_hud.level`/`game_hud.moves`), Menu button (`game_hud.menu_button`), enemy HP value (`game_hud.hp`), round modifier description (`game_hud.modifier`), booster count labels (`game_hud.booster_count`).
- **Result UI** (`battle_result_overlay.gd`): top label used for both the defeat title and victory reward lines (`result.reward`), Retry/Next/Menu buttons (`result.button`); Stage 67.2 added the dedicated gold reward row's `%GoldRewardLabel` (`result.reward_gold`, font size 25).
- **Lose continue popup** (`lose_continue_popup.gd`): title (`lose_continue.title`), feedback/"not enough gems" label (`lose_continue.feedback`), the watch-ad and close buttons (`lose_continue.button`); Stage 67.2 gave the gem-cost buy-moves button its own style id (`lose_continue.gem_cost`, font size 30 — same value as `lose_continue.button`, kept separate so cost text can diverge from the other two buttons later).

## Inline currency icons (Stage 67.2)

Small inline gold/gems icons, distinct from the larger per-item shop icons (`shop_icon_gems_50`, etc.):

- **Asset keys** (`AssetKeyResolver.CURRENCY_ICON_ASSET_KEYS`/`get_currency_icon_asset_key(currency_id)`, `CurrencyType.GOLD`/`GEMS` keyed): `currency_icon_gold` -> `res://assets/images/ui/currency/gold_icon.png`, `currency_icon_gems` -> `res://assets/images/ui/currency/gems_icon.png`. Both are safe placeholders — missing files fall back to a solid-color `FallbackImageSlot` rect, never a crash or broken reference.
- **Used in:** `LoseContinuePopup`'s gem-continue button (`%GemCostIcon`, 24x24, next to the "5" cost text, `lose_continue.gem_cost` style, font size 30) and `BattleResultOverlay`'s gold reward row (`%GoldRewardIcon`, 28x28, next to the "+10" text, `result.reward_gold` style, font size 25).
- **Rule:** icons are only added next to a *standalone* currency amount with no icon already nearby. Wallet displays that already read from a background/texture with a built-in icon (e.g. `MainMenuScreen`/`ShopScreen` gold/gems labels) are left untouched — no duplicate icon was added there.

## Not styled (deliberately out of scope)

No style blocks were created for save keys, asset keys, config ids, booster ids, enemy ids, level ids, or debug console output — this system styles visible UI text only.

## Localization stays intact

This patch does not rename, remove, or otherwise touch `LocalizationManager`, the CSV format, or any localized text value. `TextStyleApplier` only ever sets `theme_override_*` properties; it never reads or writes a `.text` property.

## Tests

No automated tests were added, updated, touched, or run as part of Stage 66.2. Manual verification in the Godot editor is expected for this stage.
