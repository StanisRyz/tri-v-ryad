extends RefCounted
class_name BoardResolveStep

## One visual/logical board phase produced by StepwiseBoardResolver: a single
## clear + gravity/refill pass, used to drive animation and later be folded
## into a BoardResolveResult once the board is stable.

var cascade_index := 0
var matches: Array[MatchResult] = []
var matched_cells: Array[Vector2i] = []
var special_cleared_cells: Array[Vector2i] = []
## Each entry: {"cell": Vector2i, "special_type": int, "source_cells": Array[Vector2i], "tile_type": int}.
## source_cells is the full matched-cell list that created the special (including "cell" itself),
## used to animate the matched crystals gathering into the creation cell.
var created_special_tiles: Array[Dictionary] = []
var activated_special_tiles: Array[Dictionary] = []
var cleared_cells: Array[Vector2i] = []
var fall_movements: Array[Dictionary] = []
var refill_cells: Array[Dictionary] = []
var damage_tile_types: Dictionary = {}
var is_stable := false
var message := ""


static func stable_step(at_cascade_index: int) -> BoardResolveStep:
	var step := BoardResolveStep.new()
	step.cascade_index = at_cascade_index
	step.is_stable = true
	return step


func to_dictionary() -> Dictionary:
	return {
		"cascade_index": cascade_index,
		"matches": matches.duplicate(),
		"matched_cells": matched_cells.duplicate(),
		"special_cleared_cells": special_cleared_cells.duplicate(),
		"created_special_tiles": created_special_tiles.duplicate(true),
		"activated_special_tiles": activated_special_tiles.duplicate(true),
		"cleared_cells": cleared_cells.duplicate(),
		"fall_movements": fall_movements.duplicate(true),
		"refill_cells": refill_cells.duplicate(true),
		"damage_tile_types": damage_tile_types.duplicate(),
		"is_stable": is_stable,
		"message": message,
	}
