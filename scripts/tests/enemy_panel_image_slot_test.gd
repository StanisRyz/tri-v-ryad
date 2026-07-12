extends SceneTree

const ENEMY_PANEL := preload("res://scenes/ui/EnemyPanel.tscn")
const ENEMY_CONFIG := preload("res://scripts/game/config/enemy_config.gd")

var _failures := 0


func _initialize() -> void:
	print("Running enemy panel image slot tests...")
	_run()


func _run() -> void:
	var panel := ENEMY_PANEL.instantiate()
	root.add_child(panel)
	await process_frame

	var image_slot := panel.get_node("%EnemyImageSlot") as ImageSlot
	_expect_true(image_slot != null, "EnemyPanel has EnemyImageSlot")
	_expect_equal(image_slot.mouse_filter, Control.MOUSE_FILTER_IGNORE, "EnemyImageSlot ignores input")
	_expect_false(image_slot.has_texture(), "EnemyImageSlot starts without texture")

	var enemy_config = ENEMY_CONFIG.enemy_3()
	panel.set_enemy_state(enemy_config.to_enemy_data(), enemy_config.to_enemy_intent())
	await process_frame
	_expect_equal(image_slot.get_asset_key(), "enemy_3_normal", "enemy id maps to expected asset key")
	_expect_false(image_slot.has_texture(), "missing enemy image stays placeholder")

	panel.set_enemy_state(null, null)
	await process_frame
	_expect_equal(image_slot.get_asset_key(), "", "null enemy clears enemy asset key")
	_expect_false(image_slot.has_texture(), "null enemy keeps placeholder safe")

	panel.queue_free()

	if _failures == 0:
		print("Enemy panel image slot tests passed.")
		quit(0)
	else:
		push_error("Enemy panel image slot tests failed: %d" % _failures)
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
