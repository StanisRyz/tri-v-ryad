extends Control

const LEVEL_CATALOG_SCRIPT := preload("res://scripts/game/config/level_catalog.gd")
const LEVEL_ZONE_HELPER_SCRIPT := preload("res://scripts/game/config/level_zone_helper.gd")
const LEVEL_LABEL_FORMATTER_SCRIPT := preload("res://scripts/game/config/level_label_formatter.gd")
const ASSET_KEY_RESOLVER_SCRIPT := preload("res://scripts/game/config/asset_key_resolver.gd")
const GAME_ASSET_CATALOG_SCRIPT := preload("res://scripts/game/config/game_asset_catalog.gd")
const UI_ASSET_BINDING_SCRIPT := preload("res://scripts/ui/ui_asset_binding.gd")
const LEVEL_MAP_BUTTON_SCRIPT := preload("res://scripts/ui/level_select/level_map_button.gd")

signal level_selected(level_id: String)
signal settings_pressed
signal back_pressed

const LEVEL_SLOT_COUNT := 5

@onready var back_button: PressableTextureButton = %BackButton
@onready var zone_selector: OptionButton = %ZoneSelector
@onready var background_slot: FallbackImageSlot = %Background
@onready var level_button_1: LevelMapButton = %LevelButton1
@onready var level_button_2: LevelMapButton = %LevelButton2
@onready var level_button_3: LevelMapButton = %LevelButton3
@onready var level_button_4: LevelMapButton = %LevelButton4
@onready var level_button_5: LevelMapButton = %LevelButton5
@onready var level_info_popup: Control = %LevelInfoPopup
@onready var popup_window_slot: FallbackImageSlot = %PopupWindow
@onready var popup_level_title_label: Label = %LevelTitleLabel
@onready var popup_start_button: PressableTextureButton = %StartButton
@onready var popup_back_button: PressableTextureButton = %PopupBackButton

var _level_buttons: Array[LevelMapButton] = []

var _level_catalog = LEVEL_CATALOG_SCRIPT.new()
var _progress_manager
var _settings_manager
var _selected_zone_index := -1
var _has_manual_zone_selection := false
var _slot_level_ids: Array[String] = ["", "", "", "", ""]
var _pending_level_id := ""


func _ready() -> void:
	_level_buttons = [level_button_1, level_button_2, level_button_3, level_button_4, level_button_5]
	_bind_static_ui_assets()
	back_button.delayed_pressed.connect(_on_back_button_pressed)
	zone_selector.item_selected.connect(_on_zone_selected)
	for slot_index in range(_level_buttons.size()):
		_level_buttons[slot_index].pressed.connect(_on_level_button_pressed.bind(slot_index))
	popup_start_button.delayed_pressed.connect(_on_popup_start_button_pressed)
	popup_back_button.delayed_pressed.connect(_on_popup_back_button_pressed)
	_style_zone_selector_popup()
	_refresh()


func _bind_static_ui_assets() -> void:
	background_slot.texture = UI_ASSET_BINDING_SCRIPT.bind_ui_asset(background_slot, "level_select_background")
	UI_ASSET_BINDING_SCRIPT.bind_ui_asset(zone_selector, "zone_selector_panel")
	_bind_back_button_textures()
	_bind_pressable_texture_button(popup_start_button, "shared_back_button_default", "shared_back_button_pressed")
	_bind_pressable_texture_button(popup_back_button, "shared_back_button_default", "shared_back_button_pressed")

	var default_texture := _load_ui_texture("level_button_default")
	var locked_overlay_texture := _load_ui_texture("level_button_locked_overlay")
	var completed_overlay_texture := _load_ui_texture("level_button_completed_overlay")
	var pressed_texture := _load_ui_texture("level_button_pressed")
	for button in _level_buttons:
		if button.default_texture == null:
			button.default_texture = default_texture
		if button.locked_overlay_texture == null:
			button.locked_overlay_texture = locked_overlay_texture
		if button.completed_overlay_texture == null:
			button.completed_overlay_texture = completed_overlay_texture
		if button.pressed_texture == null:
			button.pressed_texture = pressed_texture


func _load_ui_texture(ui_id: String) -> Texture2D:
	var asset_key: String = ASSET_KEY_RESOLVER_SCRIPT.get_ui_asset_key(ui_id)
	return GAME_ASSET_CATALOG_SCRIPT.try_load_texture_cached(asset_key)


