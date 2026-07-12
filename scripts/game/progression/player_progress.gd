extends RefCounted
class_name PlayerProgress

const SAVE_VERSION := 1
const SCRIPT_PATH := "res://scripts/game/progression/player_progress.gd"
const HERO_UPGRADE_STATE_SCRIPT := preload("res://scripts/game/progression/hero_upgrade_state.gd")
const LEVEL_PROGRESS_STATE_SCRIPT := preload("res://scripts/game/progression/level_progress_state.gd")
const TEAM_SELECTION_STATE_SCRIPT := preload("res://scripts/game/progression/team_selection_state.gd")
const BOOSTER_CATALOG_SCRIPT := preload("res://scripts/game/config/booster_catalog.gd")
const CURRENCY_TYPE_SCRIPT := preload("res://scripts/game/economy/currency_type.gd")
const DEFAULT_HERO_IDS := ["hero_1", "hero_2", "hero_3"]

var save_version := SAVE_VERSION
var upgrade_points := 0
var hero_upgrades: Dictionary = {}
var completed_levels: Dictionary = {}
var level_progress: Dictionary = {}
var team_selection: TeamSelectionState
var gold := 0
var gems := 0
var booster_inventory: Dictionary = {}
var processed_purchase_tokens: Dictionary = {}
var pending_consume_tokens: Dictionary = {}

## Stage 69.3: caps how many processed Yandex purchase tokens are kept, so
## save data can't grow unbounded over a long play history. Oldest tokens
## (Dictionary preserves insertion order) are dropped first once the cap is
## exceeded — a dropped token would only re-grant if that same purchase were
## somehow re-delivered by the SDK long after being consumed, which is not a
## realistic scenario.
const MAX_PROCESSED_PURCHASE_TOKENS := 500


static func create_default() -> PlayerProgress:
	var progress = load(SCRIPT_PATH).new()
	progress.save_version = SAVE_VERSION
	progress.upgrade_points = 0
	progress.team_selection = TEAM_SELECTION_STATE_SCRIPT.create_default(DEFAULT_HERO_IDS)
	for hero_id in DEFAULT_HERO_IDS:
		progress.ensure_hero(hero_id)
	progress.gold = 0
	progress.gems = 0
	progress.booster_inventory = {}
	progress.ensure_booster_inventory()
	return progress


func get_hero_upgrade(hero_id: String) -> HeroUpgradeState:
	return ensure_hero(hero_id)


func ensure_hero(hero_id: String) -> HeroUpgradeState:
	if not hero_upgrades.has(hero_id) or hero_upgrades[hero_id] == null:
		hero_upgrades[hero_id] = HERO_UPGRADE_STATE_SCRIPT.new(hero_id)
	return hero_upgrades[hero_id]


func add_upgrade_points(amount: int) -> void:
	upgrade_points = max(0, upgrade_points + max(0, amount))


func mark_level_completed(level_id: String) -> void:
	if level_id == "":
		return
	completed_levels[level_id] = true
	var state = ensure_level_progress(level_id)
	state.completed = true
	state.stars = max(state.stars, 1)
	set_level_progress(level_id, state)


func is_level_completed(level_id: String) -> bool:
	if level_progress.has(level_id):
		var state = level_progress[level_id]
		return state != null and bool(state.completed)
	return bool(completed_levels.get(level_id, false))


func get_level_progress(level_id: String):
	return ensure_level_progress(level_id)


func ensure_level_progress(level_id: String):
	if not level_progress.has(level_id) or level_progress[level_id] == null:
		level_progress[level_id] = LEVEL_PROGRESS_STATE_SCRIPT.new(level_id)
	return level_progress[level_id]


func set_level_progress(level_id: String, state) -> void:
	if level_id == "" or state == null:
		return
	level_progress[level_id] = state
	completed_levels[level_id] = bool(state.completed)


func get_team_selection() -> TeamSelectionState:
	if team_selection == null:
		team_selection = TEAM_SELECTION_STATE_SCRIPT.create_default(DEFAULT_HERO_IDS)
	return team_selection


func set_team_selection(team_state: TeamSelectionState) -> void:
	if team_state == null:
		return
	team_selection = team_state


func get_selected_team_ids() -> Array[String]:
	return get_team_selection().selected_hero_ids.duplicate()


func get_level_stars(level_id: String) -> int:
	if level_progress.has(level_id):
		var state = level_progress[level_id]
		if state != null:
			return int(state.stars)
	return 1 if bool(completed_levels.get(level_id, false)) else 0


