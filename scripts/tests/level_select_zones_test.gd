extends SceneTree

const LEVEL_SELECT_SCREEN := preload("res://scenes/screens/LevelSelectScreen.tscn")
const PROGRESS_MANAGER_SCRIPT := preload("res://scripts/game/progression/progress_manager.gd")
const SAVE_MANAGER_SCRIPT := preload("res://scripts/game/save/save_manager.gd")

const TEST_SAVE_PATH := "user://test_level_select_zones_save_v1.json"
const TEST_TEMP_SAVE_PATH := "user://test_level_select_zones_save_v1.tmp"

var _failures := 0


class TestSettings:
	var debug_labels_enabled := false


class TestSettingsManager:
	var settings := TestSettings.new()

	func _init(debug_labels_enabled: bool) -> void:
		settings.debug_labels_enabled = debug_labels_enabled

	func get_settings():
		return settings


func _initialize() -> void:
	print("Running level select zone tests...")
	_run()


func _run() -> void:
	_cleanup()
	await _test_default_progress_shows_zone_1_only()
	await _test_zone_2_after_level_10()
	await _test_zone_3_after_level_20()
	await _test_zone_10_after_level_90()
	await _test_debug_labels_and_selection()
	_cleanup()

	if _failures == 0:
		print("Level select zone tests passed.")
		quit(0)
	else:
		push_error("Level select zone tests failed: %d" % _failures)
		quit(1)


func _test_default_progress_shows_zone_1_only() -> void:
	var screen: Control = await _make_screen([])
	var selector := screen.get_node("%ZoneSelector") as OptionButton
	var buttons := screen.get_node("%LevelButtons") as VBoxContainer

	_expect_equal(selector.get_item_count(), 1, "new progress shows only one zone")
	_expect_equal(selector.get_item_text(0), "Zone 1: Levels 1-10", "new progress shows zone 1 label")
	_expect_equal(buttons.get_child_count(), 10, "new progress builds only level 1-10 buttons")
	_expect_true((buttons.get_child(0) as Button).text.begins_with("Level 1"), "first visible level is level 1")
	_expect_true((buttons.get_child(9) as Button).text.begins_with("Level 10"), "last visible level is level 10")
	_expect_false((buttons.get_child(0) as Button).disabled, "level 1 is open by default")
	_expect_true((buttons.get_child(1) as Button).disabled, "locked level buttons remain disabled")
	_expect_true(buttons.get_child_count() < 100, "level select does not build 100 buttons")

	screen.queue_free()


func _test_zone_2_after_level_10() -> void:
	var screen: Control = await _make_screen(["level_10"])
	var selector := screen.get_node("%ZoneSelector") as OptionButton
	var buttons := screen.get_node("%LevelButtons") as VBoxContainer

	_expect_equal(selector.get_item_count(), 2, "level_10 completion unlocks zone 2")
	_expect_equal(selector.get_item_text(1), "Zone 2: Levels 11-20", "zone 2 label appears")
	_expect_equal(selector.get_selected_id(), 1, "highest unlocked zone is selected by default")
	_expect_true((buttons.get_child(0) as Button).text.begins_with("Level 11"), "zone 2 starts at level 11")
	_expect_true((buttons.get_child(9) as Button).text.begins_with("Level 20"), "zone 2 ends at level 20")
	_expect_false((buttons.get_child(0) as Button).disabled, "level 11 is open after level 10")
	_expect_true((buttons.get_child(1) as Button).disabled, "level 12 remains locked until level 11 is completed")

	selector.select(0)
	selector.item_selected.emit(0)
	await process_frame
	_expect_true(((screen.get_node("%LevelButtons") as VBoxContainer).get_child(0) as Button).text.begins_with("Level 1"), "manual zone 1 selection rebuilds level 1-10")

	screen.queue_free()


func _test_zone_3_after_level_20() -> void:
	var screen: Control = await _make_screen(["level_10", "level_20"])
	var selector := screen.get_node("%ZoneSelector") as OptionButton
	var buttons := screen.get_node("%LevelButtons") as VBoxContainer

	_expect_equal(selector.get_item_count(), 3, "level_20 completion unlocks zone 3")
	_expect_equal(selector.get_item_text(2), "Zone 3: Levels 21-30", "zone 3 label appears")
	_expect_equal(selector.get_selected_id(), 2, "zone 3 is selected by default")
	_expect_true((buttons.get_child(0) as Button).text.begins_with("Level 21"), "zone 3 starts at level 21")

	screen.queue_free()


func _test_zone_10_after_level_90() -> void:
	var completed_levels: Array[String] = []
	for level_number in range(10, 91, 10):
		completed_levels.append("level_%d" % level_number)

	var screen: Control = await _make_screen(completed_levels)
	var selector := screen.get_node("%ZoneSelector") as OptionButton
	var buttons := screen.get_node("%LevelButtons") as VBoxContainer

	_expect_equal(selector.get_item_count(), 10, "level_90 completion unlocks zone 10")
	_expect_equal(selector.get_item_text(9), "Zone 10: Levels 91-100", "zone 10 label appears")
	_expect_equal(selector.get_selected_id(), 9, "zone 10 is selected by default")
	_expect_true((buttons.get_child(9) as Button).text.begins_with("Level 100"), "level 100 appears in zone 10")
	_expect_true(buttons.get_child_count() < 100, "zone 10 still builds only its 10 buttons")

	screen.queue_free()


func _test_debug_labels_and_selection() -> void:
	var screen: Control = await _make_screen(["level_10"], true)
	var buttons := screen.get_node("%LevelButtons") as VBoxContainer
	var level_button := buttons.get_child(0) as Button
	var selected_levels: Array[String] = []
	screen.level_selected.connect(func(level_id: String): selected_levels.append(level_id))

	_expect_true(level_button.text.begins_with("Level 11 (level_11)"), "debug labels add level_id")
	_expect_false(level_button.disabled, "level 11 can be selected")
	level_button.pressed.emit()
	_expect_equal(selected_levels, ["level_11"], "selecting an unlocked level emits the correct level_id")

	screen.queue_free()


func _make_screen(completed_level_ids: Array, debug_labels_enabled: bool = false) -> Control:
	var progress_manager = _make_progress_manager(completed_level_ids)
	var screen := LEVEL_SELECT_SCREEN.instantiate() as Control
	root.add_child(screen)
	screen.set_progress_manager(progress_manager)
	screen.set_settings_manager(TestSettingsManager.new(debug_labels_enabled))
	await process_frame
	return screen


func _make_progress_manager(completed_level_ids: Array):
	_cleanup()
	var save_manager = SAVE_MANAGER_SCRIPT.new(TEST_SAVE_PATH, TEST_TEMP_SAVE_PATH)
	var progress_manager = PROGRESS_MANAGER_SCRIPT.new(save_manager)
	progress_manager.load()
	for level_id in completed_level_ids:
		progress_manager.progress.mark_level_completed(str(level_id))
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
