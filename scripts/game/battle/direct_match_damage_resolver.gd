extends RefCounted
class_name DirectMatchDamageResolver

## Stage 32 v0.1: 1 cleared crystal = 1 damage when no round modifier is supplied.
## Stage 33 v0.1: an optional RoundModifierConfig multiplies damage per cleared tile
## color. Cells without known color data (e.g. special-tile activation clears with
## no owning match) always fall back to x1 damage.


func calculate_damage(cleared_cells: Array) -> int:
	return count_unique_cleared_cells(cleared_cells)


func count_unique_cleared_cells(cells: Array) -> int:
	var seen := {}
	var count := 0
	for cell in cells:
		if seen.has(cell):
			continue
		seen[cell] = true
		count += 1
	return count


## Accepts either a BoardResolveResult (uses total_cleared/steps) or a
## TurnPresentationData-shaped object (uses matched_cells + special_cleared_cells) so
## callers can pass whichever data shape they already have. Passing a round_modifier
## only changes the BoardResolveResult path; without one, behavior matches Stage 32.
func calculate_damage_from_turn_result(turn_result, round_modifier = null) -> int:
	if turn_result == null:
		return 0

	if "total_cleared" in turn_result:
		if round_modifier == null:
			return int(turn_result.total_cleared)
		return calculate_damage_for_board_result(turn_result, round_modifier)

	if "matched_cells" in turn_result:
		var cells: Array = []
		cells.append_array(turn_result.matched_cells)
		if "special_cleared_cells" in turn_result:
			cells.append_array(turn_result.special_cleared_cells)
		return calculate_damage(cells)

	return 0


## Computes color-aware damage for a flat array of MatchResult (the initial swap
## matches, before cascades). Returns total_damage, tile_count, and a per-color breakdown.
func calculate_damage_for_matches(matches: Array, round_modifier = null) -> Dictionary:
	var seen := {}
	var breakdown_by_type := {}
	var total_damage := 0.0
	var tile_count := 0

	for match_result in matches:
		if match_result == null:
			continue
		for cell in match_result.cells:
			if seen.has(cell):
				continue
			seen[cell] = true
			tile_count += 1

			var multiplier := _get_multiplier(round_modifier, match_result.tile_type)
			total_damage += multiplier

			if not breakdown_by_type.has(match_result.tile_type):
				breakdown_by_type[match_result.tile_type] = {
					"tile_type": match_result.tile_type,
					"tile_count": 0,
					"multiplier": multiplier,
					"damage": 0,
				}
			breakdown_by_type[match_result.tile_type].tile_count += 1
			breakdown_by_type[match_result.tile_type].damage += int(round(multiplier))

	return {
		"total_damage": int(round(total_damage)),
		"tile_count": tile_count,
		"breakdown": breakdown_by_type.values(),
	}


func calculate_damage_for_typed_cells(cells: Array[Vector2i], tile_types: Dictionary, round_modifier = null) -> Dictionary:
	var seen := {}
	var breakdown_by_type := {}
	var total_damage := 0.0
	var tile_count := 0

	for cell in cells:
		if seen.has(cell):
			continue
		seen[cell] = true
		tile_count += 1

		var tile_type: int = int(tile_types.get(cell, -1))
		var multiplier := _get_multiplier(round_modifier, tile_type) if TileType.is_valid_tile_type(tile_type) else 1.0
		total_damage += multiplier

		if not breakdown_by_type.has(tile_type):
			breakdown_by_type[tile_type] = {
				"tile_type": tile_type,
				"tile_count": 0,
				"multiplier": multiplier,
				"damage": 0,
			}
		breakdown_by_type[tile_type].tile_count += 1
		breakdown_by_type[tile_type].damage += int(round(multiplier))

	return {
		"total_damage": int(round(total_damage)),
		"tile_count": tile_count,
		"breakdown": breakdown_by_type.values(),
	}


## Computes color-aware damage across a resolved cascade (BoardResolveResult). Each
## step's matches carry known tile colors; any remaining cleared cell in that step
## without a matching color (special-tile activation clears) counts as x1 damage.
func calculate_damage_for_board_result(board_result, round_modifier = null) -> int:
	if board_result == null:
		return 0
	if round_modifier == null:
		return int(board_result.total_cleared)

	var seen := {}
	var total_damage := 0.0

	for step in board_result.steps:
		var match_tile_types := _match_tile_types_for_step(step)
		var cleared_cells: Array = step.get("cleared_cells", [])
		for cell in cleared_cells:
			if seen.has(cell):
				continue
			seen[cell] = true
			if match_tile_types.has(cell):
				total_damage += _get_multiplier(round_modifier, match_tile_types[cell])
			else:
				total_damage += 1.0

	return int(round(total_damage))


## Builds a per-color damage breakdown across either a flat matches array or a
## resolved cascade, for feedback messages. Cells without known color data are
## grouped under tile_type -1 at x1 damage.
func build_damage_breakdown(matches: Array, board_result = null, round_modifier = null) -> Array:
	if board_result != null:
		return _breakdown_for_board_result(board_result, round_modifier)

	return calculate_damage_for_matches(matches, round_modifier).get("breakdown", [])


func _breakdown_for_board_result(board_result, round_modifier) -> Array:
	var seen := {}
	var breakdown_by_type := {}
	var generic_count := 0
	var generic_damage := 0

	for step in board_result.steps:
		var match_tile_types := _match_tile_types_for_step(step)
		var cleared_cells: Array = step.get("cleared_cells", [])
		for cell in cleared_cells:
			if seen.has(cell):
				continue
			seen[cell] = true

			if match_tile_types.has(cell):
				var tile_type = match_tile_types[cell]
				var multiplier := _get_multiplier(round_modifier, tile_type)
				if not breakdown_by_type.has(tile_type):
					breakdown_by_type[tile_type] = {
						"tile_type": tile_type,
						"tile_count": 0,
						"multiplier": multiplier,
						"damage": 0,
					}
				breakdown_by_type[tile_type].tile_count += 1
				breakdown_by_type[tile_type].damage += int(round(multiplier))
			else:
				generic_count += 1
				generic_damage += 1

	var breakdown: Array = breakdown_by_type.values()
	if generic_count > 0:
		breakdown.append({"tile_type": -1, "tile_count": generic_count, "multiplier": 1.0, "damage": generic_damage})

	return breakdown


func _match_tile_types_for_step(step: Dictionary) -> Dictionary:
	var match_tile_types := {}
	var step_matches: Array = step.get("matches", [])
	for match_result in step_matches:
		for cell in match_result.cells:
			match_tile_types[cell] = match_result.tile_type
	return match_tile_types


func _get_multiplier(round_modifier, tile_type: int) -> float:
	if round_modifier == null:
		return 1.0

	return round_modifier.get_multiplier(tile_type)
