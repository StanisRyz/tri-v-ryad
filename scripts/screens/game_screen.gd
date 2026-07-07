extends Control

signal back_pressed
signal upgrades_pressed

const BATTLE_PRESENTER_SCRIPT := preload("res://scripts/game/presentation/battle_presenter.gd")
const BOARD_INPUT_CONTROLLER_SCRIPT := preload("res://scripts/game/input/board_input_controller.gd")
const TURN_FEEDBACK_PRESENTER_SCRIPT := preload("res://scripts/game/presentation/turn_feedback_presenter.gd")
const ABILITY_FEEDBACK_PRESENTER_SCRIPT := preload("res://scripts/game/presentation/ability_feedback_presenter.gd")
const LEVEL_LABEL_FORMATTER_SCRIPT := preload("res://scripts/game/config/level_label_formatter.gd")
const DIRECT_BATTLE_BALANCE_SCRIPT := preload("res://scripts/game/config/direct_battle_balance.gd")
const LEVEL_BOOST_FORMATTER_SCRIPT := preload("res://scripts/game/presentation/level_boost_formatter.gd")
const LEVEL_CATALOG_SCRIPT := preload("res://scripts/game/config/level_catalog.gd")
const LEVEL_ZONE_HELPER_SCRIPT := preload("res://scripts/game/config/level_zone_helper.gd")
const LEVEL_COMPLETION_RESOLVER_SCRIPT := preload("res://scripts/game/progression/level_completion_resolver.gd")
const BATTLE_MESSAGE_FORMATTER_SCRIPT := preload("res://scripts/game/presentation/battle_message_formatter.gd")
const ASSET_KEY_RESOLVER_SCRIPT := preload("res://scripts/game/config/asset_key_resolver.gd")
const UI_ASSET_BINDING_SCRIPT := preload("res://scripts/ui/ui_asset_binding.gd")
const BOARD_ANIMATION_CONTROLLER_SCRIPT := preload("res://scripts/game/view/board_animation_controller.gd")
const BOARD_ANIMATION_SEQUENCE_BUILDER_SCRIPT := preload("res://scripts/game/presentation/board_animation_sequence_builder.gd")
const ANIMATED_TURN_FLOW_SCRIPT := preload("res://scripts/game/presentation/animated_turn_flow.gd")
const BATTLE_EFFECT_CONTROLLER_SCRIPT := preload("res://scripts/game/view/battle_effect_controller.gd")
const DAMAGE_PARTICLE_EVENT_BUILDER_SCRIPT := preload("res://scripts/game/presentation/damage_particle_event_builder.gd")
const AVAILABLE_MOVE_FINDER_SCRIPT := preload("res://scripts/game/board/available_move_finder.gd")
const BOARD_SHUFFLE_RESOLVER_SCRIPT := preload("res://scripts/game/board/board_shuffle_resolver.gd")
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
@onready var battle_effect_layer: Control = %BattleEffectLayer

