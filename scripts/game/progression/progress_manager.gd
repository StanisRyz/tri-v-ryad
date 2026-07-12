extends RefCounted
class_name ProgressManager

const SAVE_MANAGER_SCRIPT := preload("res://scripts/game/save/save_manager.gd")
const PLAYER_PROGRESS_SCRIPT := preload("res://scripts/game/progression/player_progress.gd")
const UPGRADE_RESOLVER_SCRIPT := preload("res://scripts/game/progression/upgrade_resolver.gd")
const LEVEL_COMPLETION_RESOLVER_SCRIPT := preload("res://scripts/game/progression/level_completion_resolver.gd")
const LEVEL_STAR_REWARD_RESOLVER_SCRIPT := preload("res://scripts/game/progression/level_star_reward_resolver.gd")
const HERO_CATALOG_SCRIPT := preload("res://scripts/game/config/hero_catalog.gd")
const TEAM_SELECTION_RESOLVER_SCRIPT := preload("res://scripts/game/progression/team_selection_resolver.gd")
const TEAM_SELECTION_STATE_SCRIPT := preload("res://scripts/game/progression/team_selection_state.gd")
const LEVEL_LABEL_FORMATTER_SCRIPT := preload("res://scripts/game/config/level_label_formatter.gd")

var save_manager
var progress
var upgrade_resolver
var level_completion_resolver
var level_star_reward_resolver
var hero_catalog
var team_selection_resolver
var _milestone_reward_rng := RandomNumberGenerator.new()


func _init(manager_save_manager = null) -> void:
	save_manager = manager_save_manager if manager_save_manager != null else SAVE_MANAGER_SCRIPT.new()
	progress = PLAYER_PROGRESS_SCRIPT.create_default()
	upgrade_resolver = UPGRADE_RESOLVER_SCRIPT.new()
	level_completion_resolver = LEVEL_COMPLETION_RESOLVER_SCRIPT.new()
	level_star_reward_resolver = LEVEL_STAR_REWARD_RESOLVER_SCRIPT.new()
	hero_catalog = HERO_CATALOG_SCRIPT.new()
	team_selection_resolver = TEAM_SELECTION_RESOLVER_SCRIPT.new()
	_milestone_reward_rng.randomize()


func load() -> void:
	progress = save_manager.load_progress()
	_normalize_loaded_team_selection()


func save() -> bool:
	return save_manager.save_progress(progress)


func get_progress():
	return progress


func get_hero_catalog() -> HeroCatalog:
	return hero_catalog


func get_selected_team_ids() -> Array[String]:
	if progress == null:
		return hero_catalog.get_default_team_ids()
	return team_selection_resolver.normalize_team(progress.get_selected_team_ids(), hero_catalog)


func get_selected_team_state() -> TeamSelectionState:
	if progress == null:
		return TEAM_SELECTION_STATE_SCRIPT.create_default(hero_catalog.get_default_team_ids())
	var normalized_ids := get_selected_team_ids()
	return TEAM_SELECTION_STATE_SCRIPT.new(normalized_ids)


func set_selected_team_ids(hero_ids: Array) -> bool:
	if progress == null or not team_selection_resolver.is_valid_team(hero_ids, hero_catalog):
		return false

	progress.set_team_selection(TEAM_SELECTION_STATE_SCRIPT.new(hero_ids.duplicate()))
	for hero_id in hero_ids:
		progress.ensure_hero(hero_id)
	save()
	return true


func get_upgrade_points() -> int:
	return progress.upgrade_points if progress != null else 0


func ensure_hero_upgrade(hero_id: String) -> HeroUpgradeState:
	if progress == null:
		return null
	return progress.ensure_hero(hero_id)


func get_hero_upgrade(hero_id: String) -> HeroUpgradeState:
	if progress == null:
		return null
	return progress.get_hero_upgrade(hero_id)


func add_victory_reward(level_config) -> int:
	if progress == null or level_config == null:
		return 0

	var reward: int = max(0, level_config.reward_upgrade_points)
	progress.add_upgrade_points(reward)
	save()
	return reward


func complete_level(level_config, moves_left: int):
	if progress == null or level_config == null:
		return null

	var state = level_completion_resolver.apply_victory_result(progress, level_config, moves_left)
	save()
	return state


## Stage 62.3 v0.1: reward-aware level completion. Reads previous_stars before
## applying the victory result, resolves any newly earned star-milestone
## rewards (1-star unlock / 2-star gold / 3-star random booster) via
## LevelStarRewardResolver, applies them directly against `progress`, and
## saves once at the end - the existing complete_level()/add_currency()/
## add_booster() wrapper methods are intentionally bypassed here so a single
## victory only triggers a single save() instead of stacking one per reward.
func complete_level_with_rewards(level_config, moves_left: int, level_catalog) -> Dictionary:
	var result := {
		"level_progress_state": null,
		"previous_stars": 0,
		"new_stars": 0,
		"rewards": [],
		"unlocked_next_level": false,
		"gold_awarded": 0,
		"booster_awarded": "",
	}

	if progress == null or level_config == null:
		return result

	var level_id: String = level_config.level_id
	var previous_stars: int = get_level_stars(level_id)
	var state = level_completion_resolver.apply_victory_result(progress, level_config, moves_left)
	if state == null:
		return result

	var new_stars: int = int(state.stars)
	var next_level_id := _find_next_level_id(level_catalog, level_id)
	var rewards: Array[Dictionary] = level_star_reward_resolver.resolve_milestone_rewards(previous_stars, new_stars, next_level_id, _milestone_reward_rng)

	var unlocked_next_level := false
	var gold_awarded := 0
	var booster_awarded := ""

	for reward in rewards:
		match str(reward.get("type", "")):
			LEVEL_STAR_REWARD_RESOLVER_SCRIPT.REWARD_TYPE_UNLOCK_LEVEL:
				unlocked_next_level = true
			LEVEL_STAR_REWARD_RESOLVER_SCRIPT.REWARD_TYPE_CURRENCY:
				var amount: int = int(reward.get("amount", 0))
				progress.add_currency(str(reward.get("currency_id", "")), amount)
				gold_awarded += amount
			LEVEL_STAR_REWARD_RESOLVER_SCRIPT.REWARD_TYPE_BOOSTER:
				var booster_id := str(reward.get("booster_id", ""))
				progress.add_booster(booster_id, int(reward.get("amount", 0)))
				booster_awarded = booster_id

	save()

	result["level_progress_state"] = state
	result["previous_stars"] = previous_stars
	result["new_stars"] = new_stars
	result["rewards"] = rewards
	result["unlocked_next_level"] = unlocked_next_level
	result["gold_awarded"] = gold_awarded
	result["booster_awarded"] = booster_awarded
	return result


