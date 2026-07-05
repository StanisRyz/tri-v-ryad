extends RefCounted
class_name RoundModifierSelectionResolver

## Stage 33 v0.1: selects one round modifier at battle start, mirroring the
## deterministic seeded-RNG style of EnemySelectionResolver / BattleBackgroundSelectionResolver.

const ROUND_MODIFIER_CATALOG_SCRIPT := preload("res://scripts/game/config/round_modifier_catalog.gd")


func select_modifier(modifier_catalog, rng: RandomNumberGenerator = null):
	var valid_modifiers := _get_valid_modifiers(modifier_catalog)
	if valid_modifiers.is_empty():
		return _get_safe_fallback_modifier()

	if rng == null:
		return valid_modifiers[0]

	var selected_index := rng.randi_range(0, valid_modifiers.size() - 1)
	return valid_modifiers[selected_index]


func _get_valid_modifiers(modifier_catalog) -> Array:
	var valid_modifiers: Array = []
	var candidate_modifiers := _get_candidate_modifiers(modifier_catalog)

	var seen_ids := {}
	for modifier_config in candidate_modifiers:
		if not _is_valid_modifier(modifier_config):
			continue
		if seen_ids.has(modifier_config.modifier_id):
			continue
		seen_ids[modifier_config.modifier_id] = true
		valid_modifiers.append(modifier_config)

	return valid_modifiers


## Stage 34 v0.1: prefer the catalog's color-focused random pool (excludes
## all_x2) when available, falling back to get_all_modifiers() for callers
## that only implement the older interface (e.g. test fakes).
func _get_candidate_modifiers(modifier_catalog) -> Array:
	if modifier_catalog == null:
		return []
	if modifier_catalog.has_method("get_random_pool_modifiers"):
		return modifier_catalog.get_random_pool_modifiers()
	if modifier_catalog.has_method("get_all_modifiers"):
		return modifier_catalog.get_all_modifiers()
	return []


func _is_valid_modifier(modifier_config) -> bool:
	return ROUND_MODIFIER_CATALOG_SCRIPT.new().is_valid_modifier(modifier_config)


func _get_safe_fallback_modifier():
	return ROUND_MODIFIER_CATALOG_SCRIPT.new().get_default_modifier()