func _bind_back_button_textures() -> void:
	_bind_pressable_texture_button(back_button, "shared_back_button_default", "shared_back_button_pressed")


func _bind_pressable_texture_button(button: PressableTextureButton, normal_key: String, pressed_key: String) -> void:
	if button.normal_texture == null:
		var normal_texture := _load_ui_texture(normal_key)
		if normal_texture != null:
			button.set_normal_texture(normal_texture)

	if button.pressed_texture == null:
		var pressed_texture := _load_ui_texture(pressed_key)
		if pressed_texture != null:
			button.set_pressed_texture(pressed_texture)


func set_progress_manager(progress_manager) -> void:
	_progress_manager = progress_manager
	if is_inside_tree():
		_refresh()


func set_settings_manager(settings_manager) -> void:
	_settings_manager = settings_manager
	if is_inside_tree():
		_refresh()


func refresh_progress_state() -> void:
	_refresh()


func _refresh() -> void:
	_build_zone_selector()
	_refresh_level_button_slots()


func _build_zone_selector() -> void:
	zone_selector.clear()

	var levels: Array = _level_catalog.get_all_levels()
	var total_levels := levels.size()
	var zone_count: int = LEVEL_ZONE_HELPER_SCRIPT.get_zone_count(total_levels)
	var unlocked_zone_indices: Array[int] = []
	for zone_index in range(zone_count):
		if _is_zone_unlocked(zone_index):
			unlocked_zone_indices.append(zone_index)

	if unlocked_zone_indices.is_empty():
		unlocked_zone_indices.append(0)

	var highest_unlocked_zone_index: int = unlocked_zone_indices[unlocked_zone_indices.size() - 1]
	if not _has_manual_zone_selection or not unlocked_zone_indices.has(_selected_zone_index):
		_selected_zone_index = highest_unlocked_zone_index

	var selected_item_index := 0
	for zone_index in unlocked_zone_indices:
		var level_range: Vector2i = LEVEL_ZONE_HELPER_SCRIPT.get_level_range_for_zone(zone_index, total_levels)
		var label: String = LEVEL_ZONE_HELPER_SCRIPT.format_zone_label(zone_index, level_range.x, level_range.y)
		label += " %s" % _format_zone_stars(_get_zone_rating_stars(zone_index))
		zone_selector.add_item(label, zone_index)
		if zone_index == _selected_zone_index:
			selected_item_index = zone_selector.get_item_count() - 1

	zone_selector.select(selected_item_index)
	_style_zone_selector_popup()


func _style_zone_selector_popup() -> void:
	var popup := zone_selector.get_popup()
	if popup == null:
		return

	popup.add_theme_font_size_override("font_size", 26)
	popup.add_theme_constant_override("v_separation", 18)
	popup.add_theme_constant_override("item_start_padding", 16)
	popup.add_theme_constant_override("item_end_padding", 16)


func _get_zone_rating_stars(zone_index: int) -> int:
	var levels: Array = _level_catalog.get_all_levels()
	var level_range: Vector2i = LEVEL_ZONE_HELPER_SCRIPT.get_level_range_for_zone(zone_index, levels.size())
	if level_range == Vector2i.ZERO:
		return 1

	var earned_stars := 0
	var max_stars := 0
	for level_number in range(level_range.x, level_range.y + 1):
		earned_stars += _get_level_stars("level_%d" % level_number)
		max_stars += 3

	if max_stars <= 0:
		return 1
	if earned_stars == max_stars:
		return 3
	if float(earned_stars) / float(max_stars) >= 0.5:
		return 2
	return 1


func _format_zone_stars(stars: int) -> String:
	var clamped_stars: int = clampi(stars, 1, 3)
	return "★".repeat(clamped_stars) + "☆".repeat(3 - clamped_stars)


