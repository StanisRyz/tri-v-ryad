extends PanelContainer

@onready var level_label: Label = %LevelLabel
@onready var moves_label: Label = %MovesLabel


func _ready() -> void:
	set_placeholder_values("Level 1", "Moves: --")


func set_values(level_text: String, moves_text: String) -> void:
	level_label.text = level_text
	moves_label.text = moves_text


func set_placeholder_values(level_text: String, moves_text: String) -> void:
	set_values(level_text, moves_text)
