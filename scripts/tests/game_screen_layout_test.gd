extends SceneTree

const GAME_SCREEN := preload("res://scenes/screens/GameScreen.tscn")
const LEVEL_LABEL_FORMATTER := preload("res://scripts/game/config/level_label_formatter.gd")

var _failures := 0


func _initialize() -> void:
	print("Running game screen layout test...")
	_run()


func _run() -> void:
	var screen := GAME_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame

	var enemy_panel := screen.get_node("%EnemyPanel") as Control
	var battle_hud := screen.get_node("%BattleHud") as Control
	var menu_button := screen.get_node("%MenuButton") as Button
	var board_view := screen.get_node("%BoardView") as Control
	var status_label := screen.get_node("%StatusLabel") as Label
	var hero_party_panel := screen.get_node("%HeroPartyPanel") as Control
	var result_overlay := screen.get_node("%BattleResultOverlay") as Control
	var background_rect := screen.get_node("%Background") as ColorRect
	var background_texture := screen.get_node("%BackgroundTexture") as TextureRect
	var round_modifier_panel := screen.get_node("%RoundModifierPanel") as Control
	var modifier_name_label := screen.get_node("%ModifierNameLabel") as Label
	var modifier_description_label := screen.get_node("%ModifierDescriptionLabel") as Label

	_expect_true(enemy_panel != null, "game screen has EnemyPanel")
	_expect_true(battle_hud != null, "game screen has BattleHud")
	_expect_true(menu_button != null, "game screen has MenuButton")
	_expect_true(board_view != null, "game screen has BoardView")
	_expect_true(status_label != null, "game screen has StatusLabel")
	_expect_true(hero_party_panel != null, "game screen has HeroPartyPanel")
	_expect_true(not hero_party_panel.visible, "hero party panel is hidden while hero systems are frozen")
	_expect_true(result_overlay != null, "game screen has BattleResultOverlay")
	_expect_true(background_rect != null, "game screen has background layer")
	_expect_true(background_texture != null, "game screen has background texture layer")
	_expect_true(round_modifier_panel != null, "game screen has RoundModifierPanel")
	_expect_true(round_modifier_panel.visible, "round modifier panel is visible once a battle starts")
	_expect_true(modifier_name_label.text != "", "round modifier panel shows a modifier name")
	_expect_true(modifier_description_label.text != "", "round modifier panel shows a modifier description")
	_expect_equal(background_rect.mouse_filter, Control.MOUSE_FILTER_IGNORE, "background layer does not block input")
	_expect_true(background_rect.get_index() < result_overlay.get_index(), "background layer stays behind result overlay")

	if enemy_panel != null and battle_hud != null and menu_button != null and board_view != null and status_label != null and hero_party_panel != null:
		var battle_root := screen.get_node("%BattleRoot")
		_expect_equal(battle_root.get_child(0), enemy_panel, "enemy panel is first in BattleRoot")
		_expect_equal(battle_root.get_child(1), battle_hud.get_parent(), "HUD row is directly below enemy panel")
		_expect_equal(battle_hud.get_parent(), menu_button.get_parent(), "battle HUD and menu share one row")
		_expect_true(enemy_panel.get_index() < battle_hud.get_parent().get_index(), "enemy appears above HUD row")
		_expect_true(battle_hud.get_parent().get_index() < board_view.get_parent().get_index(), "HUD row appears above board area")
		_expect_true(board_view.get_parent().get_index() < status_label.get_index(), "board area appears above status label")
		_expect_true(status_label.get_index() < hero_party_panel.get_index(), "status label appears above hero party panel")

	_expect_equal(board_view.custom_minimum_size, Vector2(664, 664), "portrait board remains widened and square")
	_expect_equal(hero_party_panel.custom_minimum_size.x, board_view.custom_minimum_size.x, "hero panel remains aligned to board width")

	screen.set_level_id("level_1")
	await process_frame
	var level_label := battle_hud.get_node("%LevelLabel") as Label
	_expect_equal(level_label.text, "Level 1", "battle HUD uses shared compact level label")
	_expect_equal(LEVEL_LABEL_FORMATTER.format_level_label("level_10", "Gatekeeper"), "Level 10", "level_10 formats as Level 10")
	_expect_equal(LEVEL_LABEL_FORMATTER.format_level_label("boss_intro", "Boss Intro"), "Boss Intro", "unexpected level ids use fallback display name")

	var menu_signals: Array = []
	screen.back_pressed.connect(func(): menu_signals.append(true))
	menu_button.pressed.emit()
	_expect_equal(menu_signals.size(), 1, "menu button still emits back_pressed")

	var enemy_config = load("res://scripts/game/config/enemy_config.gd").goblin_scout()
	var enemy_data = enemy_config.to_enemy_data()
	var enemy_intent = enemy_config.to_enemy_intent()
	enemy_panel.set_enemy_state(enemy_data, enemy_intent)
	await process_frame
	var enemy_name_label := enemy_panel.get_node("%EnemyNameLabel") as Label
	var enemy_hp_label := enemy_panel.get_node("%EnemyHpLabel") as Label
	var enemy_hp_bar := enemy_panel.get_node("%EnemyHpBar") as ProgressBar
	var enemy_intent_label := enemy_panel.get_node("%EnemyIntentLabel") as Label
	var enemy_target_label := enemy_panel.get_node("%EnemyTargetLabel") as Label
	_expect_equal(enemy_name_label.text, "Goblin Scout", "enemy panel shows enemy name")
	_expect_true(enemy_hp_label.text.find(str(enemy_data.max_hp)) != -1, "enemy panel shows HP text")
	_expect_equal(enemy_hp_bar.value, 1.0, "enemy panel HP bar reflects full health")
	_expect_equal(enemy_intent_label.text, "Goal: defeat enemy | Enemy does not attack", "enemy panel shows direct-mode enemy copy")
	_expect_equal(enemy_target_label.text, "Match crystals to deal damage", "enemy panel avoids hero-target copy in direct mode")

	enemy_panel.set_enemy_state(null, null)
	await process_frame
	_expect_true(enemy_hp_label.text.find("--") != -1, "enemy panel handles null enemy state safely")

	screen.queue_free()

	if _failures == 0:
		print("Game screen layout test passed.")
		quit(0)
	else:
		push_error("Game screen layout test failed: %d" % _failures)
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
