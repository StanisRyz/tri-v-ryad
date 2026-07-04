extends PanelContainer

@export var enemy_title := "Enemy Placeholder"
@export var enemy_status := "Battle systems will be added later"

@onready var enemy_title_label: Label = %EnemyTitleLabel
@onready var enemy_status_label: Label = %EnemyStatusLabel


func _ready() -> void:
	enemy_title_label.text = enemy_title
	enemy_status_label.text = enemy_status
