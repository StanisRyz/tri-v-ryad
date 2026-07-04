extends RefCounted
class_name HeroUpgradeViewData

var hero_id := ""
var display_name := ""
var ability_id := ""
var attack_level := 0
var hp_level := 0
var current_attack := 0
var next_attack := 0
var current_max_hp := 0
var next_max_hp := 0
var can_upgrade_attack := false
var can_upgrade_hp := false


static func from_config(hero_config: HeroConfig, progress: PlayerProgress, progress_manager: ProgressManager) -> HeroUpgradeViewData:
	var data := HeroUpgradeViewData.new()
	if hero_config == null:
		return data

	data.hero_id = hero_config.hero_id
	data.display_name = hero_config.display_name
	data.ability_id = hero_config.ability_id

	var upgrade_state: HeroUpgradeState = null
	if progress_manager != null and progress_manager.has_method("get_hero_upgrade"):
		upgrade_state = progress_manager.get_hero_upgrade(hero_config.hero_id)
	elif progress != null:
		upgrade_state = progress.get_hero_upgrade(hero_config.hero_id)

	if upgrade_state != null:
		data.attack_level = upgrade_state.attack_level
		data.hp_level = upgrade_state.hp_level

	data.current_attack = hero_config.base_attack + data.attack_level * 2
	data.next_attack = hero_config.base_attack + (data.attack_level + 1) * 2
	data.current_max_hp = hero_config.base_max_hp + data.hp_level * 10
	data.next_max_hp = hero_config.base_max_hp + (data.hp_level + 1) * 10

	if progress_manager != null:
		data.can_upgrade_attack = progress_manager.can_upgrade(hero_config.hero_id, "attack")
		data.can_upgrade_hp = progress_manager.can_upgrade(hero_config.hero_id, "hp")

	return data
