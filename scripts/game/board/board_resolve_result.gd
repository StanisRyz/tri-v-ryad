extends RefCounted
class_name BoardResolveResult

var steps: Array[Dictionary] = []
var total_cleared := 0


func add_step(matches: Array[MatchResult], cleared_cells: Array[Vector2i], gravity_result: Dictionary) -> void:
	var step := {
		"matches": matches.duplicate(),
		"cleared_cells": cleared_cells.duplicate(),
		"spawned_cells": gravity_result.get("spawned_cells", []).duplicate(),
	}
	steps.append(step)
	total_cleared += cleared_cells.size()


func to_dictionary() -> Dictionary:
	return {
		"steps": steps,
		"total_cleared": total_cleared,
	}
