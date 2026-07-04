extends RefCounted
class_name TeamSelectionResolver


func is_valid_team(hero_ids: Array, hero_catalog: HeroCatalog) -> bool:
	if hero_catalog == null or hero_ids.size() != 3:
		return false

	var seen := {}
	for hero_id in hero_ids:
		if hero_id == "" or seen.has(hero_id) or not hero_catalog.has_hero(hero_id):
			return false
		seen[hero_id] = true

	return true


func normalize_team(hero_ids: Array, hero_catalog: HeroCatalog) -> Array[String]:
	if is_valid_team(hero_ids, hero_catalog):
		return hero_ids.duplicate()
	return get_default_team(hero_catalog)


func get_default_team(hero_catalog: HeroCatalog) -> Array[String]:
	if hero_catalog == null:
		return []
	return hero_catalog.get_default_team_ids()
