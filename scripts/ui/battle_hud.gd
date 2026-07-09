extends PanelContainer

const ASSET_KEY_RESOLVER_SCRIPT := preload("res://scripts/game/config/asset_key_resolver.gd")
const GAME_ASSET_CATALOG_SCRIPT := preload("res://scripts/game/config/game_asset_catalog.gd")

@onready var background_visual: FallbackImageSlot = %BackgroundVisual
@onready var level_label: Label = %LevelLabel
@onready var moves_label: Label = %MovesLabel


func _ready() -> void:
	_bind_panel_background()
	set_placeholder_values("Level 1", "Moves: --")


## Fallback-only: an Inspector-assigned background texture is never overwritten.
func _bind_panel_background() -> void:
	if background_visual == null or background_visual.has_texture():
		return

	background_visual.set_texture(GAME_ASSET_CATALOG_SCRIPT.try_load_texture_cached(
		ASSET_KEY_RESOLVER_SCRIPT.get_ui_asset_key("battle_hud_panel")
	))


func set_values(level_text: String, moves_text: String) -> void:
	level_label.text = level_text
	moves_label.text = moves_text


func set_placeholder_values(level_text: String, moves_text: String) -> void:
	set_values(level_text, moves_text)
