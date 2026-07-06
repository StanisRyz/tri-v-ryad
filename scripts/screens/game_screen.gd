extends Control

signal back_pressed
signal upgrades_pressed

const BATTLE_PRESENTER_SCRIPT := preload("res://scripts/game/presentation/battle_presenter.gd")
const BOARD_INPUT_CONTROLLER_SCRIPT := preload("res://scripts/game/input/board_input_controller.gd")
const TURN_FEEDBACK_PRESENTER_SCRIPT := preload("res://scripts/game/presentation/turn_feedback_presenter.gd")
const ABILITY_FEEDBACK_PRESENTER_SCRIPT := preload("res://scripts/game/presentation/ability_feedback_presenter.gd")
const LEVEL_LABEL_FORMATTER_SCRIPT := preload("res://scripts/game/config/level_label_formatter.gd")
const BATTLE_MESSAGE_FORMATTER_SCRIPT := preload("res://scripts/game/presentation/battle_message_formatter.gd")
const ASSET_KEY_RESOLVER_SCRIPT := preload("res://scripts/game/config/asset_key_resolver.gd")
const UI_ASSET_BINDING_SCRIPT := preload("res://scripts/ui/ui_asset_binding.gd")
const PORTRAIT_CONTENT_WIDTH := 664.0
const PORTRAIT_BOARD_SIZE := PORTRAIT_CONTENT_WIDTH
const LANDSCAPE_CONTENT_WIDTH := 560.0
const LANDSCAPE_BOARD_SIZE := 320.0

@onready var menu_button: Button = %MenuButton
@onready var battle_root: VBoxContainer = %BattleRoot
@onready var battle_hud: PanelContainer = %BattleHud
@onready var enemy_panel: PanelContainer = %EnemyPanel
@onready var board_view: Control = %BoardView
@onready var status_label: Label = %StatusLabel
@onready var hero_party_panel: HBoxContainer = %HeroPartyPanel
@onready var booster_panel = %BoosterPanel
@onready var result_overlay: PanelContainer = %BattleResultOverlay
@onready var background_slot: ImageSlot = %Background
@onready var round_modifier_panel: PanelContainer = %RoundModifierPanel
@onready var modifier_name_label: Label = %ModifierNameLabel
@onready var modifier_description_label: Label = %ModifierDescriptionLabel

var _layout_manager: LayoutManager
var _presenter
var _input_controller
var _turn_feedback_presenter
var _ability_feedback_presenter
var _pending_battle_status := -1
var _feedback_active := false
var _current_level_id := "level_1"
var _current_level_name := "Level 1"
var _progress_manager
var _settings_manager
var _reward_granted_for_current_battle := false
var _last_reward_amount := 0
var _completion_saved_for_current_battle := false
var _last_stars_earned := 0
var _debug_labels_enabled := false
var _input_mode := "normal"
var _selected_booster_id := ""

func _ready() -> void:
	if not menu_button.pressed.is_connected(_on_menu_button_pressed):
		menu_button.pressed.connect(_on_menu_button_pressed)

	_bind_static_ui_assets()
	_layout_manager = LayoutManager.new(get_viewport())
	_layout_manager.layout_changed.connect(_on_layout_changed)

	_setup_playable_battle()
	_apply_layout(_layout_manager.get_layout_mode())


func _bind_static_ui_assets() -> void:
	UI_ASSET_BINDING_SCRIPT.bind_ui_asset(battle_hud, "battle_hud_panel")
	UI_ASSET_BINDING_SCRIPT.bind_ui_asset(enemy_panel, "enemy_panel")
	UI_ASSET_BINDING_SCRIPT.bind_ui_asset(round_modifier_panel, "round_modifier_panel")
	UI_ASSET_BINDING_SCRIPT.bind_ui_asset(status_label, "status_panel")
	UI_ASSET_BINDING_SCRIPT.bind_ui_asset(result_overlay, "result_panel")


func _on_menu_button_pressed() -> void:
	_play_button_click()
	back_pressed.emit()


func _on_layout_changed(mode: int) -> void:
	_apply_layout(mode)


