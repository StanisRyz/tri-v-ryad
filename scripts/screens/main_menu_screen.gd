extends Control

signal play_pressed
signal heroes_pressed

@onready var play_button: Button = %PlayButton
@onready var heroes_button: Button = %HeroesButton


func _ready() -> void:
	play_button.pressed.connect(_on_play_button_pressed)
	heroes_button.pressed.connect(_on_heroes_button_pressed)


func _on_play_button_pressed() -> void:
	play_pressed.emit()


func _on_heroes_button_pressed() -> void:
	heroes_pressed.emit()
