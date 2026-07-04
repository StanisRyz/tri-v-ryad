extends Control
class_name UpgradeScreen

signal back_pressed

const HERO_CONFIG_SCRIPT := preload("res://scripts/game/config/hero_config.gd")

@onready var points_label: Label = %PointsLabel
@onready var hero_rows: VBoxContainer = %HeroRows
@onready var back_button: Button = %BackButton

var _progress_manager
var _row_controls: Dictionary = {}


func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
	_build_rows()
	_refresh()


func set_progress_manager(progress_manager) -> void:
	_progress_manager = progress_manager
	if is_inside_tree():
		_refresh()


func _build_rows() -> void:
	for child in hero_rows.get_children():
		child.queue_free()

	_row_controls.clear()
	for hero_config in HERO_CONFIG_SCRIPT.get_default_party():
		var row := PanelContainer.new()
		row.custom_minimum_size = Vector2(0, 132)

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 16)
		margin.add_theme_constant_override("margin_top", 12)
		margin.add_theme_constant_override("margin_right", 16)
		margin.add_theme_constant_override("margin_bottom", 12)
		row.add_child(margin)

		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 8)
		margin.add_child(content)

		var title := Label.new()
		title.text = hero_config.display_name
		title.add_theme_font_size_override("font_size", 22)
		content.add_child(title)

		var stats := Label.new()
		stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(stats)

		var buttons := HBoxContainer.new()
		buttons.add_theme_constant_override("separation", 10)
		content.add_child(buttons)

		var attack_button := Button.new()
		attack_button.custom_minimum_size = Vector2(132, 48)
		attack_button.text = "+Attack"
		attack_button.pressed.connect(_on_upgrade_button_pressed.bind(hero_config.hero_id, "attack"))
		buttons.add_child(attack_button)

		var hp_button := Button.new()
		hp_button.custom_minimum_size = Vector2(132, 48)
		hp_button.text = "+HP"
		hp_button.pressed.connect(_on_upgrade_button_pressed.bind(hero_config.hero_id, "hp"))
		buttons.add_child(hp_button)

		hero_rows.add_child(row)
		_row_controls[hero_config.hero_id] = {
			"config": hero_config,
			"stats": stats,
			"attack_button": attack_button,
			"hp_button": hp_button,
		}


func _refresh() -> void:
	var points := 0
	if _progress_manager != null:
		points = _progress_manager.get_upgrade_points()

	points_label.text = "Upgrade points: %d" % points

	for hero_id in _row_controls.keys():
		var controls: Dictionary = _row_controls[hero_id]
		var hero_config = controls["config"]
		var attack_level := 0
		var hp_level := 0
		if _progress_manager != null:
			var upgrade = _progress_manager.get_progress().get_hero_upgrade(hero_id)
			attack_level = upgrade.attack_level
			hp_level = upgrade.hp_level

		var attack_value: int = hero_config.base_attack + attack_level * 2
		var hp_value: int = hero_config.base_max_hp + hp_level * 10
		controls["stats"].text = "Attack Lv %d  Value %d\nHP Lv %d  Max HP %d" % [attack_level, attack_value, hp_level, hp_value]
		controls["attack_button"].disabled = _progress_manager == null or not _progress_manager.can_upgrade(hero_id, "attack")
		controls["hp_button"].disabled = _progress_manager == null or not _progress_manager.can_upgrade(hero_id, "hp")


func _on_upgrade_button_pressed(hero_id: String, stat: String) -> void:
	if _progress_manager == null:
		return

	if _progress_manager.upgrade(hero_id, stat):
		_refresh()


func _on_back_button_pressed() -> void:
	back_pressed.emit()
