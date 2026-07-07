extends RefCounted
class_name PlayLevelResolver


## Resolves the level_id the "Играть" button should jump into: the highest
## unlocked level, validated against the catalog, falling back to level_1 if
## progress/catalog data is missing or corrupted. Stage 61 v0.1: no persisted
## "last played level" field exists yet, so this always recomputes from
## unlock state; a later patch can prefer a stored last-level value here.
func resolve_play_level_id(progress_manager, level_catalog) -> String:
	var fallback_level_id := "level_1"
	if level_catalog != null:
		fallback_level_id = level_catalog.get_default_level_id()

	if progress_manager == null or level_catalog == null:
		return fallback_level_id

	var resolved_level_id := fallback_level_id
	for level_config in level_catalog.get_all_levels():
		if progress_manager.is_level_unlocked(level_catalog, level_config.level_id):
			resolved_level_id = level_config.level_id

	if not level_catalog.has_level(resolved_level_id):
		return fallback_level_id

	return resolved_level_id