func _apply_layout(mode: int) -> void:
	if mode == LayoutManager.LANDSCAPE:
		_apply_landscape_layout()
	else:
		_apply_portrait_layout()


func _apply_portrait_layout() -> void:
	battle_root.custom_minimum_size = Vector2(PORTRAIT_CONTENT_WIDTH, 0)
	battle_root.add_theme_constant_override("separation", 12)
	menu_button.custom_minimum_size = Vector2(118, 60)
	battle_hud.custom_minimum_size = Vector2(0, 60)
	enemy_panel.custom_minimum_size = Vector2(0, 132)
	board_view.custom_minimum_size = Vector2(PORTRAIT_BOARD_SIZE, PORTRAIT_BOARD_SIZE)
	hero_party_panel.custom_minimum_size = Vector2(PORTRAIT_CONTENT_WIDTH, 132)
	booster_panel.custom_minimum_size = Vector2(PORTRAIT_CONTENT_WIDTH, 132)


func _apply_landscape_layout() -> void:
	battle_root.custom_minimum_size = Vector2(LANDSCAPE_CONTENT_WIDTH, 0)
	battle_root.add_theme_constant_override("separation", 10)
	menu_button.custom_minimum_size = Vector2(104, 52)
	battle_hud.custom_minimum_size = Vector2(0, 52)
	enemy_panel.custom_minimum_size = Vector2(0, 92)
	board_view.custom_minimum_size = Vector2(LANDSCAPE_BOARD_SIZE, LANDSCAPE_BOARD_SIZE)
	hero_party_panel.custom_minimum_size = Vector2(LANDSCAPE_CONTENT_WIDTH, 96)
	booster_panel.custom_minimum_size = Vector2(LANDSCAPE_CONTENT_WIDTH, 96)


func _setup_playable_battle() -> void:
	_presenter = BATTLE_PRESENTER_SCRIPT.new()
	if _progress_manager != null:
		_presenter.set_progress(_progress_manager.get_progress())
		_presenter.set_hero_catalog(_progress_manager.get_hero_catalog())
	_input_controller = BOARD_INPUT_CONTROLLER_SCRIPT.new()
	_turn_feedback_presenter = TURN_FEEDBACK_PRESENTER_SCRIPT.new()
	_ability_feedback_presenter = ABILITY_FEEDBACK_PRESENTER_SCRIPT.new()

	board_view.tile_pressed.connect(_input_controller.handle_tile_pressed)
	board_view.tile_pressed.connect(_on_board_tile_pressed)
	board_view.tile_drag_released.connect(_input_controller.handle_tile_drag_released)
	_input_controller.swap_requested.connect(_on_swap_requested)
	_input_controller.selection_changed.connect(_on_selection_changed)
	_input_controller.selection_cleared.connect(_on_selection_cleared)
	_input_controller.invalid_input.connect(_on_invalid_input)
	if FeatureFlags.HERO_SYSTEMS_ENABLED:
		hero_party_panel.ability_requested.connect(_on_ability_requested)
		booster_panel.visible = false
	else:
		hero_party_panel.visible = false
		booster_panel.visible = true
		booster_panel.setup_boosters(_presenter.get_booster_catalog())
		booster_panel.booster_pressed.connect(_on_booster_pressed)

	_presenter.board_changed.connect(_on_board_changed)
	_presenter.battle_state_changed.connect(_on_battle_state_changed)
	_presenter.level_changed.connect(_on_level_changed)
	_presenter.turn_resolved.connect(_on_turn_resolved)
	_presenter.turn_presentation_ready.connect(_on_turn_presentation_ready)
	_presenter.ability_presentation_ready.connect(_on_ability_presentation_ready)
	_presenter.invalid_swap.connect(_on_invalid_swap)
	_presenter.battle_finished.connect(_on_battle_finished)
	_presenter.battle_background_changed.connect(_on_battle_background_changed)
	_presenter.round_modifier_changed.connect(_on_round_modifier_changed)
	_presenter.booster_state_changed.connect(_on_booster_state_changed)
	_presenter.booster_resolved.connect(_on_booster_resolved)
	_turn_feedback_presenter.feedback_finished.connect(_on_feedback_finished)
	_ability_feedback_presenter.feedback_finished.connect(_on_feedback_finished)

	result_overlay.restart_pressed.connect(_on_restart_pressed)
	result_overlay.menu_pressed.connect(_on_menu_button_pressed)
	result_overlay.upgrades_pressed.connect(_on_upgrades_pressed)
	_start_new_battle()


