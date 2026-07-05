extends RefCounted
class_name DirectMatchDamageResolver

## Stage 32 v0.1: 1 cleared crystal = 1 damage. Color multipliers are Stage 33 work.


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


## Accepts either a BoardResolveResult (uses total_cleared) or a TurnPresentationData-shaped
## object (uses matched_cells + special_cleared_cells) so callers can pass whichever data
## shape they already have.
func calculate_damage_from_turn_result(turn_result) -> int:
	if turn_result == null:
		return 0

	if "total_cleared" in turn_result:
		return int(turn_result.total_cleared)

	if "matched_cells" in turn_result:
		var cells: Array = []
		cells.append_array(turn_result.matched_cells)
		if "special_cleared_cells" in turn_result:
			cells.append_array(turn_result.special_cleared_cells)
		return calculate_damage(cells)

	return 0
