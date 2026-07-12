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
const SHOP_REWARD_TYPE_SCRIPT := preload("res://scripts/game/shop/shop_reward_type.gd")

## Stage 69.3.1: apply_platform_purchase_atomic() result statuses.
const PURCHASE_STATUS_GRANTED := "granted"
const PURCHASE_STATUS_ALREADY_GRANTED := "already_granted"
const PURCHASE_STATUS_INVALID_TOKEN := "invalid_token"
const PURCHASE_STATUS_INVALID_ITEM := "invalid_item"
const PURCHASE_STATUS_INVALID_REWARD := "invalid_reward"
const PURCHASE_STATUS_SAVE_FAILED := "save_failed"

## Stage 69.4: emitted only after SaveManager successfully writes progress to
## disk. CloudSaveCoordinator listens to this instead of being called from
## every gameplay method — "critical" saves (paid purchase reward granted,
## pending-consume state changed, level completion, explicit reset) request
## an immediate cloud upload; "normal" saves go through the debounce queue.
signal local_save_completed(snapshot: Dictionary, importance: String)

const IMPORTANCE_NORMAL := "normal"
const IMPORTANCE_CRITICAL := "critical"

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


func save(importance: String = IMPORTANCE_NORMAL) -> bool:
	var success: bool = save_manager.save_progress(progress)
	if success:
		local_save_completed.emit(progress.to_dictionary(), importance)
	return success


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
	save(IMPORTANCE_CRITICAL)
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

	save(IMPORTANCE_CRITICAL)

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
	save(IMPORTANCE_CRITICAL)


func get_pending_consume_tokens() -> Dictionary:
	return progress.get_pending_consume_tokens() if progress != null else {}


## Stage 69.3.1: removes a token once Platform.consume_purchase() actually
## succeeded for it (the caller, PlatformPurchaseCoordinator, is responsible
## for only calling this after payment_consume_success). Saves once.
func remove_pending_consume_token(token: String) -> bool:
	if progress == null or not progress.has_pending_consume_token(token):
		return false
	progress.remove_pending_consume_token(token)
	return save(IMPORTANCE_CRITICAL)


## Stage 69.3.1: the single entry point for granting a paid shop item's
## rewards. Either everything (every reward + processed-token mark +
## pending-consume record) lands in one save(), or nothing changes at all —
## see PlayerProgress.duplicate_progress(). Never uses add_currency()/
## add_booster() here, since those each save independently and could leave a
## purchase half-applied if a later reward or the save itself failed.
##
## Returns {"status", "item_id", "purchase_token", "platform_product_id"}.
## Callers (PlatformPurchaseCoordinator) must only request
## Platform.consume_purchase() when status is "granted" or "already_granted".
func apply_platform_purchase_atomic(item, purchase_token: String, platform_product_id: String) -> Dictionary:
	var result := {
		"status": PURCHASE_STATUS_INVALID_ITEM,
		"item_id": item.item_id if item != null else "",
		"purchase_token": purchase_token,
		"platform_product_id": platform_product_id,
	}

	if item == null or progress == null:
		result["status"] = PURCHASE_STATUS_INVALID_ITEM
		return result

	if purchase_token == "":
		result["status"] = PURCHASE_STATUS_INVALID_TOKEN
		return result

	if progress.has_processed_purchase_token(purchase_token):
		# Already granted earlier. Keep it tracked for a consume retry in case
		# the original attempt recorded the grant but never got a consume
		# success (e.g. app closed between the atomic save and the consume
		# call finishing) — never re-applies any reward. Stage 69.4: this
		# still goes through an isolated candidate snapshot (never mutates
		# the live `progress` directly), same one-save-or-nothing guarantee
		# as the "granted" branch below.
		if not progress.has_pending_consume_token(purchase_token):
			var pending_candidate: PlayerProgress = progress.duplicate_progress()
			pending_candidate.add_pending_consume_token(purchase_token, platform_product_id, item.item_id)
			if not save_manager.save_progress(pending_candidate):
				result["status"] = PURCHASE_STATUS_SAVE_FAILED
				return result
			progress = pending_candidate
			local_save_completed.emit(progress.to_dictionary(), IMPORTANCE_CRITICAL)
		result["status"] = PURCHASE_STATUS_ALREADY_GRANTED
		return result

	if item.rewards.is_empty():
		result["status"] = PURCHASE_STATUS_INVALID_REWARD
		return result
	for reward in item.rewards:
		if not SHOP_REWARD_TYPE_SCRIPT.is_valid(reward):
			result["status"] = PURCHASE_STATUS_INVALID_REWARD
			return result

	var candidate: PlayerProgress = progress.duplicate_progress()
	for reward in item.rewards:
		match str(reward.get("type", "")):
			SHOP_REWARD_TYPE_SCRIPT.CURRENCY:
				candidate.add_currency(str(reward.get("currency_id", "")), int(reward.get("amount", 0)))
			SHOP_REWARD_TYPE_SCRIPT.BOOSTER:
				candidate.add_booster(str(reward.get("booster_id", "")), int(reward.get("amount", 0)))
	candidate.mark_processed_purchase_token(purchase_token)
	candidate.add_pending_consume_token(purchase_token, platform_product_id, item.item_id)

	if not save_manager.save_progress(candidate):
		result["status"] = PURCHASE_STATUS_SAVE_FAILED
		return result

	progress = candidate
	local_save_completed.emit(progress.to_dictionary(), IMPORTANCE_CRITICAL)
	result["status"] = PURCHASE_STATUS_GRANTED
	return result


func get_economy_debug_summary() -> String:
	return progress.get_economy_debug_summary() if progress != null else ""


func reset_progress() -> void:
	progress = save_manager.reset_progress()
	local_save_completed.emit(progress.to_dictionary(), IMPORTANCE_CRITICAL)
	_normalize_loaded_team_selection()


## Stage 69.4: applies an authoritative cloud snapshot locally. Parses
## through PlayerProgress.from_dictionary() (always returns a sane object —
## unknown/missing fields fall back to defaults), saves it to the local file
## FIRST, and only replaces the live `progress` if that save succeeds — a
## corrupt/oversized cloud payload or a local write failure never disturbs
## the existing local progress. Saved with bump_metadata = false: this is a
## passive sync of already-authoritative data, not a new local mutation, so
## it intentionally does not bump save_revision or emit local_save_completed
## (which would otherwise immediately re-queue the same snapshot for upload).
## Purchase token ledgers (processed_purchase_tokens/pending_consume_tokens)
## come through unchanged since they're part of the same to_dictionary()/
## from_dictionary() round trip as everything else.
func replace_progress_from_cloud(progress_data: Dictionary) -> bool:
	if progress_data.is_empty():
		return false

	var candidate: PlayerProgress = PLAYER_PROGRESS_SCRIPT.from_dictionary(progress_data)
	if candidate == null:
		return false

	if not save_manager.save_progress(candidate, false):
		return false

	progress = candidate
	return true


func _normalize_loaded_team_selection() -> void:
	if progress == null:
		return

	var current_ids: Array[String] = progress.get_selected_team_ids()
	var normalized_ids: Array[String] = team_selection_resolver.normalize_team(current_ids, hero_catalog)
	if current_ids == normalized_ids:
		return

	progress.set_team_selection(TEAM_SELECTION_STATE_SCRIPT.new(normalized_ids))
	save()