var _layout_manager: LayoutManager
var _presenter
var _input_controller
var _turn_feedback_presenter
var _ability_feedback_presenter
var _board_animation_controller
var _board_animation_sequence_builder
var _animated_turn_flow
var _battle_effect_controller
var _damage_particle_event_builder
var _level_catalog = LEVEL_CATALOG_SCRIPT.new()
var _level_completion_resolver = LEVEL_COMPLETION_RESOLVER_SCRIPT.new()
var _animations_enabled := true
var _reduced_motion_enabled := false
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
var _last_victory_result_data: Dictionary = {}
var _debug_labels_enabled := false
var _current_generated_challenge
var _current_level_boost
var _input_mode := "normal"
var _selected_booster_id := ""
var _booster_preview_target_cell := Vector2i(-1, -1)
var _defer_board_update_for_turn := false
var _pending_board_for_animation: BoardModel
var _available_move_finder := AVAILABLE_MOVE_FINDER_SCRIPT.new()
var _board_shuffle_resolver := BOARD_SHUFFLE_RESOLVER_SCRIPT.new()
var _shuffle_rng := RandomNumberGenerator.new()
var _shuffle_count := 0
var _last_shuffle_debug_info: Dictionary = {}
var _last_booster_spend_failed := false

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
	_force_cleanup_visual_state()
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
	_board_animation_controller = BOARD_ANIMATION_CONTROLLER_SCRIPT.new()
	_board_animation_sequence_builder = BOARD_ANIMATION_SEQUENCE_BUILDER_SCRIPT.new()
	_animated_turn_flow = ANIMATED_TURN_FLOW_SCRIPT.new()
	_animated_turn_flow.configure(board_view, _board_animation_controller, _board_animation_sequence_builder)
	_shuffle_rng.randomize()
	_battle_effect_controller = BATTLE_EFFECT_CONTROLLER_SCRIPT.new()
	_damage_particle_event_builder = DAMAGE_PARTICLE_EVENT_BUILDER_SCRIPT.new()
	_apply_presentation_settings()

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
		_refresh_booster_inventory_ui()

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
	_presenter.level_boost_changed.connect(_on_level_boost_changed)
	_presenter.generated_challenge_changed.connect(_on_generated_challenge_changed)
	_presenter.booster_state_changed.connect(_on_booster_state_changed)
	_presenter.booster_resolved.connect(_on_booster_resolved)
	_presenter.swap_accepted.connect(_on_swap_accepted)
	_presenter.targeted_booster_accepted.connect(_on_targeted_booster_accepted)
	_turn_feedback_presenter.feedback_finished.connect(_on_feedback_finished)
	_ability_feedback_presenter.feedback_finished.connect(_on_feedback_finished)

	result_overlay.restart_pressed.connect(_on_restart_pressed)
	result_overlay.next_level_pressed.connect(_on_next_level_pressed)
	result_overlay.menu_pressed.connect(_on_menu_button_pressed)
	result_overlay.upgrades_pressed.connect(_on_upgrades_pressed)
	_start_new_battle()


func _start_new_battle() -> void:
	_force_cleanup_visual_state()
	_pending_battle_status = -1
	_feedback_active = false
	_reward_granted_for_current_battle = false
	_last_reward_amount = 0
	_completion_saved_for_current_battle = false
	_last_stars_earned = 0
	_last_victory_result_data = {}
	_shuffle_count = 0
	_last_shuffle_debug_info = {}
	result_overlay.hide_result()
	_set_input_mode("normal", "")
	_input_controller.set_input_enabled(true)
	_set_status("Select a tile")
	_presenter.start_level(_current_level_id)


func _on_board_changed(board: BoardModel) -> void:
	if _defer_board_update_for_turn:
		_pending_board_for_animation = board
		return

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


## Stage 60.2 v0.1: the random round modifier no longer affects direct-mode
## damage. Stage 60.3 v0.1: this handler is now a no-op - the panel it used
## to drive is repurposed as the LevelBoostPanel, driven entirely by
## _on_level_boost_changed() below. round_modifier_changed is still emitted
## by BattlePresenter (kept for round_modifier_presenter_test.gd and any
## other legacy caller) but GameScreen no longer reacts to it.
func _on_round_modifier_changed(_modifier) -> void:
	pass


## Stage 60.3 v0.1: RoundModifierPanel/ModifierNameLabel/ModifierDescriptionLabel
## (scene node names unchanged) now display the active current_level_boost
## instead of the legacy random round modifier. A none/fallback boost hides
## the panel, matching the old null-modifier behavior.
func _on_level_boost_changed(boost) -> void:
	_current_level_boost = boost

	if boost == null or boost.is_none():
		round_modifier_panel.visible = false
		return

	round_modifier_panel.visible = true
	modifier_name_label.text = LEVEL_BOOST_FORMATTER_SCRIPT.format_label(boost)
	modifier_description_label.text = boost.description


func _on_level_changed(level_config) -> void:
	_current_level_id = level_config.level_id
	_current_level_name = level_config.display_name


