extends RefCounted
class_name SwapResult

var accepted := false
var from_cell := Vector2i.ZERO
var to_cell := Vector2i.ZERO
var matches: Array[MatchResult] = []
var reason := ""


func _init(is_accepted: bool = false, source_cell: Vector2i = Vector2i.ZERO, target_cell: Vector2i = Vector2i.ZERO, found_matches: Array[MatchResult] = [], reject_reason: String = "") -> void:
	accepted = is_accepted
	from_cell = source_cell
	to_cell = target_cell
	matches = found_matches.duplicate()
	reason = reject_reason
