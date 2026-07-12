extends PanelContainer
class_name BoosterPanel

signal booster_pressed(booster_id: String)

const ASSET_KEY_RESOLVER_SCRIPT := preload("res://scripts/game/config/asset_key_resolver.gd")
const GAME_ASSET_CATALOG_SCRIPT := preload("res://scripts/game/config/game_asset_catalog.gd")
const UI_ASSET_BINDING_SCRIPT := preload("res://scripts/ui/ui_asset_binding.gd")

const BUTTON_SIZE_MARGIN := 8.0
const MIN_BUTTON_SIZE := 48.0

## Stage 65.21 v0.1: BoosterConfig.display_name/description (booster_catalog.gd)
## are English-only gameplay data, not display text, so the tooltip is built
## from these localization keys instead — the only place those two fields are
## ever shown to the player.
const TOOLTIP_NAME_KEYS := {
	"hammer": "shop.item.hammer",
	"freeze_time": "shop.item.time_freeze",
	"rocket_barrage": "shop.item.rocket_barrage",
}
const TOOLTIP_DESC_KEYS := {
	"hammer": "booster.desc.hammer",
	"freeze_time": "booster.desc.freeze_time",
	"rocket_barrage": "booster.desc.rocket_barrage",
}

@onready var panel_background: FallbackImageSlot = %PanelBackground
@onready var button_row: HBoxContainer = %ButtonRow
@onready var hammer_button: BoosterTextureButton = %HammerButton
@onready var freeze_time_button: BoosterTextureButton = %FreezeTimeButton
@onready var rocket_barrage_button: BoosterTextureButton = %RocketBarrageButton

var _catalog
var _booster_state
var _selected_booster_id := ""
var _buttons: Dictionary = {}
var _inventory_counts: Dictionary = {}


func _ready() -> void:
	UI_ASSET_BINDING_SCRIPT.bind_ui_asset(self, "booster_panel")
	_bind_panel_background()
	_register_fixed_buttons()
	resized.connect(_apply_button_square_size)
	refresh()


## Stage 64.3 v0.1: booster buttons are fixed editor-visible scene nodes
## (HammerButton/FreezeTimeButton/RocketBarrageButton), no longer created at
## runtime. setup_boosters() still accepts the catalog for tooltip text, but
## no longer instantiates or clears any UI nodes.
func setup_boosters(catalog) -> void:
	_catalog = catalog
	_apply_tooltips()
	refresh()


func set_booster_state(booster_state) -> void:
	_booster_state = booster_state
	refresh()


func set_selected_booster(booster_id: String) -> void:
	_selected_booster_id = booster_id
	refresh()


## Stage 62.2 v0.1: counts is the global cross-battle booster_inventory read
## from ProgressManager (e.g. {"hammer": 3, "freeze_time": 1, "rocket_barrage": 0}),
## not the battle-local BoosterState.uses_left. Missing/unavailable data is
## treated as an empty Dictionary, which refresh() reads back as 0 per booster.
func set_booster_counts(counts: Dictionary) -> void:
	_inventory_counts = counts.duplicate()
	refresh()


func play_booster_feedback(booster_id: String, animations_enabled: bool = true, reduced_motion_enabled: bool = false) -> void:
	var button: BoosterTextureButton = _buttons.get(booster_id)
	if button != null and button.has_method("play_feedback"):
		button.play_feedback(animations_enabled, reduced_motion_enabled)


func refresh() -> void:
	for booster_id in _buttons.keys():
		var button: BoosterTextureButton = _buttons[booster_id]
		if button == null:
			continue
		var battle_uses_left := 0
		if _booster_state != null:
			battle_uses_left = _booster_state.get_uses_left(booster_id)
		var inventory_count: int = int(_inventory_counts.get(booster_id, 0))
		button.set_count(inventory_count)
		button.is_selected = booster_id == _selected_booster_id
		button.is_disabled_state = battle_uses_left <= 0 or inventory_count <= 0


func get_button_count() -> int:
	return _buttons.size()


func _register_fixed_buttons() -> void:
	_buttons = {
		"hammer": hammer_button,
		"freeze_time": freeze_time_button,
		"rocket_barrage": rocket_barrage_button,
	}

	for booster_id in _buttons.keys():
		var button: BoosterTextureButton = _buttons[booster_id]
		if button == null:
			continue
		if not button.pressed.is_connected(_on_button_pressed):
			button.pressed.connect(_on_button_pressed.bind(booster_id))
		_bind_booster_icon(button, booster_id)

	_apply_button_square_size.call_deferred()


## Fallback-only: an Inspector-assigned default_texture is never overwritten.
func _bind_booster_icon(button: BoosterTextureButton, booster_id: String) -> void:
	if button.default_texture != null:
		return

	button.default_texture = GAME_ASSET_CATALOG_SCRIPT.try_load_texture_cached(
		ASSET_KEY_RESOLVER_SCRIPT.get_shop_booster_icon_asset_key(booster_id)
	)


func _bind_panel_background() -> void:
	if panel_background == null or panel_background.has_texture():
		return

	panel_background.set_texture(GAME_ASSET_CATALOG_SCRIPT.try_load_texture_cached(
		ASSET_KEY_RESOLVER_SCRIPT.get_ui_asset_key("booster_panel_background")
	))


func _apply_tooltips() -> void:
	if _catalog == null:
		return

	var localization_manager := get_node_or_null("/root/LocalizationManager")
	for booster_id in _buttons.keys():
		var button: BoosterTextureButton = _buttons[booster_id]
		if button == null:
			continue
		var config = _catalog.get_booster(booster_id)
		if config == null:
			continue
		button.tooltip_text = _format_tooltip(booster_id, config, localization_manager)


func _format_tooltip(booster_id: String, config, localization_manager) -> String:
	if localization_manager != null and TOOLTIP_NAME_KEYS.has(booster_id):
		var name_text: String = localization_manager.tr_key(TOOLTIP_NAME_KEYS[booster_id])
		var desc_text: String = localization_manager.tr_key(TOOLTIP_DESC_KEYS[booster_id])
		return "%s\n%s" % [name_text, desc_text]
	return "%s\n%s" % [config.display_name, config.description]


func _apply_button_square_size() -> void:
	if button_row == null or _buttons.is_empty():
		return

	var target_size: float = maxf(button_row.size.y - BUTTON_SIZE_MARGIN, MIN_BUTTON_SIZE)
	for button in _buttons.values():
		if button == null:
			continue
		button.custom_minimum_size = Vector2(target_size, target_size)


func _on_button_pressed(booster_id: String) -> void:
	booster_pressed.emit(booster_id)
