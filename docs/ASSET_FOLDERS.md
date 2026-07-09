# Asset Folders

Stage 39 completes the reserved AssetKey texture binding surface for current and future image holders. Real image files are intentionally not included yet.

## Folder Structure

- `assets/images/backgrounds/`: future battle background images named `background_1.png` through `background_5.png`.
- `assets/images/enemies/`: future enemy portraits or sprites using the reserved enemy asset keys.
- `assets/images/tiles/`: base tile images (`tile_red.png`, `tile_blue.png`, `tile_green.png`, `tile_yellow.png`, `tile_purple.png`) plus special tile overlays/placeholders (`tile_special_horizontal.png`, `tile_special_vertical.png`, `tile_color_bomb.png`).
- `assets/images/ui/`: future panel, button, star, toggle, and screen background textures.
- `assets/images/boosters/`: legacy duplicate booster icon path, kept for `BoosterConfig`/legacy `BoosterButton` compatibility. New booster icon art belongs under `assets/images/ui/icons/boosters/` instead (see the Stage 64.5 naming rule below).
- `assets/images/heroes/`: reserved future/frozen hero portrait assets. Hero systems remain inactive in the current direct flow.
- `assets/images/ui/icons/boosters/`: shared booster icon art (`hammer.png`, `freeze_time.png`, `rocket_barrage.png`), used by the Shop UI and by `BoosterPanel`/`BoosterTextureButton`.
- `assets/images/ui/game/enemies/`: `EnemyPanel` enemy sprite states, named `enemy_N_normal.png`/`enemy_N_damaged.png` (Stage 64.5 numeric naming).
- `assets/images/ui/game/enemy_panel/backgrounds/`: `EnemyPanel` background candidates, named `enemy_background_N.png` (Stage 64.5 numeric naming).
- `assets/images/ui/game/booster_panel/`: `BoosterPanel`'s `PanelBackground`, `background.png`.

Each folder contains a `.gitkeep` file so the empty folder is tracked.

## Naming

Image filenames should match the `GameAssetCatalog` path for their asset key. For example, `background_1` maps to `res://assets/images/backgrounds/background_1.png`, `enemy_small_slime` maps to `res://assets/images/enemies/enemy_small_slime.png`, and `booster_hammer` maps to `res://assets/images/boosters/booster_hammer.png`.

Stage 64.5 introduced a numeric naming convention for `EnemyPanel` visual assets, since art no longer needs to be tied to one specific enemy name:

- Enemy sprite states: `enemy_N_normal.png` / `enemy_N_damaged.png` under `assets/images/ui/game/enemies/` (asset keys `enemy_N_normal`/`enemy_N_damaged`). The gameplay enemy id is unchanged (still `"gatekeeper"` for the first enemy); `AssetKeyResolver.ENEMY_STATE_ASSET_KEYS` maps that gameplay id to the numeric asset keys, so gameplay ids/level/battle configs were not touched.
- Enemy panel backgrounds: `enemy_background_N.png` under `assets/images/ui/game/enemy_panel/backgrounds/` (asset keys `enemy_background_N`), returned in order by `AssetKeyResolver.get_enemy_panel_background_asset_keys()` and picked at random by `enemy_panel.gd`.
- Booster icons: shared UI icon art continues to live at `assets/images/ui/icons/boosters/<booster_id>.png` (`hammer.png`/`freeze_time.png`/`rocket_barrage.png`); new booster art should be added there, not under the legacy `assets/images/boosters/` folder.

Future numbered enemies should follow the same pattern (`enemy_2_normal.png`/`enemy_2_damaged.png`, etc.) as they're added to `AssetKeyResolver.ENEMY_STATE_ASSET_KEYS`.

## Missing Assets

Missing files are expected in Stage 39. `GameAssetCatalog.try_load_texture()` checks `ResourceLoader.exists()` before loading and returns `null` safely when a file is absent or when a loaded resource is not a `Texture2D`. `GameAssetCatalog.try_load_texture_cached()` reuses loaded textures and caches missing keys/paths so optional files are not rechecked excessively during a run.

`ImageSlot` displays its configured placeholder color whenever no texture is available. Active battle backgrounds, enemy visuals, LevelSelect/Settings backgrounds, and the visual-only `BoosterButton` stub use ImageSlot-compatible binding. `TileView` resolves tile asset keys and uses cached optional textures when present; if missing, the current color placeholder and special marker text remain visible.
