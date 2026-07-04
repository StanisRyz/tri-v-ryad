extends Control
class_name TeamSelectScreen

signal back_pressed
signal start_battle_pressed(level_id: String)

@onready var back_button: Button = %BackButton
@onready var save_button: Button = %SaveButton
@onready var status_label: Label = %StatusLabel
@onready var lane_slots: HBoxContainer = %LaneSlots
@onready var roster_grid: GridContainer = %RosterGrid

var _progress_manager
var _hero_catalog: HeroCatalog
var _selected_hero_ids: Array[String] = []
var _hero_buttons: Dictionary = {}
var _level_id := ""


func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
	save_button.pressed.connect(_on_save_button_pressed)
	_refresh_from_progress()


func set_progress_manager(progress_manager) -> void:
	_progress_manager = progress_manager
	_hero_catalog = _progress_manager.get_hero_catalog() if _progress_manager != null else HeroCatalog.new()
	if is_inside_tree():
		_refresh_from_progress()


func set_level_id(level_id: String) -> void:
	_level_id = level_id
	if is_inside_tree():
		_refresh_controls("")


func _refresh_from_progress() -> void:
	if _hero_catalog == null:
		_hero_catalog = HeroCatalog.new()

	if _progress_manager != null:
		_selected_hero_ids = _progress_manager.get_selected_team_ids()
	else:
		_selected_hero_ids = _hero_catalog.get_default_team_ids()

	_build_lane_slots()
	_build_roster()
	_refresh_controls("")


func _build_lane_slots() -> void:
	for child in lane_slots.get_children():
		child.free()

	for lane_index in range(3):
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(190, 96)
		var margin := MarginContainer.new()
		margin.name = "MarginContainer"
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_bottom", 8)
		panel.add_child(margin)

		var label := Label.new()
		label.name = "LaneLabel"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		margin.add_child(label)
		lane_slots.add_child(panel)


func _build_roster() -> void:
	for child in roster_grid.get_children():
		child.free()

	_hero_buttons.clear()
	for hero_config in _hero_catalog.get_all_heroes():
		var button := Button.new()
		button.custom_minimum_size = Vector2(294, 112)
		button.toggle_mode = true
		button.text = _get_hero_button_text(hero_config)
		button.pressed.connect(_on_hero_button_pressed.bind(hero_config.hero_id))
		roster_grid.add_child(button)
		_hero_buttons[hero_config.hero_id] = button


func _refresh_controls(message: String) -> void:
	for lane_index in range(3):
		var panel := lane_slots.get_child(lane_index)
		var label: Label = panel.get_node("MarginContainer/LaneLabel")
		var hero_label := "Empty"
		if lane_index < _selected_hero_ids.size():
			var hero_config := _hero_catalog.get_hero(_selected_hero_ids[lane_index])
			if hero_config != null:
				hero_label = hero_config.display_name
		label.text = "Lane %d\n%s" % [lane_index + 1, hero_label]

	for hero_id in _hero_buttons.keys():
		var button: Button = _hero_buttons[hero_id]
		button.button_pressed = _selected_hero_ids.has(hero_id)

	var team_valid := _selected_hero_ids.size() == 3 and not _has_duplicates(_selected_hero_ids)
	save_button.disabled = not team_valid or _level_id == ""
	if message != "":
		status_label.text = message
	elif not team_valid:
		status_label.text = "Select exactly 3 unique heroes"
	else:
		status_label.text = "Team ready"


func _on_hero_button_pressed(hero_id: String) -> void:
	if _selected_hero_ids.has(hero_id):
		_selected_hero_ids.erase(hero_id)
		_refresh_controls("Removed hero")
		return

	if _selected_hero_ids.size() >= 3:
		_refresh_controls("Team already has 3 heroes")
		return

	_selected_hero_ids.append(hero_id)
	_refresh_controls("Added hero")


func _on_save_button_pressed() -> void:
	if _progress_manager == null:
		_refresh_controls("Progress is unavailable")
		return

	if _progress_manager.set_selected_team_ids(_selected_hero_ids):
		_refresh_controls("Team saved")
		start_battle_pressed.emit(_level_id)
	else:
		_refresh_controls("Invalid team")


func _on_back_button_pressed() -> void:
	back_pressed.emit()


func _get_hero_button_text(hero_config: HeroConfig) -> String:
	return "%s\nAttack: %d  HP: %d\nAbility: %s" % [
		hero_config.display_name,
		hero_config.base_attack,
		hero_config.base_max_hp,
		hero_config.ability_id,
	]


func _has_duplicates(hero_ids: Array[String]) -> bool:
	var seen := {}
	for hero_id in hero_ids:
		if seen.has(hero_id):
			return true
		seen[hero_id] = true
	return false
