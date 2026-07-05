extends SceneTree

const GAME_SCREEN := preload("res://scenes/screens/GameScreen.tscn")
const BATTLE_BACKGROUND_CATALOG := preload("res://scripts/game/config/battle_background_catalog.gd")

var _failures := 0


func _initialize() -> void:
	print("Running battle background asset integration tests...")
	_run()


func _run() -> void:
	var screen := GAME_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame

	var background_slot := screen.get_node("%Background") as ImageSlot
	_expect_true(background_slot != null, "GameScreen background is an ImageSlot")
	_expect_equal(background_slot.mouse_filter, Control.MOUSE_FILTER_IGNORE, "background ImageSlot ignores input")

	var catalog = BATTLE_BACKGROUND_CATALOG.new()
	var background_config = catalog.get_background("background_3")
	screen._on_battle_background_changed(background_config)
	await process_frame

	_expect_equal(background_slot.get_asset_key(), "background_3", "background ImageSlot receives selected asset key")
	_expect_equal(background_slot.color, background_config.placeholder_color, "missing background image shows selected placeholder color")
	_expect_false(background_slot.has_texture(), "missing background image does not create texture")

	screen.queue_free()

	if _failures == 0:
		print("Battle background asset integration tests passed.")
		quit(0)
	else:
		push_error("Battle background asset integration tests failed: %d" % _failures)
		quit(1)


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
