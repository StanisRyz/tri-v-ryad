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
const TEXT_STYLE_APPLIER_SCRIPT := preload("res://scripts/ui/text/text_style_applier.gd")
const PORTRAIT_CONTENT_WIDTH := 664.0
const PORTRAIT_BOARD_SIZE := PORTRAIT_CONTENT_WIDTH
const LANDSCAPE_CONTENT_WIDTH := 560.0
const LANDSCAPE_BOARD_SIZE := 320.0

@onready var menu_button: PressableTextureButton = %MenuButton
@onready var battle_root: VBoxContainer = %BattleRoot
@onready var battle_hud: PanelContainer = %BattleHud
@onready var enemy_panel: PanelContainer = %EnemyPanel
@onready var board_view: Control = %BoardView
@onready var status_label: Label = %StatusLabel
@onready var hero_party_panel: HBoxContainer = %HeroPartyPanel
@onready var booster_panel = %BoosterPanel
@onready var result_overlay: BattleResultOverlay = %BattleResultOverlay
@onready var lose_continue_popup: LoseContinuePopup = %LoseContinuePopup
@onready var background_slot: ImageSlot = %Background
@onready var round_modifier_panel: PanelContainer = %RoundModifierPanel
@onready var round_modifier_background: FallbackImageSlot = %RoundModifierBackground
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
var _developer_mode_active: bool = false
var _lose_continue_ad_active := false
var _lose_continue_ad_rewarded := false
var _platform_paused := false
var _pending_result_kind := ""
var _pending_result_data: Dictionary = {}
var _fullscreen_result_attempt_active := false
var _fullscreen_result_attempted := false

const REWARDED_AD_PLACEMENT_LOSE_CONTINUE := "lose_continue"

func _ready() -> void:
	if not menu_button.delayed_pressed.is_connected(_on_menu_button_pressed):
		menu_button.delayed_pressed.connect(_on_menu_button_pressed)

	_bind_static_ui_assets()
	_layout_manager = LayoutManager.new(get_viewport())
	_layout_manager.layout_changed.connect(_on_layout_changed)

	_setup_playable_battle()
	_apply_layout(_layout_manager.get_layout_mode())
	_localize_ui()
	_apply_text_styles()
	var localization_manager := get_node_or_null("/root/LocalizationManager")
	if localization_manager != null:
		localization_manager.language_changed.connect(_localize_ui)
	_connect_platform_rewarded_ad_signals()
	_connect_platform_fullscreen_signals()


## Stage 69.2: LoseContinuePopup's "Watch Ad" continue routes through
## Platform.show_rewarded_ad(REWARDED_AD_PLACEMENT_LOSE_CONTINUE) instead of
## granting moves directly. These connections live for the lifetime of the
## screen; ScreenRouter.change_screen() frees the previous screen on
## navigation, which auto-disconnects these the same way, so a signal from
## an ad requested by this screen can never be picked up by a different one.
func _connect_platform_rewarded_ad_signals() -> void:
	var platform := get_node_or_null("/root/Platform")
	if platform == null:
		return
	if not platform.rewarded_ad_opened.is_connected(_on_platform_rewarded_ad_opened):
		platform.rewarded_ad_opened.connect(_on_platform_rewarded_ad_opened)
	if not platform.rewarded_ad_rewarded.is_connected(_on_platform_rewarded_ad_rewarded):
		platform.rewarded_ad_rewarded.connect(_on_platform_rewarded_ad_rewarded)
	if not platform.rewarded_ad_closed.is_connected(_on_platform_rewarded_ad_closed):
		platform.rewarded_ad_closed.connect(_on_platform_rewarded_ad_closed)
	if not platform.rewarded_ad_error.is_connected(_on_platform_rewarded_ad_error):
		platform.rewarded_ad_error.connect(_on_platform_rewarded_ad_error)


