extends RefCounted
class_name DirectMatchDamageResolver

## Stage 32 v0.1: 1 cleared crystal = 1 damage when no round modifier/level
## boost is supplied.
## Stage 33 v0.1: an optional RoundModifierConfig multiplies damage per cleared tile
## color. Cells without known color data (e.g. special-tile activation clears with
## no owning match) always fall back to x1 damage.
## Stage 60.2 v0.1: an optional LevelBoostConfig (current_level_boost from
## BattlePresenter) takes priority over round_modifier and supports both
## color multipliers and match-size multipliers (match 4 / match 5+).
## round_modifier is kept only for legacy/manual callers (e.g. BoosterResolver
## callers that still pass one directly, and existing tests); the active
## direct-mode battle flow now threads level_boost instead.

const LEVEL_BOOST_RESOLVER_SCRIPT := preload("res://scripts/game/config/level_boost_resolver.gd")

var _level_boost_resolver = LEVEL_BOOST_RESOLVER_SCRIPT.new()


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
## or level_boost only changes the BoardResolveResult path; without either, behavior
## matches Stage 32.
func calculate_damage_from_turn_result(turn_result, round_modifier = null, level_boost = null) -> int:
	if turn_result == null:
		return 0

	if "total_cleared" in turn_result:
		if round_modifier == null and level_boost == null:
			return int(turn_result.total_cleared)
		return calculate_damage_for_board_result(turn_result, round_modifier, level_boost)

	if "matched_cells" in turn_result:
		var cells: Array = []
		cells.append_array(turn_result.matched_cells)
		if "special_cleared_cells" in turn_result:
			cells.append_array(turn_result.special_cleared_cells)
		return calculate_damage(cells)

	return 0


## Computes color/match-size-aware damage for a flat array of MatchResult (the
## initial swap matches, before cascades). Returns total_damage, tile_count, and
## a breakdown grouped by (tile_type, match_size).
func calculate_damage_for_matches(matches: Array, round_modifier = null, level_boost = null) -> Dictionary:
	var seen := {}
	var breakdown_by_key := {}
	var total_damage := 0.0
	var tile_count := 0

	for match_result in matches:
		if match_result == null:
			continue
		var match_size := match_result.length()
		for cell in match_result.cells:
			if seen.has(cell):
				continue
			seen[cell] = true
			tile_count += 1

			var multiplier := _get_multiplier(round_modifier, level_boost, match_result.tile_type, match_size)
			total_damage += multiplier
			_accumulate_breakdown(breakdown_by_key, match_result.tile_type, match_size, multiplier, round_modifier, level_boost)

	return {
		"total_damage": int(round(total_damage)),
		"tile_count": tile_count,
		"breakdown": breakdown_by_key.values(),
	}


func calculate_damage_for_typed_cells(cells: Array[Vector2i], tile_types: Dictionary, round_modifier = null, level_boost = null) -> Dictionary:
	var seen := {}
	var breakdown_by_key := {}
	var total_damage := 0.0
	var tile_count := 0

	for cell in cells:
		if seen.has(cell):
			continue
		seen[cell] = true
		tile_count += 1

		var tile_type: int = int(tile_types.get(cell, -1))
		var match_size := 1
		var multiplier := _get_multiplier(round_modifier, level_boost, tile_type, match_size) if TileType.is_valid_tile_type(tile_type) else 1.0
		total_damage += multiplier
		_accumulate_breakdown(breakdown_by_key, tile_type, match_size, multiplier, round_modifier, level_boost)

	return {
		"total_damage": int(round(total_damage)),
		"tile_count": tile_count,
		"breakdown": breakdown_by_key.values(),
	}


