extends RefCounted
class_name HeroLaneResolver

const LANE_WIDTH := 3
const LANE_COUNT := 3


func resolve_matches(matches: Array[MatchResult]) -> Dictionary:
	var activations := {
		0: 0,
		1: 0,
		2: 0,
	}
	var counted_cells := {}

	for match_result in matches:
		for cell in match_result.cells:
			if counted_cells.has(cell):
				continue

			var lane_index := _get_lane_index_for_cell(cell)
			if lane_index == -1:
				continue

			counted_cells[cell] = true
			activations[lane_index] += 1

	return activations


func _get_lane_index_for_cell(cell: Vector2i) -> int:
	if cell.x < 0 or cell.x >= LANE_WIDTH * LANE_COUNT:
		return -1

	return cell.x / LANE_WIDTH
