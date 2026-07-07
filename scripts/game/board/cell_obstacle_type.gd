extends RefCounted
class_name CellObstacleType

## Stage 56 v0.1: identifiers for the board obstacle layer, a per-cell state
## kept separate from tile type and special tile metadata. Extend this list
## when adding future blockers/crates/chains/locks rather than modeling them
## as TileType or SpecialTileType values.

const NONE := 0
const ICE := 1


static func is_valid(value: int) -> bool:
	return value == NONE or value == ICE


static func is_ice(value: int) -> bool:
	return value == ICE