func _start_new_battle() -> void:
	_pending_battle_status = -1
	_feedback_active = false
	_reward_granted_for_current_battle = false
	_last_reward_amount = 0
	_completion_saved_for_current_battle = false
	_last_stars_earned = 0
	result_overlay.hide_result()
	board_view.clear_lane_highlights()
	board_view.clear_cell_highlights()
	_set_input_mode("normal", "")
	_input_controller.set_input_enabled(true)
	_set_status("Select a tile")
	_presenter.start_level(_current_level_id)


func _on_board_changed(board: BoardModel) -> void:
	board_view.set_board(board)


func _on_battle_state_changed(state: BattleState) -> void:
	if battle_hud.has_method("set_values"):
		battle_hud.set_values(LEVEL_LABEL_FORMATTER_SCRIPT.format_level_label(_current_level_id, _current_level_name), "Moves: %d" % state.moves_left)

	if enemy_panel.has_method("set_enemy_state"):
		enemy_panel.set_enemy_state(state.enemy, state.enemy_intent)

	if FeatureFlags.HERO_SYSTEMS_ENABLED and hero_party_panel.has_method("set_heroes"):
		hero_party_panel.set_heroes(state.heroes)

	if not FeatureFlags.HERO_SYSTEMS_ENABLED and booster_panel != null and state.get("booster_state") != null:
		booster_panel.set_booster_state(state.get("booster_state"))


func _on_battle_background_changed(background_config) -> void:
	if background_config == null:
		return

	if background_slot == null:
		return

	if background_config.placeholder_color is Color:
		background_slot.set_placeholder_color(background_config.placeholder_color)
	var asset_key: String = background_config.asset_key if "asset_key" in background_config else ""
	if asset_key == "":
		asset_key = ASSET_KEY_RESOLVER_SCRIPT.get_background_asset_key(background_config.background_id)
	background_slot.set_asset_key(asset_key)


func _on_round_modifier_changed(modifier) -> void:
	if modifier == null:
		round_modifier_panel.visible = false
		return

	round_modifier_panel.visible = true
	modifier_name_label.text = modifier.display_name
	modifier_description_label.text = modifier.description


func _on_level_changed(level_config) -> void:
	_current_level_id = level_config.level_id
	_current_level_name = level_config.display_name


func _on_turn_resolved(_result: BattleTurnResult) -> void:
	pass


func _on_invalid_swap(_reason: String) -> void:
	pass


func _on_battle_finished(status: int) -> void:
	_input_controller.set_input_enabled(false)
	_pending_battle_status = status
	if _feedback_active:
		return

	_show_battle_result(status)


func _on_turn_presentation_ready(data) -> void:
	_play_turn_audio(data)
	_feedback_active = true
	_turn_feedback_presenter.play_turn_feedback(data, board_view, Callable(self, "_set_status"))


func _on_ability_presentation_ready(data) -> void:
	_feedback_active = true
	_ability_feedback_presenter.play_ability_feedback(data, board_view, Callable(self, "_set_status"))


func _on_feedback_finished() -> void:
	_feedback_active = false
	if _pending_battle_status != -1:
		_show_battle_result(_pending_battle_status)
		return

	if not _presenter.is_battle_finished():
		_input_controller.set_input_enabled(true)
		if _input_mode == "booster_targeting":
			_input_controller.set_input_enabled(false)


