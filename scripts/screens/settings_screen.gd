extends Control
class_name SettingsScreen

signal back_pressed

const ASSET_KEY_RESOLVER_SCRIPT := preload("res://scripts/game/config/asset_key_resolver.gd")
const UI_ASSET_BINDING_SCRIPT := preload("res://scripts/ui/ui_asset_binding.gd")

@onready var back_button: Button = %BackButton
@onready var animations_toggle: CheckButton = %AnimationsToggle
@onready var reduced_motion_toggle: CheckButton = %ReducedMotionToggle
@onready var debug_labels_toggle: CheckButton = %DebugLabelsToggle
@onready var music_toggle: CheckButton = %MusicToggle
@onready var sound_effects_toggle: CheckButton = %SoundEffectsToggle
@onready var background_slot: ImageSlot = %Background
@onready var toggles_panel: Control = %TogglesPanel

var _settings_manager
var _is_refreshing := false


func _ready() -> void:
	_bind_static_ui_assets()
	back_button.pressed.connect(_on_back_button_pressed)
	animations_toggle.toggled.connect(_on_animations_toggled)
	reduced_motion_toggle.toggled.connect(_on_reduced_motion_toggled)
	debug_labels_toggle.toggled.connect(_on_debug_labels_toggled)
	music_toggle.toggled.connect(_on_music_toggled)
	sound_effects_toggle.toggled.connect(_on_sound_effects_toggled)
	_refresh_from_settings()


func _bind_static_ui_assets() -> void:
	UI_ASSET_BINDING_SCRIPT.bind_ui_asset(background_slot, "settings_background")
	UI_ASSET_BINDING_SCRIPT.bind_ui_asset(toggles_panel, "settings_panel")
	for toggle in [animations_toggle, reduced_motion_toggle, debug_labels_toggle, music_toggle, sound_effects_toggle]:
		_bind_toggle_asset_key(toggle)


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
	for toggle in [animations_toggle, reduced_motion_toggle, debug_labels_toggle, music_toggle, sound_effects_toggle]:
		_bind_toggle_asset_key(toggle)
	_is_refreshing = false


func _on_animations_toggled(value: bool) -> void:
	if _is_refreshing or _settings_manager == null:
		return
	_settings_manager.set_animations_enabled(value)
	_bind_toggle_asset_key(animations_toggle)


func _on_reduced_motion_toggled(value: bool) -> void:
	if _is_refreshing or _settings_manager == null:
		return
	_settings_manager.set_reduced_motion_enabled(value)
	_bind_toggle_asset_key(reduced_motion_toggle)


func _on_debug_labels_toggled(value: bool) -> void:
	if _is_refreshing or _settings_manager == null:
		return
	_settings_manager.set_debug_labels_enabled(value)
	_bind_toggle_asset_key(debug_labels_toggle)


func _on_music_toggled(value: bool) -> void:
	if _is_refreshing or _settings_manager == null:
		return
	_settings_manager.set_music_enabled(value)
	_bind_toggle_asset_key(music_toggle)
	_apply_audio_manager_settings()


func _on_sound_effects_toggled(value: bool) -> void:
	if _is_refreshing or _settings_manager == null:
		return
	_settings_manager.set_sound_effects_enabled(value)
	_bind_toggle_asset_key(sound_effects_toggle)
	_apply_audio_manager_settings()


func _bind_toggle_asset_key(toggle: CheckButton) -> void:
	if toggle == null:
		return

	var ui_id := "toggle_on" if toggle.button_pressed else "toggle_off"
	UI_ASSET_BINDING_SCRIPT.bind_asset_key(toggle, ASSET_KEY_RESOLVER_SCRIPT.get_ui_asset_key(ui_id), ui_id)


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