func _find_next_level_id(level_catalog, level_id: String) -> String:
	if level_catalog == null:
		return ""

	var level_number := LEVEL_LABEL_FORMATTER_SCRIPT.extract_level_number(level_id)
	if level_number <= 0:
		return ""

	var next_level_id := "level_%d" % (level_number + 1)
	return next_level_id if level_catalog.has_level(next_level_id) else ""


func get_level_progress(level_id: String):
	return progress.get_level_progress(level_id) if progress != null else null


func get_level_stars(level_id: String) -> int:
	return progress.get_level_stars(level_id) if progress != null else 0


func is_level_completed(level_id: String) -> bool:
	return progress.is_level_completed(level_id) if progress != null else false


func is_level_unlocked(level_catalog, level_id: String) -> bool:
	return level_completion_resolver.is_level_unlocked(progress, level_catalog, level_id)


func can_upgrade(hero_id: String, stat: String) -> bool:
	if hero_catalog != null and not hero_catalog.has_hero(hero_id):
		return false
	return upgrade_resolver.can_upgrade(progress, hero_id, stat)


func get_upgrade_cost(hero_id: String, stat: String) -> int:
	if hero_catalog != null and not hero_catalog.has_hero(hero_id):
		return -1
	return upgrade_resolver.get_upgrade_cost(progress, hero_id, stat)


func get_upgrade_result(hero_id: String, stat: String) -> Dictionary:
	if hero_catalog != null and not hero_catalog.has_hero(hero_id):
		return {
			"accepted": false,
			"reason": "invalid_hero",
			"cost": -1,
			"current_level": 0,
			"max_level": 0,
			"stat": stat,
			"hero_id": hero_id,
		}
	return upgrade_resolver.get_upgrade_result(progress, hero_id, stat)


func upgrade_with_result(hero_id: String, stat: String) -> Dictionary:
	if hero_catalog != null and not hero_catalog.has_hero(hero_id):
		return get_upgrade_result(hero_id, stat)
	var result: Dictionary = upgrade_resolver.upgrade_with_result(progress, hero_id, stat)
	if bool(result.get("accepted", false)):
		save()
	return result


func upgrade(hero_id: String, stat: String) -> bool:
	return bool(upgrade_with_result(hero_id, stat).get("accepted", false))


func get_currency(currency_id: String) -> int:
	return progress.get_currency(currency_id) if progress != null else 0


func add_currency(currency_id: String, amount: int) -> void:
	if progress == null:
		return
	progress.add_currency(currency_id, amount)
	save()


func can_spend_currency(currency_id: String, amount: int) -> bool:
	return progress.can_spend_currency(currency_id, amount) if progress != null else false


func spend_currency(currency_id: String, amount: int) -> bool:
	if progress == null:
		return false
	var spent: bool = progress.spend_currency(currency_id, amount)
	if spent:
		save()
	return spent


func get_booster_count(booster_id: String) -> int:
	return progress.get_booster_count(booster_id) if progress != null else 0


func add_booster(booster_id: String, amount: int) -> void:
	if progress == null:
		return
	progress.add_booster(booster_id, amount)
	save()


func has_booster(booster_id: String, amount: int = 1) -> bool:
	return progress.has_booster(booster_id, amount) if progress != null else false


func spend_booster(booster_id: String, amount: int = 1) -> bool:
	if progress == null:
		return false
	var spent: bool = progress.spend_booster(booster_id, amount)
	if spent:
		save()
	return spent


## Stage 69.3: guards a Yandex purchase token from granting its reward twice
## (once from a live payment_purchase_success, once from a later
## check_unprocessed_purchases() restore of the same purchase).
func has_processed_purchase_token(token: String) -> bool:
	return progress.has_processed_purchase_token(token) if progress != null else false


func mark_processed_purchase_token(token: String) -> void:
	if progress == null:
		return
	progress.mark_processed_purchase_token(token)
	save()


func get_economy_debug_summary() -> String:
	return progress.get_economy_debug_summary() if progress != null else ""


func reset_progress() -> void:
	progress = save_manager.reset_progress()
	_normalize_loaded_team_selection()


func _normalize_loaded_team_selection() -> void:
	if progress == null:
		return

	var current_ids: Array[String] = progress.get_selected_team_ids()
	var normalized_ids: Array[String] = team_selection_resolver.normalize_team(current_ids, hero_catalog)
	if current_ids == normalized_ids:
		return

	progress.set_team_selection(TEAM_SELECTION_STATE_SCRIPT.new(normalized_ids))
	save()
