extends RefCounted
class_name BoardResolveResult

var steps: Array[Dictionary] = []
var total_cleared := 0
var created_special_tiles: Array[Dictionary] = []
var activated_special_tiles: Array[Dictionary] = []
var special_cleared_cells: Array[Vector2i] = []
var fall_movements: Array[Dictionary] = []
var refill_cells: Array[Dictionary] = []
var cascade_steps: Array[Dictionary] = []


func add_step(matches: Array[MatchResult], cleared_cells: Array[Vector2i], gravity_result: Dictionary, step_created_special_tiles: Array[Dictionary] = [], step_activated_special_tiles: Array[Dictionary] = [], step_special_cleared_cells: Array[Vector2i] = []) -> void:
	var cascade_index := steps.size()
	var step_fall_movements: Array[Dictionary] = _to_dictionary_array(gravity_result.get("fall_movements", []))
	var step_refill_cells: Array[Dictionary] = _to_dictionary_array(gravity_result.get("refill_cells", []))
	var step := {
		"matches": matches.duplicate(),
		"cleared_cells": cleared_cells.duplicate(),
		"spawned_cells": gravity_result.get("spawned_cells", []).duplicate(),
		"fall_movements": step_fall_movements.duplicate(true),
		"refill_cells": step_refill_cells.duplicate(true),
		"created_special_tiles": step_created_special_tiles.duplicate(),
		"activated_special_tiles": step_activated_special_tiles.duplicate(),
		"special_cleared_cells": step_special_cleared_cells.duplicate(),
		"cascade_index": cascade_index,
	}
	steps.append(step)
	total_cleared += cleared_cells.size()
	created_special_tiles.append_array(step_created_special_tiles)
	activated_special_tiles.append_array(step_activated_special_tiles)
	special_cleared_cells.append_array(step_special_cleared_cells)
	fall_movements.append_array(step_fall_movements)
	refill_cells.append_array(step_refill_cells)
	cascade_steps.append({
		"cascade_index": cascade_index,
		"matched_cells": cleared_cells.duplicate(),
		"special_cleared_cells": step_special_cleared_cells.duplicate(),
		"fall_movements": step_fall_movements.duplicate(true),
		"refill_cells": step_refill_cells.duplicate(true),
		"damage": 0,
	})


func _to_dictionary_array(values: Array) -> Array[Dictionary]:
	var typed_values: Array[Dictionary] = []
	for value in values:
		typed_values.append(value as Dictionary)
	return typed_values


func get_step(index: int) -> Dictionary:
	if index < 0 or index >= steps.size():
		return {}
	return steps[index]


func to_dictionary() -> Dictionary:
	return {
		"steps": steps,
		"total_cleared": total_cleared,
		"created_special_tiles": created_special_tiles.duplicate(),
		"activated_special_tiles": activated_special_tiles.duplicate(),
		"special_cleared_cells": special_cleared_cells.duplicate(),
		"fall_movements": fall_movements.duplicate(),
		"refill_cells": refill_cells.duplicate(),
		"cascade_steps": cascade_steps.duplicate(),
	}