## Stage 51 v0.1: minimal, unobtrusive debug visibility into the generated
## challenge archetype/seed. Only surfaces when debug labels are enabled.
## Stage 60.1 v0.1: also appends the fixed HP/moves baseline for the level.
func _on_generated_challenge_changed(challenge) -> void:
	_current_generated_challenge = challenge
	if _debug_labels_enabled and challenge != null:
		var level_number := LEVEL_LABEL_FORMATTER_SCRIPT.extract_level_number(_current_level_id)
		_set_status("Select a tile  |  %s  |  %s  |  %s" % [
			challenge.get_debug_label(),
			DIRECT_BATTLE_BALANCE_SCRIPT.get_debug_label(level_number),
			LEVEL_BOOST_FORMATTER_SCRIPT.format_debug_info_label(_presenter.get_current_level_boost_debug_info()),
		])


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

	if not data.is_valid:
		# Rejected swaps never enter the stepwise AnimatedTurnFlow, so this is
		# still the only place the invalid-swap animation plays.
		var sequence = _board_animation_sequence_builder.build_invalid_swap(data.swapped_from, data.swapped_to, data.invalid_reason)
		_play_board_animation_sequence(sequence, Callable(self, "_after_turn_board_animation").bind(data))
		return

	# Valid turns already played their swap/clear/gravity/cascade animation
	# live through AnimatedTurnFlow (or animations are disabled and there is
	# nothing to play), so go straight to applying the final board.
	_after_turn_board_animation(data)


func _on_ability_presentation_ready(data) -> void:
	_feedback_active = true
	_ability_feedback_presenter.play_ability_feedback(data, board_view, Callable(self, "_set_status"))


func _after_turn_board_animation(data) -> void:
	_apply_pending_board_for_animation()
	var events: Array = _damage_particle_event_builder.build_from_turn_presentation(data) if _damage_particle_event_builder != null else []
	_play_damage_particles(events, Callable(self, "_play_turn_feedback_after_animation").bind(data))


func _play_turn_feedback_after_animation(data) -> void:
	if data.total_damage_to_enemy > 0:
		_play_enemy_damage()

	if _turn_feedback_presenter == null:
		_on_feedback_finished()
		return

	if data.is_valid:
		# Valid turns already played their real board animation live through
		# AnimatedTurnFlow, so only status/lane/damage text remains — the old
		# full board-visual feedback path would replay swap/clear/highlight
		# effects on the already-final board, causing a visible blink and
		# leaving matched cells highlighted.
		_turn_feedback_presenter.play_turn_text_feedback_only(data, board_view, Callable(self, "_set_status"))
	else:
		_turn_feedback_presenter.play_turn_feedback(data, board_view, Callable(self, "_set_status"))


func _on_feedback_finished() -> void:
	_apply_pending_board_for_animation()
	board_view.clear_transient_visual_state()
	_feedback_active = false
	if _pending_battle_status != -1:
		_show_battle_result(_pending_battle_status)
		return

	if not _presenter.is_battle_finished():
		await _maybe_resolve_no_move_shuffle()
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
		_force_cleanup_visual_state()
		result_overlay.show_victory_result(_last_victory_result_data)
	elif status == BattleState.Status.DEFEAT:
		_play_defeat()
		_set_status(BATTLE_MESSAGE_FORMATTER_SCRIPT.format_defeat_message())
		_force_cleanup_visual_state()
		result_overlay.show_defeat_result(_build_defeat_result_data())


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
		_last_victory_result_data = _build_victory_result_data(null, false, false)
		return

	var next_level_id := _get_next_level_id(_presenter.current_level_config.level_id)
	var was_current_completed: bool = _progress_manager.is_level_completed(_presenter.current_level_config.level_id)
	var was_next_unlocked: bool = next_level_id != "" and _progress_manager.is_level_unlocked(_level_catalog, next_level_id)
	var was_next_zone_unlocked: bool = next_level_id != "" and _is_zone_unlocked_for_level(next_level_id)
	_last_stars_earned = _level_completion_resolver.calculate_stars(_presenter.current_level_config, _presenter.state.moves_left)
	var state = _progress_manager.complete_level(_presenter.current_level_config, _presenter.state.moves_left)
	if state != null:
		var is_next_unlocked: bool = next_level_id != "" and _progress_manager.is_level_unlocked(_level_catalog, next_level_id)
		var is_next_zone_unlocked: bool = next_level_id != "" and _is_zone_unlocked_for_level(next_level_id)
		var next_level_newly_unlocked: bool = not was_current_completed and not was_next_unlocked and is_next_unlocked
		var zone_newly_unlocked: bool = not was_current_completed and not was_next_zone_unlocked and is_next_zone_unlocked
		_last_victory_result_data = _build_victory_result_data(state, next_level_newly_unlocked, zone_newly_unlocked)
	else:
		_last_victory_result_data = _build_victory_result_data(null, false, false)