func get_currency(currency_id: String) -> int:
	match currency_id:
		CURRENCY_TYPE_SCRIPT.GOLD:
			return gold
		CURRENCY_TYPE_SCRIPT.GEMS:
			return gems
		_:
			return 0


func add_currency(currency_id: String, amount: int) -> void:
	if amount <= 0 or not CURRENCY_TYPE_SCRIPT.is_valid(currency_id):
		return
	match currency_id:
		CURRENCY_TYPE_SCRIPT.GOLD:
			gold = max(0, gold + amount)
		CURRENCY_TYPE_SCRIPT.GEMS:
			gems = max(0, gems + amount)


func can_spend_currency(currency_id: String, amount: int) -> bool:
	if amount <= 0 or not CURRENCY_TYPE_SCRIPT.is_valid(currency_id):
		return false
	return get_currency(currency_id) >= amount


func spend_currency(currency_id: String, amount: int) -> bool:
	if not can_spend_currency(currency_id, amount):
		return false
	match currency_id:
		CURRENCY_TYPE_SCRIPT.GOLD:
			gold = max(0, gold - amount)
		CURRENCY_TYPE_SCRIPT.GEMS:
			gems = max(0, gems - amount)
	return true


func get_default_booster_ids() -> Array[String]:
	return BOOSTER_CATALOG_SCRIPT.new().get_default_booster_ids()


func ensure_booster_inventory() -> void:
	for booster_id in get_default_booster_ids():
		if not booster_inventory.has(booster_id):
			booster_inventory[booster_id] = 0


func get_booster_count(booster_id: String) -> int:
	return int(max(0, int(booster_inventory.get(booster_id, 0))))


func add_booster(booster_id: String, amount: int) -> void:
	if amount <= 0 or booster_id == "":
		return
	booster_inventory[booster_id] = get_booster_count(booster_id) + amount


func has_booster(booster_id: String, amount: int = 1) -> bool:
	if amount <= 0:
		return false
	return get_booster_count(booster_id) >= amount


func spend_booster(booster_id: String, amount: int = 1) -> bool:
	if not has_booster(booster_id, amount):
		return false
	booster_inventory[booster_id] = get_booster_count(booster_id) - amount
	return true


func has_processed_purchase_token(token: String) -> bool:
	if token == "":
		return false
	return bool(processed_purchase_tokens.get(token, false))


func mark_processed_purchase_token(token: String) -> void:
	if token == "" or has_processed_purchase_token(token):
		return
	processed_purchase_tokens[token] = true
	while processed_purchase_tokens.size() > MAX_PROCESSED_PURCHASE_TOKENS:
		processed_purchase_tokens.erase(processed_purchase_tokens.keys()[0])


## Stage 69.3.1: tokens whose reward has already been granted/saved but whose
## Platform.consume_purchase() has not yet succeeded. Never capped/trimmed —
## unlike processed_purchase_tokens, losing one of these would leave a real
## purchase permanently unconfirmed with the Yandex SDK.
func has_pending_consume_token(token: String) -> bool:
	if token == "":
		return false
	return pending_consume_tokens.has(token)


func add_pending_consume_token(token: String, product_id: String, item_id: String) -> void:
	if token == "":
		return
	pending_consume_tokens[token] = {"product_id": product_id, "item_id": item_id}


func remove_pending_consume_token(token: String) -> void:
	if token == "":
		return
	pending_consume_tokens.erase(token)


func get_pending_consume_tokens() -> Dictionary:
	return pending_consume_tokens.duplicate(true)


## Stage 69.3.1: an isolated, fully independent copy for atomic transactions
## (see ProgressManager.apply_platform_purchase_atomic()) — mutating the
## copy and only replacing the live progress after a successful save can
## never leave a partially-applied purchase behind. Routed through
## to_dictionary()/from_dictionary() (rather than a manual field-by-field
## copy) so every nested Dictionary/Array/state object is freshly
## reconstructed, not shared by reference with the original.
func duplicate_progress() -> PlayerProgress:
	return load(SCRIPT_PATH).from_dictionary(to_dictionary())


func get_economy_debug_summary() -> String:
	var parts: Array[String] = []
	parts.append("gold=%d" % gold)
	parts.append("gems=%d" % gems)
	for booster_id in get_default_booster_ids():
		parts.append("%s=%d" % [booster_id, get_booster_count(booster_id)])
	return ", ".join(parts)


