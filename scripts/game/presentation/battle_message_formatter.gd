extends RefCounted
class_name BattleMessageFormatter

const LANE_NAMES := ["Left", "Center", "Right"]
const LANE_KEYS := ["battle.lane.left", "battle.lane.center", "battle.lane.right"]


static func format_hero_name(hero_id: String, debug_labels_enabled: bool = false, localization_manager = null) -> String:
	if hero_id == null or hero_id == "":
		return localization_manager.tr_key("battle.hero.default") if localization_manager != null else "Hero"

	var display_name := _hero_display_name(hero_id, localization_manager)
	if debug_labels_enabled:
		return "%s (%s)" % [display_name, hero_id]

	return display_name


static func format_lane_name(lane_index: int, localization_manager = null) -> String:
	if lane_index < 0 or lane_index >= LANE_NAMES.size():
		return localization_manager.tr_key("battle.lane.default") if localization_manager != null else "Lane"

	if localization_manager != null:
		return localization_manager.tr_key(LANE_KEYS[lane_index])
	return LANE_NAMES[lane_index]


static func format_damage_message(data, debug_labels_enabled: bool = false, localization_manager = null) -> String:
	if data == null:
		return _tr(localization_manager, "battle.damage.none", "No damage dealt")

	var total_damage: int = data.total_damage_to_enemy
	if total_damage <= 0:
		return _tr(localization_manager, "battle.damage.none", "No damage dealt")

	var events := _attacking_events(data.damage_events)
	if events.size() == 1:
		var event: Dictionary = events[0]
		var hero_name := format_hero_name(event.get("hero_id", ""), debug_labels_enabled, localization_manager)
		if localization_manager != null:
			return localization_manager.format_key("battle.damage.single", {"hero": hero_name, "damage": event.get("damage", 0)})
		return "%s dealt %d damage" % [hero_name, event.get("damage", 0)]

	if events.size() > 1:
		if localization_manager != null:
			return localization_manager.format_key("battle.damage.multi", {"count": events.size(), "damage": total_damage})
		return "%d heroes attacked for %d total damage" % [events.size(), total_damage]

	if localization_manager != null:
		return localization_manager.format_key("battle.damage.total", {"damage": total_damage})
	return "Heroes dealt %d total damage" % total_damage


static func format_direct_damage_message(data, _debug_labels_enabled: bool = false, localization_manager = null) -> String:
	if data == null:
		return _tr(localization_manager, "battle.damage.none", "No damage dealt")

	var total_damage: int = data.total_damage_to_enemy
	if total_damage <= 0:
		return _tr(localization_manager, "battle.damage.none", "No damage dealt")

	var tile_count: int = total_damage
	if "total_tiles_cleared" in data and data.total_tiles_cleared > 0:
		tile_count = data.total_tiles_cleared

	if not data.special_cleared_cells.is_empty():
		if localization_manager != null:
			return localization_manager.format_key("battle.direct_damage.special", {"count": tile_count, "damage": total_damage})
		return "Special cleared %d tiles: %d damage" % [tile_count, total_damage]

	var breakdown: Array = data.damage_breakdown if "damage_breakdown" in data else []
	if breakdown.size() == 1:
		var entry: Dictionary = breakdown[0]
		var multiplier: float = entry.get("multiplier", 1.0)
		var tile_type: int = entry.get("tile_type", -1)
		if multiplier > 1.0 and tile_type != -1:
			var color_name := _tile_color_name(tile_type, localization_manager)
			if localization_manager != null:
				return localization_manager.format_key("battle.direct_damage.match_multiplier", {
					"count": entry.get("tile_count", tile_count),
					"color": color_name,
					"multiplier": _format_multiplier(multiplier),
					"damage": total_damage,
				})
			return "Matched %d %s tiles x%s: %d damage" % [entry.get("tile_count", tile_count), color_name, _format_multiplier(multiplier), total_damage]

	if breakdown.size() > 1:
		if localization_manager != null:
			return localization_manager.format_key("battle.direct_damage.cleared", {"count": tile_count, "damage": total_damage})
		return "Cleared %d tiles: %d damage" % [tile_count, total_damage]

	if localization_manager != null:
		return localization_manager.format_key("battle.direct_damage.matched", {"count": tile_count, "damage": total_damage})
	return "Matched %d tiles: %d damage" % [tile_count, total_damage]


