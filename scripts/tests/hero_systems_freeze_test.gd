extends SceneTree

const APP_SCENE := preload("res://scenes/app/App.tscn")
const MAIN_MENU_SCREEN := preload("res://scenes/screens/MainMenuScreen.tscn")
const GAME_SCREEN := preload("res://scenes/screens/GameScreen.tscn")
const TEAM_SELECT_SCREEN := preload("res://scenes/screens/TeamSelectScreen.tscn")
const PROGRESS_MANAGER_SCRIPT := preload("res://scripts/game/progression/progress_manager.gd")
const SAVE_MANAGER_SCRIPT := preload("res://scripts/game/save/save_manager.gd")

const TEST_SAVE_PATH := "user://test_hero_systems_freeze_save_v1.json"
const TEST_TEMP_SAVE_PATH := "user://test_hero_systems_freeze_save_v1.tmp"

var _failures := 0


func _initialize() -> void:
	print("Running hero systems freeze tests...")
	_run()


func _run() -> void:
	_cleanup()
	_test_feature_flag_defaults()
	await _test_level_select_opens_game_screen_directly()
	await _test_heroes_button_hidden_in_main_menu()
	await _test_hero_party_panel_hidden_in_game_screen()
	_test_enemy_attack_does_not_crash_without_heroes()
	_test_hero_abilities_not_required_for_battle()
	_test_victory_and_defeat_still_resolve()
	_test_hero_upgrades_do_not_affect_direct_damage()
	await _test_stars_and_progression_saved_on_victory()
	_cleanup()

	if _failures == 0:
		print("Hero systems freeze tests passed.")
		quit(0)
	else:
		push_error("Hero systems freeze tests failed: %d" % _failures)
		quit(1)


func _test_feature_flag_defaults() -> void:
	_expect_true(not FeatureFlags.HERO_SYSTEMS_ENABLED, "hero systems are frozen by default")
	_expect_true(FeatureFlags.DIRECT_MATCH_DAMAGE_ENABLED, "direct match damage is enabled by default")
	print("ok - feature flag defaults match Stage 32 direction")


func _test_level_select_opens_game_screen_directly() -> void:
	var app := APP_SCENE.instantiate()
	root.add_child(app)
	await process_frame

	_expect_true(app._router._current_screen is Control, "app shows a screen after Play is pressed")
	_expect_true(app._router._current_screen.get_scene_file_path() == "res://scenes/screens/LevelSelectScreen.tscn", "app starts on level select")

	app._on_level_selected("level_2")
	await process_frame
	_expect_true(app._router._current_screen.get_scene_file_path() == "res://scenes/screens/GameScreen.tscn", "level select opens game screen directly")
	_expect_true(app._router._current_screen.get_scene_file_path() != TEAM_SELECT_SCREEN.resource_path, "team select is skipped in the active play flow")

	app.queue_free()


func _test_heroes_button_hidden_in_main_menu() -> void:
	var screen := MAIN_MENU_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame

	var heroes_button := screen.get_node("%HeroesButton") as Button
	_expect_true(not heroes_button.visible, "heroes/upgrade entry is hidden from the active main menu")

	screen.queue_free()


func _test_hero_party_panel_hidden_in_game_screen() -> void:
	var screen := GAME_SCREEN.instantiate()
	root.add_child(screen)
	await process_frame

	var hero_party_panel := screen.get_node("%HeroPartyPanel") as Control
	_expect_true(not hero_party_panel.visible, "hero party panel is hidden in direct match mode")

	screen.queue_free()


func _test_enemy_attack_does_not_crash_without_heroes() -> void:
	var heroes: Array[HeroData] = []
	var enemy := EnemyData.new("enemy_training", "Training Enemy", 300, 20)
	var enemy_intent := EnemyIntent.new(1, 0)
	var state := BattleState.new(heroes, enemy, enemy_intent, 20)
	var matches: Array[MatchResult] = [_match([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])]

	var result := BattleResolver.new().resolve_player_matches(state, matches)

	_expect_true(not result.enemy_action.get("acted", false), "enemy action does not run without heroes in direct mode")
	_expect_equal(result.total_damage_to_enemy, 3, "direct damage still applies without any heroes present")
	print("ok - enemy attack does not crash when heroes are absent")


