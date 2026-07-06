extends RefCounted
class_name BattleEffectController

const NORMAL_PARTICLE_CAP := 16
const REDUCED_PARTICLE_CAP := 6
const PARTICLE_TRAVEL_DURATION := 0.28
const PARTICLE_TRAVEL_DURATION_REDUCED := 0.16
const PARTICLE_STAGGER := 0.02
const PARTICLE_STAGGER_REDUCED := 0.01

var _animations_enabled := true
var _reduced_motion_enabled := false
var _playing := false
var _playback_generation := 0


func configure_settings(animations_enabled: bool, reduced_motion_enabled: bool) -> void:
	_animations_enabled = animations_enabled
	_reduced_motion_enabled = reduced_motion_enabled


func is_playing() -> bool:
	return _playing


func clear_effects(effect_layer: Control = null) -> void:
	_playback_generation += 1
	_playing = false
	if effect_layer == null:
		return

	for child in effect_layer.get_children():
		child.free()


func cap_events(events: Array) -> Array:
	var cap := REDUCED_PARTICLE_CAP if _reduced_motion_enabled else NORMAL_PARTICLE_CAP
	if events.size() <= cap:
		return events.duplicate()
	return events.slice(0, cap)


func play_damage_particles(events: Array, board_view: BoardView, enemy_panel: Control, effect_layer: Control, finished_callback: Callable = Callable()) -> void:
	if not _animations_enabled or events.is_empty():
		_call_finished(finished_callback)
		return
	if board_view == null or enemy_panel == null or effect_layer == null:
		_call_finished(finished_callback)
		return
	if effect_layer.get_tree() == null:
		_call_finished(finished_callback)
		return

	_playback_generation += 1
	var generation := _playback_generation
	_playing = true
	var capped_events := cap_events(events)
	var travel_duration: float = PARTICLE_TRAVEL_DURATION_REDUCED if _reduced_motion_enabled else PARTICLE_TRAVEL_DURATION
	var stagger: float = PARTICLE_STAGGER_REDUCED if _reduced_motion_enabled else PARTICLE_STAGGER

	for index in range(capped_events.size()):
		_spawn_particle(capped_events[index], index, stagger, travel_duration, board_view, enemy_panel, effect_layer)

	var total_duration: float = travel_duration + stagger * maxf(capped_events.size() - 1, 0.0)
	await effect_layer.get_tree().create_timer(total_duration).timeout
	if generation != _playback_generation:
		return

	clear_effects(effect_layer)
	_playing = false
	_trigger_hit_feedback(events, enemy_panel)
	_call_finished(finished_callback)


func _spawn_particle(event: Dictionary, index: int, stagger: float, travel_duration: float, board_view: BoardView, enemy_panel: Control, effect_layer: Control) -> void:
	var particle := ColorRect.new()
	particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tile_type: int = int(event.get("tile_type", -1))
	var base_color: Color = TileView.TILE_COLORS.get(tile_type, Color(0.85, 0.85, 0.9, 1.0))
	var is_boosted: bool = bool(event.get("is_boosted", false))
	var particle_size: float = 18.0 if is_boosted else 14.0
	if _reduced_motion_enabled:
		particle_size *= 0.85
	particle.color = base_color.lightened(0.3) if is_boosted else base_color
	particle.size = Vector2(particle_size, particle_size)
	particle.pivot_offset = particle.size * 0.5

	var start_global := _get_start_position(board_view, event.get("cell", Vector2i(-1, -1)))
	var target_global := _get_target_position(enemy_panel)
	particle.position = start_global - effect_layer.global_position - particle.size * 0.5
	effect_layer.add_child(particle)

	var target_position := target_global - effect_layer.global_position - particle.size * 0.5
	var tween := effect_layer.create_tween()
	if stagger > 0.0 and index > 0:
		tween.tween_interval(stagger * index)
	tween.tween_property(particle, "position", target_position, travel_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(particle, "modulate:a", 0.15, travel_duration)


func _get_start_position(board_view: BoardView, cell: Vector2i) -> Vector2:
	if board_view != null and board_view.get_tile_view(cell) != null:
		return board_view.get_cell_global_center(cell)
	if board_view != null:
		return board_view.global_position + board_view.size * 0.5
	return Vector2.ZERO


func _get_target_position(enemy_panel: Control) -> Vector2:
	if enemy_panel != null and enemy_panel.has_method("get_hit_target_global_position"):
		return enemy_panel.get_hit_target_global_position()
	if enemy_panel != null:
		return enemy_panel.global_position + enemy_panel.size * 0.5
	return Vector2.ZERO


func _trigger_hit_feedback(events: Array, enemy_panel: Control) -> void:
	if enemy_panel == null:
		return

	var total_damage := 0
	for event in events:
		total_damage += int(event.get("damage", 0))

	if enemy_panel.has_method("play_hit_feedback"):
		enemy_panel.play_hit_feedback(total_damage)


func _call_finished(finished_callback: Callable) -> void:
	if finished_callback.is_valid():
		finished_callback.call()
