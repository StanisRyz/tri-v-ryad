extends SceneTree

const CONTROLLER_SCRIPT := "res://scripts/game/view/battle_effect_controller.gd"
const BOARD_VIEW_SCENE := preload("res://scenes/game/BoardView.tscn")
const ENEMY_PANEL_SCENE := preload("res://scenes/ui/EnemyPanel.tscn")

var _failures := 0
var _callback_count := 0


func _initialize() -> void:
	print("Running battle effect controller tests...")
	_run()


func _run() -> void:
	await _test_disabled_calls_callback_immediately()
	await _test_empty_events_calls_callback_immediately()
	_test_missing_nodes_call_callback_safely()
	await _test_particles_play_and_clean_up()
	_test_reduced_motion_caps_fewer_particles()
	_finish()


func _test_disabled_calls_callback_immediately() -> void:
	_callback_count = 0
	var controller = load(CONTROLLER_SCRIPT).new()
	controller.configure_settings(false, false)
	var board_view := BOARD_VIEW_SCENE.instantiate()
	var enemy_panel := ENEMY_PANEL_SCENE.instantiate()
	var effect_layer := Control.new()
	root.add_child(board_view)
	root.add_child(enemy_panel)
	root.add_child(effect_layer)
	await process_frame

	controller.play_damage_particles([_event(Vector2i(0, 0), 3)], board_view, enemy_panel, effect_layer, Callable(self, "_on_callback"))
	_expect_equal(_callback_count, 1, "animations disabled calls callback immediately")
	_expect_false(controller.is_playing(), "animations disabled does not stay playing")

	board_view.free()
	enemy_panel.free()
	effect_layer.free()


func _test_empty_events_calls_callback_immediately() -> void:
	_callback_count = 0
	var controller = load(CONTROLLER_SCRIPT).new()
	controller.configure_settings(true, false)
	var board_view := BOARD_VIEW_SCENE.instantiate()
	var enemy_panel := ENEMY_PANEL_SCENE.instantiate()
	var effect_layer := Control.new()
	root.add_child(board_view)
	root.add_child(enemy_panel)
	root.add_child(effect_layer)
	await process_frame

	controller.play_damage_particles([], board_view, enemy_panel, effect_layer, Callable(self, "_on_callback"))
	_expect_equal(_callback_count, 1, "empty events calls callback immediately")

	board_view.free()
	enemy_panel.free()
	effect_layer.free()


func _test_missing_nodes_call_callback_safely() -> void:
	_callback_count = 0
	var controller = load(CONTROLLER_SCRIPT).new()
	controller.configure_settings(true, false)
	controller.play_damage_particles([_event(Vector2i(0, 0), 3)], null, null, null, Callable(self, "_on_callback"))
	_expect_equal(_callback_count, 1, "missing board_view/enemy_panel/effect_layer calls callback safely")
	_expect_false(controller.is_playing(), "missing nodes leave controller not playing")


func _test_particles_play_and_clean_up() -> void:
	_callback_count = 0
	var controller = load(CONTROLLER_SCRIPT).new()
	controller.configure_settings(true, false)
	var board_view := BOARD_VIEW_SCENE.instantiate()
	var enemy_panel := ENEMY_PANEL_SCENE.instantiate()
	var effect_layer := Control.new()
	root.add_child(board_view)
	root.add_child(enemy_panel)
	root.add_child(effect_layer)
	await process_frame

	var events := [_event(Vector2i(0, 0), 2), _event(Vector2i(1, 0), 1)]
	controller.play_damage_particles(events, board_view, enemy_panel, effect_layer, Callable(self, "_on_callback"))
	await process_frame
	_expect_true(controller.is_playing(), "controller is playing while particles travel")
	_expect_true(effect_layer.get_child_count() > 0, "particle nodes are spawned")

	await create_timer(0.6).timeout
	_expect_equal(_callback_count, 1, "callback is called exactly once")
	_expect_false(controller.is_playing(), "controller finishes playing")
	_expect_equal(effect_layer.get_child_count(), 0, "temporary particle nodes are cleaned up")

	board_view.free()
	enemy_panel.free()
	effect_layer.free()


func _test_reduced_motion_caps_fewer_particles() -> void:
	var controller = load(CONTROLLER_SCRIPT).new()
	var many_events: Array = []
	for i in range(30):
		many_events.append(_event(Vector2i(i % 9, int(i / 9.0)), 1))

	controller.configure_settings(true, false)
	var normal_capped: Array = controller.cap_events(many_events)
	_expect_true(normal_capped.size() <= 16, "normal mode caps particle count at 16")

	controller.configure_settings(true, true)
	var reduced_capped: Array = controller.cap_events(many_events)
	_expect_true(reduced_capped.size() <= 6, "reduced motion caps particle count at 6")
	_expect_true(reduced_capped.size() <= normal_capped.size(), "reduced motion caps fewer particles than normal mode")


func _event(cell: Vector2i, damage: int) -> Dictionary:
	return {
		"cell": cell,
		"tile_type": TileType.RED,
		"damage": damage,
		"multiplier": 1.0,
		"is_boosted": false,
		"source": "test",
	}


func _on_callback() -> void:
	_callback_count += 1


func _finish() -> void:
	if _failures == 0:
		print("Battle effect controller tests passed.")
		quit(0)
	else:
		push_error("Battle effect controller tests failed: %d" % _failures)
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
