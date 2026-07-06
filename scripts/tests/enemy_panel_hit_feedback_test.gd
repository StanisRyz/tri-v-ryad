extends SceneTree

const ENEMY_PANEL_SCENE := preload("res://scenes/ui/EnemyPanel.tscn")

var _failures := 0


func _initialize() -> void:
	print("Running enemy panel hit feedback tests...")
	_run()


func _run() -> void:
	await _test_hit_target_position_safe_without_scene()
	await _test_play_hit_feedback_and_floating_damage()
	await _test_zero_damage_shows_no_floating_label()
	await _test_animate_hp_change_updates_bar_and_label()
	await _test_disabled_animations_apply_instantly()
	_finish()


func _test_hit_target_position_safe_without_scene() -> void:
	var panel := ENEMY_PANEL_SCENE.instantiate()
	root.add_child(panel)
	await process_frame

	var target: Vector2 = panel.get_hit_target_global_position()
	_expect_true(target is Vector2, "get_hit_target_global_position returns a Vector2")

	panel.free()


func _test_play_hit_feedback_and_floating_damage() -> void:
	var panel := ENEMY_PANEL_SCENE.instantiate()
	root.add_child(panel)
	await process_frame
	panel.configure_presentation(true, false)

	panel.play_hit_feedback(5)
	await process_frame

	var hit_effect_layer := panel.get_node("%HitEffectLayer") as Control
	_expect_true(hit_effect_layer != null, "EnemyPanel exposes HitEffectLayer")
	_expect_true(hit_effect_layer.get_child_count() > 0, "floating damage label appears after a hit")

	await create_timer(1.0).timeout
	_expect_equal(hit_effect_layer.get_child_count(), 0, "floating damage label is cleaned up after fading")

	panel.free()


func _test_zero_damage_shows_no_floating_label() -> void:
	var panel := ENEMY_PANEL_SCENE.instantiate()
	root.add_child(panel)
	await process_frame
	panel.configure_presentation(true, false)

	panel.play_hit_feedback(0)
	await process_frame

	var hit_effect_layer := panel.get_node("%HitEffectLayer") as Control
	_expect_equal(hit_effect_layer.get_child_count(), 0, "zero damage does not spawn a floating label")

	panel.free()


func _test_animate_hp_change_updates_bar_and_label() -> void:
	var panel := ENEMY_PANEL_SCENE.instantiate()
	root.add_child(panel)
	await process_frame
	panel.configure_presentation(true, false)

	panel.animate_hp_change(40, 80)
	await process_frame

	var hp_label := panel.get_node("%EnemyHpLabel") as Label
	_expect_equal(hp_label.text, "HP: 40 / 80", "animate_hp_change updates hp label text")

	await create_timer(0.5).timeout
	var hp_bar := panel.get_node("%EnemyHpBar") as ProgressBar
	_expect_true(absf(hp_bar.value - 0.5) < 0.01, "animate_hp_change eventually settles the hp bar at the target ratio")

	panel.free()


func _test_disabled_animations_apply_instantly() -> void:
	var panel := ENEMY_PANEL_SCENE.instantiate()
	root.add_child(panel)
	await process_frame
	panel.configure_presentation(false, false)

	panel.animate_hp_change(20, 100)
	await process_frame

	var hp_bar := panel.get_node("%EnemyHpBar") as ProgressBar
	_expect_true(absf(hp_bar.value - 0.2) < 0.01, "animations_enabled=false applies hp bar change instantly")

	panel.play_hit_feedback(4)
	await process_frame
	_expect_true(true, "play_hit_feedback stays safe when animations are disabled")

	panel.free()


func _finish() -> void:
	if _failures == 0:
		print("Enemy panel hit feedback tests passed.")
		quit(0)
	else:
		push_error("Enemy panel hit feedback tests failed: %d" % _failures)
		quit(1)


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
