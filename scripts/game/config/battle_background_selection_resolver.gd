extends RefCounted
class_name BattleBackgroundSelectionResolver

const BATTLE_BACKGROUND_CATALOG_SCRIPT := preload("res://scripts/game/config/battle_background_catalog.gd")


func select_background(background_catalog, rng: RandomNumberGenerator = null):
	var valid_backgrounds := _get_valid_backgrounds(background_catalog)
	if valid_backgrounds.is_empty():
		return _get_safe_fallback_background()

	if rng == null:
		return valid_backgrounds[0]

	var selected_index := rng.randi_range(0, valid_backgrounds.size() - 1)
	return valid_backgrounds[selected_index]


func _get_valid_backgrounds(background_catalog) -> Array:
	var valid_backgrounds: Array = []
	if background_catalog == null or not background_catalog.has_method("get_all_backgrounds"):
		return valid_backgrounds

	var seen_ids := {}
	for background_config in background_catalog.get_all_backgrounds():
		if not _is_valid_background(background_config):
			continue
		if seen_ids.has(background_config.background_id):
			continue
		seen_ids[background_config.background_id] = true
		valid_backgrounds.append(background_config)

	return valid_backgrounds


func _is_valid_background(background_config) -> bool:
	return BATTLE_BACKGROUND_CATALOG_SCRIPT.new().is_valid_background(background_config)


func _get_safe_fallback_background():
	return BATTLE_BACKGROUND_CATALOG_SCRIPT.new().get_default_background()
