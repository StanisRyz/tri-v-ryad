extends RefCounted
class_name BoardMaskGenerator

## Stage 55.1 v0.1: generates real symmetrical, validated procedural hole
## masks using HoleGenerationRules + BoardMaskSymmetry + HoleBlockPlacer/
## HoleShapePlacer + BoardMaskValidator. Candidates place a mix of
## quadrant-mirrored rectangular blocks (2x2/2x3/3x2), "light" center-aware
## shape presets that never touch the exact center cell
## (center_diamond/center_circle_light), and — starting at medium tier —
## "hole" center presets that deliberately do include the exact center cell
## (center_dot_plus/center_diamond_hole/center_circle_hole_light), chosen
## from a difficulty-tier shape pool. Falls back to a full-active mask
## whenever no valid candidate is found within the attempt budget.
##
## Stage 54 note: with the default (early-tier) max_hole_cells of 16, a
## single quadrant-mirrored 2x2 block already uses the entire hole budget
## (4 mirrored copies x 4 cells = 16), and the old upper-left-quadrant-only
## anchor never touched the center row/column — so 2x3/3x2 blocks (24
## mirrored cells) and any center shape were effectively unreachable.
## HoleGenerationRules.for_tier() now grows max_hole_cells/min_active_cells
## with difficulty tier so larger blocks and center shapes have room to be
## validated in.
##
## Stage 55.1 note: HoleGenerationRules.for_tier() also sets
## keep_center_active = false starting at medium tier, which is what lets
## the new "hole" center presets validate when the shape pool picks one —
## rectangular blocks are provably incapable of reaching the exact center
## cell (Stage 54.1), so this has no effect on their behavior. The "light"
## center presets still never hole all four of the center cell's orthogonal
## neighbors at once, so the center cell can sit inside their silhouette
## while staying active and connected even when keep_center_active is true.

const HOLE_GENERATION_RULES_SCRIPT := preload("res://scripts/game/config/hole_generation_rules.gd")
const HOLE_BLOCK_PLACER_SCRIPT := preload("res://scripts/game/board/hole_block_placer.gd")
const HOLE_SHAPE_PLACER_SCRIPT := preload("res://scripts/game/board/hole_shape_placer.gd")
const HOLE_SHAPE_PRESET_SCRIPT := preload("res://scripts/game/board/hole_shape_preset.gd")
const BOARD_MASK_SYMMETRY_SCRIPT := preload("res://scripts/game/board/board_mask_symmetry.gd")
const BOARD_MASK_VALIDATOR_SCRIPT := preload("res://scripts/game/board/board_mask_validator.gd")

const DEFAULT_VALIDATION_ATTEMPTS := 20

var _hole_block_placer := HOLE_BLOCK_PLACER_SCRIPT.new()
var _hole_shape_placer := HOLE_SHAPE_PLACER_SCRIPT.new()
var _validator := BOARD_MASK_VALIDATOR_SCRIPT.new()


## Convenience entry point returning only the mask. Kept as a thin wrapper
## around generate_holes_mask_with_metadata() so existing callers that only
## need the mask (and the Stage 53.1 signature) keep working unchanged.
func generate_holes_mask(rng: RandomNumberGenerator = null, difficulty_budget = null, rules: HoleGenerationRules = null) -> Array:
	var result := generate_holes_mask_with_metadata(rng, difficulty_budget, rules)
	return result.get("mask", build_full_active_mask())