## Computes color/match-size-aware damage across a resolved cascade
## (BoardResolveResult). Each step's matches carry known tile colors and match
## sizes; any remaining cleared cell in that step without a matching color
## (special-tile activation clears) counts as x1 damage.
func calculate_damage_for_board_result(board_result, round_modifier = null, level_boost = null) -> int:
	if board_result == null:
		return 0
	if round_modifier == null and level_boost == null:
		return int(board_result.total_cleared)

	var seen := {}
	var total_damage := 0.0

	for step in board_result.steps:
		var match_context := _match_context_for_step(step)
		var cleared_cells: Array = step.get("cleared_cells", [])
		for cell in cleared_cells:
			if seen.has(cell):
				continue
			seen[cell] = true
			if match_context.has(cell):
				var context: Dictionary = match_context[cell]
				total_damage += _get_multiplier(round_modifier, level_boost, context.tile_type, context.match_size)
			else:
				total_damage += 1.0

	return int(round(total_damage))


## Builds a per-(tile_type, match_size) damage breakdown across either a flat
## matches array or a resolved cascade, for feedback/debug messages. Cells
## without known color data are grouped under tile_type -1 at x1 damage.
func build_damage_breakdown(matches: Array, board_result = null, round_modifier = null, level_boost = null) -> Array:
	if board_result != null:
		return _breakdown_for_board_result(board_result, round_modifier, level_boost)

	return calculate_damage_for_matches(matches, round_modifier, level_boost).get("breakdown", [])


func _breakdown_for_board_result(board_result, round_modifier, level_boost) -> Array:
	var seen := {}
	var breakdown_by_key := {}
	var generic_count := 0
	var generic_damage := 0

	for step in board_result.steps:
		var match_context := _match_context_for_step(step)
		var cleared_cells: Array = step.get("cleared_cells", [])
		for cell in cleared_cells:
			if seen.has(cell):
				continue
			seen[cell] = true

			if match_context.has(cell):
				var context: Dictionary = match_context[cell]
				var tile_type: int = context.tile_type
				var match_size: int = context.match_size
				var multiplier := _get_multiplier(round_modifier, level_boost, tile_type, match_size)
				_accumulate_breakdown(breakdown_by_key, tile_type, match_size, multiplier, round_modifier, level_boost)
			else:
				generic_count += 1
				generic_damage += 1

	var breakdown: Array = breakdown_by_key.values()
	if generic_count > 0:
		breakdown.append({
			"tile_type": -1,
			"match_size": 1,
			"tile_count": generic_count,
			"multiplier": 1.0,
			"damage": generic_damage,
			"boost_id": "",
			"boost_type": -1,
		})

	return breakdown


func _match_context_for_step(step: Dictionary) -> Dictionary:
	var context := {}
	var step_matches: Array = step.get("matches", [])
	for match_result in step_matches:
		var match_size := match_result.length()
		for cell in match_result.cells:
			context[cell] = {"tile_type": match_result.tile_type, "match_size": match_size}
	return context


func _accumulate_breakdown(breakdown_by_key: Dictionary, tile_type: int, match_size: int, multiplier: float, round_modifier, level_boost) -> void:
	var key := "%d_%d" % [tile_type, match_size]
	if not breakdown_by_key.has(key):
		breakdown_by_key[key] = _new_breakdown_entry(tile_type, match_size, multiplier, round_modifier, level_boost)
	breakdown_by_key[key].tile_count += 1
	breakdown_by_key[key].damage += int(round(multiplier))


func _new_breakdown_entry(tile_type: int, match_size: int, multiplier: float, round_modifier, level_boost) -> Dictionary:
	var boost_id := ""
	var boost_type := -1
	if level_boost != null and not level_boost.is_none():
		boost_id = level_boost.boost_id
		boost_type = level_boost.boost_type
	elif round_modifier != null:
		boost_id = round_modifier.modifier_id

	return {
		"tile_type": tile_type,
		"match_size": match_size,
		"tile_count": 0,
		"multiplier": multiplier,
		"damage": 0,
		"boost_id": boost_id,
		"boost_type": boost_type,
	}


func _get_multiplier(round_modifier, level_boost, tile_type: int, match_size: int = 1) -> float:
	if level_boost != null and not level_boost.is_none():
		return _level_boost_resolver.get_damage_multiplier_for_tile(tile_type, match_size, level_boost)

	if round_modifier != null:
		return round_modifier.get_multiplier(tile_type)

	return 1.0
