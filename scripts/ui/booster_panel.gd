extends PanelContainer
class_name BoosterPanel

signal booster_pressed(booster_id: String)

const BOOSTER_BUTTON_SCENE := preload("res://scenes/ui/BoosterButton.tscn")
const UI_ASSET_BINDING_SCRIPT := preload("res://scripts/ui/ui_asset_binding.gd")

@onready var button_row: HBoxContainer = %ButtonRow
@onready var freeze_label: Label = %FreezeLabel

var _catalog
var _booster_state
var _selected_booster_id := ""
var _buttons: Dictionary = {}


func _ready() -> void:
	UI_ASSET_BINDING_SCRIPT.bind_ui_asset(self, "booster_panel")
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


func play_booster_feedback(booster_id: String, animations_enabled: bool = true, reduced_motion_enabled: bool = false) -> void:
	var button: BoosterButton = _buttons.get(booster_id)
	if button != null and button.has_method("play_feedback"):
		button.play_feedback(animations_enabled, reduced_motion_enabled)


func refresh() -> void:
	if button_row == null:
		return

	for booster_id in _buttons.keys():
		var button: BoosterButton = _buttons[booster_id]
		var uses_left := 0
		if _booster_state != null:
			uses_left = _booster_state.get_uses_left(booster_id)
		button.set_uses_left(uses_left)
		button.set_selected(booster_id == _selected_booster_id)
		button.set_disabled_state(uses_left <= 0)

	if freeze_label != null:
		var freeze_turns := 0
		if _booster_state != null:
			freeze_turns = _booster_state.freeze_turns_left
		freeze_label.text = "Freeze turns: %d" % freeze_turns


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
		var button: BoosterButton = BOOSTER_BUTTON_SCENE.instantiate()
		button.name = "%sButton" % booster.booster_id.capitalize().replace(" ", "")
		button.tooltip_text = "%s\n%s" % [booster.display_name, booster.description]
		button.set_booster_id(booster.booster_id)
		button.pressed.connect(_on_button_pressed.bind(booster.booster_id))
		button_row.add_child(button)
		_buttons[booster.booster_id] = button


func _on_button_pressed(booster_id: String) -> void:
	booster_pressed.emit(booster_id)
