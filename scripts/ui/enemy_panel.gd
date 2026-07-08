extends PanelContainer

const ASSET_KEY_RESOLVER_SCRIPT := preload("res://scripts/game/config/asset_key_resolver.gd")
const GAME_ASSET_CATALOG_SCRIPT := preload("res://scripts/game/config/game_asset_catalog.gd")
const UI_ASSET_BINDING_SCRIPT := preload("res://scripts/ui/ui_asset_binding.gd")

@onready var background_visual: FallbackImageSlot = %BackgroundVisual
@onready var enemy_sprite: FallbackImageSlot = %EnemySprite
@onready var hp_bar_fill: ColorRect = %HpBarFill
@onready var hp_value_label: Label = %HpValueLabel
@onready var hit_effect_layer: Control = %HitEffectLayer

var _animations_enabled := true
var _reduced_motion_enabled := false
var _hp_tween: Tween
var _hit_tween: Tween
var _damage_feedback_tween: Tween

var _sprite_manual_override := false
var _background_manual_override := false
var _normal_texture: Texture2D
var _damaged_texture: Texture2D


func _ready() -> void:
	UI_ASSET_BINDING_SCRIPT.bind_ui_asset(self, "enemy_panel")
	_sprite_manual_override = enemy_sprite.has_texture()
	_background_manual_override = background_visual.has_texture()
	if not _background_manual_override:
		background_visual.set_texture(_pick_random_background_texture())
	set_hp_values(0, 0)


func configure_presentation(animations_enabled: bool, reduced_motion_enabled: bool) -> void:
	_animations_enabled = animations_enabled
	_reduced_motion_enabled = reduced_motion_enabled


func set_enemy_state(enemy: EnemyData, _intent: EnemyIntent) -> void:
	if enemy == null:
		set_hp_values(0, 0)
		return

	set_hp_values(enemy.current_hp, enemy.max_hp)
	set_enemy_textures(
		GAME_ASSET_CATALOG_SCRIPT.try_load_texture_cached(ASSET_KEY_RESOLVER_SCRIPT.get_enemy_normal_asset_key(enemy.id)),
		GAME_ASSET_CATALOG_SCRIPT.try_load_texture_cached(ASSET_KEY_RESOLVER_SCRIPT.get_enemy_damaged_asset_key(enemy.id))
	)


func set_enemy_textures(normal_texture: Texture2D, damaged_texture: Texture2D) -> void:
	_damaged_texture = damaged_texture
	if normal_texture != null:
		_normal_texture = normal_texture
	if not _sprite_manual_override and _normal_texture != null:
		enemy_sprite.set_texture(_normal_texture)


func set_hp_values(current_hp: int, max_hp: int) -> void:
	var safe_current: int = maxi(current_hp, 0)
	var safe_max: int = maxi(max_hp, 0)
	if hp_value_label != null:
		hp_value_label.text = "%d / %d" % [safe_current, safe_max]

	var ratio: float = float(safe_current) / float(safe_max) if safe_max > 0 else 0.0
	_animate_hp_bar_to(clampf(ratio, 0.0, 1.0))


func animate_hp_change(current_hp: int, max_hp: int) -> void:
	set_hp_values(current_hp, max_hp)


func get_hit_target_global_position() -> Vector2:
	if enemy_sprite != null:
		return enemy_sprite.global_position + enemy_sprite.size * 0.5
	return global_position + size * 0.5


func play_hit_feedback(damage: int) -> void:
	_play_flash_and_shake()
	if damage > 0:
		show_floating_damage(damage)


func play_damage_feedback() -> void:
	if _damage_feedback_tween != null and _damage_feedback_tween.is_valid():
		_damage_feedback_tween.kill()

	if not _sprite_manual_override and _damaged_texture != null:
		var restore_texture: Texture2D = _normal_texture
		enemy_sprite.set_texture(_damaged_texture)
		var duration: float = 0.12 if _reduced_motion_enabled else 0.22
		_damage_feedback_tween = create_tween()
		_damage_feedback_tween.tween_interval(duration)
		_damage_feedback_tween.tween_callback(func() -> void:
			if is_instance_valid(enemy_sprite) and restore_texture != null:
				enemy_sprite.set_texture(restore_texture)
		)
		return

	_play_flash_and_shake()


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


func _pick_random_background_texture() -> Texture2D:
	var asset_keys: Array = ASSET_KEY_RESOLVER_SCRIPT.get_enemy_panel_background_asset_keys()
	asset_keys.shuffle()
	for asset_key in asset_keys:
		var texture := GAME_ASSET_CATALOG_SCRIPT.try_load_texture_cached(asset_key)
		if texture != null:
			return texture
	return null


func _animate_hp_bar_to(ratio: float) -> void:
	if hp_bar_fill == null:
		return

	if not _animations_enabled:
		if _hp_tween != null and _hp_tween.is_valid():
			_hp_tween.kill()
		hp_bar_fill.anchor_right = ratio
		return

	if _hp_tween != null and _hp_tween.is_valid():
		_hp_tween.kill()

	var duration: float = 0.12 if _reduced_motion_enabled else 0.3
	_hp_tween = create_tween()
	_hp_tween.tween_property(hp_bar_fill, "anchor_right", ratio, duration)


func _play_flash_and_shake() -> void:
	if enemy_sprite == null or not _animations_enabled:
		return

	if _hit_tween != null and _hit_tween.is_valid():
		_hit_tween.kill()

	enemy_sprite.pivot_offset = enemy_sprite.size * 0.5
	var base_position: Vector2 = enemy_sprite.position
	var base_scale: Vector2 = Vector2.ONE
	var flash_scale: Vector2 = Vector2(1.03, 1.03) if _reduced_motion_enabled else Vector2(1.07, 1.07)
	var shake_offset: float = 2.0 if _reduced_motion_enabled else 6.0

	_hit_tween = create_tween()
	_hit_tween.tween_property(enemy_sprite, "modulate", Color(1.6, 1.6, 1.6, 1.0), 0.05)
	_hit_tween.parallel().tween_property(enemy_sprite, "scale", flash_scale, 0.05)
	if not _reduced_motion_enabled:
		_hit_tween.tween_property(enemy_sprite, "position", base_position + Vector2(shake_offset, 0.0), 0.035)
		_hit_tween.tween_property(enemy_sprite, "position", base_position - Vector2(shake_offset, 0.0), 0.035)
	_hit_tween.tween_property(enemy_sprite, "position", base_position, 0.04)
	_hit_tween.parallel().tween_property(enemy_sprite, "modulate", Color.WHITE, 0.08)
	_hit_tween.parallel().tween_property(enemy_sprite, "scale", base_scale, 0.08)