func _connect_platform_fullscreen_signals() -> void:
	var platform := get_node_or_null("/root/Platform")
	if platform == null:
		return
	if not platform.fullscreen_ad_opened.is_connected(_on_platform_fullscreen_ad_opened):
		platform.fullscreen_ad_opened.connect(_on_platform_fullscreen_ad_opened)
	if not platform.fullscreen_ad_closed.is_connected(_on_platform_fullscreen_ad_closed):
		platform.fullscreen_ad_closed.connect(_on_platform_fullscreen_ad_closed)
	if not platform.fullscreen_ad_error.is_connected(_on_platform_fullscreen_ad_error):
		platform.fullscreen_ad_error.connect(_on_platform_fullscreen_ad_error)


## Stage 64.16 v0.1: developer-only debug hotkeys, fully gated behind
## FeatureFlags.DEBUG_MODE_ENABLED so they are inert in production builds.
## F12 toggles developer mode; F1/F2/F3 only do anything once developer mode
## is active. Echoed (auto-repeat) key events are ignored so holding a key
## down doesn't spam grants or repeatedly trigger a win/loss.
## Stage 64.12 v0.1: added F3, an instant-loss hotkey that mirrors F2's win
## path (same guards, same _show_battle_result() routing) so a defeat can be
## triggered on demand to exercise LoseContinuePopup.
func _unhandled_input(event: InputEvent) -> void:
	if not FeatureFlags.DEBUG_MODE_ENABLED:
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	if event.keycode == KEY_F12:
		_developer_mode_active = not _developer_mode_active
		print_debug("Developer mode %s" % ("ON" if _developer_mode_active else "OFF"))
		return

	if not _developer_mode_active:
		return

	if event.keycode == KEY_F1:
		_debug_grant_boosters()
	elif event.keycode == KEY_F2:
		_debug_complete_level()
	elif event.keycode == KEY_F3:
		_debug_trigger_defeat()


## Stage 64.16 v0.1: grants +10 of every catalog booster through the same
## ProgressManager API normal booster rewards use, then refreshes BoosterPanel
## so the new counts are visible immediately.
func _debug_grant_boosters() -> void:
	if _progress_manager == null or _presenter == null:
		return

	var catalog = _presenter.get_booster_catalog()
	if catalog == null:
		return

	for booster_id in catalog.get_default_booster_ids():
		_progress_manager.add_booster(booster_id, 10)

	_refresh_booster_inventory_ui()
	print_debug("Developer mode: granted +10 of each booster")


## Stage 64.16 v0.1: forces the current battle to a victory by zeroing enemy
## HP and re-deriving status through BattleState.update_status(), then routes
## through the normal _show_battle_result() path so reward granting, save,
## UI refresh and the result overlay all behave exactly as a real win would.
## Guards against firing before a battle exists, after the battle already
## finished, or while the result overlay is already on screen.
func _debug_complete_level() -> void:
	if _presenter == null or _presenter.state == null or _presenter.state.enemy == null:
		return
	if _presenter.is_battle_finished():
		return
	if result_overlay != null and result_overlay.visible:
		return

	_presenter.state.enemy.current_hp = 0
	_presenter.state.update_status()
	_pending_battle_status = _presenter.state.status
	_feedback_active = false
	print_debug("Developer mode: instant level win triggered")
	_show_battle_result(_pending_battle_status)


## Stage 64.12 v0.1: forces the current battle to a defeat by zeroing
## moves_left and re-deriving status through BattleState.update_status(),
## then routes through the normal _show_battle_result() path so
## LoseContinuePopup, defeat audio/status and the result overlay all behave
## exactly as a real loss would. Mirrors _debug_complete_level()'s guards:
## no-ops before a battle exists, after the battle already finished, or
## while the result overlay/lose-continue popup is already on screen.
func _debug_trigger_defeat() -> void:
	if _presenter == null or _presenter.state == null:
		return
	if _presenter.is_battle_finished():
		return
	if result_overlay != null and result_overlay.visible:
		return
	if lose_continue_popup != null and lose_continue_popup.visible:
		return

	_presenter.state.moves_left = 0
	_presenter.state.update_status()
	_pending_battle_status = _presenter.state.status
	_feedback_active = false
	print_debug("Developer mode: instant level loss triggered")
	_show_battle_result(_pending_battle_status)


