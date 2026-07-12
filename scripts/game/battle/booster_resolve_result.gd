extends RefCounted
class_name BoosterResolveResult

const ICE_DAMAGE_RESOLVER_SCRIPT := preload("res://scripts/game/board/ice_damage_resolver.gd")

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
var ice_events: Array[Dictionary] = []
## Stage 67.1 v0.1: populated when a booster's clear area hits a pre-existing
## special crystal, which now activates through the same
## SpecialTileResolver.resolve_special_activation_chain() queue used by match
## resolution (see booster_resolver.gd). activated_special_tiles mirrors
## BoardResolveStep's shape ({"cell","special_type","affected_cells",
## "base_tile_type"}); special_cleared_cells is the cell set those
## activations swept up beyond the booster's own target area.
var activated_special_tiles: Array[Dictionary] = []
var special_cleared_cells: Array[Vector2i] = []


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
		"ice_events": ice_events.duplicate(true),
		"ice_damaged_cells": ICE_DAMAGE_RESOLVER_SCRIPT.extract_damaged_cells(ice_events),
		"ice_broken_cells": ICE_DAMAGE_RESOLVER_SCRIPT.extract_broken_cells(ice_events),
		"activated_special_tiles": activated_special_tiles.duplicate(true),
		"special_cleared_cells": special_cleared_cells.duplicate(),
	}
