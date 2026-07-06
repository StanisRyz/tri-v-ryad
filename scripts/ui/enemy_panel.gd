extends PanelContainer

const ASSET_KEY_RESOLVER_SCRIPT := preload("res://scripts/game/config/asset_key_resolver.gd")
const UI_ASSET_BINDING_SCRIPT := preload("res://scripts/ui/ui_asset_binding.gd")

const TARGET_LANE_LABELS := {
	0: "Left",
	1: "Center",
	2: "Right",
}

@onready var enemy_image_slot: ImageSlot = %EnemyImageSlot
@onready var enemy_name_label: Label = %EnemyNameLabel
@onready var enemy_hp_label: Label = %EnemyHpLabel
@onready var enemy_hp_bar: ProgressBar = %EnemyHpBar
@onready var enemy_intent_label: Label = %EnemyIntentLabel
@onready var enemy_target_label: Label = %EnemyTargetLabel


func _ready() -> void:
	UI_ASSET_BINDING_SCRIPT.bind_ui_asset(self, "enemy_panel")
	set_placeholder_values("Training Enemy", "HP: -- / --", 1.0, "Intent: Waiting", "Target: --")


func set_enemy_state(enemy: EnemyData, intent: EnemyIntent) -> void:
	if enemy == null:
		set_placeholder_values("Enemy", "HP: -- / --", 0.0, "Intent: --", "Target: --")
		return

	var hp_ratio := float(enemy.current_hp) / float(enemy.max_hp) if enemy.max_hp > 0 else 0.0
	var intent_text := "Intent: attacks in %d" % intent.turns_until_action if intent != null else "Intent: --"
	var attack_text := "Attack: %d" % enemy.attack
	var target_text := "Target: %s" % _format_target_lane(intent.target_lane if intent != null else -1)
	if not FeatureFlags.HERO_SYSTEMS_ENABLED:
		intent_text = "Goal: defeat enemy"
		attack_text = "Enemy does not attack"
		target_text = "Match crystals to deal damage"

	set_placeholder_values(
		enemy.display_name,
		"HP: %d / %d" % [enemy.current_hp, enemy.max_hp],
		hp_ratio,
		"%s | %s" % [intent_text, attack_text],
		target_text,
		ASSET_KEY_RESOLVER_SCRIPT.get_enemy_asset_key(enemy.id)
	)


func set_placeholder_values(enemy_name: String, enemy_hp: String, hp_ratio: float, enemy_intent: String, enemy_target: String = "Target: --", enemy_asset_key: String = "") -> void:
	enemy_name_label.text = enemy_name
	enemy_hp_label.text = enemy_hp
	enemy_hp_bar.value = clampf(hp_ratio, 0.0, 1.0)
	enemy_intent_label.text = enemy_intent
	enemy_target_label.text = enemy_target
	if enemy_image_slot != null:
		enemy_image_slot.set_placeholder_color(Color(0.18, 0.2, 0.24, 1.0))
		enemy_image_slot.set_asset_key(enemy_asset_key)


func _format_target_lane(target_lane: int) -> String:
	return TARGET_LANE_LABELS.get(target_lane, "Unknown")
