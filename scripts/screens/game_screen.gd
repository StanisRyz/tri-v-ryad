extends Control

signal back_pressed

@onready var menu_button: Button = %MenuButton


func _ready() -> void:
	menu_button.pressed.connect(_on_menu_button_pressed)


func _on_menu_button_pressed() -> void:
	back_pressed.emit()
