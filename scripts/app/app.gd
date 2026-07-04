extends Control

const MAIN_MENU_SCREEN := preload("res://scenes/screens/MainMenuScreen.tscn")
const GAME_SCREEN := preload("res://scenes/screens/GameScreen.tscn")

@onready var screen_host: Control = %ScreenHost

var _router: ScreenRouter


func _ready() -> void:
	_router = ScreenRouter.new(screen_host)
	_show_main_menu()


func _show_main_menu() -> void:
	var screen := _router.change_screen(MAIN_MENU_SCREEN)
	screen.play_pressed.connect(_on_main_menu_play_pressed)


func _show_game_screen() -> void:
	var screen := _router.change_screen(GAME_SCREEN)
	screen.back_pressed.connect(_on_game_back_pressed)


func _on_main_menu_play_pressed() -> void:
	_show_game_screen()


func _on_game_back_pressed() -> void:
	_show_main_menu()
