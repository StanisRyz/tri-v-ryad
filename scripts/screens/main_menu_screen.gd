extends Control

signal play_pressed
signal heroes_pressed
signal settings_pressed

@onready var play_button: Button = %PlayButton
@onready var heroes_button: Button = %HeroesButton
@onready var settings_button: Button = %SettingsButton


func _ready() -> void:
	play_button.pressed.connect(_on_play_button_pressed)
	heroes_button.pressed.connect(_on_heroes_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)


func _on_play_button_pressed() -> void:
	play_pressed.emit()


func _on_heroes_button_pressed() -> void:
	heroes_pressed.emit()


func _on_settings_button_pressed() -> void:
	settings_pressed.emit()