## Stage 54 entry point that also reports generation metadata (attempts
## used, fallback state, validation reasons, active/hole counts, shape
## choices) so callers like BoardChallengeGenerator can attach rich debug
## info without having to re-run/re-validate generation themselves.
func generate_holes_mask_with_metadata(rng: RandomNumberGenerator = null, difficulty_budget = null, rules: HoleGenerationRules = null) -> Dictionary:
	var safe_rng := rng
	if safe_rng == null:
		safe_rng = RandomNumberGenerator.new()
		safe_rng.randomize()

	var tier: String = _resolve_tier(difficulty_budget)
	var safe_rules: HoleGenerationRules = rules if rules != null else HOLE_GENERATION_RULES_SCRIPT.for_tier(tier)
	var max_attempts := _resolve_attempt_budget(difficulty_budget)
	var shape_count := _resolve_shape_count(difficulty_budget)
	var shape_pool := _resolve_shape_pool(tier)

	var last_validation = null
	var last_selected_shape_types: Array[String] = []
	var attempts_used := 0

	for attempt in range(max_attempts):
		attempts_used = attempt + 1
		var candidate_result := _build_candidate_mask(safe_rng, shape_count, shape_pool, safe_rules)
		var candidate: Array = candidate_result.get("mask", build_full_active_mask())
		last_selected_shape_types = candidate_result.get("selected_shape_types", [])
		var validation := _validator.validate(candidate, safe_rules)
		last_validation = validation
		if validation.valid:
			return {
				"mask": candidate,
				"metadata": _build_metadata(attempts_used, false, validation, shape_count, last_selected_shape_types, candidate),
			}

	var fallback_mask := build_full_active_mask()
	var fallback_validation := _validator.validate(fallback_mask, safe_rules)
	return {
		"mask": fallback_mask,
		"metadata": _build_metadata(attempts_used, true, last_validation if last_validation != null else fallback_validation, shape_count, last_selected_shape_types, fallback_mask),
	}


func build_full_active_mask(width: int = BoardModel.DEFAULT_WIDTH, height: int = BoardModel.DEFAULT_HEIGHT) -> Array:
	var mask: Array = []
	for y in range(height):
		var row: Array = []
		for x in range(width):
			row.append(true)
		mask.append(row)
	return mask


## Places up to shape_count shapes drawn from shape_pool. Rectangular shapes
## are anchored in the upper-left quadrant [0, width/2) x [0, height/2) and
## mirrored via HoleBlockPlacer; center shapes are expanded from their base
## offsets (mirrored around the true board center) and applied via
## HoleShapePlacer. A shape attempt that its placer rejects is simply
## skipped; the outer attempt loop in generate_holes_mask_with_metadata()
## retries a whole fresh candidate rather than retrying single placements
## forever.
func _build_candidate_mask(rng: RandomNumberGenerator, shape_count: int, shape_pool: Array[String], rules: HoleGenerationRules) -> Dictionary:
	var mask := build_full_active_mask()
	var selected_shape_types: Array[String] = []
	if shape_count <= 0 or shape_pool.is_empty():
		return {"mask": mask, "selected_shape_types": selected_shape_types}

	var placed_count := 0
	var placement_attempts := 0
	var max_placement_attempts := shape_count * 10

	while placed_count < shape_count and placement_attempts < max_placement_attempts:
		placement_attempts += 1
		var shape_type: String = shape_pool[rng.randi_range(0, shape_pool.size() - 1)]

		var placed := false
		if HOLE_SHAPE_PRESET_SCRIPT.is_center_shape(shape_type):
			placed = _try_place_center_shape(mask, shape_type, rules)
		else:
			placed = _try_place_block_shape(rng, mask, shape_type, rules)

		if placed:
			placed_count += 1
			selected_shape_types.append(shape_type)

	return {"mask": mask, "selected_shape_types": selected_shape_types}


## Stage 54.1: BLOCK_2X2 keeps the original corner-quadrant anchor (4
## distinct mirrored copies, 16 cells) since that already fits every tier's
## hole budget. BLOCK_2X3/BLOCK_3X2 straddle a symmetry axis instead (see
## _try_place_axis_straddling_block()) so their mirrored footprint halves
## from 24 to 12 cells — otherwise a full 4-copy 2x3/3x2 would exceed even
## the raised tier caps for early/medium and rarely if ever validate.
func _try_place_block_shape(rng: RandomNumberGenerator, mask: Array, shape_type: String, rules: HoleGenerationRules) -> bool:
	var block_size := HOLE_SHAPE_PRESET_SCRIPT.get_block_size(shape_type)
	var block_width: int = clampi(block_size.x, rules.min_block_width, rules.max_block_width)
	var block_height: int = clampi(block_size.y, rules.min_block_height, rules.max_block_height)

	if shape_type == HOLE_SHAPE_PRESET_SCRIPT.BLOCK_2X2:
		return _try_place_corner_block(rng, mask, block_width, block_height, rules)

	return _try_place_axis_straddling_block(rng, mask, shape_type, block_width, block_height, rules)


