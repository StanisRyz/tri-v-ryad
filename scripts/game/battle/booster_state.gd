extends RefCounted
class_name BoosterState

var uses_left: Dictionary = {}
var active_booster_id := ""
var freeze_turns_left := 0


func setup_from_catalog(catalog) -> void:
	uses_left.clear()
	active_booster_id = ""
	freeze_turns_left = 0
	if catalog == null:
		return

	for booster in catalog.get_all_boosters():
		if booster == null:
			continue
		uses_left[booster.booster_id] = max(booster.uses_per_battle, 0)


func get_uses_left(booster_id: String) -> int:
	return int(uses_left.get(booster_id, 0))


func can_use(booster_id: String) -> bool:
	return get_uses_left(booster_id) > 0


func consume_use(booster_id: String) -> bool:
	if not can_use(booster_id):
		return false

	uses_left[booster_id] = get_uses_left(booster_id) - 1
	if active_booster_id == booster_id and get_uses_left(booster_id) <= 0:
		clear_active_booster()
	return true


func set_active_booster(booster_id: String) -> void:
	if can_use(booster_id):
		active_booster_id = booster_id


func clear_active_booster() -> void:
	active_booster_id = ""


func get_active_booster_id() -> String:
	return active_booster_id


func add_freeze_turns(count: int) -> void:
	freeze_turns_left += max(count, 0)


func has_freeze_turns() -> bool:
	return freeze_turns_left > 0


func consume_freeze_turn() -> bool:
	if not has_freeze_turns():
		return false

	freeze_turns_left -= 1
	return true
