extends PanelContainer
class_name BattleResultOverlay

signal restart_pressed
signal menu_pressed
signal upgrades_pressed

const UI_ASSET_BINDING_SCRIPT := preload("res://scripts/ui/ui_asset_binding.gd")

@onready var result_label: Label = %ResultLabel
@onready var reward_label: Label = %RewardLabel
@onready var stars_label: Label = %StarsLabel
@onready var restart_button: Button = %RestartButton
@onready var upgrades_button: Button = %UpgradesButton
@onready var menu_button: Button = %ResultMenuButton


func _ready() -> void:
	UI_ASSET_BINDING_SCRIPT.bind_ui_asset(self, "result_panel")
	restart_button.pressed.connect(_on_restart_button_pressed)
	upgrades_button.pressed.connect(_on_upgrades_button_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)
	hide_result()


func show_victory(_reward_points: int = 0, stars: int = 0) -> void:
	result_label.text = "Victory"
	reward_label.text = "Progress saved"
	stars_label.text = "Stars: %d/3" % clampi(stars, 0, 3)
	stars_label.visible = true
	upgrades_button.visible = FeatureFlags.HERO_SYSTEMS_ENABLED
	upgrades_button.disabled = not FeatureFlags.HERO_SYSTEMS_ENABLED
	visible = true


func show_defeat() -> void:
	result_label.text = "Defeat"
	reward_label.text = "Use boosted colors, better matches, and special tiles"
	stars_label.text = ""
	stars_label.visible = false
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
