extends RefCounted
class_name EnemySelectionResolver

const ENEMY_CATALOG_SCRIPT := preload("res://scripts/game/config/enemy_catalog.gd")


func select_enemy(enemy_catalog, rng: RandomNumberGenerator = null):
	var valid_enemies := _get_valid_enemies(enemy_catalog)
	if valid_enemies.is_empty():
		return _get_safe_fallback_enemy()

	if rng == null:
		return valid_enemies[0]

	var selected_index := rng.randi_range(0, valid_enemies.size() - 1)
	return valid_enemies[selected_index]


func select_enemy_for_level(level_config, enemy_catalog, rng: RandomNumberGenerator = null):
	var valid_enemies := _get_valid_enemies(enemy_catalog)
	if not valid_enemies.is_empty():
		return select_enemy(enemy_catalog, rng)

	if level_config != null and level_config.has_method("get_enemy_config"):
		var fallback_enemy = level_config.get_enemy_config()
		if _is_valid_enemy(fallback_enemy):
			return fallback_enemy

	return _get_safe_fallback_enemy()


func _get_valid_enemies(enemy_catalog) -> Array:
	var valid_enemies: Array = []
	if enemy_catalog == null or not enemy_catalog.has_method("get_all_enemies"):
		return valid_enemies

	var seen_ids := {}
	for enemy_config in enemy_catalog.get_all_enemies():
		if not _is_valid_enemy(enemy_config):
			continue
		if seen_ids.has(enemy_config.enemy_id):
			continue
		seen_ids[enemy_config.enemy_id] = true
		valid_enemies.append(enemy_config)

	return valid_enemies


func _is_valid_enemy(enemy_config) -> bool:
	return ENEMY_CATALOG_SCRIPT.new().is_valid_enemy(enemy_config)


func _get_safe_fallback_enemy():
	return ENEMY_CATALOG_SCRIPT.new().get_default_enemy()
