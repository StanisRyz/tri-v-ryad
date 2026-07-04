extends PanelContainer

signal ability_pressed(lane_index: int)

@export var hero_name := "Hero"
@export var lane_text := "Columns 1-3"
@export var hp_text := "HP: -- / --"
@export var charge_text := "Charge: --%"

@onready var hero_name_label: Label = %HeroNameLabel
@onready var lane_label: Label = %LaneLabel
@onready var hp_label: Label = %HpLabel
@onready var charge_label: Label = %ChargeLabel
@onready var ability_button: Button = %AbilityButton

var _lane_index := -1


func _ready() -> void:
	if not ability_button.pressed.is_connected(_on_ability_button_pressed):
		ability_button.pressed.connect(_on_ability_button_pressed)
	refresh()


func refresh() -> void:
	hero_name_label.text = hero_name
	lane_label.text = lane_text
	hp_label.text = hp_text
	charge_label.text = charge_text


func set_hero(hero: HeroData) -> void:
	if hero == null:
		_lane_index = -1
		hero_name = "Hero"
		lane_text = "Columns --"
		hp_text = "HP: -- / --"
		charge_text = "Charge: -- / --"
		ability_button.disabled = true
		ability_button.text = "Charge --"
	else:
		_lane_index = hero.lane_index
		hero_name = hero.display_name
		lane_text = _get_lane_text(hero.lane_index)
		hp_text = "HP: %d / %d" % [hero.current_hp, hero.get_max_hp()]
		charge_text = "Charge: %d / %d" % [hero.ability_charge, hero.ability_charge_required]
		ability_button.disabled = not hero.is_alive() or not hero.is_ability_ready()
		if not hero.is_alive():
			ability_button.text = "Down"
		elif hero.is_ability_ready():
			ability_button.text = "Use"
		else:
			ability_button.text = "Charge %d/%d" % [hero.ability_charge, hero.ability_charge_required]

	refresh()


func _get_lane_text(lane_index: int) -> String:
	var start_column := lane_index * 3 + 1
	var end_column := start_column + 2
	return "Columns %d-%d" % [start_column, end_column]


func _on_ability_button_pressed() -> void:
	if _lane_index == -1:
		return

	ability_pressed.emit(_lane_index)
