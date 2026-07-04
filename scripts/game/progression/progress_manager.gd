extends RefCounted
class_name ProgressManager

const SAVE_MANAGER_SCRIPT := preload("res://scripts/game/save/save_manager.gd")
const PLAYER_PROGRESS_SCRIPT := preload("res://scripts/game/progression/player_progress.gd")
const UPGRADE_RESOLVER_SCRIPT := preload("res://scripts/game/progression/upgrade_resolver.gd")

var save_manager
var progress
var upgrade_resolver


func _init(manager_save_manager = null) -> void:
	save_manager = manager_save_manager if manager_save_manager != null else SAVE_MANAGER_SCRIPT.new()
	progress = PLAYER_PROGRESS_SCRIPT.create_default()
	upgrade_resolver = UPGRADE_RESOLVER_SCRIPT.new()


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
	progress.mark_level_completed(level_config.level_id)
	save()
	return reward


func can_upgrade(hero_id: String, stat: String) -> bool:
	return upgrade_resolver.can_upgrade(progress, hero_id, stat)


func upgrade(hero_id: String, stat: String) -> bool:
	if not upgrade_resolver.upgrade(progress, hero_id, stat):
		return false
	save()
	return true


func reset_progress() -> void:
	progress = save_manager.reset_progress()
