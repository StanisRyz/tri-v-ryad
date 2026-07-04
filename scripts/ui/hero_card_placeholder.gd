extends PanelContainer

@export var hero_name := "Hero"
@export var lane_text := "Columns 1-3"

@onready var hero_name_label: Label = %HeroNameLabel
@onready var lane_label: Label = %LaneLabel


func _ready() -> void:
	hero_name_label.text = hero_name
	lane_label.text = lane_text
