extends Control

const MAIN_MENU_SCREEN := preload("res://scenes/screens/MainMenuScreen.tscn")
const LEVEL_SELECT_SCREEN := preload("res://scenes/screens/LevelSelectScreen.tscn")
const GAME_SCREEN := preload("res://scenes/screens/GameScreen.tscn")

@onready var screen_host: Control = %ScreenHost

var _router: ScreenRouter


func _ready() -> void:
	_router = ScreenRouter.new(screen_host)
	_show_main_menu()


func _show_main_menu() -> void:
	var screen := _router.change_screen(MAIN_MENU_SCREEN)
	screen.play_pressed.connect(_on_main_menu_play_pressed)


func _show_level_select() -> void:
	var screen := _router.change_screen(LEVEL_SELECT_SCREEN)
	screen.level_selected.connect(_on_level_selected)
	screen.back_pressed.connect(_on_level_select_back_pressed)


func _show_game_screen(level_id: String) -> void:
	var screen := _router.change_screen(GAME_SCREEN)
	if screen.has_method("set_level_id"):
		screen.set_level_id(level_id)
	screen.back_pressed.connect(_on_game_back_pressed)


func _on_main_menu_play_pressed() -> void:
	_show_level_select()


func _on_level_selected(level_id: String) -> void:
	_show_game_screen(level_id)


func _on_level_select_back_pressed() -> void:
	_show_main_menu()


func _on_game_back_pressed() -> void:
	_show_level_select()
