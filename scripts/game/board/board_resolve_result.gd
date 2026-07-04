extends RefCounted
class_name BoardResolveResult

var steps: Array[Dictionary] = []
var total_cleared := 0
var created_special_tiles: Array[Dictionary] = []
var activated_special_tiles: Array[Dictionary] = []
var special_cleared_cells: Array[Vector2i] = []


func add_step(matches: Array[MatchResult], cleared_cells: Array[Vector2i], gravity_result: Dictionary, step_created_special_tiles: Array[Dictionary] = [], step_activated_special_tiles: Array[Dictionary] = [], step_special_cleared_cells: Array[Vector2i] = []) -> void:
	var step := {
		"matches": matches.duplicate(),
		"cleared_cells": cleared_cells.duplicate(),
		"spawned_cells": gravity_result.get("spawned_cells", []).duplicate(),
		"created_special_tiles": step_created_special_tiles.duplicate(),
		"activated_special_tiles": step_activated_special_tiles.duplicate(),
		"special_cleared_cells": step_special_cleared_cells.duplicate(),
	}
	steps.append(step)
	total_cleared += cleared_cells.size()
	created_special_tiles.append_array(step_created_special_tiles)
	activated_special_tiles.append_array(step_activated_special_tiles)
	special_cleared_cells.append_array(step_special_cleared_cells)


func to_dictionary() -> Dictionary:
	return {
		"steps": steps,
		"total_cleared": total_cleared,
		"created_special_tiles": created_special_tiles.duplicate(),
		"activated_special_tiles": activated_special_tiles.duplicate(),
		"special_cleared_cells": special_cleared_cells.duplicate(),
	}
