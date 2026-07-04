extends PanelContainer

@onready var enemy_name_label: Label = %EnemyNameLabel
@onready var enemy_hp_label: Label = %EnemyHpLabel
@onready var enemy_intent_label: Label = %EnemyIntentLabel


func _ready() -> void:
	set_placeholder_values("Training Enemy", "HP: -- / --", "Intent: Waiting")


func set_placeholder_values(enemy_name: String, enemy_hp: String, enemy_intent: String) -> void:
	enemy_name_label.text = enemy_name
	enemy_hp_label.text = enemy_hp
	enemy_intent_label.text = enemy_intent