static func format_enemy_defeated_message(localization_manager = null) -> String:
	return _tr(localization_manager, "battle.enemy.defeated", "Enemy defeated!")


static func format_lane_activation_message(lane_activations: Dictionary, localization_manager = null) -> String:
	if lane_activations == null:
		return ""

	var active_lanes: Array[int] = []
	for lane_index in lane_activations.keys():
		if int(lane_activations[lane_index]) > 0:
			active_lanes.append(int(lane_index))

	if active_lanes.is_empty():
		return ""

	if active_lanes.size() == 1:
		var lane_name := format_lane_name(active_lanes[0], localization_manager)
		if localization_manager != null:
			return localization_manager.format_key("battle.lane_activation.single", {"lane": lane_name})
		return "%s lane activated" % lane_name

	if localization_manager != null:
		return localization_manager.format_key("battle.lane_activation.multi", {"count": active_lanes.size()})
	return "%d lanes activated" % active_lanes.size()


static func format_special_activation_message(data, _debug_labels_enabled: bool = false, localization_manager = null) -> String:
	if data == null or data.activated_special_tiles.is_empty():
		return ""

	var cleared_count: int = data.special_cleared_cells.size()

	if data.activated_special_tiles.size() > 1:
		if cleared_count > 0:
			if localization_manager != null:
				return localization_manager.format_key("battle.special.combo", {"count": cleared_count})
			return "Special combo cleared %d tiles" % cleared_count
		return _tr(localization_manager, "battle.special.activated_generic", "Specials activated")

	var special_type: int = data.activated_special_tiles[0].get("special_type", -1)
	var type_label := _special_type_label(special_type, localization_manager)

	if cleared_count > 0:
		if localization_manager != null:
			return localization_manager.format_key("battle.special.single_cleared", {"special": type_label, "count": cleared_count})
		return "%s cleared %d tiles" % [type_label, cleared_count]

	if localization_manager != null:
		return localization_manager.format_key("battle.special.single_activated", {"special": type_label})
	return "%s activated" % type_label


static func format_enemy_action_message(enemy_action: Dictionary, debug_labels_enabled: bool = false, localization_manager = null) -> String:
	if enemy_action == null or not enemy_action.get("acted", false):
		return _tr(localization_manager, "battle.enemy_action.preparing", "Enemy is preparing an attack")

	var target_id: String = enemy_action.get("target_hero_id", "")
	var damage: int = enemy_action.get("damage", 0)
	var hero_name := format_hero_name(target_id, debug_labels_enabled, localization_manager)
	if localization_manager != null:
		return localization_manager.format_key("battle.enemy_action.attacked", {"hero": hero_name, "damage": damage})
	return "Enemy attacked %s for %d damage" % [hero_name, damage]


static func format_invalid_swap_message(reason: String, localization_manager = null) -> String:
	match reason:
		"no_match":
			return _tr(localization_manager, "battle.invalid_swap.no_match", "Swap must create a match")
		"not_adjacent", "invalid_swap":
			return _tr(localization_manager, "battle.invalid_swap.not_neighbor", "Choose a neighboring tile")
		"iced_cell":
			return _tr(localization_manager, "battle.invalid_swap.frozen", "Frozen cells cannot be swapped.")
		_:
			return _tr(localization_manager, "battle.invalid_swap.generic", "That swap doesn't work")


