# Asset Folders

Stage 39 completes the reserved AssetKey texture binding surface for current and future image holders. Real image files are intentionally not included yet.

## Folder Structure

- `assets/images/backgrounds/`: future battle background images named `background_1.png` through `background_5.png`.
- `assets/images/enemies/`: future enemy portraits or sprites using the reserved enemy asset keys.
- `assets/images/tiles/`: base tile images (`tile_red.png`, `tile_blue.png`, `tile_green.png`, `tile_yellow.png`, `tile_purple.png`) plus special tile overlays/placeholders (`tile_special_horizontal.png`, `tile_special_vertical.png`, `tile_color_bomb.png`).
- `assets/images/ui/`: future panel, button, star, toggle, and screen background textures.
- `assets/images/boosters/`: reserved future booster icons.
- `assets/images/heroes/`: reserved future/frozen hero portrait assets. Hero systems remain inactive in the current direct flow.

Each folder contains a `.gitkeep` file so the empty folder is tracked.

## Naming

Image filenames should match the `GameAssetCatalog` path for their asset key. For example, `background_1` maps to `res://assets/images/backgrounds/background_1.png`, `enemy_small_slime` maps to `res://assets/images/enemies/enemy_small_slime.png`, and `booster_hammer` maps to `res://assets/images/boosters/booster_hammer.png`.

## Missing Assets

Missing files are expected in Stage 39. `GameAssetCatalog.try_load_texture()` checks `ResourceLoader.exists()` before loading and returns `null` safely when a file is absent or when a loaded resource is not a `Texture2D`. `GameAssetCatalog.try_load_texture_cached()` reuses loaded textures and caches missing keys/paths so optional files are not rechecked excessively during a run.

`ImageSlot` displays its configured placeholder color whenever no texture is available. Active battle backgrounds, enemy visuals, LevelSelect/Settings backgrounds, and the visual-only `BoosterButton` stub use ImageSlot-compatible binding. `TileView` resolves tile asset keys and uses cached optional textures when present; if missing, the current color placeholder and special marker text remain visible.
