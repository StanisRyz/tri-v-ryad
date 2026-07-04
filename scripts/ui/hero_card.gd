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