func _bind_static_ui_assets() -> void:
	UI_ASSET_BINDING_SCRIPT.bind_ui_asset(battle_hud, "battle_hud_panel")
	UI_ASSET_BINDING_SCRIPT.bind_ui_asset(enemy_panel, "enemy_panel")
	var round_modifier_texture := UI_ASSET_BINDING_SCRIPT.bind_ui_asset(round_modifier_panel, "round_modifier_panel")
	UI_ASSET_BINDING_SCRIPT.bind_ui_asset(status_label, "status_panel")
	UI_ASSET_BINDING_SCRIPT.bind_ui_asset(result_overlay, "result_panel")
	_bind_round_modifier_panel_background(round_modifier_texture)


## Fallback-only: an Inspector-assigned background texture is never overwritten.
func _bind_round_modifier_panel_background(texture: Texture2D) -> void:
	if round_modifier_background == null or round_modifier_background.has_texture():
		return

	round_modifier_background.set_texture(texture)


func _localize_ui() -> void:
	var localization_manager := get_node_or_null("/root/LocalizationManager")
	if localization_manager == null:
		return
	menu_button.button_text = localization_manager.tr_key("ui.game.menu")


func _apply_text_styles() -> void:
	TEXT_STYLE_APPLIER_SCRIPT.apply_to_child_label(menu_button, "TextMargin/Label", "game_hud.menu_button")
	TEXT_STYLE_APPLIER_SCRIPT.apply_to_label(modifier_description_label, "game_hud.modifier")


func _localized_level_label(level_id: String, fallback_display_name: String) -> String:
	var localization_manager := get_node_or_null("/root/LocalizationManager")
	if localization_manager == null:
		return LEVEL_LABEL_FORMATTER_SCRIPT.format_level_label(level_id, fallback_display_name)
	var level_number := LEVEL_LABEL_FORMATTER_SCRIPT.extract_level_number(level_id)
	if level_number > 0:
		return localization_manager.format_key("ui.game.level", {"level": level_number})
	if fallback_display_name != "":
		return fallback_display_name
	return localization_manager.tr_key("ui.common.levels")


func _localized_not_enough_gems_message() -> String:
	var localization_manager := get_node_or_null("/root/LocalizationManager")
	if localization_manager == null:
		return "Недостаточно гемов"
	return localization_manager.tr_key("ui.lose_continue.not_enough_gems")


func _localized_moves_label(moves_left: int) -> String:
	var localization_manager := get_node_or_null("/root/LocalizationManager")
	if localization_manager == null:
		return "Moves: %d" % moves_left
	return localization_manager.format_key("ui.game.moves", {"moves": moves_left})


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
	menu_button.custom_minimum_size = Vector2(176, 60)
	battle_hud.custom_minimum_size = Vector2(0, 60)
	enemy_panel.custom_minimum_size = Vector2(0, 200)
	round_modifier_panel.custom_minimum_size = Vector2(0, 48)
	board_view.custom_minimum_size = Vector2(PORTRAIT_BOARD_SIZE, PORTRAIT_BOARD_SIZE)
	hero_party_panel.custom_minimum_size = Vector2(PORTRAIT_CONTENT_WIDTH, 132)
	booster_panel.custom_minimum_size = Vector2(PORTRAIT_CONTENT_WIDTH, 160)


