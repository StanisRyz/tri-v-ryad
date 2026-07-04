extends Control

const LEVEL_CATALOG_SCRIPT := preload("res://scripts/game/config/level_catalog.gd")

signal level_selected(level_id: String)
signal back_pressed
signal upgrades_pressed

@onready var back_button: Button = %BackButton
@onready var upgrades_button: Button = %UpgradesButton
@onready var points_label: Label = %PointsLabel
@onready var level_buttons: VBoxContainer = %LevelButtons

var _level_catalog = LEVEL_CATALOG_SCRIPT.new()
var _progress_manager


func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
	upgrades_button.pressed.connect(_on_upgrades_button_pressed)
	_build_level_buttons()
	_refresh_points()


func set_progress_manager(progress_manager) -> void:
	_progress_manager = progress_manager
	if is_inside_tree():
		_refresh_points()


func _build_level_buttons() -> void:
	for child in level_buttons.get_children():
		child.queue_free()

	for level_config in _level_catalog.get_all_levels():
		var button := Button.new()
		button.custom_minimum_size = Vector2(360, 58)
		button.text = level_config.display_name
		button.pressed.connect(_on_level_button_pressed.bind(level_config.level_id))
		level_buttons.add_child(button)


func _on_level_button_pressed(level_id: String) -> void:
	level_selected.emit(level_id)


func _on_back_button_pressed() -> void:
	back_pressed.emit()


func _on_upgrades_button_pressed() -> void:
	upgrades_pressed.emit()


func _refresh_points() -> void:
	if _progress_manager == null:
		points_label.text = "Upgrade points: 0"
		return

	points_label.text = "Upgrade points: %d" % _progress_manager.get_upgrade_points()