func _try_place_corner_block(rng: RandomNumberGenerator, mask: Array, block_width: int, block_height: int, rules: HoleGenerationRules) -> bool:
	var width := BoardModel.DEFAULT_WIDTH
	var height := BoardModel.DEFAULT_HEIGHT
	@warning_ignore("integer_division")
	var quadrant_width := width / 2
	@warning_ignore("integer_division")
	var quadrant_height := height / 2

	var max_top_left_x := quadrant_width - block_width
	var max_top_left_y := quadrant_height - block_height
	if max_top_left_x < 0 or max_top_left_y < 0:
		return false

	var top_left := Vector2i(rng.randi_range(0, max_top_left_x), rng.randi_range(0, max_top_left_y))
	return _hole_block_placer.try_place_hole_block(mask, top_left, block_width, block_height, rules)


## Anchors the block's odd (3-cell) dimension so it straddles the matching
## symmetry axis (e.g. rows 3-5 straddle row 4 on a 9-tall board): that
## axis's mirror then maps the block onto itself, so only the other axis's
## mirror still produces a second, non-overlapping copy — 2 copies total
## instead of 4.
func _try_place_axis_straddling_block(rng: RandomNumberGenerator, mask: Array, shape_type: String, block_width: int, block_height: int, rules: HoleGenerationRules) -> bool:
	var width := BoardModel.DEFAULT_WIDTH
	var height := BoardModel.DEFAULT_HEIGHT
	@warning_ignore("integer_division")
	var center := Vector2i(width / 2, height / 2)
	@warning_ignore("integer_division")
	var quadrant_width := width / 2
	@warning_ignore("integer_division")
	var quadrant_height := height / 2

	var top_left: Vector2i
	if shape_type == HOLE_SHAPE_PRESET_SCRIPT.BLOCK_2X3:
		@warning_ignore("integer_division")
		var straddle_top := center.y - (block_height - 1) / 2
		var max_top_left_x := quadrant_width - block_width
		if max_top_left_x < 0 or straddle_top < 0 or straddle_top + block_height > height:
			return false
		top_left = Vector2i(rng.randi_range(0, max_top_left_x), straddle_top)
	else:
		@warning_ignore("integer_division")
		var straddle_left := center.x - (block_width - 1) / 2
		var max_top_left_y := quadrant_height - block_height
		if max_top_left_y < 0 or straddle_left < 0 or straddle_left + block_width > width:
			return false
		top_left = Vector2i(straddle_left, rng.randi_range(0, max_top_left_y))

	return _hole_block_placer.try_place_hole_block(mask, top_left, block_width, block_height, rules)


## Expands a center shape's base offsets (relative to the true board center)
## through BoardMaskSymmetry so the placed shape is always symmetrical, then
## applies the resulting absolute cell list via HoleShapePlacer.
func _try_place_center_shape(mask: Array, shape_type: String, rules: HoleGenerationRules) -> bool:
	var width := BoardModel.DEFAULT_WIDTH
	var height := BoardModel.DEFAULT_HEIGHT
	@warning_ignore("integer_division")
	var center := Vector2i(width / 2, height / 2)

	var base_offsets := HOLE_SHAPE_PRESET_SCRIPT.get_center_shape_offsets(shape_type)
	if base_offsets.is_empty():
		return false

	var cells: Array[Vector2i] = []
	var seen := {}
	for offset in base_offsets:
		var absolute_cell := center + (offset as Vector2i)
		for mirrored_cell in BOARD_MASK_SYMMETRY_SCRIPT.get_mirrored_cells(absolute_cell, width, height, rules.symmetry_mode):
			if seen.has(mirrored_cell):
				continue
			seen[mirrored_cell] = true
			cells.append(mirrored_cell)

	return _hole_shape_placer.try_place_shape(mask, cells, rules)


