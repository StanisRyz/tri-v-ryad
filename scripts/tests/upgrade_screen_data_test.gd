extends SceneTree

const HERO_CATALOG_SCRIPT := "res://scripts/game/config/hero_catalog.gd"
const HERO_UPGRADE_VIEW_DATA_SCRIPT := "res://scripts/game/presentation/hero_upgrade_view_data.gd"
const PLAYER_PROGRESS_SCRIPT := "res://scripts/game/progression/player_progress.gd"
const PROGRESS_MANAGER_SCRIPT := "res://scripts/game/progression/progress_manager.gd"
const SAVE_MANAGER_SCRIPT := "res://scripts/game/save/save_manager.gd"
const ECONOMY_CONFIG := preload("res://scripts/game/progression/upgrade_economy_config.gd")

const TEST_SAVE_PATH := "user://test_upgrade_screen_data_save_v1.json"
const TEST_TEMP_SAVE_PATH := "user://test_upgrade_screen_data_save_v1.tmp"

var _failures := 0


func _initialize() -> void:
	print("Running upgrade screen data tests...")

	_cleanup()
	var catalog = load(HERO_CATALOG_SCRIPT).new()
	var save_manager = load(SAVE_MANAGER_SCRIPT).new(TEST_SAVE_PATH, TEST_TEMP_SAVE_PATH)
	var progress_manager = load(PROGRESS_MANAGER_SCRIPT).new(save_manager)
	progress_manager.progress = load(PLAYER_PROGRESS_SCRIPT).create_default()
	progress_manager.progress.upgrade_points = ECONOMY_CONFIG.get_attack_upgrade_cost(0)

	var hero_config = catalog.get_hero("hero_1")
	var view_data = load(HERO_UPGRADE_VIEW_DATA_SCRIPT).from_config(hero_config, progress_manager.get_progress(), progress_manager)
	_expect_equal(view_data.attack_cost, ECONOMY_CONFIG.get_attack_upgrade_cost(0), "attack cost is shown")
	_expect_equal(view_data.hp_cost, ECONOMY_CONFIG.get_hp_upgrade_cost(0), "hp cost is shown")
	_expect_equal(view_data.attack_status, "Cost: %d" % ECONOMY_CONFIG.get_attack_upgrade_cost(0), "attack status shows cost")
	_expect_true(view_data.can_upgrade_attack, "attack button can be enabled with enough points")

	progress_manager.progress.upgrade_points = 0
	var poor_view_data = load(HERO_UPGRADE_VIEW_DATA_SCRIPT).from_config(hero_config, progress_manager.get_progress(), progress_manager)
	_expect_equal(poor_view_data.attack_status, "Not enough points", "attack status shows insufficient points")
	_expect_false(poor_view_data.can_upgrade_attack, "attack button disabled without points")

	progress_manager.progress.upgrade_points = 999
	progress_manager.get_hero_upgrade("hero_1").attack_level = ECONOMY_CONFIG.MAX_ATTACK_LEVEL
	var max_view_data = load(HERO_UPGRADE_VIEW_DATA_SCRIPT).from_config(hero_config, progress_manager.get_progress(), progress_manager)
	_expect_equal(max_view_data.attack_status, "Max level", "attack status shows max level")
	_expect_false(max_view_data.can_upgrade_attack, "attack button disabled at max level")
	_expect_equal(max_view_data.current_attack, max_view_data.next_attack, "max attack next value does not exceed current")

	_cleanup()
	if _failures == 0:
		print("Upgrade screen data tests passed.")
		quit(0)
	else:
		push_error("Upgrade screen data tests failed: %d" % _failures)
		quit(1)


func _cleanup() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)
	if FileAccess.file_exists(TEST_TEMP_SAVE_PATH):
		DirAccess.remove_absolute(TEST_TEMP_SAVE_PATH)


func _expect_true(value: bool, message: String) -> void:
	if value:
		return

	_failures += 1
	push_error("FAILED: %s" % message)


func _expect_false(value: bool, message: String) -> void:
	_expect_true(not value, message)


func _expect_equal(actual, expected, message: String) -> void:
	if actual == expected:
		return

	_failures += 1
	push_error("FAILED: %s | expected=%s actual=%s" % [message, expected, actual])
