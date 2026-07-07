extends RefCounted
class_name BoardShuffleResolver

## Stage 59 v0.1: the "no available move" safety net. shuffle() rearranges
## only the *tile payloads* (tile_type + special_data) sitting on active
## cells — it never touches board.set_cell_active()/the active mask and never
## touches the obstacle/ice layer (BoardModel._obstacle_types/_obstacle_layers
## are cell-anchored and completely independent of tile payload, so shuffling
## tile content via set_tile()/set_special_tile() automatically leaves ice
## fixed in place with no extra bookkeeping — see BoardModel Stage 56 notes).
## Inactive (hole) cells are never read from or written to.
##
## Retries a Fisher-Yates reshuffle of the collected payloads until the
## resulting board has at least one available move (AvailableMoveFinder) and,
## where practical, no immediate match (MatchFinder) — up to max_attempts.
## If every attempt fails, a bounded deterministic rotation fallback runs
## (never an unbounded loop); if even that can't find a fully clean result,
## the last attempted arrangement is left in place rather than leaving the
## board unshuffled, so the player is never stuck without at least an attempt
## at a move-bearing board.

const MATCH_FINDER_SCRIPT := preload("res://scripts/game/board/match_finder.gd")
const AVAILABLE_MOVE_FINDER_SCRIPT := preload("res://scripts/game/board/available_move_finder.gd")

const DEFAULT_MAX_ATTEMPTS := 40

var _match_finder := MATCH_FINDER_SCRIPT.new()
var _available_move_finder := AVAILABLE_MOVE_FINDER_SCRIPT.new()


## Mutates board in place. Returns a Dictionary describing what happened:
## {shuffled: bool, attempts_used: int, fallback_used: bool,
## has_available_move: bool, has_immediate_match: bool}.
func shuffle(board: BoardModel, rng: RandomNumberGenerator = null, max_attempts: int = DEFAULT_MAX_ATTEMPTS) -> Dictionary:
	if board == null:
		return _result(false, 0, false, false, false)

	var active_cells := board.get_active_cells()
	if active_cells.size() < 2:
		return _result(false, 0, false, _available_move_finder.has_available_move(board), _match_finder.has_matches(board))

	var payloads := _collect_payloads(board, active_cells)
	var working_rng := rng if rng != null else RandomNumberGenerator.new()
	if rng == null:
		working_rng.randomize()

	var attempts_used := 0
	var success := false
	var safe_max_attempts := maxi(max_attempts, 1)

	for attempt in range(safe_max_attempts):
		attempts_used = attempt + 1
		var shuffled_payloads := payloads.duplicate()
		_fisher_yates_shuffle(shuffled_payloads, working_rng)
		_apply_payloads(board, active_cells, shuffled_payloads)

		if _match_finder.has_matches(board):
			continue
		if not _available_move_finder.has_available_move(board):
			continue

		success = true
		break

	var fallback_used := false
	if not success:
		fallback_used = true
		_apply_fallback_pattern(board, active_cells, payloads)

	return _result(
		true,
		attempts_used,
		fallback_used,
		_available_move_finder.has_available_move(board),
		_match_finder.has_matches(board)
	)


func _collect_payloads(board: BoardModel, cells: Array[Vector2i]) -> Array:
	var payloads: Array = []
	for cell in cells:
		payloads.append({
			"tile_type": board.get_tile(cell),
			"special_data": board.get_special_tile(cell),
		})
	return payloads


func _apply_payloads(board: BoardModel, cells: Array[Vector2i], payloads: Array) -> void:
	for index in range(cells.size()):
		var cell: Vector2i = cells[index]
		var payload: Dictionary = payloads[index]
		board.set_tile(cell, int(payload.get("tile_type", BoardModel.EMPTY)))
		board.clear_special_tile(cell)
		board.set_special_tile(cell, payload.get("special_data"))


func _fisher_yates_shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temp = values[i]
		values[i] = values[j]
		values[j] = temp


## Bounded (at most cells.size() - 1 passes) deterministic rotation of the
## original payload list — never depends on RNG, so it always terminates and
## always leaves the board in some rearranged state even in the pathological
## case where no rotation happens to be fully clean.
func _apply_fallback_pattern(board: BoardModel, cells: Array[Vector2i], original_payloads: Array) -> bool:
	for shift in range(1, cells.size()):
		var rotated := _rotate(original_payloads, shift)
		_apply_payloads(board, cells, rotated)
		if not _match_finder.has_matches(board) and _available_move_finder.has_available_move(board):
			return true

	return false


func _rotate(values: Array, shift: int) -> Array:
	var rotated: Array = []
	var count := values.size()
	for index in range(count):
		rotated.append(values[(index + shift) % count])
	return rotated


func _result(shuffled: bool, attempts_used: int, fallback_used: bool, has_available_move: bool, has_immediate_match: bool) -> Dictionary:
	return {
		"shuffled": shuffled,
		"attempts_used": attempts_used,
		"fallback_used": fallback_used,
		"has_available_move": has_available_move,
		"has_immediate_match": has_immediate_match,
	}
