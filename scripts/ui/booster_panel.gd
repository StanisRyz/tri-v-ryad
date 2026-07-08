extends PanelContainer
class_name BoosterPanel

signal booster_pressed(booster_id: String)

const BOOSTER_TEXTURE_BUTTON_SCENE := preload("res://scenes/ui/BoosterTextureButton.tscn")
const ASSET_KEY_RESOLVER_SCRIPT := preload("res://scripts/game/config/asset_key_resolver.gd")
const GAME_ASSET_CATALOG_SCRIPT := preload("res://scripts/game/config/game_asset_catalog.gd")
const UI_ASSET_BINDING_SCRIPT := preload("res://scripts/ui/ui_asset_binding.gd")

const BUTTON_SIZE_MARGIN := 8.0
const MIN_BUTTON_SIZE := 48.0

@onready var button_row: HBoxContainer = %ButtonRow

var _catalog
var _booster_state
var _selected_booster_id := ""
var _buttons: Dictionary = {}
var _inventory_counts: Dictionary = {}


func _ready() -> void:
	UI_ASSET_BINDING_SCRIPT.bind_ui_asset(self, "booster_panel")
	resized.connect(_apply_button_square_size)
	refresh()


func setup_boosters(catalog) -> void:
	_catalog = catalog
	_rebuild_buttons()
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
	if button_row == null:
		return

	for booster_id in _buttons.keys():
		var button: BoosterTextureButton = _buttons[booster_id]
		var battle_uses_left := 0
		if _booster_state != null:
			battle_uses_left = _booster_state.get_uses_left(booster_id)
		var inventory_count: int = int(_inventory_counts.get(booster_id, 0))
		button.set_count(inventory_count)
		button.is_selected = booster_id == _selected_booster_id
		button.is_disabled_state = battle_uses_left <= 0 or inventory_count <= 0


func get_button_count() -> int:
	return _buttons.size()


func _rebuild_buttons() -> void:
	if button_row == null:
		return

	for child in button_row.get_children():
		child.queue_free()
	_buttons.clear()

	if _catalog == null:
		return

	for booster in _catalog.get_all_boosters():
		var button: BoosterTextureButton = BOOSTER_TEXTURE_BUTTON_SCENE.instantiate()
		button.name = "%sButton" % booster.booster_id.capitalize().replace(" ", "")
		button.tooltip_text = "%s\n%s" % [booster.display_name, booster.description]
		button.booster_id = booster.booster_id
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.default_texture = GAME_ASSET_CATALOG_SCRIPT.try_load_texture_cached(
			ASSET_KEY_RESOLVER_SCRIPT.get_shop_booster_icon_asset_key(booster.booster_id)
		)
		button.pressed.connect(_on_button_pressed.bind(booster.booster_id))
		button_row.add_child(button)
		_buttons[booster.booster_id] = button

	_apply_button_square_size.call_deferred()


func _apply_button_square_size() -> void:
	if button_row == null or _buttons.is_empty():
		return

	var target_size: float = maxf(button_row.size.y - BUTTON_SIZE_MARGIN, MIN_BUTTON_SIZE)
	for button in _buttons.values():
		button.custom_minimum_size = Vector2(target_size, target_size)


func _on_button_pressed(booster_id: String) -> void:
	booster_pressed.emit(booster_id)
