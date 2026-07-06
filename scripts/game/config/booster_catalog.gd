extends RefCounted
class_name BoosterCatalog

const BOOSTER_CONFIG_SCRIPT := preload("res://scripts/game/config/booster_config.gd")

const HAMMER := "hammer"
const FREEZE_TIME := "freeze_time"
const ROCKET_BARRAGE := "rocket_barrage"

var _boosters: Dictionary = {}
var _booster_order: Array[String] = []


func _init() -> void:
	_register_boosters()


func get_all_boosters() -> Array:
	var boosters: Array = []
	for booster_id in _booster_order:
		boosters.append(_boosters[booster_id])
	return boosters


func get_booster(booster_id: String):
	if has_booster(booster_id):
		return _boosters[booster_id]
	return null


func has_booster(booster_id: String) -> bool:
	return _boosters.has(booster_id)


func get_default_booster_ids() -> Array[String]:
	return _booster_order.duplicate()


func is_valid_booster(config) -> bool:
	return config != null and config.has_method("is_valid") and config.is_valid()


func _register_boosters() -> void:
	_add_booster(BOOSTER_CONFIG_SCRIPT.new(
		HAMMER,
		"Hammer",
		"Clear a 3x3 area around one crystal.",
		"booster_hammer",
		1,
		BOOSTER_CONFIG_SCRIPT.TARGETING_TARGET_CELL
	))
	_add_booster(BOOSTER_CONFIG_SCRIPT.new(
		FREEZE_TIME,
		"Time Freeze",
		"The next 3 successful turns do not reduce moves.",
		"booster_freeze_time",
		1,
		BOOSTER_CONFIG_SCRIPT.TARGETING_NONE
	))
	_add_booster(BOOSTER_CONFIG_SCRIPT.new(
		ROCKET_BARRAGE,
		"Rocket Barrage",
		"Clear every crystal of the selected color.",
		"booster_rocket_barrage",
		1,
		BOOSTER_CONFIG_SCRIPT.TARGETING_TARGET_CELL
	))


func _add_booster(config) -> void:
	if not is_valid_booster(config):
		return
	if _boosters.has(config.booster_id):
		return

	_boosters[config.booster_id] = config
	_booster_order.append(config.booster_id)
