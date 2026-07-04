extends PanelContainer

@export var hero_name := "Hero"
@export var lane_text := "Columns 1-3"
@export var hp_text := "HP: -- / --"
@export var charge_text := "Charge: --%"

@onready var hero_name_label: Label = %HeroNameLabel
@onready var lane_label: Label = %LaneLabel
@onready var hp_label: Label = %HpLabel
@onready var charge_label: Label = %ChargeLabel


func _ready() -> void:
	refresh()


func refresh() -> void:
	hero_name_label.text = hero_name
	lane_label.text = lane_text
	hp_label.text = hp_text
	charge_label.text = charge_text


func set_hero(hero: HeroData) -> void:
	if hero == null:
		hero_name = "Hero"
		lane_text = "Columns --"
		hp_text = "HP: -- / --"
		charge_text = "Charge: -- / --"
	else:
		hero_name = hero.display_name
		lane_text = _get_lane_text(hero.lane_index)
		hp_text = "HP: %d / %d" % [hero.current_hp, hero.get_max_hp()]
		charge_text = "Charge: %d / %d" % [hero.ability_charge, hero.ability_charge_required]

	refresh()


func _get_lane_text(lane_index: int) -> String:
	var start_column := lane_index * 3 + 1
	var end_column := start_column + 2
	return "Columns %d-%d" % [start_column, end_column]
