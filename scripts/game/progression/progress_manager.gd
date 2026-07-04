extends RefCounted
class_name ProgressManager

const SAVE_MANAGER_SCRIPT := preload("res://scripts/game/save/save_manager.gd")
const PLAYER_PROGRESS_SCRIPT := preload("res://scripts/game/progression/player_progress.gd")
const UPGRADE_RESOLVER_SCRIPT := preload("res://scripts/game/progression/upgrade_resolver.gd")
const LEVEL_COMPLETION_RESOLVER_SCRIPT := preload("res://scripts/game/progression/level_completion_resolver.gd")

var save_manager
var progress
var upgrade_resolver
var level_completion_resolver


func _init(manager_save_manager = null) -> void:
	save_manager = manager_save_manager if manager_save_manager != null else SAVE_MANAGER_SCRIPT.new()
	progress = PLAYER_PROGRESS_SCRIPT.create_default()
	upgrade_resolver = UPGRADE_RESOLVER_SCRIPT.new()
	level_completion_resolver = LEVEL_COMPLETION_RESOLVER_SCRIPT.new()


func load() -> void:
	progress = save_manager.load_progress()


func save() -> bool:
	return save_manager.save_progress(progress)


func get_progress():
	return progress


func get_upgrade_points() -> int:
	return progress.upgrade_points if progress != null else 0


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


func get_level_progress(level_id: String):
	return progress.get_level_progress(level_id) if progress != null else null


func get_level_stars(level_id: String) -> int:
	return progress.get_level_stars(level_id) if progress != null else 0


func is_level_completed(level_id: String) -> bool:
	return progress.is_level_completed(level_id) if progress != null else false


func is_level_unlocked(level_catalog, level_id: String) -> bool:
	return level_completion_resolver.is_level_unlocked(progress, level_catalog, level_id)


func can_upgrade(hero_id: String, stat: String) -> bool:
	return upgrade_resolver.can_upgrade(progress, hero_id, stat)


func upgrade(hero_id: String, stat: String) -> bool:
	if not upgrade_resolver.upgrade(progress, hero_id, stat):
		return false
	save()
	return true


func reset_progress() -> void:
	progress = save_manager.reset_progress()