func _apply_landscape_layout() -> void:
	battle_root.custom_minimum_size = Vector2(LANDSCAPE_CONTENT_WIDTH, 0)
	battle_root.add_theme_constant_override("separation", 10)
	menu_button.custom_minimum_size = Vector2(176, 52)
	battle_hud.custom_minimum_size = Vector2(0, 52)
	enemy_panel.custom_minimum_size = Vector2(0, 120)
	round_modifier_panel.custom_minimum_size = Vector2(0, 40)
	board_view.custom_minimum_size = Vector2(LANDSCAPE_BOARD_SIZE, LANDSCAPE_BOARD_SIZE)
	hero_party_panel.custom_minimum_size = Vector2(LANDSCAPE_CONTENT_WIDTH, 96)
	booster_panel.custom_minimum_size = Vector2(LANDSCAPE_CONTENT_WIDTH, 112)


func _setup_playable_battle() -> void:
	_presenter = BATTLE_PRESENTER_SCRIPT.new()
	if _progress_manager != null:
		_presenter.set_progress(_progress_manager.get_progress())
		_presenter.set_hero_catalog(_progress_manager.get_hero_catalog())
	_input_controller = BOARD_INPUT_CONTROLLER_SCRIPT.new()
	_turn_feedback_presenter = TURN_FEEDBACK_PRESENTER_SCRIPT.new()
	_turn_feedback_presenter.set_localization_manager(get_node_or_null("/root/LocalizationManager"))
	_ability_feedback_presenter = ABILITY_FEEDBACK_PRESENTER_SCRIPT.new()
	_ability_feedback_presenter.set_localization_manager(get_node_or_null("/root/LocalizationManager"))
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

	lose_continue_popup.watch_ad_pressed.connect(_on_lose_continue_watch_ad_pressed)
	lose_continue_popup.buy_moves_pressed.connect(_on_lose_continue_buy_moves_pressed)
	lose_continue_popup.close_pressed.connect(_on_lose_continue_close_pressed)

	_start_new_battle()


func _start_new_battle() -> void:
	_reset_fullscreen_result_gate()
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
	lose_continue_popup.hide_popup()
	_set_input_mode("normal", "")
	_input_controller.set_input_enabled(not _platform_paused)
	_set_status("Select a tile")
	_presenter.start_level(_current_level_id)
	var platform := get_node_or_null("/root/Platform")
	if platform != null:
		platform.gameplay_start()


func _on_board_changed(board: BoardModel) -> void:
	if _defer_board_update_for_turn:
		_pending_board_for_animation = board
		return

	board_view.set_board(board)


func _on_battle_state_changed(state: BattleState) -> void:
	if battle_hud.has_method("set_values"):
		battle_hud.set_values(_localized_level_label(_current_level_id, _current_level_name), _localized_moves_label(state.moves_left))

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


## Stage 60.3 v0.1: RoundModifierPanel/ModifierDescriptionLabel display the
## active current_level_boost instead of the legacy random round modifier.
## Stage 64.1 v0.1: ModifierNameLabel was removed; only the description shows.
## Stage 64.4 v0.1: the label now shows LevelBoostFormatter.format_gameplay_label()
## (a short "x2 Damage Red"/"+3 Moves"-style string) instead of the verbose
## LevelBoostConfig.description. A none/fallback boost hides the panel,
## matching the old null-modifier behavior.
func _on_level_boost_changed(boost) -> void:
	_current_level_boost = boost

	if boost == null or boost.is_none():
		round_modifier_panel.visible = false
		return

	round_modifier_panel.visible = true
	modifier_description_label.text = LEVEL_BOOST_FORMATTER_SCRIPT.format_gameplay_label(boost, get_node_or_null("/root/LocalizationManager"))


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
	# Stage 68.1 hotfix: when animations are on, every sound for this turn
	# already played live from BoardAnimationController as each animation
	# request ran (see board_animation_controller.gd._play_request_audio()),
	# in sync with the visuals. Calling _play_turn_audio() here too — after
	# the whole sequence has already finished — would just replay every
	# sound a second time, bunched up at the end. With animations off there
	# is no per-request playback to sync to, so this remains the only place
	# turn audio fires.
	if not _animations_enabled:
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
		_input_controller.set_input_enabled(not _platform_paused)
		if _input_mode == "booster_targeting":
			_input_controller.set_input_enabled(false)