func _test_hero_abilities_not_required_for_battle() -> void:
	var state := BattleTestFactory.create_default_state()
	var matches: Array[MatchResult] = [_match([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])]

	var result := BattleResolver.new().resolve_player_matches(state, matches)

	_expect_true(result.ability_charge_events.is_empty(), "no ability charge events occur in direct match mode")
	_expect_equal(result.total_damage_to_enemy, 3, "battle proceeds using direct damage without hero abilities")
	print("ok - hero abilities are not required for battle to proceed")


func _test_victory_and_defeat_still_resolve() -> void:
	var resolver := BattleResolver.new()

	var victory_heroes: Array[HeroData] = []
	var weak_enemy := EnemyData.new("enemy_weak", "Weak Enemy", 3, 5)
	var victory_state := BattleState.new(victory_heroes, weak_enemy, EnemyIntent.new(10, 0), 20)
	var matches: Array[MatchResult] = [_match([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])]
	resolver.resolve_player_matches(victory_state, matches)
	_expect_equal(victory_state.status, BattleState.Status.VICTORY, "victory triggers when enemy hp reaches zero")

	var defeat_heroes: Array[HeroData] = []
	var tough_enemy := EnemyData.new("enemy_tough", "Tough Enemy", 999, 5)
	var defeat_state := BattleState.new(defeat_heroes, tough_enemy, EnemyIntent.new(10, 0), 1)
	resolver.resolve_player_matches(defeat_state, matches)
	_expect_equal(defeat_state.status, BattleState.Status.DEFEAT, "defeat triggers when moves reach zero and enemy survives")

	print("ok - victory and defeat still resolve without hero systems")


func _test_hero_upgrades_do_not_affect_direct_damage() -> void:
	var upgraded_heroes: Array[HeroData] = [
		HeroData.new("hero_1", "Hero 1", 0, 999, 100, 10, 10, 10),
	]
	var enemy := EnemyData.new("enemy_training", "Training Enemy", 300, 20)
	var state := BattleState.new(upgraded_heroes, enemy, EnemyIntent.new(10, 0), 20)
	var matches: Array[MatchResult] = [_match([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)])]

	var result := BattleResolver.new().resolve_player_matches(state, matches)

	_expect_equal(result.total_damage_to_enemy, 3, "heavily upgraded hero attack stats do not change direct match damage")

	var red_x3 = load("res://scripts/game/config/round_modifier_config.gd").new("red_x3", "Red Surge", "Red crystals deal x3 damage", {TileType.RED: 3.0})
	var modified_resolver := BattleResolver.new()
	modified_resolver.set_round_modifier(red_x3)
	var modified_result := modified_resolver.resolve_player_matches(state, matches)
	_expect_equal(modified_result.total_damage_to_enemy, 9, "round modifier damage is unaffected by hero upgrade stats")
	print("ok - hero upgrades do not affect direct match damage")


func _test_stars_and_progression_saved_on_victory() -> void:
	var progress_manager = _make_progress_manager()
	var level_catalog = load("res://scripts/game/config/level_catalog.gd").new()
	var level_config = level_catalog.get_level("level_1")

	var state = progress_manager.complete_level(level_config, level_config.moves)

	_expect_true(state != null, "victory saves level completion state")
	_expect_true(progress_manager.is_level_completed("level_1"), "level 1 is marked completed on victory")
	_expect_true(progress_manager.get_level_stars("level_1") > 0, "stars are awarded on victory")
	_expect_true(progress_manager.is_level_unlocked(level_catalog, "level_2"), "next level unlocks after completion")

	await process_frame
	print("ok - stars and progression are preserved on victory")


func _match(raw_cells: Array, direction: MatchResult.Direction = MatchResult.Direction.HORIZONTAL) -> MatchResult:
	var cells: Array[Vector2i] = []
	for cell in raw_cells:
		cells.append(cell)
	return MatchResult.new(cells, TileType.RED, direction)


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


func _expect_equal(actual, expected, message: String) -> void:
	if actual == expected:
		return

	_failures += 1
	push_error("FAILED: %s | expected=%s actual=%s" % [message, expected, actual])
