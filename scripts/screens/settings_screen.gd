extends Control
class_name SettingsScreen

signal back_pressed

const ASSET_KEY_RESOLVER_SCRIPT := preload("res://scripts/game/config/asset_key_resolver.gd")
const UI_ASSET_BINDING_SCRIPT := preload("res://scripts/ui/ui_asset_binding.gd")
const GAME_ASSET_CATALOG := preload("res://scripts/game/config/game_asset_catalog.gd")
const TEXT_STYLE_APPLIER_SCRIPT := preload("res://scripts/ui/text/text_style_applier.gd")

@onready var back_button: PressableTextureButton = %BackButton
@onready var animations_toggle: CheckButton = %AnimationsToggle
@onready var reduced_motion_toggle: CheckButton = %ReducedMotionToggle
@onready var debug_labels_toggle: CheckButton = get_node_or_null("%DebugLabelsToggle")
@onready var music_toggle: CheckButton = %MusicToggle
@onready var sound_effects_toggle: CheckButton = %SoundEffectsToggle
@onready var background_rect: TextureRect = %Background
@onready var settings_window_rect: TextureRect = %SettingsWindow
@onready var title_label: Label = %TitleLabel
@onready var animations_label: Label = %AnimationsLabel
@onready var reduced_motion_label: Label = %ReducedMotionLabel
@onready var music_label: Label = %MusicLabel
@onready var sound_effects_label: Label = %SoundEffectsLabel

var _settings_manager
var _is_refreshing := false


func _ready() -> void:
	_bind_static_ui_assets()
	back_button.delayed_pressed.connect(_on_back_button_delayed_pressed)
	animations_toggle.toggled.connect(_on_animations_toggled)
	reduced_motion_toggle.toggled.connect(_on_reduced_motion_toggled)
	if debug_labels_toggle != null:
		debug_labels_toggle.toggled.connect(_on_debug_labels_toggled)
	music_toggle.toggled.connect(_on_music_toggled)
	sound_effects_toggle.toggled.connect(_on_sound_effects_toggled)
	_refresh_from_settings()
	_localize_ui()
	_apply_text_styles()
	var localization_manager := get_node_or_null("/root/LocalizationManager")
	if localization_manager != null:
		localization_manager.language_changed.connect(_localize_ui)


func _apply_text_styles() -> void:
	TEXT_STYLE_APPLIER_SCRIPT.apply_to_label(title_label, "settings.title")
	TEXT_STYLE_APPLIER_SCRIPT.apply_to_label(animations_label, "settings.option_label")
	TEXT_STYLE_APPLIER_SCRIPT.apply_to_label(reduced_motion_label, "settings.option_label")
	TEXT_STYLE_APPLIER_SCRIPT.apply_to_label(music_label, "settings.option_label")
	TEXT_STYLE_APPLIER_SCRIPT.apply_to_label(sound_effects_label, "settings.option_label")
	TEXT_STYLE_APPLIER_SCRIPT.apply_to_child_label(back_button, "TextMargin/Label", "settings.button")


func _localize_ui() -> void:
	var localization_manager := get_node_or_null("/root/LocalizationManager")
	if localization_manager == null:
		return
	title_label.text = localization_manager.tr_key("ui.settings.title")
	animations_label.text = localization_manager.tr_key("ui.settings.animations")
	reduced_motion_label.text = localization_manager.tr_key("ui.settings.reduced_motion")
	music_label.text = localization_manager.tr_key("ui.settings.music")
	sound_effects_label.text = localization_manager.tr_key("ui.settings.sound_effects")
	back_button.button_text = localization_manager.tr_key("ui.common.back")


func _bind_static_ui_assets() -> void:
	_apply_background_texture()
	_apply_settings_window_texture()
	_bind_back_button_textures()
	for toggle in _visible_toggles():
		_bind_toggle_asset_key(toggle)


func _apply_background_texture() -> void:
	if background_rect == null or background_rect.texture != null:
		return
	var texture := GAME_ASSET_CATALOG.try_load_texture_cached(ASSET_KEY_RESOLVER_SCRIPT.get_ui_asset_key("shared_background"))
	if texture != null:
		background_rect.texture = texture


func _apply_settings_window_texture() -> void:
	if settings_window_rect == null or settings_window_rect.texture != null:
		return
	var texture := GAME_ASSET_CATALOG.try_load_texture_cached(ASSET_KEY_RESOLVER_SCRIPT.get_ui_asset_key("settings_window"))
	if texture != null:
		settings_window_rect.texture = texture


func _bind_back_button_textures() -> void:
	if back_button == null:
		return

	if back_button.normal_texture == null:
		var normal_key := ASSET_KEY_RESOLVER_SCRIPT.get_ui_asset_key("shared_back_button_default")
		var normal_texture := GAME_ASSET_CATALOG.try_load_texture_cached(normal_key)
		if normal_texture != null:
			back_button.set_normal_texture(normal_texture)

	if back_button.pressed_texture == null:
		var pressed_key := ASSET_KEY_RESOLVER_SCRIPT.get_ui_asset_key("shared_back_button_pressed")
		var pressed_texture := GAME_ASSET_CATALOG.try_load_texture_cached(pressed_key)
		if pressed_texture != null:
			back_button.set_pressed_texture(pressed_texture)


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
	if debug_labels_toggle != null:
		debug_labels_toggle.button_pressed = settings.debug_labels_enabled
	music_toggle.button_pressed = settings.music_enabled
	sound_effects_toggle.button_pressed = settings.sound_effects_enabled
	for toggle in _visible_toggles():
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


func _visible_toggles() -> Array:
	var toggles := [animations_toggle, reduced_motion_toggle, music_toggle, sound_effects_toggle]
	if debug_labels_toggle != null:
		toggles.append(debug_labels_toggle)
	return toggles


func _bind_toggle_asset_key(toggle: CheckButton) -> void:
	if toggle == null:
		return

	var ui_id := "toggle_on" if toggle.button_pressed else "toggle_off"
	UI_ASSET_BINDING_SCRIPT.bind_asset_key(toggle, ASSET_KEY_RESOLVER_SCRIPT.get_ui_asset_key(ui_id), ui_id)


func _on_back_button_delayed_pressed() -> void:
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
