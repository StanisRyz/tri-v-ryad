extends Control
class_name UpgradeScreen

signal back_pressed

const HERO_CATALOG_SCRIPT := preload("res://scripts/game/config/hero_catalog.gd")
const HERO_UPGRADE_VIEW_DATA_SCRIPT := preload("res://scripts/game/presentation/hero_upgrade_view_data.gd")

@onready var points_label: Label = %PointsLabel
@onready var status_label: Label = %StatusLabel
@onready var hero_rows: VBoxContainer = %HeroRows
@onready var back_button: Button = %BackButton

var _progress_manager
var _settings_manager
var _hero_catalog: HeroCatalog
var _row_controls: Dictionary = {}


func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
	_set_status("")
	_build_rows()
	_refresh()


func set_progress_manager(progress_manager) -> void:
	_progress_manager = progress_manager
	_hero_catalog = _progress_manager.get_hero_catalog() if _progress_manager != null else null
	if is_inside_tree():
		_build_rows()
		_refresh()


func set_settings_manager(settings_manager) -> void:
	_settings_manager = settings_manager
	if is_inside_tree():
		_build_rows()
		_refresh()


func _build_rows() -> void:
	if hero_rows == null:
		return

	for child in hero_rows.get_children():
		child.queue_free()

	_row_controls.clear()
	var catalog := _get_hero_catalog()
	for hero_config in catalog.get_all_heroes():
		var row := PanelContainer.new()
		row.custom_minimum_size = Vector2(0, 188)

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
		title.text = _get_hero_title_text(hero_config)
		title.add_theme_font_size_override("font_size", 22)
		content.add_child(title)

		var ability := Label.new()
		ability.text = "Ability: %s" % hero_config.ability_id
		ability.add_theme_font_size_override("font_size", 16)
		content.add_child(ability)

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
			"ability": ability,
			"stats": stats,
			"attack_button": attack_button,
			"hp_button": hp_button,
		}


func _refresh() -> void:
	var points := 0
	if _progress_manager != null:
		points = _progress_manager.get_upgrade_points()

	points_label.text = "Upgrade points: %d" % points
	if _progress_manager == null:
		_set_status("Progress is unavailable.")

	for hero_id in _row_controls.keys():
		var controls: Dictionary = _row_controls[hero_id]
		var hero_config = controls["config"]
		var progress = _progress_manager.get_progress() if _progress_manager != null else null
		var view_data = HERO_UPGRADE_VIEW_DATA_SCRIPT.from_config(hero_config, progress, _progress_manager)

		controls["ability"].text = "Ability: %s" % view_data.ability_id
		controls["stats"].text = "Attack Lv %d | %d -> %d\nHP Lv %d | %d -> %d" % [
			view_data.attack_level,
			view_data.current_attack,
			view_data.next_attack,
			view_data.hp_level,
			view_data.current_max_hp,
			view_data.next_max_hp,
		]
		controls["attack_button"].disabled = not view_data.can_upgrade_attack
		controls["hp_button"].disabled = not view_data.can_upgrade_hp


func _on_upgrade_button_pressed(hero_id: String, stat: String) -> void:
	if _progress_manager == null:
		_set_status("Progress is unavailable.")
		return

	if _progress_manager.upgrade(hero_id, stat):
		if stat == "attack":
			_set_status("Attack upgraded")
		else:
			_set_status("HP upgraded")
		_refresh()
	else:
		_set_status("Not enough upgrade points")
		_refresh()


func _on_back_button_pressed() -> void:
	back_pressed.emit()


func _get_hero_catalog() -> HeroCatalog:
	if _hero_catalog != null:
		return _hero_catalog
	if _progress_manager != null:
		_hero_catalog = _progress_manager.get_hero_catalog()
	if _hero_catalog == null:
		_hero_catalog = HERO_CATALOG_SCRIPT.new()
	return _hero_catalog


func _set_status(message: String) -> void:
	if status_label != null:
		status_label.text = message


func _get_hero_title_text(hero_config: HeroConfig) -> String:
	if _settings_manager != null and _settings_manager.get_settings().debug_labels_enabled:
		return "%s (%s)" % [hero_config.display_name, hero_config.hero_id]
	return hero_config.display_name
