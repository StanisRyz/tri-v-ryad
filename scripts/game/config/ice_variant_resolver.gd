extends RefCounted
class_name IceVariantResolver

## Stage 57.2 v0.1: resolves the ice cycle variant from a level number, using
## the same repeating 5-level cycle ChallengeArchetypeResolver already uses
## for archetype selection (1 normal, 2 ice, 3 holes, 4 ice, 5 holes) — `ice`
## always lands on cycle positions 2 and 4. Position 2 is weak (1-layer-only)
## ice, position 4 is strong (2-layer-only) ice; every other position never
## resolves to `ice` in the first place, so NONE is only a defensive default.

const ICE_VARIANT_SCRIPT := preload("res://scripts/game/config/ice_variant.gd")


static func resolve_for_level(level_number: int) -> String:
	var safe_level_number: int = max(1, level_number)
	var cycle_position := safe_level_number % 5

	match cycle_position:
		2:
			return ICE_VARIANT_SCRIPT.WEAK
		4:
			return ICE_VARIANT_SCRIPT.STRONG
		_:
			return ICE_VARIANT_SCRIPT.NONE
