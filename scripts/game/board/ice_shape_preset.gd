extends RefCounted
class_name IceShapePreset

## Stage 57.1 v0.1: named ice shape presets for procedural generation, mirroring
## HoleShapePreset's shape. Center presets are simple offset lists relative to
## the exact board center cell and are already self-symmetric about that one
## cell by construction, so — unlike HoleShapePreset's center offsets — they
## don't need a separate BoardMaskSymmetry mirroring pass. Mirrored-block
## presets are plain rectangle sizes.
##
## Stage 57.4 v0.1: mirrored-block presets grew from 3 sizes (2x2/2x3/3x2) to
## 8 (adding 2x4/4x2/3x3/4x3/3x4), and IcePatternGenerator now mirrors every
## one of them across all four quadrants via BoardMaskSymmetry (matching
## HoleBlockPlacer's approach) rather than Stage 57.1's single-axis 2-copy
## mirror, since Stage 57.2's 32-40 cell density target needs the larger
## 4-copy footprint. 4x3/3x4 (12 cells/quadrant, 48 mirrored) is the largest
## allowed size — IceGenerationRules.ABSOLUTE_RECTANGULAR_MAX_ICE_CELLS.

const CENTER_SQUARE_LIGHT := "center_square_light"
const CENTER_DIAMOND_LIGHT := "center_diamond_light"
const CENTER_SQUARE_HEAVY := "center_square_heavy"
const CENTER_DIAMOND_HEAVY := "center_diamond_heavy"
const MIRRORED_BLOCK_2X2 := "mirrored_block_2x2"
const MIRRORED_BLOCK_2X3 := "mirrored_block_2x3"
const MIRRORED_BLOCK_3X2 := "mirrored_block_3x2"
const MIRRORED_BLOCK_2X4 := "mirrored_block_2x4"
const MIRRORED_BLOCK_4X2 := "mirrored_block_4x2"
const MIRRORED_BLOCK_3X3 := "mirrored_block_3x3"
const MIRRORED_BLOCK_4X3 := "mirrored_block_4x3"
const MIRRORED_BLOCK_3X4 := "mirrored_block_3x4"


static func get_center_shape_types() -> Array[String]:
	return [CENTER_SQUARE_LIGHT, CENTER_DIAMOND_LIGHT, CENTER_SQUARE_HEAVY, CENTER_DIAMOND_HEAVY]


static func get_mirrored_block_shape_types() -> Array[String]:
	return [
		MIRRORED_BLOCK_2X2, MIRRORED_BLOCK_2X3, MIRRORED_BLOCK_3X2,
		MIRRORED_BLOCK_2X4, MIRRORED_BLOCK_4X2, MIRRORED_BLOCK_3X3,
		MIRRORED_BLOCK_4X3, MIRRORED_BLOCK_3X4,
	]


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
		MIRRORED_BLOCK_2X4:
			return Vector2i(2, 4)
		MIRRORED_BLOCK_4X2:
			return Vector2i(4, 2)
		MIRRORED_BLOCK_3X3:
			return Vector2i(3, 3)
		MIRRORED_BLOCK_4X3:
			return Vector2i(4, 3)
		MIRRORED_BLOCK_3X4:
			return Vector2i(3, 4)
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
