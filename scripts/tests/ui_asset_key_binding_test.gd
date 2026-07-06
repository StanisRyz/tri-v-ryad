extends SceneTree

const LEVEL_SELECT_SCREEN := preload("res://scenes/screens/LevelSelectScreen.tscn")
const SETTINGS_SCREEN := preload("res://scenes/screens/SettingsScreen.tscn")
const GAME_ASSET_CATALOG := preload("res://scripts/game/config/game_asset_catalog.gd")

var _failures := 0


func _initialize() -> void:
	print("Running UI asset key binding test...")
	_run()


func _run() -> void:
	GAME_ASSET_CATALOG.clear_texture_cache()
	await _test_level_select_bindings()
	await _test_settings_bindings()

	if _failures == 0:
		print("UI asset key binding test passed.")
		quit(0)
	else:
		push_error("UI asset key binding test failed: %d" % _failures)
		quit(1)


func _test_level_select_bindings() -> void:
	var screen := LEVEL_SELECT_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame

	var background := screen.get_node("%Background") as ImageSlot
	var root_panel := screen.get_node("%Root") as Control
	var zone_selector := screen.get_node("%ZoneSelector") as OptionButton
	var level_buttons := screen.get_node("%LevelButtons") as VBoxContainer

	_expect_equal(background.get_asset_key(), "ui_level_select_background", "LevelSelect background ImageSlot receives asset key")
	_expect_false(background.has_texture(), "missing LevelSelect background keeps placeholder")
	_expect_equal(root_panel.get_meta("asset_key"), "ui_level_select_panel", "LevelSelect panel has asset key")
	_expect_equal(zone_selector.get_meta("asset_key"), "ui_zone_selector_panel", "zone selector has asset key")
	_expect_true(level_buttons.get_child_count() > 0, "LevelSelect creates level buttons")
	var first_button := level_buttons.get_child(0) as Button
	_expect_equal(first_button.get_meta("asset_key"), "ui_level_button_open", "first level button has open asset key")
	_expect_equal(first_button.get_meta("star_asset_keys"), ["ui_star_empty", "ui_star_empty", "ui_star_empty"], "level stars have empty asset keys")
	screen.queue_free()
	print("ok - LevelSelect asset bindings are safe")


func _test_settings_bindings() -> void:
	var screen := SETTINGS_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame

	var background := screen.get_node("%Background") as ImageSlot
	var toggles_panel := screen.get_node("%TogglesPanel") as Control
	var animations_toggle := screen.get_node("%AnimationsToggle") as CheckButton

	_expect_equal(background.get_asset_key(), "ui_settings_background", "Settings background ImageSlot receives asset key")
	_expect_false(background.has_texture(), "missing Settings background keeps placeholder")
	_expect_equal(toggles_panel.get_meta("asset_key"), "ui_settings_panel", "Settings panel has asset key")
	_expect_equal(animations_toggle.get_meta("asset_key"), "ui_toggle_off", "toggle starts with off asset key without manager")

	animations_toggle.button_pressed = true
	animations_toggle.toggled.emit(true)
	await process_frame
	_expect_equal(animations_toggle.get_meta("asset_key"), "ui_toggle_off", "toggle binding stays safe without manager")

	screen.queue_free()
	print("ok - Settings asset bindings are safe")


func _expect_false(value: bool, message: String) -> void:
	_expect_true(not value, message)


func _expect_true(value: bool, message: String) -> void:
	if value:
		return

	_failures += 1
	push_error("FAILED: %s" % message)


func _expect_equal(actual, expected, message: String) -> void:
	if actual == expected:
		return

	_failures += 1
	push_error("FAILED: %s | expected=%s actual=%s" % [message, expected, actual])
