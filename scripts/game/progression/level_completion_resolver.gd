extends RefCounted
class_name LevelCompletionResolver


func calculate_stars(level_config, moves_left: int) -> int:
	if level_config == null:
		return 0

	var safe_moves_left: int = max(0, moves_left)
	var max_moves: int = max(1, int(level_config.moves))
	if safe_moves_left >= float(max_moves) * 0.5:
		return 3
	if safe_moves_left >= float(max_moves) * 0.25:
		return 2
	return 1


func apply_victory_result(progress, level_config, moves_left: int):
	if progress == null or level_config == null:
		return null

	var state = progress.ensure_level_progress(level_config.level_id)
	var earned_stars := calculate_stars(level_config, moves_left)
	state.completed = true
	state.stars = max(state.stars, earned_stars)
	state.best_moves_left = max(state.best_moves_left, max(0, moves_left))
	progress.set_level_progress(level_config.level_id, state)
	return state


func is_level_unlocked(progress, level_catalog, level_id: String) -> bool:
	if level_catalog == null or level_id == "":
		return false

	var levels: Array = level_catalog.get_all_levels()
	for index in range(levels.size()):
		var level_config = levels[index]
		if level_config.level_id != level_id:
			continue

		if index == 0:
			return true

		var previous_level = levels[index - 1]
		return progress != null and progress.is_level_completed(previous_level.level_id)

	return false
