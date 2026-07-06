extends RefCounted
class_name HoleBlockPlacer

## Stage 53.1 v0.1: safely punches a symmetrical hole block (and its mirrored
## copies) into a board_mask under HoleGenerationRules. Prepares the API
## Stage 54 will drive with real random block placement; nothing calls this
## from active battle generation yet.

const BOARD_MASK_SYMMETRY_SCRIPT := preload("res://scripts/game/board/board_mask_symmetry.gd")


## Attempts to deactivate top_left..(top_left + size) and its symmetry
## mirrors in mask. Returns true and mutates mask in place only if every
## safety rule passes; otherwise returns false and leaves mask untouched.
func try_place_hole_block(mask: Array, top_left: Vector2i, block_width: int, block_height: int, rules: HoleGenerationRules) -> bool:
	if rules == null:
		return false

	var width := _mask_width(mask)
	var height := mask.size()

	if block_width < rules.min_block_width or block_width > rules.max_block_width:
		return false
	if block_height < rules.min_block_height or block_height > rules.max_block_height:
		return false

	if top_left.x < 0 or top_left.y < 0 or top_left.x + block_width > width or top_left.y + block_height > height:
		return false

	var mirrored_cells := BOARD_MASK_SYMMETRY_SCRIPT.get_mirrored_block_cells(top_left, block_width, block_height, width, height, rules.symmetry_mode)

	for cell in mirrored_cells:
		if cell.x < 0 or cell.y < 0 or cell.x >= width or cell.y >= height:
			return false

	if rules.keep_center_active:
		@warning_ignore("integer_division")
		var center := Vector2i(width / 2, height / 2)
		for cell in mirrored_cells:
			if cell == center:
				return false

	var current_active_count := _count_active(mask)
	var current_total_count := width * height
	var newly_holed_count := 0
	for cell in mirrored_cells:
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

	for cell in mirrored_cells:
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
