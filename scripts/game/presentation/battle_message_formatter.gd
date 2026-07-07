extends RefCounted
class_name BattleMessageFormatter

const LANE_NAMES := ["Left", "Center", "Right"]


static func format_hero_name(hero_id: String, debug_labels_enabled: bool = false) -> String:
	if hero_id == null or hero_id == "":
		return "Hero"

	var display_name := _hero_display_name(hero_id)
	if debug_labels_enabled:
		return "%s (%s)" % [display_name, hero_id]

	return display_name


static func format_lane_name(lane_index: int) -> String:
	if lane_index < 0 or lane_index >= LANE_NAMES.size():
		return "Lane"

	return LANE_NAMES[lane_index]


static func format_damage_message(data, debug_labels_enabled: bool = false) -> String:
	if data == null:
		return "No damage dealt"

	var total_damage: int = data.total_damage_to_enemy
	if total_damage <= 0:
		return "No damage dealt"

	var events := _attacking_events(data.damage_events)
	if events.size() == 1:
		var event: Dictionary = events[0]
		return "%s dealt %d damage" % [format_hero_name(event.get("hero_id", ""), debug_labels_enabled), event.get("damage", 0)]

	if events.size() > 1:
		return "%d heroes attacked for %d total damage" % [events.size(), total_damage]

	return "Heroes dealt %d total damage" % total_damage


static func format_direct_damage_message(data, _debug_labels_enabled: bool = false) -> String:
	if data == null:
		return "No damage dealt"

	var total_damage: int = data.total_damage_to_enemy
	if total_damage <= 0:
		return "No damage dealt"

	var tile_count: int = total_damage
	if "total_tiles_cleared" in data and data.total_tiles_cleared > 0:
		tile_count = data.total_tiles_cleared

	if not data.special_cleared_cells.is_empty():
		return "Special cleared %d tiles: %d damage" % [tile_count, total_damage]

	var breakdown: Array = data.damage_breakdown if "damage_breakdown" in data else []
	if breakdown.size() == 1:
		var entry: Dictionary = breakdown[0]
		var multiplier: float = entry.get("multiplier", 1.0)
		var tile_type: int = entry.get("tile_type", -1)
		if multiplier > 1.0 and tile_type != -1:
			var color_name := _tile_color_name(tile_type)
			return "Matched %d %s tiles x%s: %d damage" % [entry.get("tile_count", tile_count), color_name, _format_multiplier(multiplier), total_damage]

	if breakdown.size() > 1:
		return "Cleared %d tiles: %d damage" % [tile_count, total_damage]

	return "Matched %d tiles: %d damage" % [tile_count, total_damage]


static func format_enemy_defeated_message() -> String:
	return "Enemy defeated!"


static func format_lane_activation_message(lane_activations: Dictionary) -> String:
	if lane_activations == null:
		return ""

	var active_lanes: Array[int] = []
	for lane_index in lane_activations.keys():
		if int(lane_activations[lane_index]) > 0:
			active_lanes.append(int(lane_index))

	if active_lanes.is_empty():
		return ""

	if active_lanes.size() == 1:
		return "%s lane activated" % format_lane_name(active_lanes[0])

	return "%d lanes activated" % active_lanes.size()


static func format_special_activation_message(data, _debug_labels_enabled: bool = false) -> String:
	if data == null or data.activated_special_tiles.is_empty():
		return ""

	var cleared_count: int = data.special_cleared_cells.size()

	if data.activated_special_tiles.size() > 1:
		if cleared_count > 0:
			return "Special combo cleared %d tiles" % cleared_count
		return "Specials activated"

	var special_type: int = data.activated_special_tiles[0].get("special_type", -1)
	var type_label := _special_type_label(special_type)

	if cleared_count > 0:
		return "%s cleared %d tiles" % [type_label, cleared_count]

	return "%s activated" % type_label


static func format_enemy_action_message(enemy_action: Dictionary, debug_labels_enabled: bool = false) -> String:
	if enemy_action == null or not enemy_action.get("acted", false):
		return "Enemy is preparing an attack"

	var target_id: String = enemy_action.get("target_hero_id", "")
	var damage: int = enemy_action.get("damage", 0)
	return "Enemy attacked %s for %d damage" % [format_hero_name(target_id, debug_labels_enabled), damage]


static func format_invalid_swap_message(reason: String) -> String:
	match reason:
		"no_match":
			return "Swap must create a match"
		"not_adjacent", "invalid_swap":
			return "Choose a neighboring tile"
		"iced_cell":
			return "Frozen cells cannot be swapped."
		_:
			return "That swap doesn't work"


static func format_invalid_input_message(reason: String) -> String:
	match reason:
		"swipe_too_short":
			return "Swipe a little farther"
		"outside_board":
			return "Stay inside the board"
		"input_locked":
			return "Wait until the turn finishes"
		_:
			return "Invalid input"


static func format_ability_start_message(data, debug_labels_enabled: bool = false) -> String:
	if data == null:
		return "Ability activated"

	return "%s activated" % _ability_display_name(data, debug_labels_enabled)


static func format_ability_damage_message(data, debug_labels_enabled: bool = false) -> String:
	if data == null or data.damage_to_enemy <= 0:
		return ""

	return "%s dealt %d damage" % [_ability_display_name(data, debug_labels_enabled), data.damage_to_enemy]


static func format_ability_rejected_message(reason: String) -> String:
	match reason:
		"ability_not_ready":
			return "Ability is not ready yet"
		"hero_dead":
			return "This hero is down"
		"battle_finished":
			return "Battle is already over"
		_:
			return "Ability unavailable"


static func format_victory_message(_reward_points: int, stars: int) -> String:
	return "Victory! Progress saved (%d/3 stars)" % clampi(stars, 0, 3)


static func format_defeat_message() -> String:
	return "Defeat: use boosted colors, special tiles, and better matches"


static func _ability_display_name(data, debug_labels_enabled: bool) -> String:
	var display_name: String = data.display_name if data.display_name != "" else "Ability"
	if debug_labels_enabled and data.ability_id != "":
		return "%s (%s)" % [display_name, data.ability_id]

	return display_name


static func _attacking_events(events: Array[Dictionary]) -> Array[Dictionary]:
	var attacking: Array[Dictionary] = []
	for event in events:
		if event.get("damage", 0) > 0:
			attacking.append(event)

	return attacking


static func _hero_display_name(hero_id: String) -> String:
	match hero_id:
		"hero_1":
			return "Hero 1"
		"hero_2":
			return "Hero 2"
		"hero_3":
			return "Hero 3"
		"hero_4":
			return "Hero 4"
		"hero_5":
			return "Hero 5"
		_:
			return hero_id.capitalize()


static func _tile_color_name(tile_type: int) -> String:
	match tile_type:
		TileType.RED:
			return "red"
		TileType.BLUE:
			return "blue"
		TileType.GREEN:
			return "green"
		TileType.YELLOW:
			return "yellow"
		TileType.PURPLE:
			return "purple"
		_:
			return "colored"


static func _format_multiplier(multiplier: float) -> String:
	if multiplier == floor(multiplier):
		return str(int(multiplier))

	return str(multiplier)


static func _special_type_label(special_type: int) -> String:
	match special_type:
		SpecialTileType.LINE_HORIZONTAL, SpecialTileType.LINE_VERTICAL:
			return "Line special"
		SpecialTileType.COLOR_BOMB:
			return "Color bomb"
		_:
			return "Special tile"
