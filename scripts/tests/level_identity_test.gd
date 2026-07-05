extends SceneTree

const LEVEL_CATALOG := preload("res://scripts/game/config/level_catalog.gd")
const LEVEL_LABEL_FORMATTER := preload("res://scripts/game/config/level_label_formatter.gd")
const LEVEL_SELECT_SCREEN := preload("res://scenes/screens/LevelSelectScreen.tscn")

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
	print("Running level identity tests...")
	_run()


func _run() -> void:
	_test_formatter()
	_test_catalog_identity()
	await _test_level_select_labels(false)
	await _test_level_select_labels(true)

	if _failures == 0:
		print("Level identity tests passed.")
		quit(0)
	else:
		push_error("Level identity tests failed: %d" % _failures)
		quit(1)


func _test_formatter() -> void:
	_expect_equal(LEVEL_LABEL_FORMATTER.extract_level_number("level_1"), 1, "extracts level_1")
	_expect_equal(LEVEL_LABEL_FORMATTER.extract_level_number("level_10"), 10, "extracts level_10")
	_expect_equal(LEVEL_LABEL_FORMATTER.extract_level_number("level_100"), 100, "extracts level_100")
	_expect_equal(LEVEL_LABEL_FORMATTER.extract_level_number("level_0"), -1, "rejects level_0")
	_expect_equal(LEVEL_LABEL_FORMATTER.extract_level_number("level_alpha"), -1, "rejects non-numeric suffix")
	_expect_equal(LEVEL_LABEL_FORMATTER.extract_level_number(""), -1, "rejects empty id")
	_expect_equal(LEVEL_LABEL_FORMATTER.format_level_label("level_1"), "Level 1", "formats level_1")
	_expect_equal(LEVEL_LABEL_FORMATTER.format_level_label("level_10"), "Level 10", "formats level_10")
	_expect_equal(LEVEL_LABEL_FORMATTER.format_level_label("level_100"), "Level 100", "formats level_100")
	_expect_equal(LEVEL_LABEL_FORMATTER.format_level_label("boss_intro", "Boss Intro"), "Boss Intro", "uses fallback display name")
	_expect_equal(LEVEL_LABEL_FORMATTER.format_level_label("boss_intro"), "Level", "uses safe default fallback")


func _test_catalog_identity() -> void:
	var catalog := LEVEL_CATALOG.new()
	var levels := catalog.get_all_levels()
	_expect_equal(levels.size(), 10, "catalog still has 10 levels")

	for index in range(levels.size()):
		var level_number := index + 1
		var level_config = levels[index]
		_expect_equal(level_config.level_id, "level_%d" % level_number, "level id remains unchanged")
		_expect_equal(level_config.display_name, "Level %d" % level_number, "display name is numbers-only")
		_expect_false(level_config.display_name.contains(":"), "display name has no location subtitle")
		_expect_false(_contains_old_level_name(level_config.display_name), "display name omits old location names")


func _test_level_select_labels(debug_labels_enabled: bool) -> void:
	var screen := LEVEL_SELECT_SCREEN.instantiate()
	root.add_child(screen)
	screen.set_settings_manager(TestSettingsManager.new(debug_labels_enabled))
	await process_frame

	var first_button := screen.get_node("%LevelButtons").get_child(0) as Button
	var expected_title := "Level 1 (level_1)" if debug_labels_enabled else "Level 1"
	_expect_true(first_button.text.begins_with(expected_title), "level select title respects debug label setting")
	_expect_true(first_button.text.contains("Stars: 0/3"), "level select keeps star text")
	_expect_false(_contains_old_level_name(first_button.text), "level select omits old location names")

	screen.queue_free()


func _contains_old_level_name(value: String) -> bool:
	var old_level_names := [
		"%s %s" % ["Training", "Yard"],
		"%s %s" % ["Slime", "Trail"],
		"%s %s" % ["Scout", "Post"],
		"%s %s" % ["Fighter", "Camp"],
		"%s %s" % ["Armored", "Watch"],
		"%s %s" % ["Wild", "Path"],
		"%s %s" % ["Bandit", "Road"],
		"%s %s" % ["Brute", "Cave"],
		"%s %s" % ["Shaman", "Hollow"],
		"%s%s" % ["Gate", "keeper"],
	]
	for old_name in old_level_names:
		if value.contains(old_name):
			return true
	return false


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