static func format_invalid_input_message(reason: String, localization_manager = null) -> String:
	match reason:
		"swipe_too_short":
			return _tr(localization_manager, "battle.invalid_input.swipe_short", "Swipe a little farther")
		"outside_board":
			return _tr(localization_manager, "battle.invalid_input.out_of_bounds", "Stay inside the board")
		"input_locked":
			return _tr(localization_manager, "battle.invalid_input.turn_busy", "Wait until the turn finishes")
		_:
			return _tr(localization_manager, "battle.invalid_input.generic", "Invalid input")


static func format_ability_start_message(data, debug_labels_enabled: bool = false, localization_manager = null) -> String:
	if data == null:
		return _tr(localization_manager, "battle.ability.start_generic", "Ability activated")

	var display_name := _ability_display_name(data, debug_labels_enabled)
	if localization_manager != null:
		return localization_manager.format_key("battle.ability.start_named", {"hero": display_name})
	return "%s activated" % display_name


static func format_ability_damage_message(data, debug_labels_enabled: bool = false, localization_manager = null) -> String:
	if data == null or data.damage_to_enemy <= 0:
		return ""

	var display_name := _ability_display_name(data, debug_labels_enabled)
	if localization_manager != null:
		return localization_manager.format_key("battle.damage.single", {"hero": display_name, "damage": data.damage_to_enemy})
	return "%s dealt %d damage" % [display_name, data.damage_to_enemy]


static func format_ability_rejected_message(reason: String, localization_manager = null) -> String:
	match reason:
		"ability_not_ready":
			return _tr(localization_manager, "battle.ability.rejected_not_ready", "Ability is not ready yet")
		"hero_dead":
			return _tr(localization_manager, "battle.ability.rejected_hero_down", "This hero is down")
		"battle_finished":
			return _tr(localization_manager, "battle.ability.rejected_battle_over", "Battle is already over")
		_:
			return _tr(localization_manager, "battle.ability.rejected_generic", "Ability unavailable")


static func format_victory_message(_reward_points: int, stars: int, localization_manager = null) -> String:
	var clamped_stars := clampi(stars, 0, 3)
	if localization_manager != null:
		return localization_manager.format_key("battle.result.victory", {"stars": clamped_stars})
	return "Victory! Progress saved (%d/3 stars)" % clamped_stars


static func format_defeat_message(localization_manager = null) -> String:
	return _tr(localization_manager, "battle.result.defeat", "Defeat: use boosted colors, special tiles, and better matches")


static func _tr(localization_manager, key: String, fallback: String) -> String:
	if localization_manager != null:
		return localization_manager.tr_key(key)
	return fallback


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


static func _hero_display_name(hero_id: String, localization_manager = null) -> String:
	match hero_id:
		"hero_1", "hero_2", "hero_3", "hero_4", "hero_5":
			var hero_number := int(hero_id.substr(5))
			if localization_manager != null:
				return localization_manager.format_key("battle.hero.numbered", {"n": hero_number})
			return "Hero %d" % hero_number
		_:
			return hero_id.capitalize()


static func _tile_color_name(tile_type: int, localization_manager = null) -> String:
	var key := ""
	match tile_type:
		TileType.RED:
			key = "color.red"
		TileType.BLUE:
			key = "color.blue"
		TileType.GREEN:
			key = "color.green"
		TileType.YELLOW:
			key = "color.yellow"
		TileType.PURPLE:
			key = "color.purple"
		_:
			key = ""

	if localization_manager != null:
		return localization_manager.tr_key(key) if key != "" else localization_manager.tr_key("modifier.color_generic")

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


static func _special_type_label(special_type: int, localization_manager = null) -> String:
	match special_type:
		SpecialTileType.LINE_HORIZONTAL, SpecialTileType.LINE_VERTICAL:
			return _tr(localization_manager, "battle.special.line", "Line special")
		SpecialTileType.COLOR_BOMB:
			return _tr(localization_manager, "battle.special.bomb", "Color bomb")
		_:
			return _tr(localization_manager, "battle.special.generic", "Special tile")
