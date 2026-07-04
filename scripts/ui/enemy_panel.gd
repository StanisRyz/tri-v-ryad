extends PanelContainer

@onready var enemy_name_label: Label = %EnemyNameLabel
@onready var enemy_hp_label: Label = %EnemyHpLabel
@onready var enemy_intent_label: Label = %EnemyIntentLabel


func _ready() -> void:
	set_placeholder_values("Training Enemy", "HP: -- / --", "Intent: Waiting")


func set_enemy_state(enemy: EnemyData, intent: EnemyIntent) -> void:
	if enemy == null:
		set_placeholder_values("Enemy", "HP: -- / --", "Intent: --")
		return

	var intent_text := "Intent: attacks in %d" % intent.turns_until_action if intent != null else "Intent: --"
	set_placeholder_values(
		enemy.display_name,
		"HP: %d / %d" % [enemy.current_hp, enemy.max_hp],
		intent_text
	)


func set_placeholder_values(enemy_name: String, enemy_hp: String, enemy_intent: String) -> void:
	enemy_name_label.text = enemy_name
	enemy_hp_label.text = enemy_hp
	enemy_intent_label.text = enemy_intent
