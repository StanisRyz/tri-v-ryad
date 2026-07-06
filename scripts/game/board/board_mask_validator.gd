extends RefCounted
class_name BoardMaskValidator

## Stage 53.1 v0.1: validates a board_mask against HoleGenerationRules ahead
## of Stage 54 real procedural hole generation. Nothing in active battle
## generation calls this yet.

const BOARD_MASK_VALIDATION_RESULT_SCRIPT := preload("res://scripts/game/board/board_mask_validation_result.gd")


func validate(mask: Array, rules: HoleGenerationRules) -> BoardMaskValidationResult:
	var width := BoardModel.DEFAULT_WIDTH
	var height := BoardModel.DEFAULT_HEIGHT
	var reasons: Array[String] = []

	if not _is_valid_shape(mask, width, height):
		reasons.append("invalid_mask_shape")
		return BOARD_MASK_VALIDATION_RESULT_SCRIPT.new(false, reasons, 0, 0, 0, 0)

	var active_cell_count := _count_matching(mask, width, height, true)
	var hole_cell_count := width * height - active_cell_count

	if active_cell_count < rules.min_active_cells:
		reasons.append("active_cells_below_minimum")

	if hole_cell_count > rules.max_hole_cells:
		reasons.append("hole_cells_above_maximum")

	if rules.keep_center_active:
		@warning_ignore("integer_division")
		var center := Vector2i(width / 2, height / 2)
		if not bool(mask[center.y][center.x]):
			reasons.append("center_cell_inactive")

	var connected_component_count := _count_components(mask, width, height, true)
	if rules.require_connected_active_area and active_cell_count > 0 and connected_component_count > 1:
		reasons.append("active_area_not_connected")

	var enclosed_active_cells := _find_enclosed_active_cells(mask, width, height)
	if rules.reject_enclosed_active_pockets and not enclosed_active_cells.is_empty():
		reasons.append("enclosed_active_pocket_detected")

	if rules.reject_single_cell_holes and _has_single_cell_hole_noise(mask, width, height):
		reasons.append("single_cell_hole_detected")

	var valid := reasons.is_empty()
	return BOARD_MASK_VALIDATION_RESULT_SCRIPT.new(valid, reasons, active_cell_count, hole_cell_count, connected_component_count, enclosed_active_cells.size())


func _is_valid_shape(mask: Array, expected_width: int, expected_height: int) -> bool:
	if mask == null or mask.size() != expected_height:
		return false

	for row in mask:
		if not (row is Array) or (row as Array).size() != expected_width:
			return false

	return true


func _count_matching(mask: Array, width: int, height: int, active_target: bool) -> int:
	var count := 0
	for y in range(height):
		for x in range(width):
			if bool(mask[y][x]) == active_target:
				count += 1
	return count


## v0.1 connected-active-area check: 4-neighbor (up/down/left/right) flood
## fill only; diagonal-only adjacency does not count as connected.
func _count_components(mask: Array, width: int, height: int, active_target: bool) -> int:
	var visited := {}
	var component_count := 0

	for y in range(height):
		for x in range(width):
			var cell := Vector2i(x, y)
			if bool(mask[y][x]) != active_target or visited.has(cell):
				continue
			component_count += 1
			_flood_fill(mask, cell, visited, width, height, active_target)

	return component_count


## Flood fills active cells starting from every board-edge cell; any active
## cell never reached this way is enclosed by a hole contour and is rejected
## for v0.1 rather than auto-fixed.
func _find_enclosed_active_cells(mask: Array, width: int, height: int) -> Array[Vector2i]:
	var edge_reachable := {}

	for x in range(width):
		_flood_fill_from_edge(mask, Vector2i(x, 0), edge_reachable, width, height)
		_flood_fill_from_edge(mask, Vector2i(x, height - 1), edge_reachable, width, height)

	for y in range(height):
		_flood_fill_from_edge(mask, Vector2i(0, y), edge_reachable, width, height)
		_flood_fill_from_edge(mask, Vector2i(width - 1, y), edge_reachable, width, height)

	var enclosed: Array[Vector2i] = []
	for y in range(height):
		for x in range(width):
			var cell := Vector2i(x, y)
			if bool(mask[y][x]) and not edge_reachable.has(cell):
				enclosed.append(cell)

	return enclosed


func _flood_fill_from_edge(mask: Array, start_cell: Vector2i, visited: Dictionary, width: int, height: int) -> void:
	if not bool(mask[start_cell.y][start_cell.x]) or visited.has(start_cell):
		return

	_flood_fill(mask, start_cell, visited, width, height, true)


## A hole cell with no adjacent hole neighbor (i.e. a hole "component" of
## size 1) is single-cell noise and is rejected for v0.1.
func _has_single_cell_hole_noise(mask: Array, width: int, height: int) -> bool:
	var visited := {}
	for y in range(height):
		for x in range(width):
			var cell := Vector2i(x, y)
			if bool(mask[y][x]) or visited.has(cell):
				continue
			var visited_before := visited.size()
			_flood_fill(mask, cell, visited, width, height, false)
			if visited.size() - visited_before == 1:
				return true
	return false


func _flood_fill(mask: Array, start_cell: Vector2i, visited: Dictionary, width: int, height: int, active_target: bool) -> void:
	var stack: Array[Vector2i] = [start_cell]
	visited[start_cell] = true

	while not stack.is_empty():
		var cell: Vector2i = stack.pop_back()
		for offset: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var neighbor := cell + offset
			if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= width or neighbor.y >= height:
				continue
			if visited.has(neighbor) or bool(mask[neighbor.y][neighbor.x]) != active_target:
				continue
			visited[neighbor] = true
			stack.append(neighbor)
