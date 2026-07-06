extends RefCounted
class_name BoosterResolveResult

var is_valid := false
var booster_id := ""
var cleared_cells: Array[Vector2i] = []
var damage_to_enemy := 0
var affected_tile_types: Array[int] = []
var freeze_turns_added := 0
var message := ""


func to_dictionary() -> Dictionary:
	return {
		"is_valid": is_valid,
		"booster_id": booster_id,
		"cleared_cells": cleared_cells.duplicate(),
		"damage_to_enemy": damage_to_enemy,
		"affected_tile_types": affected_tile_types.duplicate(),
		"freeze_turns_added": freeze_turns_added,
		"message": message,
	}
