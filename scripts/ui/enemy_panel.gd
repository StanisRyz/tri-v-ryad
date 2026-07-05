extends PanelContainer

const TARGET_LANE_LABELS := {
	0: "Left",
	1: "Center",
	2: "Right",
}

@onready var avatar_label: Label = %AvatarLabel
@onready var enemy_name_label: Label = %EnemyNameLabel
@onready var enemy_hp_label: Label = %EnemyHpLabel
@onready var enemy_hp_bar: ProgressBar = %EnemyHpBar
@onready var enemy_intent_label: Label = %EnemyIntentLabel
@onready var enemy_target_label: Label = %EnemyTargetLabel


func _ready() -> void:
	set_placeholder_values("Training Enemy", "HP: -- / --", 1.0, "Intent: Waiting", "Target: --", "?")


func set_enemy_state(enemy: EnemyData, intent: EnemyIntent) -> void:
	if enemy == null:
		set_placeholder_values("Enemy", "HP: -- / --", 0.0, "Intent: --", "Target: --", "?")
		return

	var hp_ratio := float(enemy.current_hp) / float(enemy.max_hp) if enemy.max_hp > 0 else 0.0
	var intent_text := "Intent: attacks in %d" % intent.turns_until_action if intent != null else "Intent: --"
	var attack_text := "Attack: %d" % enemy.attack
	var target_text := "Target: %s" % _format_target_lane(intent.target_lane if intent != null else -1)

	set_placeholder_values(
		enemy.display_name,
		"HP: %d / %d" % [enemy.current_hp, enemy.max_hp],
		hp_ratio,
		"%s | %s" % [intent_text, attack_text],
		target_text,
		enemy.display_name.substr(0, 1).to_upper() if enemy.display_name != "" else "?"
	)


func set_placeholder_values(enemy_name: String, enemy_hp: String, hp_ratio: float, enemy_intent: String, enemy_target: String = "Target: --", avatar_text: String = "?") -> void:
	enemy_name_label.text = enemy_name
	enemy_hp_label.text = enemy_hp
	enemy_hp_bar.value = clampf(hp_ratio, 0.0, 1.0)
	enemy_intent_label.text = enemy_intent
	enemy_target_label.text = enemy_target
	avatar_label.text = avatar_text


func _format_target_lane(target_lane: int) -> String:
	return TARGET_LANE_LABELS.get(target_lane, "Unknown")
