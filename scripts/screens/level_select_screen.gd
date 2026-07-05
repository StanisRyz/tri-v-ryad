extends Control

const LEVEL_CATALOG_SCRIPT := preload("res://scripts/game/config/level_catalog.gd")
const LEVEL_LABEL_FORMATTER_SCRIPT := preload("res://scripts/game/config/level_label_formatter.gd")

signal level_selected(level_id: String)
signal back_pressed

@onready var back_button: Button = %BackButton
@onready var points_label: Label = %PointsLabel
@onready var level_buttons: VBoxContainer = %LevelButtons

var _level_catalog = LEVEL_CATALOG_SCRIPT.new()
var _progress_manager
var _settings_manager


func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
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
	_build_level_buttons()


func _build_level_buttons() -> void:
	for child in level_buttons.get_children():
		child.queue_free()

	for level_config in _level_catalog.get_all_levels():
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