func _refresh_level_button_slots() -> void:
	var levels: Array = _level_catalog.get_all_levels()
	var level_range: Vector2i = LEVEL_ZONE_HELPER_SCRIPT.get_level_range_for_zone(_selected_zone_index, levels.size())

	for slot_index in range(LEVEL_SLOT_COUNT):
		var button := _level_buttons[slot_index]
		var level_number := level_range.x + slot_index

		if level_range == Vector2i.ZERO or level_number > level_range.y:
			button.visible = false
			_slot_level_ids[slot_index] = ""
			continue

		var level_config = _level_catalog.get_level("level_%d" % level_number)
		var unlocked := _is_level_unlocked(level_config.level_id)
		var completed := _is_level_completed(level_config.level_id)
		var stars := _get_level_stars(level_config.level_id)

		_slot_level_ids[slot_index] = level_config.level_id
		button.visible = true
		button.level_text = str(level_number)
		if _is_debug_labels_enabled():
			button.level_text = "%d (%s)" % [level_number, level_config.level_id]
		button.state = _get_level_button_state(completed, unlocked)
		button.disabled = not unlocked
		button.set_meta("star_asset_keys", _get_star_asset_keys(stars))
		button.set_meta("level_stars", stars)


func _get_level_button_state(completed: bool, unlocked: bool) -> String:
	if completed:
		return LEVEL_MAP_BUTTON_SCRIPT.STATE_COMPLETED
	if unlocked:
		return LEVEL_MAP_BUTTON_SCRIPT.STATE_OPEN
	return LEVEL_MAP_BUTTON_SCRIPT.STATE_LOCKED


func _on_zone_selected(item_index: int) -> void:
	_selected_zone_index = zone_selector.get_item_id(item_index)
	_has_manual_zone_selection = true
	_refresh_level_button_slots()


func _on_level_button_pressed(slot_index: int) -> void:
	var level_id: String = _slot_level_ids[slot_index]
	if level_id == "":
		return
	if not _is_level_unlocked(level_id):
		return

	_show_level_info_popup(level_id)


func _show_level_info_popup(level_id: String) -> void:
	_pending_level_id = level_id

	var level_number := LEVEL_LABEL_FORMATTER_SCRIPT.extract_level_number(level_id)
	var level_config = _level_catalog.get_level(level_id)
	popup_level_title_label.text = LEVEL_LABEL_FORMATTER_SCRIPT.format_level_label(level_id, level_config.display_name) if level_number <= 0 else "Level %d" % level_number
	_apply_popup_window_texture(_get_level_stars(level_id))

	level_info_popup.visible = true


func _hide_level_info_popup() -> void:
	level_info_popup.visible = false
	_pending_level_id = ""


func _apply_popup_window_texture(stars: int) -> void:
	popup_window_slot.texture = _load_ui_texture(_get_popup_window_asset_id(stars))


func _get_popup_window_asset_id(stars: int) -> String:
	var clamped_stars: int = clampi(stars, 0, 3)
	match clamped_stars:
		0:
			return "level_info_window_0_stars"
		1:
			return "level_info_window_1_star"
		2:
			return "level_info_window_2_stars"
		_:
			return "level_info_window_3_stars"


func _on_popup_start_button_pressed() -> void:
	if _pending_level_id == "":
		return

	var level_id := _pending_level_id
	_hide_level_info_popup()
	_play_level_select()
	level_selected.emit(level_id)


func _on_popup_back_button_pressed() -> void:
	_play_button_click()
	_hide_level_info_popup()


func _on_back_button_pressed() -> void:
	_play_button_click()
	back_pressed.emit()


func _is_level_unlocked(level_id: String) -> bool:
	if _progress_manager == null:
		return level_id == _level_catalog.get_default_level_id()
	return _progress_manager.is_level_unlocked(_level_catalog, level_id)


func _is_zone_unlocked(zone_index: int) -> bool:
	if zone_index <= 0:
		return true

	var unlock_level_id: String = LEVEL_ZONE_HELPER_SCRIPT.get_zone_unlock_level_id(zone_index)
	if unlock_level_id == "":
		return false
	return _is_level_completed(unlock_level_id)


func _is_level_completed(level_id: String) -> bool:
	if _progress_manager == null:
		return false
	return _progress_manager.is_level_completed(level_id)


func _get_level_stars(level_id: String) -> int:
	if _progress_manager == null:
		return 0
	return _progress_manager.get_level_stars(level_id)


func _get_star_asset_keys(stars: int) -> Array[String]:
	var keys: Array[String] = []
	for star_index in range(3):
		keys.append(ASSET_KEY_RESOLVER_SCRIPT.get_star_asset_key(star_index < stars))
	return keys


func _is_debug_labels_enabled() -> bool:
	if _settings_manager == null:
		return false
	return _settings_manager.get_settings().debug_labels_enabled


func _play_button_click() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.play_button_click()


func _play_level_select() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.play_level_select()
