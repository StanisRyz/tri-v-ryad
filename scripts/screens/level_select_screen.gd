extends Control

const LEVEL_CATALOG_SCRIPT := preload("res://scripts/game/config/level_catalog.gd")
const LEVEL_LABEL_FORMATTER_SCRIPT := preload("res://scripts/game/config/level_label_formatter.gd")
const LEVEL_ZONE_HELPER_SCRIPT := preload("res://scripts/game/config/level_zone_helper.gd")

signal level_selected(level_id: String)
signal back_pressed

@onready var back_button: Button = %BackButton
@onready var points_label: Label = %PointsLabel
@onready var zone_selector: OptionButton = %ZoneSelector
@onready var level_buttons: VBoxContainer = %LevelButtons

var _level_catalog = LEVEL_CATALOG_SCRIPT.new()
var _progress_manager
var _settings_manager
var _selected_zone_index := -1
var _has_manual_zone_selection := false


func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
	zone_selector.item_selected.connect(_on_zone_selected)
	_refresh()


func set_progress_manager(progress_manager) -> void:
	_progress_manager = progress_manager
	if is_inside_tree():
		_refresh()


func set_settings_manager(settings_manager) -> void:
	_settings_manager = settings_manager
	if is_inside_tree():
		_refresh()


func _refresh() -> void:
	_refresh_points()
	_build_zone_selector()
	_build_level_buttons()


func _build_zone_selector() -> void:
	zone_selector.clear()

	var levels: Array = _level_catalog.get_all_levels()
	var total_levels := levels.size()
	var zone_count: int = LEVEL_ZONE_HELPER_SCRIPT.get_zone_count(total_levels)
	var unlocked_zone_indices: Array[int] = []
	for zone_index in range(zone_count):
		if _is_zone_unlocked(zone_index):
			unlocked_zone_indices.append(zone_index)

	if unlocked_zone_indices.is_empty():
		unlocked_zone_indices.append(0)

	var highest_unlocked_zone_index: int = unlocked_zone_indices[unlocked_zone_indices.size() - 1]
	if not _has_manual_zone_selection or not unlocked_zone_indices.has(_selected_zone_index):
		_selected_zone_index = highest_unlocked_zone_index

	var selected_item_index := 0
	for zone_index in unlocked_zone_indices:
		var level_range: Vector2i = LEVEL_ZONE_HELPER_SCRIPT.get_level_range_for_zone(zone_index, total_levels)
		var label: String = LEVEL_ZONE_HELPER_SCRIPT.format_zone_label(zone_index, level_range.x, level_range.y)
		zone_selector.add_item(label, zone_index)
		if zone_index == _selected_zone_index:
			selected_item_index = zone_selector.get_item_count() - 1

	zone_selector.select(selected_item_index)


func _build_level_buttons() -> void:
	for child in level_buttons.get_children():
		child.queue_free()

	var levels: Array = _level_catalog.get_all_levels()
	var level_range: Vector2i = LEVEL_ZONE_HELPER_SCRIPT.get_level_range_for_zone(_selected_zone_index, levels.size())
	if level_range == Vector2i.ZERO:
		return

	for level_number in range(level_range.x, level_range.y + 1):
		var level_config = _level_catalog.get_level("level_%d" % level_number)
		var button := Button.new()
		var unlocked := _is_level_unlocked(level_config.level_id)
		var completed := _is_level_completed(level_config.level_id)
		var stars := _get_level_stars(level_config.level_id)
		var status := "Locked"
		if completed:
			status = "Completed"
		elif unlocked:
			status = "Open"

		button.custom_minimum_size = Vector2(420, 74)
		var title: String = LEVEL_LABEL_FORMATTER_SCRIPT.format_level_label(level_config.level_id, level_config.display_name)
		if _is_debug_labels_enabled():
			title = "%s (%s)" % [title, level_config.level_id]
		button.text = "%s\n%s | Stars: %d/3" % [title, status, stars]
		button.disabled = not unlocked
		if unlocked:
			button.pressed.connect(_on_level_button_pressed.bind(level_config.level_id))
		level_buttons.add_child(button)


func _on_zone_selected(item_index: int) -> void:
	_selected_zone_index = zone_selector.get_item_id(item_index)
	_has_manual_zone_selection = true
	_build_level_buttons()


func _on_level_button_pressed(level_id: String) -> void:
	level_selected.emit(level_id)


func _on_back_button_pressed() -> void:
	back_pressed.emit()


func _refresh_points() -> void:
	if _progress_manager == null:
		points_label.text = "Upgrade points: 0"
		return

	points_label.text = "Upgrade points: %d" % _progress_manager.get_upgrade_points()


func _is_level_unlocked(level_id: String) -> bool:
	if _progress_manager == null:
		return level_id == _level_catalog.get_default_level_id()
	return _progress_manager.is_level_unlocked(_level_catalog, level_id)


func _is_zone_unlocked(zone_index: int) -> bool:
	if zone_index <= 0:
		return true

	var unlock_level_id: String = LEVEL_ZONE_HELPER_SCRIPT.get_zone_unlock_level_id(zone_index)
	if unlock_level_id == "":
		return false
	return _is_level_completed(unlock_level_id)


func _is_level_completed(level_id: String) -> bool:
	if _progress_manager == null:
		return false
	return _progress_manager.is_level_completed(level_id)


func _get_level_stars(level_id: String) -> int:
	if _progress_manager == null:
		return 0
	return _progress_manager.get_level_stars(level_id)


func _is_debug_labels_enabled() -> bool:
	if _settings_manager == null:
		return false
	return _settings_manager.get_settings().debug_labels_enabled