func to_dictionary() -> Dictionary:
	var upgrade_data := {}
	for hero_id in hero_upgrades.keys():
		var upgrade = hero_upgrades[hero_id]
		if upgrade != null and upgrade.has_method("to_dictionary"):
			upgrade_data[hero_id] = upgrade.to_dictionary()

	var level_progress_data := {}
	for level_id in level_progress.keys():
		var state = level_progress[level_id]
		if state != null and state.has_method("to_dictionary"):
			level_progress_data[level_id] = state.to_dictionary()

	ensure_booster_inventory()

	return {
		"save_version": save_version,
		"upgrade_points": upgrade_points,
		"hero_upgrades": upgrade_data,
		"completed_levels": completed_levels.duplicate(),
		"level_progress": level_progress_data,
		"team_selection": get_team_selection().to_dictionary(),
		"currencies": {
			"gold": gold,
			"gems": gems,
		},
		"booster_inventory": booster_inventory.duplicate(),
		"processed_purchase_tokens": processed_purchase_tokens.keys(),
		"pending_consume_tokens": pending_consume_tokens.duplicate(true),
	}


static func from_dictionary(data: Dictionary) -> PlayerProgress:
	var progress = create_default()
	progress.save_version = int(data.get("save_version", SAVE_VERSION))
	progress.upgrade_points = max(0, int(data.get("upgrade_points", 0)))

	var raw_upgrades = data.get("hero_upgrades", {})
	if raw_upgrades is Dictionary:
		for hero_id in raw_upgrades.keys():
			var raw_upgrade = raw_upgrades[hero_id]
			if raw_upgrade is Dictionary:
				progress.hero_upgrades[str(hero_id)] = HERO_UPGRADE_STATE_SCRIPT.from_dictionary(raw_upgrade, str(hero_id))

	for hero_id in DEFAULT_HERO_IDS:
		progress.ensure_hero(hero_id)

	var raw_completed = data.get("completed_levels", {})
	progress.completed_levels = {}
	if raw_completed is Dictionary:
		for level_id in raw_completed.keys():
			progress.completed_levels[str(level_id)] = bool(raw_completed[level_id])

	progress.level_progress = {}
	var raw_level_progress = data.get("level_progress", {})
	if raw_level_progress is Dictionary:
		for level_id in raw_level_progress.keys():
			var raw_state = raw_level_progress[level_id]
			if raw_state is Dictionary:
				progress.level_progress[str(level_id)] = LEVEL_PROGRESS_STATE_SCRIPT.from_dictionary(raw_state, str(level_id))

	for level_id in progress.completed_levels.keys():
		if bool(progress.completed_levels[level_id]) and not progress.level_progress.has(level_id):
			progress.level_progress[level_id] = LEVEL_PROGRESS_STATE_SCRIPT.new(level_id, true, 1, 0)

	var raw_team_selection = data.get("team_selection", {})
	if raw_team_selection is Dictionary:
		progress.team_selection = TEAM_SELECTION_STATE_SCRIPT.from_dictionary(raw_team_selection, DEFAULT_HERO_IDS)
	else:
		progress.team_selection = TEAM_SELECTION_STATE_SCRIPT.create_default(DEFAULT_HERO_IDS)

	var raw_currencies = data.get("currencies", {})
	progress.gold = _sanitize_non_negative_int(raw_currencies.get("gold", 0) if raw_currencies is Dictionary else 0)
	progress.gems = _sanitize_non_negative_int(raw_currencies.get("gems", 0) if raw_currencies is Dictionary else 0)

	progress.booster_inventory = {}
	var raw_booster_inventory = data.get("booster_inventory", {})
	if raw_booster_inventory is Dictionary:
		for booster_id in raw_booster_inventory.keys():
			progress.booster_inventory[str(booster_id)] = _sanitize_non_negative_int(raw_booster_inventory[booster_id])
	progress.ensure_booster_inventory()

	progress.processed_purchase_tokens = {}
	var raw_processed_tokens = data.get("processed_purchase_tokens", [])
	if raw_processed_tokens is Array:
		for token in raw_processed_tokens:
			var token_string := str(token)
			if token_string != "":
				progress.processed_purchase_tokens[token_string] = true

	progress.pending_consume_tokens = {}
	var raw_pending_tokens = data.get("pending_consume_tokens", {})
	if raw_pending_tokens is Dictionary:
		for token in raw_pending_tokens.keys():
			var token_string := str(token)
			var entry = raw_pending_tokens[token]
			if token_string != "" and entry is Dictionary:
				progress.pending_consume_tokens[token_string] = {
					"product_id": str(entry.get("product_id", "")),
					"item_id": str(entry.get("item_id", "")),
				}

	return progress


static func _sanitize_non_negative_int(value) -> int:
	if value is int or value is float:
		return int(max(0, int(value)))
	return 0
