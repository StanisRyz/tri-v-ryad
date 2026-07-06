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
@onready var hit_effect_layer: Control = %HitEffectLayer

var _animations_enabled := true
var _reduced_motion_enabled := false
var _hp_tween: Tween
var _hit_tween: Tween


func _ready() -> void:
	UI_ASSET_BINDING_SCRIPT.bind_ui_asset(self, "enemy_panel")
	set_placeholder_values("Training Enemy", "HP: -- / --", 1.0, "Intent: Waiting", "Target: --")


func configure_presentation(animations_enabled: bool, reduced_motion_enabled: bool) -> void:
	_animations_enabled = animations_enabled
	_reduced_motion_enabled = reduced_motion_enabled


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
	_animate_hp_bar_to(clampf(hp_ratio, 0.0, 1.0))
	enemy_intent_label.text = enemy_intent
	enemy_target_label.text = enemy_target
	if enemy_image_slot != null:
		enemy_image_slot.set_placeholder_color(Color(0.18, 0.2, 0.24, 1.0))
		enemy_image_slot.set_asset_key(enemy_asset_key)


func get_hit_target_global_position() -> Vector2:
	if enemy_image_slot != null:
		return enemy_image_slot.global_position + enemy_image_slot.size * 0.5
	return global_position + size * 0.5


func play_hit_feedback(damage: int) -> void:
	_play_flash_and_shake()
	if damage > 0:
		show_floating_damage(damage)


func show_floating_damage(damage: int) -> void:
	if damage <= 0:
		return

	var layer := hit_effect_layer if hit_effect_layer != null else self
	if layer == null or layer.get_tree() == null:
		return

	var label := Label.new()
	label.text = "-%d" % damage
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 10
	label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.3, 1.0))
	label.add_theme_font_size_override("font_size", 22)
	var target_local: Vector2 = get_hit_target_global_position() - layer.global_position
	label.position = target_local - Vector2(12, 12)
	layer.add_child(label)

	var duration: float = 0.55 if _animations_enabled else 0.01
	if _reduced_motion_enabled:
		duration *= 0.6
	var rise: float = 12.0 if _reduced_motion_enabled else 26.0

	var tween := create_tween()
	tween.tween_property(label, "position:y", label.position.y - rise, duration)
	tween.parallel().tween_property(label, "modulate:a", 0.0, duration)
	tween.finished.connect(func() -> void:
		if is_instance_valid(label):
			label.queue_free()
	)


func animate_hp_change(current_hp: int, max_hp: int) -> void:
	if enemy_hp_label != null:
		enemy_hp_label.text = "HP: %d / %d" % [maxi(current_hp, 0), max_hp]

	var ratio: float = float(current_hp) / float(max_hp) if max_hp > 0 else 0.0
	_animate_hp_bar_to(clampf(ratio, 0.0, 1.0))


func _animate_hp_bar_to(ratio: float) -> void:
	if enemy_hp_bar == null:
		return

	if not _animations_enabled:
		if _hp_tween != null and _hp_tween.is_valid():
			_hp_tween.kill()
		enemy_hp_bar.value = ratio
		return

	if _hp_tween != null and _hp_tween.is_valid():
		_hp_tween.kill()

	var duration: float = 0.12 if _reduced_motion_enabled else 0.3
	_hp_tween = create_tween()
	_hp_tween.tween_property(enemy_hp_bar, "value", ratio, duration)


func _play_flash_and_shake() -> void:
	if enemy_image_slot == null or not _animations_enabled:
		return

	if _hit_tween != null and _hit_tween.is_valid():
		_hit_tween.kill()

	enemy_image_slot.pivot_offset = enemy_image_slot.size * 0.5
	var base_position: Vector2 = enemy_image_slot.position
	var base_scale: Vector2 = Vector2.ONE
	var flash_scale: Vector2 = Vector2(1.03, 1.03) if _reduced_motion_enabled else Vector2(1.07, 1.07)
	var shake_offset: float = 2.0 if _reduced_motion_enabled else 6.0

	_hit_tween = create_tween()
	_hit_tween.tween_property(enemy_image_slot, "modulate", Color(1.6, 1.6, 1.6, 1.0), 0.05)
	_hit_tween.parallel().tween_property(enemy_image_slot, "scale", flash_scale, 0.05)
	if not _reduced_motion_enabled:
		_hit_tween.tween_property(enemy_image_slot, "position", base_position + Vector2(shake_offset, 0.0), 0.035)
		_hit_tween.tween_property(enemy_image_slot, "position", base_position - Vector2(shake_offset, 0.0), 0.035)
	_hit_tween.tween_property(enemy_image_slot, "position", base_position, 0.04)
	_hit_tween.parallel().tween_property(enemy_image_slot, "modulate", Color.WHITE, 0.08)
	_hit_tween.parallel().tween_property(enemy_image_slot, "scale", base_scale, 0.08)


func _format_target_lane(target_lane: int) -> String:
	return TARGET_LANE_LABELS.get(target_lane, "Unknown")