func _build_victory_result_data(level_progress_state, next_level_newly_unlocked: bool, zone_newly_unlocked: bool) -> Dictionary:
	var level_config = _presenter.current_level_config if _presenter != null else null
	var level_id: String = level_config.level_id if level_config != null else _current_level_id
	var level_label := LEVEL_LABEL_FORMATTER_SCRIPT.format_level_label(level_id, _current_level_name)
	var moves_left: int = max(0, _presenter.state.moves_left) if _presenter != null and _presenter.state != null else 0
	var next_level_id := _get_next_level_id(level_id)
	if next_level_id != "" and (_progress_manager == null or not _progress_manager.is_level_unlocked(_level_catalog, next_level_id)):
		next_level_id = ""
	var best_stars: int = int(level_progress_state.stars) if level_progress_state != null else _last_stars_earned
	return {
		"level_id": level_id,
		"level_label": level_label,
		"stars_earned": _last_stars_earned,
		"best_stars": best_stars,
		"moves_left": moves_left,
		"reward_amount": _last_reward_amount,
		"next_level_id": next_level_id,
		"next_level_unlocked": next_level_newly_unlocked,
		"new_zone_unlocked": zone_newly_unlocked,
	}


func _build_defeat_result_data() -> Dictionary:
	var level_config = _presenter.current_level_config if _presenter != null else null
	var level_id: String = level_config.level_id if level_config != null else _current_level_id
	var level_label := LEVEL_LABEL_FORMATTER_SCRIPT.format_level_label(level_id, _current_level_name)
	var moves_left: int = max(0, _presenter.state.moves_left) if _presenter != null and _presenter.state != null else 0
	return {
		"level_id": level_id,
		"level_label": level_label,
		"moves_left": moves_left,
		"message": "Try again with bigger matches and special tiles.",
	}


func _get_next_level_id(level_id: String) -> String:
	var level_number := LEVEL_LABEL_FORMATTER_SCRIPT.extract_level_number(level_id)
	if level_number <= 0:
		return ""
	var next_level_id := "level_%d" % (level_number + 1)
	return next_level_id if _level_catalog.has_level(next_level_id) else ""


func _is_zone_unlocked_for_level(level_id: String) -> bool:
	var zone_index: int = LEVEL_ZONE_HELPER_SCRIPT.get_zone_index_for_level_id(level_id)
	if zone_index <= 0:
		return true
	var unlock_level_id: String = LEVEL_ZONE_HELPER_SCRIPT.get_zone_unlock_level_id(zone_index)
	return _progress_manager != null and _progress_manager.is_level_completed(unlock_level_id)


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
	_begin_animated_turn()
	board_view.clear_lane_highlights()
	board_view.clear_cell_highlights()
	_set_status("Resolving match...")
	_presenter.request_swap(from_cell, to_cell, true)


func _on_swap_accepted(from_cell: Vector2i, to_cell: Vector2i, matches: Array) -> void:
	if not _animations_enabled or _animated_turn_flow == null:
		_presenter.resolve_accepted_swap_immediately(from_cell, to_cell, matches)
		return

	_animated_turn_flow.start_swap_turn(_presenter.board, _presenter, from_cell, to_cell, matches)


func _on_ability_requested(lane_index: int) -> void:
	_input_controller.set_input_enabled(false)
	board_view.clear_lane_highlights()
	board_view.clear_cell_highlights()
	_set_status("Using ability...")
	_presenter.request_ability(lane_index)


