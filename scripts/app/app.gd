extends Control

const MAIN_MENU_SCREEN := preload("res://scenes/screens/MainMenuScreen.tscn")
const LEVEL_SELECT_SCREEN := preload("res://scenes/screens/LevelSelectScreen.tscn")
const GAME_SCREEN := preload("res://scenes/screens/GameScreen.tscn")
const UPGRADE_SCREEN := preload("res://scenes/screens/UpgradeScreen.tscn")
const TEAM_SELECT_SCREEN := preload("res://scenes/screens/TeamSelectScreen.tscn")
const SETTINGS_SCREEN := preload("res://scenes/screens/SettingsScreen.tscn")
const PROGRESS_MANAGER_SCRIPT := preload("res://scripts/game/progression/progress_manager.gd")
const SETTINGS_MANAGER_SCRIPT := preload("res://scripts/game/settings/settings_manager.gd")

@onready var screen_host: Control = %ScreenHost

var _router: ScreenRouter
var _progress_manager
var _settings_manager


func _ready() -> void:
	_router = ScreenRouter.new(screen_host)
	_progress_manager = PROGRESS_MANAGER_SCRIPT.new()
	_progress_manager.load()
	_settings_manager = SETTINGS_MANAGER_SCRIPT.new()
	_settings_manager.load()
	_show_main_menu()


func _show_main_menu() -> void:
	var screen := _router.change_screen(MAIN_MENU_SCREEN)
	screen.play_pressed.connect(_on_main_menu_play_pressed)
	screen.heroes_pressed.connect(_on_upgrades_pressed)
	screen.settings_pressed.connect(_on_settings_pressed)


func _show_level_select() -> void:
	var screen := _router.change_screen(LEVEL_SELECT_SCREEN)
	if screen.has_method("set_progress_manager"):
		screen.set_progress_manager(_progress_manager)
	if screen.has_method("set_settings_manager"):
		screen.set_settings_manager(_settings_manager)
	screen.level_selected.connect(_on_level_selected)
	screen.back_pressed.connect(_on_level_select_back_pressed)


func _show_game_screen(level_id: String) -> void:
	var screen := _router.change_screen(GAME_SCREEN)
	if screen.has_method("set_progress_manager"):
		screen.set_progress_manager(_progress_manager)
	if screen.has_method("set_settings_manager"):
		screen.set_settings_manager(_settings_manager)
	if screen.has_method("set_level_id"):
		screen.set_level_id(level_id)
	screen.back_pressed.connect(_on_game_back_pressed)
	screen.upgrades_pressed.connect(_on_upgrades_pressed)


func _show_upgrade_screen() -> void:
	var screen := _router.change_screen(UPGRADE_SCREEN)
	if screen.has_method("set_progress_manager"):
		screen.set_progress_manager(_progress_manager)
	if screen.has_method("set_settings_manager"):
		screen.set_settings_manager(_settings_manager)
	screen.back_pressed.connect(_on_upgrade_back_pressed)


func _show_team_select_screen(level_id: String) -> void:
	var screen := _router.change_screen(TEAM_SELECT_SCREEN)
	if screen.has_method("set_progress_manager"):
		screen.set_progress_manager(_progress_manager)
	if screen.has_method("set_settings_manager"):
		screen.set_settings_manager(_settings_manager)
	if screen.has_method("set_level_id"):
		screen.set_level_id(level_id)
	screen.back_pressed.connect(_on_team_select_back_pressed)
	screen.start_battle_pressed.connect(_on_team_start_battle_pressed)


func _show_settings_screen() -> void:
	var screen := _router.change_screen(SETTINGS_SCREEN)
	if screen.has_method("set_settings_manager"):
		screen.set_settings_manager(_settings_manager)
	screen.back_pressed.connect(_on_settings_back_pressed)


func _on_main_menu_play_pressed() -> void:
	_show_level_select()


func _on_level_selected(level_id: String) -> void:
	_show_team_select_screen(level_id)


func _on_team_start_battle_pressed(level_id: String) -> void:
	_show_game_screen(level_id)


func _on_upgrades_pressed() -> void:
	_show_upgrade_screen()


func _on_level_select_back_pressed() -> void:
	_show_main_menu()


func _on_game_back_pressed() -> void:
	_show_level_select()


func _on_upgrade_back_pressed() -> void:
	_show_main_menu()


func _on_team_select_back_pressed() -> void:
	_show_level_select()


func _on_settings_pressed() -> void:
	_show_settings_screen()


func _on_settings_back_pressed() -> void:
	_show_main_menu()