func _show_battle_result(status: int) -> void:
	_input_controller.set_input_enabled(false)
	var platform := get_node_or_null("/root/Platform")
	if platform != null:
		platform.gameplay_stop()
	if status == BattleState.Status.VICTORY:
		_play_victory()
		_grant_victory_reward_once()
		_save_victory_completion_once()
		_refresh_booster_inventory_ui()
		_set_status(BATTLE_MESSAGE_FORMATTER_SCRIPT.format_victory_message(_last_reward_amount, _last_stars_earned, get_node_or_null("/root/LocalizationManager")))
		_force_cleanup_visual_state()
		_queue_result_after_fullscreen("victory", _last_victory_result_data, "battle_victory_result")
	elif status == BattleState.Status.DEFEAT:
		_show_lose_continue_or_defeat()


## Stage 64.12 v0.1: LoseContinuePopup is offered once per defeat event before
## falling through to the normal 0-star result. Guarded against duplicates:
## if either the popup or the result overlay is already visible, a repeated
## defeat trigger (e.g. a stray battle_finished re-emit) is ignored rather
## than reopening/stacking UI.
func _show_lose_continue_or_defeat() -> void:
	if result_overlay != null and result_overlay.visible:
		return
	if lose_continue_popup != null and lose_continue_popup.visible:
		return

	_force_cleanup_visual_state()
	if lose_continue_popup != null:
		_set_status(BATTLE_MESSAGE_FORMATTER_SCRIPT.format_defeat_message(get_node_or_null("/root/LocalizationManager")))
		_play_lose_continue()
		lose_continue_popup.show_popup()
	else:
		_finalize_defeat_result()


func _finalize_defeat_result() -> void:
	_play_defeat()
	_set_status(BATTLE_MESSAGE_FORMATTER_SCRIPT.format_defeat_message())
	_force_cleanup_visual_state()
	_queue_result_after_fullscreen("defeat", _build_defeat_result_data(), "battle_defeat_result")


func _queue_result_after_fullscreen(result_kind: String, result_data: Dictionary, placement_id: String) -> void:
	if _pending_result_kind != "" or _fullscreen_result_attempt_active:
		return
	_pending_result_kind = result_kind
	_pending_result_data = result_data.duplicate(true)
	if _fullscreen_result_attempted:
		_show_pending_result()
		return
	_fullscreen_result_attempted = true
	var platform := get_node_or_null("/root/Platform")
	if platform == null or platform.is_ad_in_progress():
		_show_pending_result()
		return
	_fullscreen_result_attempt_active = true
	platform.show_fullscreen_ad(placement_id)


func _on_platform_fullscreen_ad_opened() -> void:
	if not _fullscreen_result_attempt_active:
		return
	var audio_manager = _get_audio_manager()
	if audio_manager != null:
		audio_manager.pause_audio("fullscreen_ad")


func _on_platform_fullscreen_ad_closed(_was_shown: bool) -> void:
	if not _fullscreen_result_attempt_active:
		return
	_finish_fullscreen_result_attempt()


func _on_platform_fullscreen_ad_error(_message: String) -> void:
	if not _fullscreen_result_attempt_active:
		return
	_finish_fullscreen_result_attempt()


func _finish_fullscreen_result_attempt() -> void:
	var audio_manager = _get_audio_manager()
	if audio_manager != null:
		audio_manager.resume_audio("fullscreen_ad")
	_fullscreen_result_attempt_active = false
	_show_pending_result()