func _on_booster_state_changed(booster_state) -> void:
	if booster_panel != null:
		booster_panel.set_booster_state(booster_state)
	if booster_state != null and _selected_booster_id != "" and not booster_state.can_use(_selected_booster_id):
		_cancel_booster_targeting("Select a tile")


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
		_play_booster_button_feedback(booster_id)
		_set_status("Booster already used.")
		return

	if not _has_global_booster(booster_id):
		_play_invalid_swap()
		_play_booster_button_feedback(booster_id)
		_set_status("No boosters left.")
		return

	if config.is_targeted():
		if _input_mode == "booster_targeting" and _selected_booster_id == booster_id:
			_cancel_booster_targeting("Select a tile")
			return

		_play_button_click()
		_enter_booster_targeting(booster_id)
		if booster_id == "hammer":
			_set_status("Hammer: tap a crystal to preview, tap again to use.")
		else:
			_set_status("Rocket: tap a crystal to preview, tap again to use.")
		return

	_play_special_activate()
	_play_booster_button_feedback(booster_id)
	_clear_booster_target_preview()
	_input_controller.set_input_enabled(false)
	_presenter.request_booster_activation(booster_id)


func _on_board_tile_pressed(cell: Vector2i) -> void:
	if _input_mode != "booster_targeting" or _selected_booster_id == "":
		return

	var booster_id := _selected_booster_id
	if _booster_preview_target_cell != cell:
		_show_booster_target_preview(booster_id, cell)
		return

	_clear_booster_target_preview()
	_set_status("Using booster...")
	_begin_animated_turn()
	_set_input_mode("normal", "")
	_input_controller.set_input_enabled(false)
	_presenter.request_targeted_booster(booster_id, cell, true)


func _on_targeted_booster_accepted(result) -> void:
	_feedback_active = true
	_input_controller.set_input_enabled(false)

	if not _animations_enabled or _animated_turn_flow == null:
		_presenter.finalize_booster_turn(result)
		return

	_animated_turn_flow.start_booster_clear(_presenter.board, _presenter, result)


func _on_booster_resolved(result) -> void:
	if result == null:
		_apply_pending_board_for_animation()
		return

	if not result.is_valid:
		_apply_pending_board_for_animation()
		_play_invalid_swap()
		_set_status(result.message)
		_input_controller.set_input_enabled(true)
		return

	# Stage 62.2 v0.1: exactly one global booster is spent here, the single
	# point every valid booster result (Time Freeze via request_booster_activation,
	# Hammer/Rocket via finalize_booster_turn) funnels through, so a booster is
	# never spent twice for one successful use and never spent for an invalid/
	# cancelled/failed attempt (handled by the early return above).
	_last_booster_spend_failed = not _spend_global_booster(result.booster_id)
	_refresh_booster_inventory_ui()

	_feedback_active = true
	_input_controller.set_input_enabled(false)
	# The board animation (if any) already played live through AnimatedTurnFlow
	# before this fires; go straight to particles/feedback.
	_after_booster_board_animation(result)


func _after_booster_board_animation(result) -> void:
	_apply_pending_board_for_animation()
	var events: Array = _damage_particle_event_builder.build_from_booster_result(result) if _damage_particle_event_builder != null else []
	_play_damage_particles(events, Callable(self, "_finish_booster_resolution").bind(result))


func _finish_booster_resolution(result) -> void:
	if result.freeze_turns_added > 0:
		_play_special_activate()
		_play_booster_button_feedback(result.booster_id)
	else:
		_play_special_activate()
		_play_booster_button_feedback(result.booster_id)
		if result.damage_to_enemy > 0:
			_play_enemy_damage()

	var status_message: String = result.message
	if _last_booster_spend_failed:
		status_message += " (booster spend failed)"
	_set_status(status_message)
	board_view.clear_transient_visual_state()
	_feedback_active = false
	if _pending_battle_status != -1:
		_show_battle_result(_pending_battle_status)
		return

	if not _presenter.is_battle_finished():
		await _maybe_resolve_no_move_shuffle()
		_input_controller.set_input_enabled(true)


