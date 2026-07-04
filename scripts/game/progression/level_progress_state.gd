extends RefCounted
class_name LevelProgressState

const SCRIPT_PATH := "res://scripts/game/progression/level_progress_state.gd"

var level_id := ""
var completed := false
var stars := 0
var best_moves_left := 0


func _init(progress_level_id: String = "", progress_completed: bool = false, progress_stars: int = 0, progress_best_moves_left: int = 0) -> void:
	level_id = progress_level_id
	stars = clampi(progress_stars, 0, 3)
	completed = progress_completed or stars > 0
	best_moves_left = max(0, progress_best_moves_left)


func to_dictionary() -> Dictionary:
	return {
		"level_id": level_id,
		"completed": completed,
		"stars": stars,
		"best_moves_left": best_moves_left,
	}


static func from_dictionary(data: Dictionary, fallback_level_id: String) -> LevelProgressState:
	var resolved_level_id := str(data.get("level_id", fallback_level_id))
	if resolved_level_id == "":
		resolved_level_id = fallback_level_id

	return load(SCRIPT_PATH).new(
		resolved_level_id,
		bool(data.get("completed", false)),
		int(data.get("stars", 0)),
		int(data.get("best_moves_left", 0))
	)
