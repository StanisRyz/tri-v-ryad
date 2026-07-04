extends RefCounted
class_name BoardResolver

const MAX_CASCADE_STEPS := 50

var _match_finder := MatchFinder.new()
var _gravity_resolver: GravityResolver


func _init(gravity_resolver: GravityResolver = null) -> void:
	_gravity_resolver = gravity_resolver if gravity_resolver != null else GravityResolver.new()


func resolve_board(board: BoardModel) -> BoardResolveResult:
	var result := BoardResolveResult.new()

	for step_index in range(MAX_CASCADE_STEPS):
		var matches := _match_finder.find_matches(board)
		if matches.is_empty():
			break

		var cleared_cells := _collect_unique_match_cells(matches)
		board.clear_cells(cleared_cells)
		var gravity_result := _gravity_resolver.apply_gravity_and_refill(board)
		result.add_step(matches, cleared_cells, gravity_result)

	if board.has_empty_cells():
		push_error("BoardResolver finished with empty cells.")

	if _match_finder.has_matches(board):
		push_error("BoardResolver reached cascade safety limit before board became stable.")

	return result


func _collect_unique_match_cells(matches: Array[MatchResult]) -> Array[Vector2i]:
	var seen := {}
	var cells: Array[Vector2i] = []

	for match_result in matches:
		for cell in match_result.cells:
			if seen.has(cell):
				continue
			seen[cell] = true
			cells.append(cell)

	return cells