func _on_restart_pressed() -> void:
	_play_button_click()
	_start_new_battle()


func _on_next_level_pressed() -> void:
	_play_button_click()
	var next_level_id := str(_last_victory_result_data.get("next_level_id", ""))
	if next_level_id == "" or _progress_manager == null or not _progress_manager.is_level_unlocked(_level_catalog, next_level_id):
		return

	_current_level_id = next_level_id
	_start_new_battle()


func _on_upgrades_pressed() -> void:
	_play_button_click()
	upgrades_pressed.emit()


func _set_status(message: String) -> void:
	status_label.text = message


func _set_input_mode(mode: String, booster_id: String) -> void:
	_input_mode = mode
	_selected_booster_id = booster_id
	if mode != "booster_targeting":
		_booster_preview_target_cell = Vector2i(-1, -1)
	if booster_panel != null:
		booster_panel.set_selected_booster(booster_id)
	if _input_controller != null:
		_input_controller.set_input_enabled(mode == "normal")


func _enter_booster_targeting(booster_id: String) -> void:
	_clear_booster_target_preview()
	board_view.clear_transient_visual_state()
	_set_input_mode("booster_targeting", booster_id)


func _cancel_booster_targeting(status_message: String) -> void:
	_clear_booster_target_preview()
	board_view.clear_transient_visual_state()
	_set_input_mode("normal", "")
	_set_status(status_message)


func _show_booster_target_preview(booster_id: String, target_cell: Vector2i) -> void:
	var cells := _get_booster_preview_cells(booster_id, target_cell)
	if cells.is_empty():
		_clear_booster_target_preview()
		_play_invalid_swap()
		_set_status("Select a crystal on the board.")
		return

	_booster_preview_target_cell = target_cell
	board_view.set_selected_cell(target_cell)
	board_view.show_booster_target_preview(cells, booster_id)
	if booster_id == "hammer":
		_set_status("Hammer will clear this area. Tap the same crystal to use.")
	else:
		_set_status("Rocket will clear this color. Tap the same crystal to use.")


