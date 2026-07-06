extends RefCounted
class_name DamageParticleEventBuilder

const BOOSTER_CATALOG_SCRIPT := preload("res://scripts/game/config/booster_catalog.gd")


func build_from_turn_presentation(data) -> Array:
	if data == null or not data.is_valid:
		return []

	var total_damage: int = int(data.total_damage_to_enemy)
	if total_damage <= 0:
		return []

	var cells := _collect_turn_cells(data)
	if cells.is_empty():
		return [_make_event(Vector2i(-1, -1), -1, total_damage, 1.0, false, "turn")]

	var tile_type_map := _build_tile_type_map(data.initial_matches)
	var multiplier_map := _build_multiplier_map(data.damage_breakdown)
	var boosted_set := {}
	for cell in data.special_cleared_cells:
		boosted_set[cell] = true

	return _distribute_damage(cells, total_damage, tile_type_map, multiplier_map, boosted_set, "turn")


func build_from_booster_result(result) -> Array:
	if result == null or not result.is_valid:
		return []
	if result.booster_id == BOOSTER_CATALOG_SCRIPT.FREEZE_TIME:
		return []
	if int(result.damage_to_enemy) <= 0:
		return []
	if result.cleared_cells.is_empty():
		return []

	var tile_type_map: Dictionary = result.cleared_cell_tile_types if "cleared_cell_tile_types" in result else {}
	var boosted_set := {}
	for cell in result.cleared_cells:
		boosted_set[cell] = true

	return _distribute_damage(result.cleared_cells, int(result.damage_to_enemy), tile_type_map, {}, boosted_set, "booster:%s" % result.booster_id)


func _collect_turn_cells(data) -> Array:
	var seen := {}
	var cells: Array = []
	for cell in data.matched_cells:
		if seen.has(cell):
			continue
		seen[cell] = true
		cells.append(cell)
	for cell in data.special_cleared_cells:
		if seen.has(cell):
			continue
		seen[cell] = true
		cells.append(cell)
	return cells


func _build_tile_type_map(initial_matches: Array) -> Dictionary:
	var tile_type_map := {}
	for match_result in initial_matches:
		if match_result == null:
			continue
		for cell in match_result.cells:
			tile_type_map[cell] = match_result.tile_type
	return tile_type_map


func _build_multiplier_map(damage_breakdown: Array) -> Dictionary:
	var multiplier_map := {}
	for entry in damage_breakdown:
		if entry is Dictionary and entry.has("tile_type"):
			multiplier_map[entry["tile_type"]] = float(entry.get("multiplier", 1.0))
	return multiplier_map


func _distribute_damage(cells: Array, total_damage: int, tile_type_map: Dictionary, multiplier_map: Dictionary, boosted_set: Dictionary, source: String) -> Array:
	var events: Array = []
	var count: int = cells.size()
	if count <= 0 or total_damage <= 0:
		return events

	@warning_ignore("integer_division")
	var base: int = total_damage / count
	var remainder: int = total_damage % count

	for i in range(count):
		var damage: int = base + (1 if i < remainder else 0)
		if damage <= 0:
			continue
		var cell: Vector2i = cells[i]
		var tile_type: int = int(tile_type_map.get(cell, -1))
		var multiplier: float = float(multiplier_map.get(tile_type, 1.0))
		events.append(_make_event(cell, tile_type, damage, multiplier, bool(boosted_set.get(cell, false)), source))

	if events.is_empty():
		var take: int = maxi(mini(count, total_damage), 1)
		for i in range(take):
			var cell: Vector2i = cells[i]
			var tile_type: int = int(tile_type_map.get(cell, -1))
			var multiplier: float = float(multiplier_map.get(tile_type, 1.0))
			events.append(_make_event(cell, tile_type, 1, multiplier, bool(boosted_set.get(cell, false)), source))

	return events


func _make_event(cell: Vector2i, tile_type: int, damage: int, multiplier: float, is_boosted: bool, source: String) -> Dictionary:
	return {
		"cell": cell,
		"tile_type": tile_type,
		"damage": damage,
		"multiplier": multiplier,
		"is_boosted": is_boosted,
		"source": source,
	}
