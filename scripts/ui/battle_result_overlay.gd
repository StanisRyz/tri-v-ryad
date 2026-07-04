extends PanelContainer
class_name BattleResultOverlay

signal restart_pressed
signal menu_pressed

@onready var result_label: Label = %ResultLabel
@onready var restart_button: Button = %RestartButton
@onready var menu_button: Button = %ResultMenuButton


func _ready() -> void:
	restart_button.pressed.connect(_on_restart_button_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)
	hide_result()


func show_victory() -> void:
	result_label.text = "Victory"
	visible = true


func show_defeat() -> void:
	result_label.text = "Defeat"
	visible = true


func hide_result() -> void:
	visible = false


func _on_restart_button_pressed() -> void:
	restart_pressed.emit()


func _on_menu_button_pressed() -> void:
	menu_pressed.emit()
