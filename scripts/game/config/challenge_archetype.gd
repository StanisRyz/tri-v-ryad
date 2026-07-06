extends RefCounted
class_name ChallengeArchetype

## Stage 51 v0.1: identifiers for procedural level challenge archetypes.
## Extend this list when adding blockers, crates, chains, portals, etc.

const NORMAL := "normal"
const ICE := "ice"
const HOLES := "holes"


static func get_all_archetypes() -> Array[String]:
	return [NORMAL, ICE, HOLES]


static func is_valid_archetype(value: String) -> bool:
	return value in get_all_archetypes()