func _show_battle_result(status: int) -> void:
	_input_controller.set_input_enabled(false)
	if status == BattleState.Status.VICTORY:
		_play_victory()
		_grant_victory_reward_once()
		_save_victory_completion_once()
		_set_status(BATTLE_MESSAGE_FORMATTER_SCRIPT.format_victory_message(_last_reward_amount, _last_stars_earned))
		result_overlay.show_victory(_last_reward_amount, _last_stars_earned)
	elif status == BattleState.Status.DEFEAT:
		_play_defeat()
		_set_status(BATTLE_MESSAGE_FORMATTER_SCRIPT.format_defeat_message())
		result_overlay.show_defeat()


func _grant_victory_reward_once() -> void:
	if _reward_granted_for_current_battle:
		return

	_reward_granted_for_current_battle = true
	_last_reward_amount = 0
	if _progress_manager == null or _presenter == null or _presenter.current_level_config == null:
		return

	_last_reward_amount = _progress_manager.add_victory_reward(_presenter.current_level_config)


func _save_victory_completion_once() -> void:
	if _completion_saved_for_current_battle:
		return

	_completion_saved_for_current_battle = true
	_last_stars_earned = 0
	if _progress_manager == null or _presenter == null or _presenter.current_level_config == null or _presenter.state == null:
		return

	var state = _progress_manager.complete_level(_presenter.current_level_config, _presenter.state.moves_left)
	if state != null:
		_last_stars_earned = state.stars


func _on_selection_changed(cell: Vector2i) -> void:
	if _input_mode == "booster_targeting":
		return
	board_view.set_selected_cell(cell)
	_set_status("Choose a neighboring tile")


func _on_selection_cleared() -> void:
	if _input_mode == "booster_targeting":
		return
	board_view.clear_selected_cell()
	_set_status("Select a tile")


func _on_invalid_input(reason: String) -> void:
	if reason == "input_locked" and (_input_mode == "booster_targeting" or _feedback_active):
		return
	_play_invalid_swap()
	_set_status(BATTLE_MESSAGE_FORMATTER_SCRIPT.format_invalid_input_message(reason))


func _on_swap_requested(from_cell: Vector2i, to_cell: Vector2i) -> void:
	if _input_mode != "normal":
		return
	_input_controller.set_input_enabled(false)
	board_view.clear_lane_highlights()
	board_view.clear_cell_highlights()
	_set_status("Resolving match...")
	_presenter.request_swap(from_cell, to_cell)


func _on_ability_requested(lane_index: int) -> void:
	_input_controller.set_input_enabled(false)
	board_view.clear_lane_highlights()
	board_view.clear_cell_highlights()
	_set_status("Using ability...")
	_presenter.request_ability(lane_index)


func _on_booster_state_changed(booster_state) -> void:
	if booster_panel != null:
		booster_panel.set_booster_state(booster_state)


func _on_booster_pressed(booster_id: String) -> void:
	if _presenter == null or _presenter.state == null or _presenter.is_battle_finished():
		return

	var config = _presenter.get_booster_catalog().get_booster(booster_id)
	if config == null:
		_play_invalid_swap()
		_set_status("Booster unavailable.")
		return

	var booster_state = _presenter.state.get("booster_state")
	if booster_state == null or not booster_state.can_use(booster_id):
		_play_invalid_swap()
		_set_status("Booster already used.")
		return

	if config.is_targeted():
		if _input_mode == "booster_targeting" and _selected_booster_id == booster_id:
			_set_input_mode("normal", "")
			_set_status("Select a tile")
			return

		_play_button_click()
		_set_input_mode("booster_targeting", booster_id)
		if booster_id == "hammer":
			_set_status("Select a crystal for Hammer.")
		else:
			_set_status("Select a crystal for Rocket Barrage.")
		return

	_play_special_activate()
	_presenter.request_booster_activation(booster_id)


func _on_board_tile_pressed(cell: Vector2i) -> void:
	if _input_mode != "booster_targeting" or _selected_booster_id == "":
		return

	_input_controller.set_input_enabled(false)
	board_view.clear_selected_cell()
	board_view.clear_cell_highlights()
	_set_status("Using booster...")
	_presenter.request_targeted_booster(_selected_booster_id, cell)
	_set_input_mode("normal", "")