## Suggested v0.1 shape pool by difficulty tier: early is mostly 2x2 with
## occasional 2x3/3x2 and no exact-center hole shapes at all; medium adds a
## rare center_diamond plus a rare center_diamond_hole (the first shape
## allowed to include the exact center cell, since HoleGenerationRules.for_tier()
## sets keep_center_active = false starting at medium); hard adds
## center_circle_hole_light and center_dot_plus alongside the existing
## center presets; very_hard weights the center-hole presets more heavily so
## they (and larger/combined multi-shape candidates) are more likely — always
## still subject to BoardMaskValidator/HoleGenerationRules approval.
func _resolve_shape_pool(tier: String) -> Array[String]:
	match tier:
		DifficultyBudget.TIER_MEDIUM:
			return [
				HOLE_SHAPE_PRESET_SCRIPT.BLOCK_2X2, HOLE_SHAPE_PRESET_SCRIPT.BLOCK_2X2,
				HOLE_SHAPE_PRESET_SCRIPT.BLOCK_2X3, HOLE_SHAPE_PRESET_SCRIPT.BLOCK_3X2,
				HOLE_SHAPE_PRESET_SCRIPT.CENTER_DIAMOND,
				HOLE_SHAPE_PRESET_SCRIPT.CENTER_DIAMOND_HOLE,
			]
		DifficultyBudget.TIER_HARD:
			return [
				HOLE_SHAPE_PRESET_SCRIPT.BLOCK_2X2, HOLE_SHAPE_PRESET_SCRIPT.BLOCK_2X3, HOLE_SHAPE_PRESET_SCRIPT.BLOCK_3X2,
				HOLE_SHAPE_PRESET_SCRIPT.CENTER_DIAMOND, HOLE_SHAPE_PRESET_SCRIPT.CENTER_CIRCLE_LIGHT,
				HOLE_SHAPE_PRESET_SCRIPT.CENTER_DOT_PLUS, HOLE_SHAPE_PRESET_SCRIPT.CENTER_DIAMOND_HOLE, HOLE_SHAPE_PRESET_SCRIPT.CENTER_CIRCLE_HOLE_LIGHT,
			]
		DifficultyBudget.TIER_VERY_HARD:
			return [
				HOLE_SHAPE_PRESET_SCRIPT.BLOCK_2X2, HOLE_SHAPE_PRESET_SCRIPT.BLOCK_2X3, HOLE_SHAPE_PRESET_SCRIPT.BLOCK_3X2,
				HOLE_SHAPE_PRESET_SCRIPT.CENTER_DIAMOND, HOLE_SHAPE_PRESET_SCRIPT.CENTER_CIRCLE_LIGHT,
				HOLE_SHAPE_PRESET_SCRIPT.CENTER_DOT_PLUS,
				HOLE_SHAPE_PRESET_SCRIPT.CENTER_DIAMOND_HOLE, HOLE_SHAPE_PRESET_SCRIPT.CENTER_DIAMOND_HOLE,
				HOLE_SHAPE_PRESET_SCRIPT.CENTER_CIRCLE_HOLE_LIGHT, HOLE_SHAPE_PRESET_SCRIPT.CENTER_CIRCLE_HOLE_LIGHT,
			]
		_:
			return [
				HOLE_SHAPE_PRESET_SCRIPT.BLOCK_2X2, HOLE_SHAPE_PRESET_SCRIPT.BLOCK_2X2, HOLE_SHAPE_PRESET_SCRIPT.BLOCK_2X2,
				HOLE_SHAPE_PRESET_SCRIPT.BLOCK_2X3, HOLE_SHAPE_PRESET_SCRIPT.BLOCK_3X2,
			]


