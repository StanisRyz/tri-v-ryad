extends Control

const MAIN_MENU_SCREEN := preload("res://scenes/screens/MainMenuScreen.tscn")
const LEVEL_SELECT_SCREEN := preload("res://scenes/screens/LevelSelectScreen.tscn")
const GAME_SCREEN := preload("res://scenes/screens/GameScreen.tscn")
const UPGRADE_SCREEN := preload("res://scenes/screens/UpgradeScreen.tscn")
const TEAM_SELECT_SCREEN := preload("res://scenes/screens/TeamSelectScreen.tscn")
const SETTINGS_SCREEN := preload("res://scenes/screens/SettingsScreen.tscn")
const SHOP_PLACEHOLDER_SCREEN := preload("res://scenes/screens/ShopPlaceholderScreen.tscn")
const PROGRESS_MANAGER_SCRIPT := preload("res://scripts/game/progression/progress_manager.gd")
const SETTINGS_MANAGER_SCRIPT := preload("res://scripts/game/settings/settings_manager.gd")
const LEVEL_CATALOG_SCRIPT := preload("res://scripts/game/config/level_catalog.gd")
const PLAY_LEVEL_RESOLVER_SCRIPT := preload("res://scripts/game/progression/play_level_resolver.gd")

@onready var screen_host: Control = %ScreenHost

var _router: ScreenRouter
var _progress_manager
var _settings_manager
var _level_catalog
var _play_level_resolver
var _settings_return_screen := "main_menu"


func _ready() -> void:
	_router = ScreenRouter.new(screen_host)
	_progress_manager = PROGRESS_MANAGER_SCRIPT.new()
	_progress_manager.load()
	_settings_manager = SETTINGS_MANAGER_SCRIPT.new()
	_settings_manager.load()
	_level_catalog = LEVEL_CATALOG_SCRIPT.new()
	_play_level_resolver = PLAY_LEVEL_RESOLVER_SCRIPT.new()
	_apply_audio_settings()
	_show_main_menu()


func _show_main_menu() -> void:
	var screen := _router.change_screen(MAIN_MENU_SCREEN)
	screen.play_pressed.connect(_on_main_menu_play_pressed)
	screen.level_select_pressed.connect(_on_main_menu_level_select_pressed)
	screen.shop_pressed.connect(_on_main_menu_shop_pressed)
	screen.heroes_pressed.connect(_on_upgrades_pressed)
	screen.settings_pressed.connect(_on_main_menu_settings_pressed)


func _show_level_select() -> void:
	var screen := _router.change_screen(LEVEL_SELECT_SCREEN)
	if screen.has_method("set_progress_manager"):
		screen.set_progress_manager(_progress_manager)
	if screen.has_method("set_settings_manager"):
		screen.set_settings_manager(_settings_manager)
	if screen.has_method("refresh_progress_state"):
		screen.refresh_progress_state()
	screen.level_selected.connect(_on_level_selected)
	screen.back_pressed.connect(_on_level_select_back_pressed)
	screen.settings_pressed.connect(_on_level_select_settings_pressed)


func _show_shop_placeholder() -> void:
	var screen := _router.change_screen(SHOP_PLACEHOLDER_SCREEN)
	screen.back_pressed.connect(_on_shop_placeholder_back_pressed)


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
	var level_id: String = _play_level_resolver.resolve_play_level_id(_progress_manager, _level_catalog)
	_show_game_screen(level_id)


func _on_main_menu_level_select_pressed() -> void:
	_show_level_select()


func _on_main_menu_shop_pressed() -> void:
	_show_shop_placeholder()


func _on_main_menu_settings_pressed() -> void:
	_settings_return_screen = "main_menu"
	_show_settings_screen()


func _on_level_select_settings_pressed() -> void:
	_settings_return_screen = "level_select"
	_show_settings_screen()


func _on_level_selected(level_id: String) -> void:
	# Stage 32: hero systems are frozen, so LevelSelect opens GameScreen directly.
	# _show_team_select_screen remains available for a future hero-systems revisit.
	_show_game_screen(level_id)


func _on_team_start_battle_pressed(level_id: String) -> void:
	_show_game_screen(level_id)


func _on_upgrades_pressed() -> void:
	_show_upgrade_screen()


func _on_level_select_back_pressed() -> void:
	_show_main_menu()


func _on_shop_placeholder_back_pressed() -> void:
	_show_main_menu()


func _on_game_back_pressed() -> void:
	_show_level_select()


func _on_upgrade_back_pressed() -> void:
	_show_main_menu()


func _on_team_select_back_pressed() -> void:
	_show_level_select()


func _on_settings_back_pressed() -> void:
	if _settings_return_screen == "level_select":
		_show_level_select()
	else:
		_show_main_menu()


func _apply_audio_settings() -> void:
	if _settings_manager == null:
		return

	var settings: PlayerSettings = _settings_manager.get_settings()
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager == null:
		return
	audio_manager.set_music_enabled(settings.music_enabled)
	audio_manager.set_sound_effects_enabled(settings.sound_effects_enabled)