func _get_booster_preview_cells(booster_id: String, target_cell: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if board_view == null or not board_view.has_method("get_visible_tile_type"):
		return cells

	var target_tile_type: int = board_view.get_visible_tile_type(target_cell)
	if target_tile_type == BoardModel.EMPTY:
		return cells

	if booster_id == "hammer":
		for y in range(target_cell.y - 1, target_cell.y + 2):
			for x in range(target_cell.x - 1, target_cell.x + 2):
				var cell := Vector2i(x, y)
				if x < 0 or y < 0 or x >= BoardView.BOARD_SIZE or y >= BoardView.BOARD_SIZE:
					continue
				if board_view.get_visible_tile_type(cell) != BoardModel.EMPTY:
					cells.append(cell)
	elif booster_id == "rocket_barrage" and board_view.has_method("get_cells_with_visible_tile_type"):
		cells = board_view.get_cells_with_visible_tile_type(target_tile_type)

	return cells


func _clear_booster_target_preview() -> void:
	_booster_preview_target_cell = Vector2i(-1, -1)
	if board_view != null and board_view.has_method("clear_booster_target_preview"):
		board_view.clear_booster_target_preview()
	if board_view != null:
		board_view.clear_selected_cell()


func _play_booster_button_feedback(booster_id: String) -> void:
	if booster_panel != null and booster_panel.has_method("play_booster_feedback"):
		booster_panel.play_booster_feedback(booster_id, _animations_enabled, _reduced_motion_enabled)


## Stage 62.2 v0.1: global cross-battle booster inventory, read through
## ProgressManager (never battle-local BoosterState). Missing progress data
## (no ProgressManager yet, or an empty/unloaded catalog) fails safely to an
## all-zero Dictionary rather than crashing.
func _get_booster_inventory_counts() -> Dictionary:
	var counts := {}
	if _presenter == null:
		return counts
	var catalog = _presenter.get_booster_catalog()
	if catalog == null:
		return counts
	for booster_id in catalog.get_default_booster_ids():
		counts[booster_id] = _progress_manager.get_booster_count(booster_id) if _progress_manager != null else 0
	return counts


func _has_global_booster(booster_id: String) -> bool:
	return _progress_manager != null and _progress_manager.has_booster(booster_id)


func _spend_global_booster(booster_id: String) -> bool:
	if _progress_manager == null:
		return false
	return _progress_manager.spend_booster(booster_id, 1)


func _refresh_booster_inventory_ui() -> void:
	if booster_panel != null and booster_panel.has_method("set_booster_counts"):
		booster_panel.set_booster_counts(_get_booster_inventory_counts())


func set_level_id(level_id: String) -> void:
	_current_level_id = level_id if level_id != "" else "level_1"
	if _presenter != null:
		_start_new_battle()


func set_progress_manager(progress_manager) -> void:
	_progress_manager = progress_manager
	if _presenter != null and _progress_manager != null:
		_presenter.set_progress(_progress_manager.get_progress())
		_presenter.set_hero_catalog(_progress_manager.get_hero_catalog())
	_refresh_booster_inventory_ui()


func set_settings_manager(settings_manager) -> void:
	_settings_manager = settings_manager
	_apply_presentation_settings()


func _apply_presentation_settings() -> void:
	var settings = _settings_manager.get_settings() if _settings_manager != null else null
	var animations_enabled: bool = settings.animations_enabled if settings != null else true
	var reduced_motion_enabled: bool = settings.reduced_motion_enabled if settings != null else false
	_debug_labels_enabled = settings.debug_labels_enabled if settings != null else false
	_animations_enabled = animations_enabled
	_reduced_motion_enabled = reduced_motion_enabled

	TileView.configure_presentation(animations_enabled, reduced_motion_enabled)
	HeroCard.set_debug_labels_enabled(_debug_labels_enabled)
	HeroCard.set_presentation_settings(animations_enabled, reduced_motion_enabled)
	if _turn_feedback_presenter != null:
		_turn_feedback_presenter.configure_settings(animations_enabled, reduced_motion_enabled, _debug_labels_enabled)
	if _ability_feedback_presenter != null:
		_ability_feedback_presenter.configure_settings(animations_enabled, reduced_motion_enabled, _debug_labels_enabled)
	if _board_animation_controller != null:
		_board_animation_controller.configure_settings(animations_enabled, reduced_motion_enabled)
	if _battle_effect_controller != null:
		_battle_effect_controller.configure_settings(animations_enabled, reduced_motion_enabled)
	if enemy_panel != null and enemy_panel.has_method("configure_presentation"):
		enemy_panel.configure_presentation(animations_enabled, reduced_motion_enabled)

	if not animations_enabled and board_view != null and board_view.is_animation_overlay_mode():
		_apply_pending_board_for_animation()
		board_view.clear_transient_visual_state()
	if not animations_enabled and board_view != null:
		board_view.clear_booster_target_preview()


func _play_board_animation_sequence(sequence, finished_callback: Callable) -> void:
	if _board_animation_controller == null:
		if finished_callback.is_valid():
			finished_callback.call()
		return

	_board_animation_controller.play_sequence(sequence, board_view, finished_callback)


func _play_damage_particles(events: Array, finished_callback: Callable) -> void:
	if _battle_effect_controller == null or events.is_empty():
		if finished_callback.is_valid():
			finished_callback.call()
		return

	_battle_effect_controller.play_damage_particles(events, board_view, enemy_panel, battle_effect_layer, finished_callback)


func _begin_animated_turn() -> void:
	_clear_booster_target_preview()
	_defer_board_update_for_turn = true
	_pending_board_for_animation = null
	var snapshot := BoardVisualSnapshot.from_board_view(board_view)
	board_view.enter_animation_overlay_mode(snapshot)


func _apply_pending_board_for_animation() -> void:
	if board_view.is_animation_overlay_mode():
		board_view.clear_transient_visual_state()
		if _pending_board_for_animation != null:
			board_view.apply_board_under_overlay(_pending_board_for_animation)
		else:
			board_view.exit_animation_overlay_mode()
	elif _pending_board_for_animation != null:
		board_view.clear_transient_visual_state()
		board_view.set_board(_pending_board_for_animation)

	_pending_board_for_animation = null
	_defer_board_update_for_turn = false


## Stage 59 v0.1, wired into the real turn flow in Stage 59.1: runs once the
## board is fully settled — after the cascade/gravity/refill sequence
## (AnimatedTurnFlow) for a swap turn, after a booster resolve sequence for a
## targeted/direct booster turn, and after the overlay->real BoardView
## handoff already applied by _apply_pending_board_for_animation() above —
## and always right before input is re-enabled for the next turn, never
## mid-animation or mid-cascade. Callers only reach this once
## _presenter.is_battle_finished() is already known false (see
## _on_feedback_finished()/_finish_booster_resolution()), so a
## turn that ends the battle never triggers a shuffle or delays the result
## overlay; the is_battle_finished() re-check below is a defensive no-op for
## any future caller. Only mutates the board (via BoardShuffleResolver,
## active cells only) when AvailableMoveFinder reports no valid swap exists;
## otherwise this is a single cheap read-only scan and nothing else happens.
## Input stays disabled by the caller for this whole (possibly awaited)
## call, so booster targeting/swap selection can't start mid-check/shuffle.
func _maybe_resolve_no_move_shuffle() -> void:
	if _presenter == null or _presenter.board == null or _presenter.is_battle_finished():
		return

	var board: BoardModel = _presenter.board
	if _available_move_finder.has_available_move(board):
		return

	var active_cells := board.get_active_cells()
	var fade_duration := _shuffle_fade_duration()

	if fade_duration > 0.0:
		board_view.play_shuffle_fade_out(active_cells, fade_duration)
		if get_tree() != null:
			await get_tree().create_timer(fade_duration).timeout

	var shuffle_info := _board_shuffle_resolver.shuffle(board, _shuffle_rng)
	board_view.refresh_all_tiles()

	if fade_duration > 0.0:
		board_view.play_shuffle_fade_in(active_cells, fade_duration)
		if get_tree() != null:
			await get_tree().create_timer(fade_duration).timeout

	_shuffle_count += 1
	_last_shuffle_debug_info = {
		"no_move_detected": true,
		"shuffle_count": _shuffle_count,
		"shuffle_attempts_used": int(shuffle_info.get("attempts_used", 0)),
		"shuffle_fallback_used": bool(shuffle_info.get("fallback_used", false)),
		"available_move_after_shuffle": bool(shuffle_info.get("has_available_move", false)),
		"immediate_match_after_shuffle": bool(shuffle_info.get("has_immediate_match", false)),
	}

	if _debug_labels_enabled:
		_set_status("Board shuffled (no moves available)  |  count=%d attempts=%d fallback=%s" % [
			_shuffle_count, _last_shuffle_debug_info["shuffle_attempts_used"], _last_shuffle_debug_info["shuffle_fallback_used"],
		])


## Stage 59.1 v0.1: mirrors TileView._adjust_duration()'s "disabled animations
## collapse to (near-)instant" rule so the no-move shuffle never makes the
## player wait on a tween that presentation settings say shouldn't play.
## Returns 0.0 (skip fade entirely, apply the shuffle immediately) when
## animations are disabled; otherwise the base fade duration, scaled by
## BoardAnimationController.REDUCED_MOTION_SCALE under reduced motion.
func _shuffle_fade_duration() -> float:
	if not _animations_enabled:
		return 0.0

	var base_duration := 0.16
	if _reduced_motion_enabled:
		return base_duration * BoardAnimationController.REDUCED_MOTION_SCALE
	return base_duration


func _force_cleanup_visual_state() -> void:
	if _animated_turn_flow != null:
		_animated_turn_flow.cancel()
	if _board_animation_controller != null:
		_board_animation_controller.clear_queue()
	if board_view != null:
		board_view.force_reset_animation_state()
	_booster_preview_target_cell = Vector2i(-1, -1)
	if _battle_effect_controller != null:
		_battle_effect_controller.clear_effects(battle_effect_layer)
	_pending_board_for_animation = null
	_defer_board_update_for_turn = false


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
