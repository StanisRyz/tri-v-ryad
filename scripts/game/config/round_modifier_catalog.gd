extends RefCounted
class_name RoundModifierCatalog

## Stage 33 v0.1: a small pool of positive per-battle color damage modifiers.
## Stage 60.2 v0.1: kept as legacy/future code. BattlePresenter still selects a
## random modifier each battle for display purposes only - active direct-mode
## damage now comes from current_level_boost (LevelBoostResolver) instead.

const ROUND_MODIFIER_CONFIG_SCRIPT := preload("res://scripts/game/config/round_modifier_config.gd")

var _modifiers: Dictionary = {}
var _modifier_order: Array[String] = []


func _init() -> void:
	_register_modifiers()


func get_all_modifiers() -> Array:
	var modifiers: Array = []
	for modifier_id in _modifier_order:
		modifiers.append(_modifiers[modifier_id])
	return modifiers


func get_modifier(modifier_id: String):
	if has_modifier(modifier_id):
		return _modifiers[modifier_id]

	return null


func has_modifier(modifier_id: String) -> bool:
	return _modifiers.has(modifier_id)


func get_default_modifier():
	return get_modifier("all_x2")


## Stage 34 v0.1: normal random battles pick from single-color surges only, so
## picking a modifier is a strategic color choice. all_x2 stays available as
## the safe default/fallback via get_default_modifier(), but is excluded here
## to keep the random pool color-focused.
func get_random_pool_modifiers() -> Array:
	var pool_ids := ["red_x3", "blue_x3", "green_x3", "yellow_x3", "purple_x3"]
	var pool: Array = []
	for modifier_id in pool_ids:
		if has_modifier(modifier_id):
			pool.append(get_modifier(modifier_id))
	return pool


func is_valid_modifier(modifier) -> bool:
	if modifier == null:
		return false

	return modifier.is_valid()


func _register_modifiers() -> void:
	_add_modifier(ROUND_MODIFIER_CONFIG_SCRIPT.new("red_x3", "Red Surge", "Red crystals deal x3 damage", {TileType.RED: 3.0}))
	_add_modifier(ROUND_MODIFIER_CONFIG_SCRIPT.new("blue_x3", "Blue Surge", "Blue crystals deal x3 damage", {TileType.BLUE: 3.0}))
	_add_modifier(ROUND_MODIFIER_CONFIG_SCRIPT.new("green_x3", "Green Surge", "Green crystals deal x3 damage", {TileType.GREEN: 3.0}))
	_add_modifier(ROUND_MODIFIER_CONFIG_SCRIPT.new("yellow_x3", "Yellow Surge", "Yellow crystals deal x3 damage", {TileType.YELLOW: 3.0}))
	_add_modifier(ROUND_MODIFIER_CONFIG_SCRIPT.new("purple_x3", "Purple Surge", "Purple crystals deal x3 damage", {TileType.PURPLE: 3.0}))
	_add_modifier(ROUND_MODIFIER_CONFIG_SCRIPT.new("all_x2", "Overcharge", "All crystals deal x2 damage", {
		TileType.RED: 2.0,
		TileType.BLUE: 2.0,
		TileType.GREEN: 2.0,
		TileType.YELLOW: 2.0,
		TileType.PURPLE: 2.0,
	}))


func _add_modifier(modifier_config) -> void:
	if modifier_config == null or modifier_config.modifier_id == "" or _modifiers.has(modifier_config.modifier_id):
		return

	_modifiers[modifier_config.modifier_id] = modifier_config
	_modifier_order.append(modifier_config.modifier_id)
