extends Control
class_name SettingsScreen

signal back_pressed

@onready var back_button: Button = %BackButton
@onready var animations_toggle: CheckButton = %AnimationsToggle
@onready var reduced_motion_toggle: CheckButton = %ReducedMotionToggle
@onready var debug_labels_toggle: CheckButton = %DebugLabelsToggle
@onready var music_toggle: CheckButton = %MusicToggle
@onready var sound_effects_toggle: CheckButton = %SoundEffectsToggle

var _settings_manager
var _is_refreshing := false


func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
	animations_toggle.toggled.connect(_on_animations_toggled)
	reduced_motion_toggle.toggled.connect(_on_reduced_motion_toggled)
	debug_labels_toggle.toggled.connect(_on_debug_labels_toggled)
	music_toggle.toggled.connect(_on_music_toggled)
	sound_effects_toggle.toggled.connect(_on_sound_effects_toggled)
	_refresh_from_settings()


func set_settings_manager(settings_manager) -> void:
	_settings_manager = settings_manager
	if is_inside_tree():
		_refresh_from_settings()


func _refresh_from_settings() -> void:
	if _settings_manager == null:
		return

	var settings: PlayerSettings = _settings_manager.get_settings()
	_is_refreshing = true
	animations_toggle.button_pressed = settings.animations_enabled
	reduced_motion_toggle.button_pressed = settings.reduced_motion_enabled
	debug_labels_toggle.button_pressed = settings.debug_labels_enabled
	music_toggle.button_pressed = settings.music_enabled
	sound_effects_toggle.button_pressed = settings.sound_effects_enabled
	_is_refreshing = false


func _on_animations_toggled(value: bool) -> void:
	if _is_refreshing or _settings_manager == null:
		return
	_settings_manager.set_animations_enabled(value)


func _on_reduced_motion_toggled(value: bool) -> void:
	if _is_refreshing or _settings_manager == null:
		return
	_settings_manager.set_reduced_motion_enabled(value)


func _on_debug_labels_toggled(value: bool) -> void:
	if _is_refreshing or _settings_manager == null:
		return
	_settings_manager.set_debug_labels_enabled(value)


func _on_music_toggled(value: bool) -> void:
	if _is_refreshing or _settings_manager == null:
		return
	_settings_manager.set_music_enabled(value)
	_apply_audio_manager_settings()


func _on_sound_effects_toggled(value: bool) -> void:
	if _is_refreshing or _settings_manager == null:
		return
	_settings_manager.set_sound_effects_enabled(value)
	_apply_audio_manager_settings()


func _on_back_button_pressed() -> void:
	_play_button_click()
	back_pressed.emit()


func _apply_audio_manager_settings() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager == null or _settings_manager == null:
		return

	var settings: PlayerSettings = _settings_manager.get_settings()
	audio_manager.set_music_enabled(settings.music_enabled)
	audio_manager.set_sound_effects_enabled(settings.sound_effects_enabled)


func _play_button_click() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.play_button_click()