func _show_pending_result() -> void:
	if _pending_result_kind == "victory":
		result_overlay.show_victory_result(_pending_result_data)
	elif _pending_result_kind == "defeat":
		result_overlay.show_defeat_result(_pending_result_data)
	_pending_result_kind = ""
	_pending_result_data = {}


func _reset_fullscreen_result_gate() -> void:
	_pending_result_kind = ""
	_pending_result_data = {}
	_fullscreen_result_attempt_active = false
	_fullscreen_result_attempted = false


func _on_lose_continue_watch_ad_pressed() -> void:
	_play_button_click()
	_try_continue_with_ad()


func _on_lose_continue_buy_moves_pressed() -> void:
	_play_button_click()
	_try_continue_with_gems()


func _on_lose_continue_close_pressed() -> void:
	_play_button_click()
	lose_continue_popup.hide_popup()
	_finalize_defeat_result()


## Stage 69.2 v0.1: routes the Watch Ad continue option through
## Platform.show_rewarded_ad() instead of granting the reward directly.
## +3 moves are only granted from _on_platform_rewarded_ad_rewarded(), never
## from here, and the popup stays open (actions locked) until the ad's
## terminal signal (closed/error) arrives.
func _try_continue_with_ad() -> void:
	var platform := get_node_or_null("/root/Platform")
	if platform == null:
		lose_continue_popup.show_feedback(_localized_ad_feedback("ui.rewarded_ad.unavailable", "Ad unavailable"))
		return

	_lose_continue_ad_active = true
	_lose_continue_ad_rewarded = false
	lose_continue_popup.set_actions_enabled(false)
	lose_continue_popup.show_feedback(_localized_ad_feedback("ui.rewarded_ad.loading", "Loading ad..."))
	platform.show_rewarded_ad(REWARDED_AD_PLACEMENT_LOSE_CONTINUE)


func _on_platform_rewarded_ad_opened() -> void:
	if not _lose_continue_ad_active:
		return
	var audio_manager = _get_audio_manager()
	if audio_manager != null:
		audio_manager.pause_for_ad()


## Grants the reward as soon as the platform confirms it was earned — closing
## the ad view (_on_platform_rewarded_ad_closed) is a separate later signal
## and only handles hiding the popup/resuming play, never the grant itself,
## so the reward can never be granted twice for one ad attempt.
func _on_platform_rewarded_ad_rewarded() -> void:
	if not _lose_continue_ad_active or _lose_continue_ad_rewarded:
		return
	_lose_continue_ad_rewarded = true
	_grant_continue_moves(3)


func _on_platform_rewarded_ad_closed(_was_shown: bool) -> void:
	if not _lose_continue_ad_active:
		return
	_lose_continue_ad_active = false
	var audio_manager = _get_audio_manager()
	if audio_manager != null:
		audio_manager.resume_after_ad()

	if _lose_continue_ad_rewarded:
		_lose_continue_ad_rewarded = false
		lose_continue_popup.hide_popup()
		_resume_after_continue()
		var platform := get_node_or_null("/root/Platform")
		if platform != null:
			platform.gameplay_start()
	else:
		lose_continue_popup.set_actions_enabled(true)
		lose_continue_popup.show_feedback(_localized_ad_feedback("ui.rewarded_ad.cancelled", "Reward was not granted"))


func _on_platform_rewarded_ad_error(_message: String) -> void:
	if not _lose_continue_ad_active:
		return
	_lose_continue_ad_active = false
	_lose_continue_ad_rewarded = false
	var audio_manager = _get_audio_manager()
	if audio_manager != null:
		audio_manager.resume_after_ad()
	lose_continue_popup.set_actions_enabled(true)
	lose_continue_popup.show_feedback(_localized_ad_feedback("ui.rewarded_ad.error", "Ad error"))


func _localized_ad_feedback(key: String, fallback_text: String) -> String:
	var localization_manager := get_node_or_null("/root/LocalizationManager")
	if localization_manager == null:
		return fallback_text
	return localization_manager.tr_key(key)


