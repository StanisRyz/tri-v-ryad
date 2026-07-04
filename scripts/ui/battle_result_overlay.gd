extends PanelContainer
class_name BattleResultOverlay

signal restart_pressed
signal menu_pressed
signal upgrades_pressed

@onready var result_label: Label = %ResultLabel
@onready var reward_label: Label = %RewardLabel
@onready var restart_button: Button = %RestartButton
@onready var upgrades_button: Button = %UpgradesButton
@onready var menu_button: Button = %ResultMenuButton


func _ready() -> void:
	restart_button.pressed.connect(_on_restart_button_pressed)
	upgrades_button.pressed.connect(_on_upgrades_button_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)
	hide_result()


func show_victory(reward_points: int = 0) -> void:
	result_label.text = "Victory"
	reward_label.text = "Reward: +%d upgrade points" % max(0, reward_points)
	upgrades_button.visible = true
	upgrades_button.disabled = false
	visible = true


func show_defeat() -> void:
	result_label.text = "Defeat"
	reward_label.text = "No reward"
	upgrades_button.visible = false
	upgrades_button.disabled = true
	visible = true


func hide_result() -> void:
	visible = false


func _on_restart_button_pressed() -> void:
	restart_pressed.emit()


func _on_upgrades_button_pressed() -> void:
	upgrades_pressed.emit()


func _on_menu_button_pressed() -> void:
	menu_pressed.emit()
