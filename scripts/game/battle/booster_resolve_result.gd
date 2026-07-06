extends RefCounted
class_name BoosterResolveResult

var is_valid := false
var booster_id := ""
var target_cell := Vector2i(-1, -1)
var cleared_cells: Array[Vector2i] = []
var damage_to_enemy := 0
var affected_tile_types: Array[int] = []
var cleared_cell_tile_types: Dictionary = {}
var freeze_turns_added := 0
var message := ""
var fall_movements: Array[Dictionary] = []
var refill_cells: Array[Dictionary] = []
var cascade_steps: Array[Dictionary] = []


func to_dictionary() -> Dictionary:
	return {
		"is_valid": is_valid,
		"booster_id": booster_id,
		"target_cell": target_cell,
		"cleared_cells": cleared_cells.duplicate(),
		"damage_to_enemy": damage_to_enemy,
		"affected_tile_types": affected_tile_types.duplicate(),
		"cleared_cell_tile_types": cleared_cell_tile_types.duplicate(),
		"freeze_turns_added": freeze_turns_added,
		"message": message,
		"fall_movements": fall_movements.duplicate(),
		"refill_cells": refill_cells.duplicate(),
		"cascade_steps": cascade_steps.duplicate(),
	}
