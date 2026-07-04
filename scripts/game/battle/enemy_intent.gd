extends RefCounted
class_name EnemyIntent

var turns_until_action := 3
var reset_turns := 3
var target_lane := 1


func _init(intent_reset_turns: int = 3, intent_target_lane: int = 1) -> void:
	reset_turns = max(1, intent_reset_turns)
	turns_until_action = reset_turns
	target_lane = intent_target_lane


func tick() -> bool:
	turns_until_action = max(0, turns_until_action - 1)
	return turns_until_action <= 0


func reset() -> void:
	turns_until_action = reset_turns
