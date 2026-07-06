extends Button
class_name BoosterButton

const ASSET_KEY_RESOLVER_SCRIPT := preload("res://scripts/game/config/asset_key_resolver.gd")
const UI_ASSET_BINDING_SCRIPT := preload("res://scripts/ui/ui_asset_binding.gd")

@onready var icon_slot: ImageSlot = %IconSlot
@onready var uses_label: Label = %UsesLabel

var _booster_id := ""
var _uses_left := 0
var _selected := false
var _disabled_state := false
var _feedback_tween: Tween


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	_refresh()


func set_booster_id(booster_id: String) -> void:
	_booster_id = booster_id
	_refresh()


func get_booster_id() -> String:
	return _booster_id


func set_uses_left(value: int) -> void:
	_uses_left = max(value, 0)
	_refresh()


func set_selected(value: bool) -> void:
	_selected = value
	_refresh()


func set_disabled_state(value: bool) -> void:
	_disabled_state = value
	disabled = false
	_refresh()


func get_icon_asset_key() -> String:
	return icon_slot.get_asset_key() if icon_slot != null else ""


func get_button_state_asset_key() -> String:
	if _disabled_state:
		return ASSET_KEY_RESOLVER_SCRIPT.get_ui_asset_key("booster_button_disabled")
	if _selected:
		return ASSET_KEY_RESOLVER_SCRIPT.get_ui_asset_key("booster_button_selected")
	return ASSET_KEY_RESOLVER_SCRIPT.get_ui_asset_key("booster_button_ready")


func _refresh() -> void:
	if icon_slot != null:
		icon_slot.set_asset_key(ASSET_KEY_RESOLVER_SCRIPT.get_booster_asset_key(_booster_id))
	if uses_label != null:
		uses_label.text = "x%d" % _uses_left
	UI_ASSET_BINDING_SCRIPT.bind_asset_key(self, get_button_state_asset_key(), "booster_button")
	modulate = Color(1.0, 1.0, 1.0, 0.45) if _disabled_state else Color.WHITE
	if _selected:
		scale = Vector2(1.04, 1.04)
	elif _feedback_tween == null:
		scale = Vector2.ONE


func play_feedback(animations_enabled: bool = true, reduced_motion_enabled: bool = false) -> void:
	if _feedback_tween != null:
		_feedback_tween.kill()
		_feedback_tween = null

	pivot_offset = size * 0.5
	if not animations_enabled:
		return

	var pulse_scale := Vector2(1.05, 1.05) if reduced_motion_enabled else Vector2(1.10, 1.10)
	var base_scale := Vector2(1.04, 1.04) if _selected else Vector2.ONE
	var pulse_duration := 0.05 if reduced_motion_enabled else 0.08
	var settle_duration := 0.08 if reduced_motion_enabled else 0.12
	_feedback_tween = create_tween()
	_feedback_tween.tween_property(self, "scale", pulse_scale, pulse_duration)
	_feedback_tween.parallel().tween_property(self, "modulate", Color(1.0, 0.92, 0.42, 1.0), pulse_duration)
	_feedback_tween.tween_property(self, "scale", base_scale, settle_duration)
	_feedback_tween.parallel().tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 0.45) if _disabled_state else Color.WHITE, settle_duration)
	_feedback_tween.finished.connect(func() -> void:
		_feedback_tween = null
	)
