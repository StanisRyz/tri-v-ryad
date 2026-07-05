# Asset Map

All Stage 37 entries are reserved placeholders. Current status is `missing/placeholder expected` until real assets are added in later stages. Active battle backgrounds and enemy visuals now resolve through `AssetKeyResolver` and display via `ImageSlot`; tile keys are mapped but tile rendering is postponed.

| asset_key | expected path | status | usage |
|---|---|---|---|
| background_1 | res://assets/images/backgrounds/background_1.png | missing/placeholder expected | active future battle background |
| background_2 | res://assets/images/backgrounds/background_2.png | missing/placeholder expected | active future battle background |
| background_3 | res://assets/images/backgrounds/background_3.png | missing/placeholder expected | active future battle background |
| background_4 | res://assets/images/backgrounds/background_4.png | missing/placeholder expected | active future battle background |
| background_5 | res://assets/images/backgrounds/background_5.png | missing/placeholder expected | active future battle background |
| enemy_training_dummy | res://assets/images/enemies/enemy_training_dummy.png | missing/placeholder expected | active future enemy image |
| enemy_small_slime | res://assets/images/enemies/enemy_small_slime.png | missing/placeholder expected | active future enemy image |
| enemy_goblin_scout | res://assets/images/enemies/enemy_goblin_scout.png | missing/placeholder expected | active future enemy image |
| enemy_goblin_fighter | res://assets/images/enemies/enemy_goblin_fighter.png | missing/placeholder expected | active future enemy image |
| enemy_armored_goblin | res://assets/images/enemies/enemy_armored_goblin.png | missing/placeholder expected | active future enemy image |
| enemy_wild_wolf | res://assets/images/enemies/enemy_wild_wolf.png | missing/placeholder expected | active future enemy image |
| enemy_bandit | res://assets/images/enemies/enemy_bandit.png | missing/placeholder expected | active future enemy image |
| enemy_orc_brute | res://assets/images/enemies/enemy_orc_brute.png | missing/placeholder expected | active future enemy image |
| enemy_cave_shaman | res://assets/images/enemies/enemy_cave_shaman.png | missing/placeholder expected | active future enemy image |
| enemy_gatekeeper | res://assets/images/enemies/enemy_gatekeeper.png | missing/placeholder expected | active future enemy image |
| tile_red | res://assets/images/tiles/tile_red.png | missing/placeholder expected | active future tile image |
| tile_blue | res://assets/images/tiles/tile_blue.png | missing/placeholder expected | active future tile image |
| tile_green | res://assets/images/tiles/tile_green.png | missing/placeholder expected | active future tile image |
| tile_yellow | res://assets/images/tiles/tile_yellow.png | missing/placeholder expected | active future tile image |
| tile_purple | res://assets/images/tiles/tile_purple.png | missing/placeholder expected | active future tile image |
| ui_level_select_panel | res://assets/images/ui/level_select_panel.png | missing/placeholder expected | future UI panel image |
| ui_battle_panel | res://assets/images/ui/battle_panel.png | missing/placeholder expected | future UI panel image |
| ui_enemy_panel | res://assets/images/ui/enemy_panel.png | missing/placeholder expected | future UI panel image |
| ui_result_panel | res://assets/images/ui/result_panel.png | missing/placeholder expected | future UI panel image |
| ui_round_modifier_panel | res://assets/images/ui/round_modifier_panel.png | missing/placeholder expected | future UI panel image |
| hero_1_portrait | res://assets/images/heroes/hero_1_portrait.png | missing/placeholder expected | future/frozen hero portrait |
| hero_2_portrait | res://assets/images/heroes/hero_2_portrait.png | missing/placeholder expected | future/frozen hero portrait |
| hero_3_portrait | res://assets/images/heroes/hero_3_portrait.png | missing/placeholder expected | future/frozen hero portrait |
| hero_4_portrait | res://assets/images/heroes/hero_4_portrait.png | missing/placeholder expected | future/frozen hero portrait |
| hero_5_portrait | res://assets/images/heroes/hero_5_portrait.png | missing/placeholder expected | future/frozen hero portrait |

`ImageSlot` shows placeholders when files are missing. `GameAssetCatalog.try_load_texture()` and `try_load_texture_cached()` return `null` safely for missing files and do not preload optional assets. `clear_texture_cache()` exists for tests. No real image assets are included in Stage 37.
