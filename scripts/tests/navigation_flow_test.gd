extends SceneTree

const MAIN_MENU_SCREEN := preload("res://scenes/screens/MainMenuScreen.tscn")
const LEVEL_SELECT_SCREEN := preload("res://scenes/screens/LevelSelectScreen.tscn")
const TEAM_SELECT_SCREEN := preload("res://scenes/screens/TeamSelectScreen.tscn")
const PROGRESS_MANAGER_SCRIPT := preload("res://scripts/game/progression/progress_manager.gd")
const SAVE_MANAGER_SCRIPT := preload("res://scripts/game/save/save_manager.gd")
const HERO_CATALOG_SCRIPT := preload("res://scripts/game/config/hero_catalog.gd")

const TEST_SAVE_PATH := "user://test_navigation_flow_save_v1.json"
const TEST_TEMP_SAVE_PATH := "user://test_navigation_flow_save_v1.tmp"

var _failures := 0


func _initialize() -> void:
	print("Running navigation flow tests...")
	_run()


func _run() -> void:
	_cleanup()
	await _test_main_menu_signals()
	await _test_level_select_signals()
	await _test_team_select_start_battle()
	await _test_team_select_rejects_invalid_team()
	_cleanup()

	if _failures == 0:
		print("Navigation flow tests passed.")
		quit(0)
	else:
		push_error("Navigation flow tests failed: %d" % _failures)
		quit(1)


func _test_main_menu_signals() -> void:
	var screen := MAIN_MENU_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame

	var play_signals: Array = []
	var heroes_signals: Array = []
	screen.play_pressed.connect(func(): play_signals.append(true))
	screen.heroes_pressed.connect(func(): heroes_signals.append(true))

	screen.get_node("%PlayButton").pressed.emit()
	screen.get_node("%HeroesButton").pressed.emit()

	_expect_equal(play_signals.size(), 1, "main menu play button emits play_pressed")
	_expect_equal(heroes_signals.size(), 1, "main menu heroes button emits heroes_pressed")

	screen.queue_free()


func _test_level_select_signals() -> void:
	var screen := LEVEL_SELECT_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame

	_expect_true(screen.has_signal("level_selected"), "level select exposes level_selected")
	_expect_true(screen.has_signal("back_pressed"), "level select exposes back_pressed")
	_expect_false(screen.has_signal("team_pressed"), "level select no longer exposes team_pressed")
	_expect_false(screen.has_signal("upgrades_pressed"), "level select no longer exposes upgrades_pressed")
	_expect_false(screen.has_node("%TeamButton"), "level select no longer has a team button")
	_expect_false(screen.has_node("%UpgradesButton"), "level select no longer has an upgrades button")

	var back_signals: Array = []
	screen.back_pressed.connect(func(): back_signals.append(true))
	screen.get_node("%BackButton").pressed.emit()
	_expect_equal(back_signals.size(), 1, "level select back button emits back_pressed")

	screen.queue_free()


func _test_team_select_start_battle() -> void:
	var progress_manager = _make_progress_manager()
	var catalog = HERO_CATALOG_SCRIPT.new()
	var valid_team := catalog.get_default_team_ids()

	var screen := TEAM_SELECT_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame
	screen.set_progress_manager(progress_manager)
	screen.set_level_id("level_2")

	var started_with: Array = []
	screen.start_battle_pressed.connect(func(level_id): started_with.append(level_id))

	_select_team(screen, valid_team)

	screen.get_node("%SaveButton").pressed.emit()

	_expect_equal(started_with, ["level_2"], "team select emits start_battle_pressed with the same level_id")
	_expect_equal(progress_manager.get_selected_team_ids(), valid_team, "valid team is saved through progress manager")

	screen.queue_free()


func _test_team_select_rejects_invalid_team() -> void:
	var progress_manager = _make_progress_manager()

	var screen := TEAM_SELECT_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame
	screen.set_progress_manager(progress_manager)
	screen.set_level_id("level_1")

	var started_with: Array = []
	screen.start_battle_pressed.connect(func(level_id): started_with.append(level_id))

	_select_team(screen, ["hero_1", "hero_2"])

	_expect_true(screen.get_node("%SaveButton").disabled, "start battle is disabled for an incomplete team")

	screen.get_node("%SaveButton").pressed.emit()

	_expect_equal(started_with.size(), 0, "team select does not emit start_battle_pressed for an invalid team")

	screen.queue_free()


func _select_team(screen, hero_ids: Array) -> void:
	for hero_id in screen._selected_hero_ids.duplicate():
		if not hero_ids.has(hero_id):
			screen._on_hero_button_pressed(hero_id)

	for hero_id in hero_ids:
		if not screen._selected_hero_ids.has(hero_id):
			screen._on_hero_button_pressed(hero_id)


func _make_progress_manager():
	var save_manager = SAVE_MANAGER_SCRIPT.new(TEST_SAVE_PATH, TEST_TEMP_SAVE_PATH)
	var progress_manager = PROGRESS_MANAGER_SCRIPT.new(save_manager)
	progress_manager.load()
	return progress_manager


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
