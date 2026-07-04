extends RefCounted
class_name HeroCatalog

const HERO_CONFIG_SCRIPT := preload("res://scripts/game/config/hero_config.gd")

var _heroes: Dictionary = {}
var _hero_order: Array[String] = []


func _init() -> void:
	_register_heroes()


func get_hero(hero_id: String) -> HeroConfig:
	return _heroes.get(hero_id, null)


func get_all_heroes() -> Array[HeroConfig]:
	var heroes: Array[HeroConfig] = []
	for hero_id in _hero_order:
		heroes.append(_heroes[hero_id])
	return heroes


func has_hero(hero_id: String) -> bool:
	return _heroes.has(hero_id)


func get_default_team_ids() -> Array[String]:
	return ["hero_1", "hero_2", "hero_3"]


func get_heroes(hero_ids: Array) -> Array[HeroConfig]:
	var heroes: Array[HeroConfig] = []
	for hero_id in hero_ids:
		if has_hero(hero_id):
			heroes.append(get_hero(hero_id))
	return heroes


func _register_heroes() -> void:
	_add_hero(HERO_CONFIG_SCRIPT.new("hero_1", "Warrior", 0, 10, 100, 10, "power_strike"))
	_add_hero(HERO_CONFIG_SCRIPT.new("hero_2", "Guardian", 1, 8, 130, 10, "line_break"))
	_add_hero(HERO_CONFIG_SCRIPT.new("hero_3", "Healer", 2, 9, 100, 10, "rally_heal"))
	_add_hero(HERO_CONFIG_SCRIPT.new("hero_4", "Mage", 0, 14, 75, 10, "power_strike"))
	_add_hero(HERO_CONFIG_SCRIPT.new("hero_5", "Ranger", 1, 11, 95, 8, "line_break"))


func _add_hero(hero_config: HeroConfig) -> void:
	_heroes[hero_config.hero_id] = hero_config
	_hero_order.append(hero_config.hero_id)
