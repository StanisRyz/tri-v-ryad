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
## CENTER_DIAMOND/CENTER_CIRCLE_LIGHT never include (0, 0) (the center cell
## itself) and never hole all four of a center's orthogonal neighbors at
## once: they only touch the north/south neighbors (each a >=2-cell
## contiguous arm, so no single-cell hole noise), leaving east/west open so
## the center cell always stays connected to the rest of the active area
## even though it sits inside the shape's silhouette.
##
## Stage 55.1 v0.1: CENTER_DOT_PLUS/CENTER_DIAMOND_HOLE/CENTER_CIRCLE_HOLE_LIGHT
## are new "hole" presets that deliberately do include (0, 0) — see
## get_center_hole_shape_types(). They only validate when the active
## HoleGenerationRules has keep_center_active = false, which
## HoleGenerationRules.for_tier() now sets for medium/hard/very_hard tiers.
## Each is one connected cluster of hole cells (never an isolated single
## cell), so BoardMaskValidator's single-cell-hole-noise check still passes
## when the rest of the mask is safe.

const BLOCK_2X2 := "block_2x2"
const BLOCK_2X3 := "block_2x3"
const BLOCK_3X2 := "block_3x2"
const CENTER_DIAMOND := "center_diamond"
const CENTER_CIRCLE_LIGHT := "center_circle_light"
const CENTER_DOT_PLUS := "center_dot_plus"
const CENTER_DIAMOND_HOLE := "center_diamond_hole"
const CENTER_CIRCLE_HOLE_LIGHT := "center_circle_hole_light"


static func get_block_shape_types() -> Array[String]:
	return [BLOCK_2X2, BLOCK_2X3, BLOCK_3X2]


static func get_center_shape_types() -> Array[String]:
	return [CENTER_DIAMOND, CENTER_CIRCLE_LIGHT, CENTER_DOT_PLUS, CENTER_DIAMOND_HOLE, CENTER_CIRCLE_HOLE_LIGHT]


## Stage 55.1 v0.1: the subset of center shapes allowed to include the exact
## center cell (0, 0). Only these require keep_center_active = false to
## validate; CENTER_DIAMOND/CENTER_CIRCLE_LIGHT never touch (0, 0) so they
## validate under either setting.
static func get_center_hole_shape_types() -> Array[String]:
	return [CENTER_DOT_PLUS, CENTER_DIAMOND_HOLE, CENTER_CIRCLE_HOLE_LIGHT]


static func is_center_shape(shape_type: String) -> bool:
	return shape_type in get_center_shape_types()


static func is_center_hole_shape(shape_type: String) -> bool:
	return shape_type in get_center_hole_shape_types()


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
		CENTER_DOT_PLUS:
			## The exact center cell plus its 4 radius-1 orthogonal neighbors:
			## the smallest hole shape allowed to include (0, 0) — one
			## connected 5-cell "plus" hole cluster, never a lone single cell.
			return [Vector2i(0, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
		CENTER_DIAMOND_HOLE:
			## Extends CENTER_DOT_PLUS's arms out to radius 2 in each
			## direction: a 9-cell connected cross/diamond hole centered on
			## (0, 0), still fully self-symmetric under quadrant_mirror.
			return [
				Vector2i(0, 0),
				Vector2i(0, -1), Vector2i(0, -2),
				Vector2i(0, 1), Vector2i(0, 2),
				Vector2i(-1, 0), Vector2i(-2, 0),
				Vector2i(1, 0), Vector2i(2, 0),
			]
		CENTER_CIRCLE_HOLE_LIGHT:
			## A solid 3x3 block centered on (0, 0): a compact circle-like
			## approximation that includes the center cell, reserved for
			## higher tiers since it uses more of the hole budget at once.
			return [
				Vector2i(0, 0),
				Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
				Vector2i(-1, 0), Vector2i(1, 0),
				Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
			]
		_:
			return []