## Stage 64.12 v0.1: gem-purchased continue. Spends through the existing
## ProgressManager currency APIs (same save path as every other spend), and
## keeps the popup open with an inline message if the player can't afford it
## rather than silently falling through to the defeat result.
func _try_continue_with_gems() -> void:
	const CONTINUE_GEM_COST := 5
	if _progress_manager == null or not _progress_manager.can_spend_currency(CurrencyType.GEMS, CONTINUE_GEM_COST):
		lose_continue_popup.show_feedback(_localized_not_enough_gems_message())
		return

	if not _progress_manager.spend_currency(CurrencyType.GEMS, CONTINUE_GEM_COST):
		lose_continue_popup.show_feedback(_localized_not_enough_gems_message())
		return

	_grant_continue_moves(5)
	lose_continue_popup.hide_popup()
	_resume_after_continue()


## Stage 64.12 v0.1: adds moves to the live BattleState and re-derives status
## through the same BattleState.update_status() every other status change
## uses, so a battle that was DEFEAT (moves_left <= 0) returns to IN_PROGRESS
## without resetting the board, enemy HP, modifiers, or booster state.
func _grant_continue_moves(amount: int) -> void:
	if _presenter == null or _presenter.state == null:
		return

	_presenter.state.moves_left += amount
	_presenter.state.update_status()
	_pending_battle_status = -1
	_on_battle_state_changed(_presenter.state)


func _resume_after_continue() -> void:
	_set_input_mode("normal", "")
	_set_status("Select a tile")


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
	var completion_result: Dictionary = _progress_manager.complete_level_with_rewards(_presenter.current_level_config, _presenter.state.moves_left, _level_catalog)
	var state = completion_result.get("level_progress_state")
	if state != null:
		var is_next_unlocked: bool = next_level_id != "" and _progress_manager.is_level_unlocked(_level_catalog, next_level_id)
		var is_next_zone_unlocked: bool = next_level_id != "" and _is_zone_unlocked_for_level(next_level_id)
		var next_level_newly_unlocked: bool = not was_current_completed and not was_next_unlocked and is_next_unlocked
		var zone_newly_unlocked: bool = not was_current_completed and not was_next_zone_unlocked and is_next_zone_unlocked
		_last_victory_result_data = _build_victory_result_data(state, next_level_newly_unlocked, zone_newly_unlocked, completion_result.get("rewards", []))
	else:
		_last_victory_result_data = _build_victory_result_data(null, false, false, [])


func _build_victory_result_data(level_progress_state, next_level_newly_unlocked: bool, zone_newly_unlocked: bool, milestone_rewards: Array = []) -> Dictionary:
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
		"milestone_rewards": milestone_rewards,
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
	_play_button_click()
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
	_set_status(BATTLE_MESSAGE_FORMATTER_SCRIPT.format_invalid_input_message(reason, get_node_or_null("/root/LocalizationManager")))


func _on_swap_requested(from_cell: Vector2i, to_cell: Vector2i) -> void:
	if _platform_paused or _input_mode != "normal":
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
	if _platform_paused:
		return
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
	if _platform_paused or _presenter == null or _presenter.state == null or _presenter.is_battle_finished():
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

	_play_booster_sfx(booster_id)
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
		_input_controller.set_input_enabled(not _platform_paused)
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


