extends RefCounted
class_name EnemyData

var id := ""
var display_name := ""
var max_hp := 0
var current_hp := 0
var attack := 0


func _init(enemy_id: String = "", enemy_display_name: String = "", enemy_max_hp: int = 0, enemy_attack: int = 0) -> void:
	id = enemy_id
	display_name = enemy_display_name
	max_hp = max(0, enemy_max_hp)
	attack = max(0, enemy_attack)
	heal_to_full()


func is_alive() -> bool:
	return current_hp > 0


func take_damage(amount: int) -> void:
	current_hp = clampi(current_hp - max(0, amount), 0, max_hp)


func heal_to_full() -> void:
	current_hp = max_hp
