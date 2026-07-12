extends Control
class_name SettingsScreen

signal back_pressed

const ASSET_KEY_RESOLVER_SCRIPT := preload("res://scripts/game/config/asset_key_resolver.gd")
const UI_ASSET_BINDING_SCRIPT := preload("res://scripts/ui/ui_asset_binding.gd")
const GAME_ASSET_CATALOG := preload("res://scripts/game/config/game_asset_catalog.gd")
const TEXT_STYLE_APPLIER_SCRIPT := preload("res://scripts/ui/text/text_style_applier.gd")

@onready var back_button: PressableTextureButton = %BackButton
@onready var animations_toggle: PressableTextureButton = %AnimationsToggle
@onready var reduced_motion_toggle: PressableTextureButton = %ReducedMotionToggle
@onready var debug_labels_toggle: PressableTextureButton = get_node_or_null("%DebugLabelsToggle")
@onready var music_toggle: PressableTextureButton = %MusicToggle
@onready var sound_effects_toggle: PressableTextureButton = %SoundEffectsToggle
@onready var background_rect: TextureRect = %Background
@onready var settings_window_rect: TextureRect = %SettingsWindow
@onready var title_label: Label = %TitleLabel
@onready var animations_label: Label = %AnimationsLabel
@onready var reduced_motion_label: Label = %ReducedMotionLabel
@onready var music_label: Label = %MusicLabel
@onready var sound_effects_label: Label = %SoundEffectsLabel

var _settings_manager


func _ready() -> void:
	back_button.delayed_pressed.connect(_on_back_button_delayed_pressed)
	animations_toggle.delayed_pressed.connect(_on_toggle_delayed_pressed.bind("animations"))
	reduced_motion_toggle.delayed_pressed.connect(_on_toggle_delayed_pressed.bind("reduced_motion"))
	if debug_labels_toggle != null:
		debug_labels_toggle.delayed_pressed.connect(_on_toggle_delayed_pressed.bind("debug_labels"))
	music_toggle.delayed_pressed.connect(_on_toggle_delayed_pressed.bind("music"))
	sound_effects_toggle.delayed_pressed.connect(_on_toggle_delayed_pressed.bind("sound_effects"))
	_bind_static_ui_assets()
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
	for toggle in _visible_toggles():
		TEXT_STYLE_APPLIER_SCRIPT.apply_to_child_label(toggle, "TextMargin/Label", "settings.option_value")


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
	for toggle in _visible_toggles():
		_refresh_toggle_fallback_text(toggle)


func _bind_static_ui_assets() -> void:
	_apply_background_texture()
	_apply_settings_window_texture()
	_bind_back_button_textures()


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

	for toggle in _visible_toggles():
		_refresh_toggle_button(toggle, _get_toggle_value(_toggle_id_for_button(toggle)))


## Maps a toggle_id to its PlayerSettings field so save/load stays wired
## through the same SettingsManager API the CheckButton version used.
func _get_toggle_value(toggle_id: String) -> bool:
	if _settings_manager == null:
		return false
	var settings: PlayerSettings = _settings_manager.get_settings()
	match toggle_id:
		"animations":
			return settings.animations_enabled
		"reduced_motion":
			return settings.reduced_motion_enabled
		"music":
			return settings.music_enabled
		"sound_effects":
			return settings.sound_effects_enabled
		"debug_labels":
			return settings.debug_labels_enabled
	return false


func _set_toggle_value(toggle_id: String, value: bool) -> void:
	if _settings_manager == null:
		return
	match toggle_id:
		"animations":
			_settings_manager.set_animations_enabled(value)
		"reduced_motion":
			_settings_manager.set_reduced_motion_enabled(value)
		"music":
			_settings_manager.set_music_enabled(value)
			_apply_audio_manager_settings()
		"sound_effects":
			_settings_manager.set_sound_effects_enabled(value)
			_apply_audio_manager_settings()
		"debug_labels":
			_settings_manager.set_debug_labels_enabled(value)


func _toggle_setting(button_id: String) -> void:
	if _settings_manager == null:
		return
	var new_value := not _get_toggle_value(button_id)
	_set_toggle_value(button_id, new_value)
	_refresh_toggle_button(_button_for_toggle_id(button_id), new_value)


func _on_toggle_delayed_pressed(toggle_id: String) -> void:
	_play_button_click()
	_toggle_setting(toggle_id)


func _visible_toggles() -> Array:
	var toggles := [animations_toggle, reduced_motion_toggle, music_toggle, sound_effects_toggle]
	if debug_labels_toggle != null:
		toggles.append(debug_labels_toggle)
	return toggles


func _toggle_id_for_button(toggle: PressableTextureButton) -> String:
	if toggle == animations_toggle:
		return "animations"
	if toggle == reduced_motion_toggle:
		return "reduced_motion"
	if toggle == music_toggle:
		return "music"
	if toggle == sound_effects_toggle:
		return "sound_effects"
	if toggle == debug_labels_toggle:
		return "debug_labels"
	return ""


func _button_for_toggle_id(toggle_id: String) -> PressableTextureButton:
	match toggle_id:
		"animations":
			return animations_toggle
		"reduced_motion":
			return reduced_motion_toggle
		"music":
			return music_toggle
		"sound_effects":
			return sound_effects_toggle
		"debug_labels":
			return debug_labels_toggle
	return null


## Sets the button's texture to match the given value and falls back to an
## "On"/"Off" label when toggle_on.png / toggle_off.png are not present,
## so the control stays legible even without art.
func _refresh_toggle_button(button: PressableTextureButton, value: bool) -> void:
	if button == null:
		return

	var ui_id := "toggle_on" if value else "toggle_off"
	var asset_key := ASSET_KEY_RESOLVER_SCRIPT.get_ui_asset_key(ui_id)
	var texture := UI_ASSET_BINDING_SCRIPT.bind_asset_key(button, asset_key, ui_id)
	button.set_normal_texture(texture)
	button.set_meta("toggle_value", value)
	_refresh_toggle_fallback_text(button)


func _refresh_toggle_fallback_text(button: PressableTextureButton) -> void:
	if button == null:
		return

	if button.normal_texture != null:
		button.set_button_text("")
		return

	var value: bool = button.get_meta("toggle_value", false)
	var localization_manager := get_node_or_null("/root/LocalizationManager")
	if localization_manager != null:
		button.set_button_text(localization_manager.tr_key("ui.common.on" if value else "ui.common.off"))
	else:
		button.set_button_text("On" if value else "Off")


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
