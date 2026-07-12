extends RefCounted
class_name BoardResolveResult

const ICE_DAMAGE_RESOLVER_SCRIPT := preload("res://scripts/game/board/ice_damage_resolver.gd")

var steps: Array[Dictionary] = []
var total_cleared := 0
## Stage 67.1 v0.1: sum of each step's damage_counted_cells.size() - the
## canonical un-modified (x1 per cell) damage total. Unlike total_cleared,
## this still counts a cell that became a special crystal and stayed on the
## board, so a plain match-4 (no boost active) correctly deals 4 damage
## instead of 3. DirectMatchDamageResolver's no-modifier fast path uses this.
var total_damage_counted := 0
var created_special_tiles: Array[Dictionary] = []
var activated_special_tiles: Array[Dictionary] = []
var special_cleared_cells: Array[Vector2i] = []
var fall_movements: Array[Dictionary] = []
var refill_cells: Array[Dictionary] = []
var cascade_steps: Array[Dictionary] = []
var ice_damaged_cells: Array[Vector2i] = []
var ice_broken_cells: Array[Vector2i] = []


## Stage 67.1 v0.1: step_matched_cells is the full original matched-cell set
## for this step (including any cell that became a special crystal and so
## stayed on the board rather than being cleared). damage_counted_cells -
## matched_cells unioned with special_cleared_cells, deduped - is the
## canonical per-step cell set DirectMatchDamageResolver sums damage over, so
## a match that creates a special still counts its full original size. When
## step_matched_cells is omitted, damage_counted_cells falls back to
## cleared_cells (pre-Stage-67.1 callers keep their previous behavior).
func add_step(matches: Array[MatchResult], cleared_cells: Array[Vector2i], gravity_result: Dictionary, step_created_special_tiles: Array[Dictionary] = [], step_activated_special_tiles: Array[Dictionary] = [], step_special_cleared_cells: Array[Vector2i] = [], step_ice_events: Array[Dictionary] = [], step_matched_cells: Array[Vector2i] = []) -> void:
	var cascade_index := steps.size()
	var step_fall_movements: Array[Dictionary] = _to_dictionary_array(gravity_result.get("fall_movements", []))
	var step_refill_cells: Array[Dictionary] = _to_dictionary_array(gravity_result.get("refill_cells", []))
	var effective_matched_cells := step_matched_cells if not step_matched_cells.is_empty() else cleared_cells
	var damage_counted_cells := _union_cells(effective_matched_cells, step_special_cleared_cells)
	var step := {
		"matches": matches.duplicate(),
		"cleared_cells": cleared_cells.duplicate(),
		"matched_cells": effective_matched_cells.duplicate(),
		"damage_counted_cells": damage_counted_cells,
		"spawned_cells": gravity_result.get("spawned_cells", []).duplicate(),
		"fall_movements": step_fall_movements.duplicate(true),
		"refill_cells": step_refill_cells.duplicate(true),
		"created_special_tiles": step_created_special_tiles.duplicate(),
		"activated_special_tiles": step_activated_special_tiles.duplicate(),
		"special_cleared_cells": step_special_cleared_cells.duplicate(),
		"ice_events": step_ice_events.duplicate(true),
		"cascade_index": cascade_index,
	}
	steps.append(step)
	total_cleared += cleared_cells.size()
	total_damage_counted += damage_counted_cells.size()
	created_special_tiles.append_array(step_created_special_tiles)
	activated_special_tiles.append_array(step_activated_special_tiles)
	special_cleared_cells.append_array(step_special_cleared_cells)
	fall_movements.append_array(step_fall_movements)
	refill_cells.append_array(step_refill_cells)
	ice_damaged_cells.append_array(ICE_DAMAGE_RESOLVER_SCRIPT.extract_damaged_cells(step_ice_events))
	ice_broken_cells.append_array(ICE_DAMAGE_RESOLVER_SCRIPT.extract_broken_cells(step_ice_events))
	cascade_steps.append({
		"cascade_index": cascade_index,
		"matched_cells": cleared_cells.duplicate(),
		"special_cleared_cells": step_special_cleared_cells.duplicate(),
		"fall_movements": step_fall_movements.duplicate(true),
		"refill_cells": step_refill_cells.duplicate(true),
		"ice_events": step_ice_events.duplicate(true),
		"damage": 0,
	})


func _union_cells(a: Array[Vector2i], b: Array[Vector2i]) -> Array[Vector2i]:
	var seen := {}
	var result: Array[Vector2i] = []
	for cell in a:
		if seen.has(cell):
			continue
		seen[cell] = true
		result.append(cell)
	for cell in b:
		if seen.has(cell):
			continue
		seen[cell] = true
		result.append(cell)
	return result


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
		"total_damage_counted": total_damage_counted,
		"created_special_tiles": created_special_tiles.duplicate(),
		"activated_special_tiles": activated_special_tiles.duplicate(),
		"special_cleared_cells": special_cleared_cells.duplicate(),
		"fall_movements": fall_movements.duplicate(),
		"refill_cells": refill_cells.duplicate(),
		"cascade_steps": cascade_steps.duplicate(),
		"ice_damaged_cells": ice_damaged_cells.duplicate(),
		"ice_broken_cells": ice_broken_cells.duplicate(),
	}


## Stage 67.1 v0.1: debug-only trace helper (not player-facing) summarizing
## the whole resolved cascade across all steps.
func get_debug_summary() -> Dictionary:
	return {
		"step_count": steps.size(),
		"matched_count": total_damage_counted,
		"removed_count": total_cleared,
		"created_special": created_special_tiles.size(),
		"queued_specials": activated_special_tiles.size(),
		"resolved_specials": activated_special_tiles.size(),
	}
