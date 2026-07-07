extends RefCounted
class_name IceVariant

## Stage 57.2 v0.1: a variant layer inside the existing `ice` archetype (not
## a new archetype) that determines whether every frozen cell IcePatternGenerator
## generates for an ice level is 1-layer (weak) or 2-layer (strong) ice.
## NONE keeps the pre-Stage-57.2 probability-based double-ice behavior, for
## any caller that builds an IceGenerationRules without resolving a variant.

const NONE := "none"
const WEAK := "weak"
const STRONG := "strong"


static func is_valid(value: String) -> bool:
	return value == NONE or value == WEAK or value == STRONG
