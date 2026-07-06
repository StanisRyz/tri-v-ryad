extends RefCounted
class_name HoleShapePlacer

## Stage 54.1 v0.1: safely applies an arbitrary list of hole cells (a "shape",
## as opposed to HoleBlockPlacer's rectangle-only blocks) to a board_mask
## under HoleGenerationRules. Used for center-aware presets whose cells are
## already symmetric around the board center by construction (mirrored by
## the caller via BoardMaskSymmetry), so no separate mirroring step happens
## here — this only validates and applies.


## Attempts to deactivate every cell in `cells` in mask. Returns true and
## mutates mask in place only if every safety rule passes (all cells
## in-bounds, center stays active when keep_center_active is set,
## min_active_cells/max_hole_cells stay respected, board never goes empty);
## otherwise returns false and leaves mask untouched.
func try_place_shape(mask: Array, cells: Array, rules: HoleGenerationRules) -> bool:
	if rules == null or cells.is_empty():
		return false

	var width := _mask_width(mask)
	var height := mask.size()

	var unique_cells: Array[Vector2i] = []
	var seen := {}
	for cell in cells:
		var typed_cell: Vector2i = cell
		if seen.has(typed_cell):
			continue
		seen[typed_cell] = true
		unique_cells.append(typed_cell)

	for cell in unique_cells:
		if cell.x < 0 or cell.y < 0 or cell.x >= width or cell.y >= height:
			return false

	if rules.keep_center_active:
		@warning_ignore("integer_division")
		var center := Vector2i(width / 2, height / 2)
		for cell in unique_cells:
			if cell == center:
				return false

	var current_active_count := _count_active(mask)
	var current_total_count := width * height
	var newly_holed_count := 0
	for cell in unique_cells:
		if mask[cell.y][cell.x]:
			newly_holed_count += 1

	var projected_active_count := current_active_count - newly_holed_count
	var projected_hole_count := (current_total_count - current_active_count) + newly_holed_count

	if projected_active_count <= 0:
		return false
	if projected_active_count < rules.min_active_cells:
		return false
	if projected_hole_count > rules.max_hole_cells:
		return false

	for cell in unique_cells:
		mask[cell.y][cell.x] = false

	return true


func _mask_width(mask: Array) -> int:
	if mask.is_empty() or not (mask[0] is Array):
		return 0

	return (mask[0] as Array).size()


func _count_active(mask: Array) -> int:
	var count := 0
	for row in mask:
		for value in row:
			if value:
				count += 1
	return count
