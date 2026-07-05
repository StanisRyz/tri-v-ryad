# Asset Folders

Stage 37 uses the placeholder image folder pipeline in active battle background and enemy visual holders. Real image files are intentionally not included yet.

## Folder Structure

- `assets/images/backgrounds/`: future battle background images named `background_1.png` through `background_5.png`.
- `assets/images/enemies/`: future enemy portraits or sprites using the reserved enemy asset keys.
- `assets/images/tiles/`: future tile images named by tile color, such as `tile_red.png`.
- `assets/images/ui/`: future panel or UI image assets for active screen image holders.
- `assets/images/heroes/`: reserved future/frozen hero portrait assets. Hero systems remain inactive in the current direct flow.

Each folder contains a `.gitkeep` file so the empty folder is tracked.

## Naming

Image filenames should match the `GameAssetCatalog` path for their asset key. For example, `background_1` maps to `res://assets/images/backgrounds/background_1.png`, and `enemy_small_slime` maps to `res://assets/images/enemies/enemy_small_slime.png`.

## Missing Assets

Missing files are expected in Stage 37. `GameAssetCatalog.try_load_texture()` checks `ResourceLoader.exists()` before loading and returns `null` safely when a file is absent or when a loaded resource is not a `Texture2D`. `GameAssetCatalog.try_load_texture_cached()` reuses loaded textures and caches missing keys/paths so optional files are not rechecked excessively during a run.

`ImageSlot` displays its configured placeholder color whenever no texture is available. Stage 37 integrates `ImageSlot` into active battle background handling and `EnemyPanel` enemy visuals. Tile image rendering is postponed, while tile asset keys remain reserved and mapped for later.
