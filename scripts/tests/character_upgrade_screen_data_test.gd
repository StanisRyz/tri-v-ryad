extends SceneTree

const HERO_CATALOG_SCRIPT := "res://scripts/game/config/hero_catalog.gd"
const HERO_UPGRADE_VIEW_DATA_SCRIPT := "res://scripts/game/presentation/hero_upgrade_view_data.gd"
const PLAYER_PROGRESS_SCRIPT := "res://scripts/game/progression/player_progress.gd"
const PROGRESS_MANAGER_SCRIPT := "res://scripts/game/progression/progress_manager.gd"
const SAVE_MANAGER_SCRIPT := "res://scripts/game/save/save_manager.gd"
const ECONOMY_CONFIG := preload("res://scripts/game/progression/upgrade_economy_config.gd")

const TEST_SAVE_PATH := "user://test_character_upgrade_save_v1.json"
const TEST_TEMP_SAVE_PATH := "user://test_character_upgrade_save_v1.tmp"

var _failures := 0


func _initialize() -> void:
	print("Running character upgrade screen data tests...")

	_cleanup()

	var catalog = load(HERO_CATALOG_SCRIPT).new()
	var save_manager = load(SAVE_MANAGER_SCRIPT).new(TEST_SAVE_PATH, TEST_TEMP_SAVE_PATH)
	var progress_manager = load(PROGRESS_MANAGER_SCRIPT).new(save_manager)
	progress_manager.progress = load(PLAYER_PROGRESS_SCRIPT).from_dictionary({
		"save_version": 1,
		"upgrade_points": 3,
		"hero_upgrades": {
			"hero_1": {
				"hero_id": "hero_1",
				"attack_level": 1,
				"hp_level": 1,
			},
		},
		"completed_levels": {},
	})

	for hero_config in catalog.get_all_heroes():
		var upgrade_state = progress_manager.ensure_hero_upgrade(hero_config.hero_id)
		_expect_true(upgrade_state != null, "upgrade state exists for %s" % hero_config.hero_id)

	_expect_equal(progress_manager.get_hero_upgrade("hero_4").attack_level, 0, "hero_4 old save attack defaults to 0")
	_expect_equal(progress_manager.get_hero_upgrade("hero_4").hp_level, 0, "hero_4 old save hp defaults to 0")
	_expect_equal(progress_manager.get_hero_upgrade("hero_5").attack_level, 0, "hero_5 old save attack defaults to 0")
	_expect_equal(progress_manager.get_hero_upgrade("hero_5").hp_level, 0, "hero_5 old save hp defaults to 0")

	var hero_4_config = catalog.get_hero("hero_4")
	var hero_4_data = load(HERO_UPGRADE_VIEW_DATA_SCRIPT).from_config(hero_4_config, progress_manager.get_progress(), progress_manager)
	_expect_equal(hero_4_data.current_attack, hero_4_config.base_attack, "hero_4 current attack uses base at level 0")
	_expect_equal(hero_4_data.next_attack, hero_4_config.base_attack + ECONOMY_CONFIG.ATTACK_GROWTH_PER_LEVEL, "hero_4 next attack previews linear growth")
	_expect_equal(hero_4_data.current_max_hp, hero_4_config.base_max_hp, "hero_4 current hp uses base at level 0")
	_expect_equal(hero_4_data.next_max_hp, hero_4_config.base_max_hp + ECONOMY_CONFIG.HP_GROWTH_PER_LEVEL, "hero_4 next hp previews linear growth")
	_expect_equal(hero_4_data.attack_cost, ECONOMY_CONFIG.get_attack_upgrade_cost(0), "hero_4 attack cost uses economy config")
	_expect_equal(hero_4_data.hp_cost, ECONOMY_CONFIG.get_hp_upgrade_cost(0), "hero_4 hp cost uses economy config")
	_expect_equal(hero_4_data.attack_status, "Cost: %d" % ECONOMY_CONFIG.get_attack_upgrade_cost(0), "hero_4 attack status shows cost")

	var points_before_invalid: int = progress_manager.get_upgrade_points()
	_expect_false(progress_manager.upgrade("hero_4", "speed"), "invalid stat fails")
	_expect_equal(progress_manager.get_upgrade_points(), points_before_invalid, "invalid stat does not spend points")
	_expect_equal(progress_manager.get_hero_upgrade("hero_4").attack_level, 0, "invalid stat does not mutate attack")

	_expect_true(progress_manager.upgrade("hero_4", "attack"), "hero_4 attack upgrade succeeds")
	_expect_equal(progress_manager.get_hero_upgrade("hero_4").attack_level, 1, "hero_4 attack level increases")
	_expect_equal(progress_manager.get_upgrade_points(), 3 - ECONOMY_CONFIG.get_attack_upgrade_cost(0), "hero_4 attack upgrade spends calculated cost")

	_expect_true(progress_manager.upgrade("hero_5", "hp"), "hero_5 hp upgrade succeeds")
	_expect_equal(progress_manager.get_hero_upgrade("hero_5").hp_level, 1, "hero_5 hp level increases")
	_expect_equal(progress_manager.get_upgrade_points(), 3 - ECONOMY_CONFIG.get_attack_upgrade_cost(0) - ECONOMY_CONFIG.get_hp_upgrade_cost(0), "hero_5 hp upgrade spends calculated cost")

	var hero_5_config = catalog.get_hero("hero_5")
	var hero_5_data = load(HERO_UPGRADE_VIEW_DATA_SCRIPT).from_config(hero_5_config, progress_manager.get_progress(), progress_manager)
	_expect_equal(hero_5_data.current_attack, hero_5_config.base_attack, "hero_5 current attack stays base")
	_expect_equal(hero_5_data.next_attack, hero_5_config.base_attack + ECONOMY_CONFIG.ATTACK_GROWTH_PER_LEVEL, "hero_5 next attack previews linear growth")
	_expect_equal(hero_5_data.current_max_hp, hero_5_config.base_max_hp + ECONOMY_CONFIG.HP_GROWTH_PER_LEVEL, "hero_5 current hp includes one level")
	_expect_equal(hero_5_data.next_max_hp, hero_5_config.base_max_hp + ECONOMY_CONFIG.HP_GROWTH_PER_LEVEL * 2, "hero_5 next hp previews next level")

	var saved_progress = save_manager.load_progress()
	_expect_equal(saved_progress.get_hero_upgrade("hero_4").attack_level, 1, "saved progress includes hero_4 upgrade")
	_expect_equal(saved_progress.get_hero_upgrade("hero_5").hp_level, 1, "saved progress includes hero_5 upgrade")

	_cleanup()
	if _failures == 0:
		print("Character upgrade screen data tests passed.")
		quit(0)
	else:
		push_error("Character upgrade screen data tests failed: %d" % _failures)
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
