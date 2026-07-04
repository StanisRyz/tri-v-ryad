extends Control

signal back_pressed

const BATTLE_PRESENTER_SCRIPT := preload("res://scripts/game/presentation/battle_presenter.gd")
const BOARD_INPUT_CONTROLLER_SCRIPT := preload("res://scripts/game/input/board_input_controller.gd")

@onready var menu_button: Button = %MenuButton
@onready var battle_root: VBoxContainer = %BattleRoot
@onready var battle_hud: PanelContainer = %BattleHud
@onready var enemy_panel: PanelContainer = %EnemyPanel
@onready var board_view: Control = %BoardView
@onready var status_label: Label = %StatusLabel
@onready var hero_party_panel: HBoxContainer = %HeroPartyPanel
@onready var result_overlay: PanelContainer = %BattleResultOverlay

var _layout_manager: LayoutManager
var _presenter
var _input_controller

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
	battle_root.custom_minimum_size = Vector2(664, 0)
	battle_root.add_theme_constant_override("separation", 14)
	menu_button.custom_minimum_size = Vector2(118, 70)
	battle_hud.custom_minimum_size = Vector2(0, 70)
	enemy_panel.custom_minimum_size = Vector2(0, 132)
	board_view.custom_minimum_size = Vector2(560, 560)
	hero_party_panel.custom_minimum_size = Vector2(0, 132)


func _apply_landscape_layout() -> void:
	battle_root.custom_minimum_size = Vector2(560, 0)
	battle_root.add_theme_constant_override("separation", 10)
	menu_button.custom_minimum_size = Vector2(104, 52)
	battle_hud.custom_minimum_size = Vector2(0, 52)
	enemy_panel.custom_minimum_size = Vector2(0, 92)
	board_view.custom_minimum_size = Vector2(320, 320)
	hero_party_panel.custom_minimum_size = Vector2(0, 96)


func _setup_playable_battle() -> void:
	_presenter = BATTLE_PRESENTER_SCRIPT.new()
	_input_controller = BOARD_INPUT_CONTROLLER_SCRIPT.new()

	board_view.tile_pressed.connect(_input_controller.handle_tile_pressed)
	board_view.tile_drag_released.connect(_input_controller.handle_tile_drag_released)
	_input_controller.swap_requested.connect(_on_swap_requested)
	_input_controller.selection_changed.connect(_on_selection_changed)
	_input_controller.selection_cleared.connect(_on_selection_cleared)
	_input_controller.invalid_input.connect(_on_invalid_input)

	_presenter.board_changed.connect(_on_board_changed)
	_presenter.battle_state_changed.connect(_on_battle_state_changed)
	_presenter.turn_resolved.connect(_on_turn_resolved)
	_presenter.invalid_swap.connect(_on_invalid_swap)
	_presenter.battle_finished.connect(_on_battle_finished)

	result_overlay.restart_pressed.connect(_on_restart_pressed)
	result_overlay.menu_pressed.connect(_on_menu_button_pressed)
	_start_new_battle()


func _start_new_battle() -> void:
	result_overlay.hide_result()
	board_view.clear_lane_highlights()
	_input_controller.set_input_enabled(true)
	_set_status("Select a tile")
	_presenter.start_new_battle()


func _on_board_changed(board: BoardModel) -> void:
	board_view.set_board(board)


func _on_battle_state_changed(state: BattleState) -> void:
	if battle_hud.has_method("set_values"):
		battle_hud.set_values("Level 1", "Moves: %d" % state.moves_left)

	if enemy_panel.has_method("set_enemy_state"):
		enemy_panel.set_enemy_state(state.enemy, state.enemy_intent)

	if hero_party_panel.has_method("set_heroes"):
		hero_party_panel.set_heroes(state.heroes)


func _on_turn_resolved(result: BattleTurnResult) -> void:
	if not _presenter.is_battle_finished():
		_input_controller.set_input_enabled(true)

	board_view.highlight_lanes(result.lane_activations)
	if result.total_damage_to_enemy <= 0:
		_set_status("Turn resolved")
		return

	var first_event := _get_first_damage_event(result.damage_events)
	if first_event.is_empty():
		_set_status("Heroes dealt %d damage" % result.total_damage_to_enemy)
	else:
		_set_status("%s dealt %d damage" % [first_event.get("hero_id", "Hero"), first_event.get("damage", 0)])


func _on_invalid_swap(reason: String) -> void:
	if not _presenter.is_battle_finished():
		_input_controller.set_input_enabled(true)

	board_view.clear_lane_highlights()
	_set_status("No match" if reason == "no_match" else "Invalid swap")


func _on_battle_finished(status: int) -> void:
	_input_controller.set_input_enabled(false)
	if status == BattleState.Status.VICTORY:
		_set_status("Victory")
		result_overlay.show_victory()
	elif status == BattleState.Status.DEFEAT:
		_set_status("Defeat")
		result_overlay.show_defeat()


func _on_selection_changed(cell: Vector2i) -> void:
	board_view.set_selected_cell(cell)
	_set_status("Select a neighboring tile")


func _on_selection_cleared() -> void:
	board_view.clear_selected_cell()
	_set_status("Select a tile")


func _on_invalid_input(reason: String) -> void:
	var messages := {
		"swipe_too_short": "Swipe too short",
		"outside_board": "Outside board",
		"input_locked": "Input locked",
	}
	_set_status(messages.get(reason, "Invalid input"))


func _on_swap_requested(from_cell: Vector2i, to_cell: Vector2i) -> void:
	_input_controller.set_input_enabled(false)
	board_view.clear_lane_highlights()
	_set_status("Resolving turn")
	_presenter.request_swap(from_cell, to_cell)


func _on_restart_pressed() -> void:
	_start_new_battle()


func _get_first_damage_event(events: Array[Dictionary]) -> Dictionary:
	for event in events:
		if event.get("damage", 0) > 0:
			return event

	return {}


func _set_status(message: String) -> void:
	status_label.text = message
