extends RefCounted
class_name IceShapePreset

## Stage 57.1 v0.1: named ice shape presets for procedural generation, mirroring
## HoleShapePreset's shape. Center presets are simple offset lists relative to
## the exact board center cell and are already self-symmetric about that one
## cell by construction, so — unlike HoleShapePreset's center offsets — they
## don't need a separate BoardMaskSymmetry mirroring pass. Mirrored-block
## presets are plain rectangle sizes; IcePatternGenerator places one copy and
## mirrors it across a single random axis (horizontal or vertical) rather than
## the full 4-way quadrant mirror BoardMaskSymmetry provides, since ice's much
## tighter per-tier cell caps (IceGenerationRules.for_tier()) can't afford a
## full 4-copy mirrored block the way holes' larger hole budget can.

const CENTER_SQUARE_LIGHT := "center_square_light"
const CENTER_DIAMOND_LIGHT := "center_diamond_light"
const CENTER_SQUARE_HEAVY := "center_square_heavy"
const CENTER_DIAMOND_HEAVY := "center_diamond_heavy"
const MIRRORED_BLOCK_2X2 := "mirrored_block_2x2"
const MIRRORED_BLOCK_2X3 := "mirrored_block_2x3"
const MIRRORED_BLOCK_3X2 := "mirrored_block_3x2"


static func get_center_shape_types() -> Array[String]:
	return [CENTER_SQUARE_LIGHT, CENTER_DIAMOND_LIGHT, CENTER_SQUARE_HEAVY, CENTER_DIAMOND_HEAVY]


static func get_mirrored_block_shape_types() -> Array[String]:
	return [MIRRORED_BLOCK_2X2, MIRRORED_BLOCK_2X3, MIRRORED_BLOCK_3X2]


static func is_center_shape(shape_type: String) -> bool:
	return shape_type in get_center_shape_types()


static func is_mirrored_block_shape(shape_type: String) -> bool:
	return shape_type in get_mirrored_block_shape_types()


static func get_block_size(shape_type: String) -> Vector2i:
	match shape_type:
		MIRRORED_BLOCK_2X3:
			return Vector2i(2, 3)
		MIRRORED_BLOCK_3X2:
			return Vector2i(3, 2)
		_:
			return Vector2i(2, 2)


## Offsets relative to the exact board center cell. IcePatternGenerator adds
## the resolved center cell directly and filters against active cells; ice
## never needs the center cell to stay clear of a shape (unlike holes), so
## every preset here is free to include the exact center offset (0, 0).
static func get_center_shape_offsets(shape_type: String) -> Array[Vector2i]:
	match shape_type:
		CENTER_SQUARE_LIGHT:
			## A solid 3x3 square centered on the board center (9 cells).
			return [
				Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
				Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0),
				Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
			]
		CENTER_DIAMOND_LIGHT:
			## Center cell plus its 4 radius-1 orthogonal neighbors (5 cells).
			return [
				Vector2i(0, 0),
				Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0),
			]
		CENTER_SQUARE_HEAVY:
			## The light 3x3 square plus 4 radius-2 orthogonal arm cells
			## (13 cells) — reserved for hard/very_hard tiers.
			return [
				Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
				Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0),
				Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
				Vector2i(0, -2), Vector2i(0, 2), Vector2i(-2, 0), Vector2i(2, 0),
			]
		CENTER_DIAMOND_HEAVY:
			## The light diamond's cross extended out to radius 2 (9 cells).
			return [
				Vector2i(0, 0),
				Vector2i(0, -1), Vector2i(0, -2),
				Vector2i(0, 1), Vector2i(0, 2),
				Vector2i(-1, 0), Vector2i(-2, 0),
				Vector2i(1, 0), Vector2i(2, 0),
			]
		_:
			return []
