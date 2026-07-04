extends RefCounted
class_name UpgradeResolver

const STAT_ATTACK := "attack"
const STAT_HP := "hp"
const UPGRADE_COST := 1


func get_upgrade_cost(_progress, _hero_id: String, stat: String) -> int:
	if not _is_supported_stat(stat):
		return -1
	return UPGRADE_COST


func can_upgrade(progress, hero_id: String, stat: String) -> bool:
	if progress == null or hero_id == "" or not _is_supported_stat(stat):
		return false
	return progress.upgrade_points >= UPGRADE_COST


func upgrade(progress, hero_id: String, stat: String) -> bool:
	if not can_upgrade(progress, hero_id, stat):
		return false

	var hero_upgrade = progress.ensure_hero(hero_id)
	progress.upgrade_points -= UPGRADE_COST
	if stat == STAT_ATTACK:
		hero_upgrade.attack_level += 1
	elif stat == STAT_HP:
		hero_upgrade.hp_level += 1
	else:
		return false

	return true


func _is_supported_stat(stat: String) -> bool:
	return stat == STAT_ATTACK or stat == STAT_HP
