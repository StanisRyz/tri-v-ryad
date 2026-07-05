extends Control

signal back_pressed
signal upgrades_pressed

const BATTLE_PRESENTER_SCRIPT := preload("res://scripts/game/presentation/battle_presenter.gd")
const BOARD_INPUT_CONTROLLER_SCRIPT := preload("res://scripts/game/input/board_input_controller.gd")
const TURN_FEEDBACK_PRESENTER_SCRIPT := preload("res://scripts/game/presentation/turn_feedback_presenter.gd")
const ABILITY_FEEDBACK_PRESENTER_SCRIPT := preload("res://scripts/game/presentation/ability_feedback_presenter.gd")
const LEVEL_LABEL_FORMATTER_SCRIPT := preload("res://scripts/game/config/level_label_formatter.gd")
const BATTLE_MESSAGE_FORMATTER_SCRIPT := preload("res://scripts/game/presentation/battle_message_formatter.gd")
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
@onready var result_overlay: PanelContainer = %BattleResultOverlay
@onready var background_rect: ColorRect = %Background
@onready var background_texture: TextureRect = %BackgroundTexture

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

func _ready() -> void:
	if not menu_button.pressed.is_connected(_on_menu_button_pressed):
		menu_button.pressed.connect(_on_menu_button_pressed)

	_layout_manager = LayoutManager.new(get_viewport())
	_layout_manager.layout_changed.connect(_on_layout_changed)

	_setup_playable_battle()
	_apply_layout(_layout_manager.get_layout_mode())


func _on_menu_button_pressed() -> void:
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


func _apply_landscape_layout() -> void:
	battle_root.custom_minimum_size = Vector2(LANDSCAPE_CONTENT_WIDTH, 0)
	battle_root.add_theme_constant_override("separation", 10)
	menu_button.custom_minimum_size = Vector2(104, 52)
	battle_hud.custom_minimum_size = Vector2(0, 52)
	enemy_panel.custom_minimum_size = Vector2(0, 92)
	board_view.custom_minimum_size = Vector2(LANDSCAPE_BOARD_SIZE, LANDSCAPE_BOARD_SIZE)
	hero_party_panel.custom_minimum_size = Vector2(LANDSCAPE_CONTENT_WIDTH, 96)


func _setup_playable_battle() -> void:
	_presenter = BATTLE_PRESENTER_SCRIPT.new()
	if _progress_manager != null:
		_presenter.set_progress(_progress_manager.get_progress())
		_presenter.set_hero_catalog(_progress_manager.get_hero_catalog())
	_input_controller = BOARD_INPUT_CONTROLLER_SCRIPT.new()
	_turn_feedback_presenter = TURN_FEEDBACK_PRESENTER_SCRIPT.new()
	_ability_feedback_presenter = ABILITY_FEEDBACK_PRESENTER_SCRIPT.new()

	board_view.tile_pressed.connect(_input_controller.handle_tile_pressed)
	board_view.tile_drag_released.connect(_input_controller.handle_tile_drag_released)
	_input_controller.swap_requested.connect(_on_swap_requested)
	_input_controller.selection_changed.connect(_on_selection_changed)
	_input_controller.selection_cleared.connect(_on_selection_cleared)
	_input_controller.invalid_input.connect(_on_invalid_input)
	hero_party_panel.ability_requested.connect(_on_ability_requested)

	_presenter.board_changed.connect(_on_board_changed)
	_presenter.battle_state_changed.connect(_on_battle_state_changed)
	_presenter.level_changed.connect(_on_level_changed)
	_presenter.turn_resolved.connect(_on_turn_resolved)
	_presenter.turn_presentation_ready.connect(_on_turn_presentation_ready)
	_presenter.ability_presentation_ready.connect(_on_ability_presentation_ready)
	_presenter.invalid_swap.connect(_on_invalid_swap)
	_presenter.battle_finished.connect(_on_battle_finished)
	_presenter.battle_background_changed.connect(_on_battle_background_changed)
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

	if hero_party_panel.has_method("set_heroes"):
		hero_party_panel.set_heroes(state.heroes)


func _on_battle_background_changed(background_config) -> void:
	if background_config == null:
		return

	if background_rect != null and background_config.placeholder_color is Color:
		background_rect.color = background_config.placeholder_color

	if background_texture == null:
		return

	var texture_path: String = background_config.texture_path if "texture_path" in background_config else ""
	if texture_path != "" and ResourceLoader.exists(texture_path):
		var texture := load(texture_path)
		if texture is Texture2D:
			background_texture.texture = texture
			background_texture.visible = true
			return

	background_texture.visible = false
	background_texture.texture = null


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


func _show_battle_result(status: int) -> void:
	_input_controller.set_input_enabled(false)
	if status == BattleState.Status.VICTORY:
		_grant_victory_reward_once()
		_save_victory_completion_once()
		_set_status(BATTLE_MESSAGE_FORMATTER_SCRIPT.format_victory_message(_last_reward_amount, _last_stars_earned))
		result_overlay.show_victory(_last_reward_amount, _last_stars_earned)
	elif status == BattleState.Status.DEFEAT:
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
	board_view.set_selected_cell(cell)
	_set_status("Choose a neighboring tile")


func _on_selection_cleared() -> void:
	board_view.clear_selected_cell()
	_set_status("Select a tile")


func _on_invalid_input(reason: String) -> void:
	_set_status(BATTLE_MESSAGE_FORMATTER_SCRIPT.format_invalid_input_message(reason))


func _on_swap_requested(from_cell: Vector2i, to_cell: Vector2i) -> void:
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


func _on_restart_pressed() -> void:
	_start_new_battle()


func _on_upgrades_pressed() -> void:
	upgrades_pressed.emit()


func _set_status(message: String) -> void:
	status_label.text = message


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