## Stage 68.1 hotfix: Hammer/Rocket Barrage (targeted, animated) already play
## their booster sound and crystal-burst live from BoardAnimationController
## as the TYPE_BOOSTER_ACTIVATION/TYPE_BOOSTER_CLEAR requests run (see
## board_animation_controller.gd._play_request_audio()); calling
## _play_booster_sfx()/_play_crystal_burst() here too would replay them late,
## a second time. With animations off, request_targeted_booster() never runs
## AnimatedTurnFlow at all, so nothing has played yet and this remains the
## only place those sounds fire. Time Freeze (freeze_turns_added > 0) never
## animates a clear either way — its sound already played immediately in
## _on_booster_pressed()'s non-targeted branch, so it's explicitly skipped
## here to avoid a second, duplicate Time Freeze sound.
func _finish_booster_resolution(result) -> void:
	_play_booster_button_feedback(result.booster_id)
	if result.freeze_turns_added <= 0:
		if not _animations_enabled:
			_play_booster_sfx(result.booster_id)
			for _cleared_cell in result.cleared_cells:
				_play_crystal_burst()
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
		_input_controller.set_input_enabled(not _platform_paused)


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
		_input_controller.set_input_enabled(mode == "normal" and not _platform_paused)


## Stage 69.5: keeps battle state intact while a Yandex/browser pause is
## active. Input re-enables only for a still-active, normal battle state.
func set_platform_paused(paused: bool) -> void:
	if _platform_paused == paused:
		return
	_platform_paused = paused
	if _board_animation_controller != null and _board_animation_controller.has_method("set_runtime_paused"):
		_board_animation_controller.set_runtime_paused(paused)
	if _animated_turn_flow != null and _animated_turn_flow.has_method("set_runtime_paused"):
		_animated_turn_flow.set_runtime_paused(paused)
	if _battle_effect_controller != null and _battle_effect_controller.has_method("set_runtime_paused"):
		_battle_effect_controller.set_runtime_paused(paused)
	if board_view != null and board_view.has_method("set_runtime_paused"):
		board_view.set_runtime_paused(paused)
	if _input_controller == null:
		return
	if paused:
		_input_controller.set_input_enabled(false)
		return
	if is_platform_gameplay_active():
		_input_controller.set_input_enabled(_input_mode == "normal" and not _feedback_active)


func is_platform_gameplay_active() -> bool:
	if _presenter == null or _presenter.state == null or _presenter.is_battle_finished():
		return false
	if result_overlay != null and result_overlay.visible:
		return false
	if lose_continue_popup != null and lose_continue_popup.visible:
		return false
	return true


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

	# One burst per destroyed crystal, matching the animated (BoardAnimationController)
	# path's per-cell playback.
	for _cleared_tile in range(data.total_tiles_cleared):
		_play_crystal_burst()


## Maps a booster id to its dedicated SFX (hammer/rocket_barrage/freeze_time),
## matching BoosterCatalog.HAMMER/FREEZE_TIME/ROCKET_BARRAGE ids exactly.
func _play_booster_sfx(booster_id: String) -> void:
	var audio_manager = _get_audio_manager()
	if audio_manager == null:
		return
	match booster_id:
		"hammer":
			audio_manager.play_booster_hammer()
		"rocket_barrage":
			audio_manager.play_booster_rocket_barrage()
		"freeze_time":
			audio_manager.play_booster_freeze_time()


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


## Stage 68.1 hotfix: the hit sound itself now plays from
## BattleEffectController._play_enemy_hit_audio(), right when the damage
## particles actually land (see battle_effect_controller.gd), so it stays in
## sync regardless of caller. This only drives the separate damaged-sprite
## texture swap.
func _play_enemy_damage() -> void:
	if enemy_panel != null and enemy_panel.has_method("play_damage_feedback"):
		enemy_panel.play_damage_feedback()


func _play_victory() -> void:
	var audio_manager = _get_audio_manager()
	if audio_manager != null:
		audio_manager.play_victory()


func _play_defeat() -> void:
	var audio_manager = _get_audio_manager()
	if audio_manager != null:
		audio_manager.play_defeat()


func _play_lose_continue() -> void:
	var audio_manager = _get_audio_manager()
	if audio_manager != null:
		audio_manager.play_lose_continue()


func _play_crystal_burst() -> void:
	var audio_manager = _get_audio_manager()
	if audio_manager != null:
		audio_manager.play_crystal_burst()
