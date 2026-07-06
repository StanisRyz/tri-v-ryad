extends RefCounted
class_name ChallengeArchetypeResolver

## Stage 51 v0.1: maps a level number to a challenge archetype using a
## repeating 5-level cycle: normal, ice, holes, ice, holes.

const CHALLENGE_ARCHETYPE_SCRIPT := preload("res://scripts/game/config/challenge_archetype.gd")
const LEVEL_LABEL_FORMATTER_SCRIPT := preload("res://scripts/game/config/level_label_formatter.gd")


func resolve_for_level(level_number: int) -> String:
	var safe_level_number: int = max(1, level_number)
	var cycle_position := safe_level_number % 5

	match cycle_position:
		1:
			return CHALLENGE_ARCHETYPE_SCRIPT.NORMAL
		2:
			return CHALLENGE_ARCHETYPE_SCRIPT.ICE
		3:
			return CHALLENGE_ARCHETYPE_SCRIPT.HOLES
		4:
			return CHALLENGE_ARCHETYPE_SCRIPT.ICE
		_:
			return CHALLENGE_ARCHETYPE_SCRIPT.HOLES


func resolve_for_level_id(level_id: String) -> String:
	var level_number := LEVEL_LABEL_FORMATTER_SCRIPT.extract_level_number(level_id)
	return resolve_for_level(max(1, level_number))