func _on_booster_resolved(result) -> void:
	if result == null:
		return

	if not result.is_valid:
		_play_invalid_swap()
		_set_status(result.message)
		_input_controller.set_input_enabled(true)
		return

	if result.freeze_turns_added > 0:
		_play_special_activate()
	else:
		_play_special_activate()
		if result.damage_to_enemy > 0:
			_play_enemy_damage()
		board_view.highlight_cells(result.cleared_cells)

	_set_status(result.message)
	if not _presenter.is_battle_finished():
		_input_controller.set_input_enabled(true)


func _on_restart_pressed() -> void:
	_play_button_click()
	_start_new_battle()


func _on_upgrades_pressed() -> void:
	_play_button_click()
	upgrades_pressed.emit()


func _set_status(message: String) -> void:
	status_label.text = message


func _set_input_mode(mode: String, booster_id: String) -> void:
	_input_mode = mode
	_selected_booster_id = booster_id
	if booster_panel != null:
		booster_panel.set_selected_booster(booster_id)
	if _input_controller != null:
		_input_controller.set_input_enabled(mode == "normal")


func set_level_id(level_id: String) -> void:
	_current_level_id = level_id if level_id != "" else "level_1"
	if _presenter != null:
		_start_new_battle()


func set_progress_manager(progress_manager) -> void:
	_progress_manager = progress_manager
	if _presenter != null and _progress_manager != null:
		_presenter.set_progress(_progress_manager.get_progress())
		_presenter.set_hero_catalog(_progress_manager.get_hero_catalog())


func set_settings_manager(settings_manager) -> void:
	_settings_manager = settings_manager
	_apply_presentation_settings()


func _apply_presentation_settings() -> void:
	var settings = _settings_manager.get_settings() if _settings_manager != null else null
	var animations_enabled: bool = settings.animations_enabled if settings != null else true
	var reduced_motion_enabled: bool = settings.reduced_motion_enabled if settings != null else false
	_debug_labels_enabled = settings.debug_labels_enabled if settings != null else false

	TileView.configure_presentation(animations_enabled, reduced_motion_enabled)
	HeroCard.set_debug_labels_enabled(_debug_labels_enabled)
	HeroCard.set_presentation_settings(animations_enabled, reduced_motion_enabled)
	if _turn_feedback_presenter != null:
		_turn_feedback_presenter.configure_settings(animations_enabled, reduced_motion_enabled, _debug_labels_enabled)
	if _ability_feedback_presenter != null:
		_ability_feedback_presenter.configure_settings(animations_enabled, reduced_motion_enabled, _debug_labels_enabled)


func _play_turn_audio(data) -> void:
	if data == null:
		return

	if not data.is_valid:
		_play_invalid_swap()
		return

	_play_tile_swap()
	if not data.activated_special_tiles.is_empty():
		_play_special_activate()

	if data.total_damage_to_enemy > 0:
		_play_match()
		_play_enemy_damage()


func _get_audio_manager():
	return get_node_or_null("/root/AudioManager")


func _play_button_click() -> void:
	var audio_manager = _get_audio_manager()
	if audio_manager != null:
		audio_manager.play_button_click()


func _play_tile_swap() -> void:
	var audio_manager = _get_audio_manager()
	if audio_manager != null:
		audio_manager.play_tile_swap()


func _play_match() -> void:
	var audio_manager = _get_audio_manager()
	if audio_manager != null:
		audio_manager.play_match()


func _play_invalid_swap() -> void:
	var audio_manager = _get_audio_manager()
	if audio_manager != null:
		audio_manager.play_invalid_swap()


func _play_special_activate() -> void:
	var audio_manager = _get_audio_manager()
	if audio_manager != null:
		audio_manager.play_special_activate()


func _play_enemy_damage() -> void:
	var audio_manager = _get_audio_manager()
	if audio_manager != null:
		audio_manager.play_enemy_damage()


func _play_victory() -> void:
	var audio_manager = _get_audio_manager()
	if audio_manager != null:
		audio_manager.play_victory()


func _play_defeat() -> void:
	var audio_manager = _get_audio_manager()
	if audio_manager != null:
		audio_manager.play_defeat()