func _resolve_tier(difficulty_budget) -> String:
	if difficulty_budget != null and "difficulty_tier" in difficulty_budget:
		return difficulty_budget.difficulty_tier

	return DifficultyBudget.TIER_EARLY


## Suggested v0.1 difficulty curve: early -> 1 shape, medium -> 1-2,
## hard -> 2, very_hard -> 2-3, nudged by layout_complexity within a tier.
## Rules (min_active_cells/max_hole_cells via HoleBlockPlacer/HoleShapePlacer/
## BoardMaskValidator) always override this — it only decides how many
## shapes to attempt.
func _resolve_shape_count(difficulty_budget) -> int:
	if difficulty_budget == null:
		return 1

	var tier: String = _resolve_tier(difficulty_budget)
	var layout_complexity: float = float(difficulty_budget.layout_complexity) if "layout_complexity" in difficulty_budget else 0.0

	match tier:
		DifficultyBudget.TIER_MEDIUM:
			return 2 if layout_complexity >= 0.5 else 1
		DifficultyBudget.TIER_HARD:
			return 2
		DifficultyBudget.TIER_VERY_HARD:
			return 3 if layout_complexity >= 0.5 else 2
		_:
			return 1


func _resolve_attempt_budget(difficulty_budget) -> int:
	if difficulty_budget != null and "validation_attempts" in difficulty_budget and int(difficulty_budget.validation_attempts) > 0:
		return int(difficulty_budget.validation_attempts)

	return DEFAULT_VALIDATION_ATTEMPTS


## Stage 55.1 v0.1: also reports center_cell_inactive/center_axis_holes_count
## so a generated holes challenge can be inspected for how (and whether) it
## used the center/main-axis area, alongside the existing Stage 54 fields.
func _build_metadata(attempts_used: int, fallback_used: bool, validation, requested_shape_count: int, selected_shape_types: Array[String], mask: Array) -> Dictionary:
	var metadata := {
		"generator_version": "0.1",
		"layout_source": "fallback_full_board" if fallback_used else "procedural_holes",
		"attempts_used": attempts_used,
		"fallback_used": fallback_used,
		"requested_shape_count": requested_shape_count,
		"selected_shape_types": selected_shape_types.duplicate(),
		"center_cell_inactive": _is_center_cell_inactive(mask),
		"center_axis_holes_count": _count_center_axis_holes(mask),
	}

	if validation != null:
		metadata["active_cell_count"] = validation.active_cell_count
		metadata["hole_cell_count"] = validation.hole_cell_count
		metadata["last_validation_reasons"] = (validation.reasons as Array).duplicate()

	return metadata


func _is_center_cell_inactive(mask: Array) -> bool:
	if mask.is_empty():
		return false

	@warning_ignore("integer_division")
	var center_x := BoardModel.DEFAULT_WIDTH / 2
	@warning_ignore("integer_division")
	var center_y := BoardModel.DEFAULT_HEIGHT / 2
	if center_y >= mask.size():
		return false
	var row: Array = mask[center_y]
	if center_x >= row.size():
		return false

	return not bool(row[center_x])


## Counts distinct inactive cells along the two center axes (the main center
## row and center column), deduplicating the exact center cell if it's
## itself inactive. A lightweight signal for how much of the cross/diamond
## center area a generated mask actually used.
func _count_center_axis_holes(mask: Array) -> int:
	if mask.is_empty():
		return 0

	var width := BoardModel.DEFAULT_WIDTH
	var height := BoardModel.DEFAULT_HEIGHT
	@warning_ignore("integer_division")
	var center_x := width / 2
	@warning_ignore("integer_division")
	var center_y := height / 2
	if center_y >= mask.size():
		return 0

	var seen := {}
	var center_row: Array = mask[center_y]
	for x in range(mini(width, center_row.size())):
		if not bool(center_row[x]):
			seen[Vector2i(x, center_y)] = true

	for y in range(mini(height, mask.size())):
		var row: Array = mask[y]
		if center_x >= row.size():
			continue
		if not bool(row[center_x]):
			seen[Vector2i(center_x, y)] = true

	return seen.size()
