extends PanelContainer
class_name HeroCard

signal ability_pressed(lane_index: int)

const PORTRAIT_COLOR := Color(0.28, 0.32, 0.4, 1.0)
const DEFAULT_BORDER_COLOR := Color(0.16, 0.17, 0.2, 1.0)
const READY_BORDER_COLOR := Color(1.0, 0.85, 0.2, 1.0)
const PULSE_SCALE := Vector2(1.04, 1.04)
const PULSE_DURATION := 0.5

static var _debug_labels_enabled := false
static var _animations_enabled := true
static var _reduced_motion_enabled := false

@onready var portrait_button: Button = %PortraitButton
@onready var down_overlay: ColorRect = %DownOverlay
@onready var debug_label: Label = %DebugLabel
@onready var hp_bar: ProgressBar = %HpBar
@onready var charge_bar: ProgressBar = %ChargeBar

var _lane_index := -1
var _is_ready := false
var _default_style: StyleBoxFlat
var _ready_style: StyleBoxFlat
var _pulse_tween: Tween


func _ready() -> void:
	if not portrait_button.pressed.is_connected(_on_portrait_pressed):
		portrait_button.pressed.connect(_on_portrait_pressed)
	_setup_styles()
	set_hero(null)


static func set_debug_labels_enabled(value: bool) -> void:
	_debug_labels_enabled = value


static func set_presentation_settings(animations_enabled: bool, reduced_motion_enabled: bool) -> void:
	_animations_enabled = animations_enabled
	_reduced_motion_enabled = reduced_motion_enabled


func set_hero(hero: HeroData) -> void:
	if hero == null:
		_lane_index = -1
		portrait_button.disabled = true
		down_overlay.visible = false
		debug_label.visible = false
		hp_bar.value = 0.0
		charge_bar.value = 0.0
		_apply_ready_visual(false)
		return

	_lane_index = hero.lane_index
	portrait_button.disabled = false

	var alive := hero.is_alive()
	var max_hp := hero.get_max_hp()
	hp_bar.value = (float(hero.current_hp) / float(max_hp)) if max_hp > 0 and alive else 0.0

	var required_charge := hero.ability_charge_required
	charge_bar.value = (float(hero.ability_charge) / float(required_charge)) if required_charge > 0 else 0.0

	down_overlay.visible = not alive

	if _debug_labels_enabled:
		debug_label.visible = true
		debug_label.text = hero.id
	else:
		debug_label.visible = false

	_is_ready = alive and hero.is_ability_ready()
	_apply_ready_visual(_is_ready)


func refresh() -> void:
	pass


func is_ready_state() -> bool:
	return _is_ready


func is_down_state() -> bool:
	return down_overlay.visible


func _setup_styles() -> void:
	_default_style = StyleBoxFlat.new()
	_default_style.bg_color = PORTRAIT_COLOR
	_default_style.set_border_width_all(2)
	_default_style.border_color = DEFAULT_BORDER_COLOR
	_default_style.set_corner_radius_all(8)

	_ready_style = StyleBoxFlat.new()
	_ready_style.bg_color = PORTRAIT_COLOR
	_ready_style.set_border_width_all(4)
	_ready_style.border_color = READY_BORDER_COLOR
	_ready_style.set_corner_radius_all(8)

	_apply_ready_visual(false)


func _apply_ready_visual(is_ready: bool) -> void:
	var style := _ready_style if is_ready else _default_style
	portrait_button.add_theme_stylebox_override("normal", style)
	portrait_button.add_theme_stylebox_override("hover", style)
	portrait_button.add_theme_stylebox_override("pressed", style)
	portrait_button.add_theme_stylebox_override("focus", style)
	portrait_button.add_theme_stylebox_override("disabled", style)

	_update_pulse(is_ready)


func _update_pulse(is_ready: bool) -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
		_pulse_tween = null
	portrait_button.scale = Vector2.ONE

	if not is_ready or not _animations_enabled or _reduced_motion_enabled:
		return

	if not is_inside_tree():
		return

	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(portrait_button, "scale", PULSE_SCALE, PULSE_DURATION).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(portrait_button, "scale", Vector2.ONE, PULSE_DURATION).set_trans(Tween.TRANS_SINE)


func _on_portrait_pressed() -> void:
	if _lane_index == -1:
		return

	ability_pressed.emit(_lane_index)
