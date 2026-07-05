extends RefCounted
class_name BattleBackgroundCatalog

const BATTLE_BACKGROUND_CONFIG_SCRIPT := preload("res://scripts/game/config/battle_background_config.gd")

var _backgrounds: Dictionary = {}
var _background_order: Array[String] = []


func _init() -> void:
	_register_backgrounds()


func get_all_backgrounds() -> Array:
	var backgrounds: Array = []
	for background_id in _background_order:
		backgrounds.append(_backgrounds[background_id])
	return backgrounds


func get_background(background_id: String):
	if has_background(background_id):
		return _backgrounds[background_id]

	return null


func has_background(background_id: String) -> bool:
	return _backgrounds.has(background_id)


func get_default_background():
	return get_background("background_1")


func is_valid_background(background_config) -> bool:
	if background_config == null:
		return false
	if background_config.background_id == "":
		return false
	if background_config.display_name == "":
		return false
	if not (background_config.placeholder_color is Color):
		return false

	return true


func _register_backgrounds() -> void:
	_add_background(BATTLE_BACKGROUND_CONFIG_SCRIPT.new("background_1", "Training Grounds", Color(0.16, 0.2, 0.24, 1.0)))
	_add_background(BATTLE_BACKGROUND_CONFIG_SCRIPT.new("background_2", "Forest Path", Color(0.11, 0.24, 0.15, 1.0)))
	_add_background(BATTLE_BACKGROUND_CONFIG_SCRIPT.new("background_3", "Cave Hall", Color(0.18, 0.15, 0.2, 1.0)))
	_add_background(BATTLE_BACKGROUND_CONFIG_SCRIPT.new("background_4", "Mountain Pass", Color(0.22, 0.2, 0.16, 1.0)))
	_add_background(BATTLE_BACKGROUND_CONFIG_SCRIPT.new("background_5", "Dark Arena", Color(0.1, 0.1, 0.14, 1.0)))


func _add_background(background_config) -> void:
	if background_config == null or background_config.background_id == "" or _backgrounds.has(background_config.background_id):
		return

	_backgrounds[background_config.background_id] = background_config
	_background_order.append(background_config.background_id)
