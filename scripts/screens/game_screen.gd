extends Control

signal back_pressed

@onready var menu_button: Button = %MenuButton
@onready var battle_root: VBoxContainer = %BattleRoot
@onready var battle_hud: PanelContainer = %BattleHud
@onready var enemy_panel: PanelContainer = %EnemyPanel
@onready var board_frame: Control = %BoardFrame
@onready var hero_party_panel: HBoxContainer = %HeroPartyPanel

var _layout_manager: LayoutManager

func _ready() -> void:
	if not menu_button.pressed.is_connected(_on_menu_button_pressed):
		menu_button.pressed.connect(_on_menu_button_pressed)

	_layout_manager = LayoutManager.new(get_viewport())
	_layout_manager.layout_changed.connect(_on_layout_changed)

	_refresh_placeholder_data()
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
	board_frame.custom_minimum_size = Vector2(560, 560)
	hero_party_panel.custom_minimum_size = Vector2(0, 132)


func _apply_landscape_layout() -> void:
	battle_root.custom_minimum_size = Vector2(560, 0)
	battle_root.add_theme_constant_override("separation", 10)
	menu_button.custom_minimum_size = Vector2(104, 52)
	battle_hud.custom_minimum_size = Vector2(0, 52)
	enemy_panel.custom_minimum_size = Vector2(0, 92)
	board_frame.custom_minimum_size = Vector2(320, 320)
	hero_party_panel.custom_minimum_size = Vector2(0, 96)


func _refresh_placeholder_data() -> void:
	if battle_hud.has_method("set_placeholder_values"):
		battle_hud.set_placeholder_values("Level 1", "Moves: --")

	if enemy_panel.has_method("set_placeholder_values"):
		enemy_panel.set_placeholder_values("Training Enemy", "HP: -- / --", "Intent: Waiting")
