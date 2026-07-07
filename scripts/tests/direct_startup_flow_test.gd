extends SceneTree

const APP_SCENE := preload("res://scenes/app/App.tscn")
const MAIN_MENU_PATH := "res://scenes/screens/MainMenuScreen.tscn"
const LEVEL_SELECT_PATH := "res://scenes/screens/LevelSelectScreen.tscn"
const SETTINGS_PATH := "res://scenes/screens/SettingsScreen.tscn"
const GAME_SCREEN_PATH := "res://scenes/screens/GameScreen.tscn"
const SHOP_PLACEHOLDER_PATH := "res://scenes/screens/ShopPlaceholderScreen.tscn"

var _failures := 0


func _initialize() -> void:
	print("Running direct startup flow tests...")
	_run()


func _run() -> void:
	await _test_app_starts_on_main_menu()
	await _test_main_menu_level_select_round_trip()
	await _test_main_menu_shop_round_trip()
	await _test_main_menu_settings_round_trip()
	await _test_main_menu_play_opens_game_screen()
	await _test_level_select_opens_game_and_game_returns_to_level_select()

	if _failures == 0:
		print("Direct startup flow tests passed.")
		quit(0)
	else:
		push_error("Direct startup flow tests failed: %d" % _failures)
		quit(1)


func _test_app_starts_on_main_menu() -> void:
	var app: Node = APP_SCENE.instantiate()
	root.add_child(app)
	await process_frame

	_expect_equal(_current_screen_path(app), MAIN_MENU_PATH, "app starts on MainMenuScreen")
	_expect_true(_current_screen_path(app) != LEVEL_SELECT_PATH, "LevelSelectScreen is not shown at startup")

	app.queue_free()


func _test_main_menu_level_select_round_trip() -> void:
	var app: Node = APP_SCENE.instantiate()
	root.add_child(app)
	await process_frame

	app._router._current_screen.get_node("%LevelSelectButton").pressed.emit()
	await process_frame
	_expect_equal(_current_screen_path(app), LEVEL_SELECT_PATH, "Level select button opens LevelSelectScreen")

	app._router._current_screen.get_node("%BackButton").pressed.emit()
	await process_frame
	_expect_equal(_current_screen_path(app), MAIN_MENU_PATH, "LevelSelect Back returns to MainMenuScreen")

	app.queue_free()


func _test_main_menu_shop_round_trip() -> void:
	var app: Node = APP_SCENE.instantiate()
	root.add_child(app)
	await process_frame

	app._router._current_screen.get_node("%ShopButton").pressed.emit()
	await process_frame
	_expect_equal(_current_screen_path(app), SHOP_PLACEHOLDER_PATH, "Shop button opens ShopPlaceholderScreen")

	app._router._current_screen.get_node("%BackButton").pressed.emit()
	await process_frame
	_expect_equal(_current_screen_path(app), MAIN_MENU_PATH, "ShopPlaceholder Back returns to MainMenuScreen")

	app.queue_free()


func _test_main_menu_settings_round_trip() -> void:
	var app: Node = APP_SCENE.instantiate()
	root.add_child(app)
	await process_frame

	app._router._current_screen.get_node("%SettingsButton").pressed.emit()
	await process_frame
	_expect_equal(_current_screen_path(app), SETTINGS_PATH, "Settings button opens SettingsScreen")

	app._router._current_screen.get_node("%BackButton").pressed.emit()
	await process_frame
	_expect_equal(_current_screen_path(app), MAIN_MENU_PATH, "Settings Back opened from MainMenu returns to MainMenuScreen")

	app.queue_free()


func _test_main_menu_play_opens_game_screen() -> void:
	var app: Node = APP_SCENE.instantiate()
	root.add_child(app)
	await process_frame

	app._router._current_screen.get_node("%PlayButton").pressed.emit()
	await process_frame
	_expect_equal(_current_screen_path(app), GAME_SCREEN_PATH, "Play button opens GameScreen for the resolved level")

	app.queue_free()


func _test_level_select_opens_game_and_game_returns_to_level_select() -> void:
	var app: Node = APP_SCENE.instantiate()
	root.add_child(app)
	await process_frame

	app._on_level_selected("level_1")
	await process_frame

	_expect_equal(_current_screen_path(app), GAME_SCREEN_PATH, "selecting an unlocked level opens GameScreen directly")
	_expect_true(not app._router._current_screen.get_node("%HeroPartyPanel").visible, "HeroPartyPanel remains hidden")
	_expect_true(app._router._current_screen.get_node("%RoundModifierPanel").visible, "RoundModifierPanel remains visible")

	app._router._current_screen.get_node("%MenuButton").pressed.emit()
	await process_frame
	_expect_equal(_current_screen_path(app), LEVEL_SELECT_PATH, "GameScreen menu returns to LevelSelectScreen")

	app.queue_free()


func _current_screen_path(app: Node) -> String:
	if app._router == null or app._router._current_screen == null:
		return ""
	return app._router._current_screen.get_scene_file_path()


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
