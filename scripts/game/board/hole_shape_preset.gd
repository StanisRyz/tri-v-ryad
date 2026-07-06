extends RefCounted
class_name HoleShapePreset

## Stage 54.1 v0.1: named hole shape presets for procedural generation.
## Rectangular presets (BLOCK_2X2/2X3/3X2) are placed as ordinary
## HoleBlockPlacer rectangles anchored away from the center. Center presets
## are simple relative cell-offset patterns anchored on the board center;
## BoardMaskGenerator mirrors each offset individually via BoardMaskSymmetry
## before applying them through HoleShapePlacer, so every shape — block or
## center — ends up symmetrical and goes through the exact same validation.
##
## Center offsets deliberately never include (0, 0) (the center cell itself)
## and deliberately never hole all four of a center's orthogonal neighbors
## at once: CENTER_DIAMOND/CENTER_CIRCLE_LIGHT only touch the north/south
## neighbors (each a >=2-cell contiguous arm, so no single-cell hole noise),
## leaving east/west open so the center cell always stays connected to the
## rest of the active area even though it sits inside the shape's silhouette.

const BLOCK_2X2 := "block_2x2"
const BLOCK_2X3 := "block_2x3"
const BLOCK_3X2 := "block_3x2"
const CENTER_DIAMOND := "center_diamond"
const CENTER_CIRCLE_LIGHT := "center_circle_light"


static func get_block_shape_types() -> Array[String]:
	return [BLOCK_2X2, BLOCK_2X3, BLOCK_3X2]


static func get_center_shape_types() -> Array[String]:
	return [CENTER_DIAMOND, CENTER_CIRCLE_LIGHT]


static func is_center_shape(shape_type: String) -> bool:
	return shape_type in get_center_shape_types()


static func get_block_size(shape_type: String) -> Vector2i:
	match shape_type:
		BLOCK_2X3:
			return Vector2i(2, 3)
		BLOCK_3X2:
			return Vector2i(3, 2)
		_:
			return Vector2i(2, 2)


## Pre-mirror offsets relative to the board center. BoardMaskGenerator
## expands each offset through BoardMaskSymmetry.get_mirrored_cells() and
## unions the results, so the caller only needs to describe one representative
## arm per shape.
static func get_center_shape_offsets(shape_type: String) -> Array[Vector2i]:
	match shape_type:
		CENTER_DIAMOND:
			## A slim north arm (radius 1-2) that mirrors into a matching
			## south arm: a compact 4-cell "bowtie" hugging the center.
			return [Vector2i(0, -1), Vector2i(0, -2)]
		CENTER_CIRCLE_LIGHT:
			## A wider north band (radius 1-2, two columns) that mirrors
			## into a matching south band: a rounder 12-cell accent.
			return [Vector2i(0, -1), Vector2i(0, -2), Vector2i(-1, -1), Vector2i(-1, -2)]
		_:
			return []
