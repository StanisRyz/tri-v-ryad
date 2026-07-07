extends PanelContainer
class_name BattleResultOverlay

signal restart_pressed
signal menu_pressed
signal upgrades_pressed
signal next_level_pressed

const UI_ASSET_BINDING_SCRIPT := preload("res://scripts/ui/ui_asset_binding.gd")
const LEVEL_REWARD_FORMATTER_SCRIPT := preload("res://scripts/game/presentation/level_reward_formatter.gd")

@onready var result_label: Label = %ResultLabel
@onready var reward_label: Label = %RewardLabel
@onready var stars_label: Label = %StarsLabel
@onready var moves_label: Label = %MovesLabel
@onready var unlock_label: Label = %UnlockLabel
@onready var milestone_reward_label: Label = %MilestoneRewardLabel
@onready var next_level_button: Button = %NextLevelButton
@onready var restart_button: Button = %RestartButton
@onready var upgrades_button: Button = %UpgradesButton
@onready var menu_button: Button = %ResultMenuButton


func _ready() -> void:
	UI_ASSET_BINDING_SCRIPT.bind_ui_asset(self, "result_panel")
	next_level_button.pressed.connect(_on_next_level_button_pressed)
	restart_button.pressed.connect(_on_restart_button_pressed)
	upgrades_button.pressed.connect(_on_upgrades_button_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)
	hide_result()


func show_victory(_reward_points: int = 0, stars: int = 0) -> void:
	show_victory_result({
		"level_label": "Level",
		"stars_earned": stars,
		"best_stars": stars,
		"moves_left": 0,
		"next_level_id": "",
		"next_level_unlocked": false,
		"new_zone_unlocked": false,
		"milestone_rewards": [],
	})


func show_victory_result(data: Dictionary) -> void:
	var level_label := str(data.get("level_label", "Level"))
	var stars_earned: int = clampi(int(data.get("stars_earned", 0)), 0, 3)
	var best_stars: int = clampi(int(data.get("best_stars", stars_earned)), 0, 3)
	var moves_left: int = max(0, int(data.get("moves_left", 0)))
	var next_level_id := str(data.get("next_level_id", ""))
	var next_level_unlocked := bool(data.get("next_level_unlocked", false))
	var new_zone_unlocked := bool(data.get("new_zone_unlocked", false))
	var milestone_rewards: Array = data.get("milestone_rewards", [])

	result_label.text = "Victory"
	reward_label.text = "%s complete" % level_label
	stars_label.text = "Stars: %d/3  Best: %d/3" % [stars_earned, best_stars]
	stars_label.visible = true
	moves_label.text = "Moves left: %d" % moves_left
	moves_label.visible = true
	unlock_label.text = _format_unlock_text(next_level_unlocked, new_zone_unlocked)
	unlock_label.visible = unlock_label.text != ""
	milestone_reward_label.text = LEVEL_REWARD_FORMATTER_SCRIPT.format_rewards_text(milestone_rewards)
	milestone_reward_label.visible = true
	next_level_button.visible = next_level_id != ""
	next_level_button.disabled = next_level_id == ""
	upgrades_button.visible = FeatureFlags.HERO_SYSTEMS_ENABLED
	upgrades_button.disabled = not FeatureFlags.HERO_SYSTEMS_ENABLED
	visible = true


func show_defeat() -> void:
	show_defeat_result({
		"level_label": "Level",
		"moves_left": 0,
		"message": "Try again with bigger matches and special tiles.",
	})


func show_defeat_result(data: Dictionary) -> void:
	var level_label := str(data.get("level_label", "Level"))
	var moves_left: int = max(0, int(data.get("moves_left", 0)))
	var message := str(data.get("message", "Try again with bigger matches and special tiles."))

	result_label.text = "Defeat"
	reward_label.text = "%s failed" % level_label
	stars_label.text = ""
	stars_label.visible = false
	moves_label.text = "Moves left: %d" % moves_left
	moves_label.visible = moves_left > 0
	unlock_label.text = message
	unlock_label.visible = true
	milestone_reward_label.text = ""
	milestone_reward_label.visible = false
	next_level_button.visible = false
	next_level_button.disabled = true
	upgrades_button.visible = false
	upgrades_button.disabled = true
	visible = true


func hide_result() -> void:
	visible = false


func _format_unlock_text(next_level_unlocked: bool, new_zone_unlocked: bool) -> String:
	var lines := PackedStringArray()
	if next_level_unlocked:
		lines.append("Next level unlocked")
	if new_zone_unlocked:
		lines.append("New zone unlocked")
	return "\n".join(lines)


func _on_next_level_button_pressed() -> void:
	next_level_pressed.emit()


func _on_restart_button_pressed() -> void:
	restart_pressed.emit()


func _on_upgrades_button_pressed() -> void:
	upgrades_pressed.emit()


func _on_menu_button_pressed() -> void:
	menu_pressed.emit()
