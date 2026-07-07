extends RefCounted
class_name IcePatternGenerator

## Stage 57 v0.1: generates real procedural frozen_cells for `ice` archetype
## levels — readable patterns (small_cluster/edge_patch/center_patch/
## diagonal_band), not random per-cell noise. Ice never disconnects or
## hides board area (unlike holes), so validation here only needs to check
## active-cell safety, duplicate-free output, count caps, and saturation —
## there is no connectivity/enclosed-pocket concern to worry about.
##
## Stage 57.1 v0.1: generation prefers symmetric, shape-based placement
## (IceShapePreset center/mirrored-block presets) over scattered patterns,
## closer to how BoardMaskGenerator generates holes.
##
## Stage 57.2 v0.1: every ice level now targets a dense 32-40 cell range
## (IceGenerationRules.MIN_ICE_CELLS/MAX_ICE_CELLS). A selected center shape
## is only a *seed* — generation tops it up with more cells until the target
## count is reached. Every generated cell's layer count is decided by
## rules.ice_variant (WEAK forces every cell to 1 layer, STRONG forces every
## cell to 2 layers) rather than a random per-cell chance.
##
## Stage 57.4 v0.1: fixes "stair-step"/partial-rectangle ice layouts. Ice
## generation had been building a candidate by adding pattern cells one at a
## time, breaking out mid-shape once target_count/max_ice_cells was reached —
## which could cut a mirrored rectangle in half, leaving an incomplete,
## asymmetric-looking cluster in one or more quadrants. Non-center generation
## now treats a mirrored-block shape as one atomic placement: the *entire*
## mirrored shape (all 4 quadrant copies) is generated up front and only ever
## accepted as a whole, never partially. _analyze_quadrant_rectangles()
## verifies the resulting non-center cells form one complete, congruent
## rectangle per quadrant (center-shape cells are analyzed separately and
## never counted as part of a quadrant rectangle); _complete_rectangle_gaps()
## is a defensive fill-in pass for the rare case a candidate isn't already
## clean. A center shape is optional and is dropped first (never the
## rectangle) if keeping both would exceed the applicable cell cap. A clean,
## single mirrored rectangle may use the enlarged
## IceGenerationRules.ABSOLUTE_RECTANGULAR_MAX_ICE_CELLS (48) cap; anything
## else stays bound by the normal max_ice_cells (40). The deterministic
## fallback also generates one clean mirrored rectangle (2x4, 32 cells)
## instead of Stage 57.2's two-separate-anchors approach.

const ICE_GENERATION_RULES_SCRIPT := preload("res://scripts/game/config/ice_generation_rules.gd")
const ICE_SHAPE_PRESET_SCRIPT := preload("res://scripts/game/board/ice_shape_preset.gd")
const ICE_VARIANT_SCRIPT := preload("res://scripts/game/config/ice_variant.gd")
const BOARD_MASK_SYMMETRY_SCRIPT := preload("res://scripts/game/board/board_mask_symmetry.gd")

const DEFAULT_VALIDATION_ATTEMPTS := 20
## Never freeze more than this fraction of the active board, regardless of
## what a (possibly hand-built) rules object's max_ice_cells allows. 48/81
## (the Stage 57.4 absolute rectangular cap on a full 9x9 board) stays safely
## under this.
const MAX_SATURATION_RATIO := 0.6
const ORTHOGONAL_OFFSETS: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0),
]
## Stage 57.4 v0.1: deterministic fallback anchor/size for one clean 2x4
## mirrored rectangle (8 cells/quadrant x 4 = 32, exactly MIN_ICE_CELLS) on a
## full active 9x9 board — no randomness involved, so this can never fail the
## way a randomized candidate can, and (being a single atomic shape) is
## always a clean rectangle by construction.
const FALLBACK_RECTANGLE_ANCHOR := Vector2i(0, 0)
const FALLBACK_RECTANGLE_SIZE := Vector2i(2, 4)


## Entry point mirroring BoardMaskGenerator.generate_holes_mask_with_metadata():
## returns {"frozen_cells": Array, "metadata": Dictionary}. board_mask is the
## already-generated active/inactive mask (full 9x9 active for `ice` in this
## stage) so frozen cells are only ever placed where the board is playable.
func generate_frozen_cells(rng: RandomNumberGenerator = null, board_mask: Array = [], difficulty_budget = null, rules: IceGenerationRules = null) -> Dictionary:
	var safe_rng := rng
	if safe_rng == null:
		safe_rng = RandomNumberGenerator.new()
		safe_rng.randomize()

	var tier := _resolve_tier(difficulty_budget)
	var safe_rules: IceGenerationRules = rules if rules != null else ICE_GENERATION_RULES_SCRIPT.for_tier(tier)
	var dimensions := _mask_dimensions(board_mask)
	var width: int = dimensions.x
	var height: int = dimensions.y
	var active_cells := _active_cells_from_mask(board_mask, width, height)

	if active_cells.is_empty():
		return {
			"frozen_cells": [],
			"metadata": _build_metadata({
				"layout_source": "fallback_no_ice",
				"ice_variant": safe_rules.ice_variant,
				"fallback_used": true,
				"reasons": ["no_active_cells"],
			}),
		}

	var active_lookup := {}
	for cell in active_cells:
		active_lookup[cell] = true

	var max_attempts := safe_rules.validation_attempts if safe_rules.validation_attempts > 0 else DEFAULT_VALIDATION_ATTEMPTS
	var low := mini(safe_rules.min_ice_cells, safe_rules.max_ice_cells)
	var high := maxi(safe_rules.min_ice_cells, safe_rules.max_ice_cells)
	var target_count: int = clampi(safe_rng.randi_range(low, high), 0, active_cells.size())

	var center_ice_roll := safe_rng.randf()
	var center_seed: Dictionary = {}
	var center_shape_type := ""
	var center_ice_used := false

	if center_ice_roll < safe_rules.center_ice_chance:
		var picked := _pick_center_shape_cells(safe_rng, active_lookup, safe_rules, width, height)
		var picked_cell_set: Dictionary = picked.get("cell_set", {})
		if not picked_cell_set.is_empty():
			center_seed = picked_cell_set
			center_shape_type = String(picked.get("shape_type", ""))
			center_ice_used = true

	var last_reasons: Array[String] = []
	var attempts_used := 0

	## Stage 57.4: each attempt builds one atomic, clean mirrored rectangle
	## (optionally paired with the center seed) and validates the *full*
	## candidate — never a partially-added shape.
	for attempt in range(max_attempts):
		attempts_used += 1
		var build_result := _build_rectangular_candidate(safe_rng, active_lookup, width, height, target_count, safe_rules, center_seed, center_shape_type, center_ice_used)
		if build_result.is_empty():
			continue

		var candidate: Dictionary = build_result.get("candidate", {})
		var used_absolute_cap: bool = build_result.get("used_absolute_cap", false)
		var effective_max: int = safe_rules.absolute_rectangular_max_ice_cells if used_absolute_cap else safe_rules.max_ice_cells

		var validation := _validate(candidate, active_cells, safe_rules, effective_max, width, height)
		last_reasons = validation.get("reasons", [])
		if bool(validation.get("valid", false)):
			var ice_count: int = int(validation.get("ice_count", 0))
			return {
				"frozen_cells": candidate.get("frozen_cells", []),
				"metadata": _build_metadata({
					"layout_source": "procedural_ice_center" if center_ice_used and not build_result.get("center_removed", false) else "procedural_ice",
					"ice_variant": safe_rules.ice_variant,
					"selected_patterns": candidate.get("selected_patterns", []),
					"target_ice_count": target_count,
					"ice_count": ice_count,
					"weak_count": validation.get("weak_count", 0),
					"strong_count": validation.get("strong_count", 0),
					"attempts_used": attempts_used,
					"fallback_used": false,
					"reasons": last_reasons,
					"center_ice_roll": center_ice_roll,
					"center_ice_used": center_ice_used and not build_result.get("center_removed", false),
					"center_ice_cell_count": candidate.get("center_cell_set", {}).size(),
					"symmetric_ice_used": _candidate_used_symmetric_shape(candidate),
					"rectangular_completion_used": build_result.get("completion_used", false),
					"center_shape_removed_for_completion": build_result.get("center_removed", false),
					"incomplete_rectangles_detected": build_result.get("incomplete_detected", false),
					"completed_rectangle_count": build_result.get("completed_rectangle_count", 0),
					"rectangle_shapes_used": build_result.get("rectangle_shapes_used", []),
					"absolute_rectangular_cap_used": used_absolute_cap,
					"final_ice_cell_count": ice_count,
				}),
			}

	## Stage 57.4: random generation exhausted its attempt budget without a
	## valid candidate — fall back to a deterministic, clean single mirrored
	## rectangle so an ice level never ends up with empty frozen_cells or a
	## non-rectangular layout, honoring the resolved weak/strong variant.
	var fallback_cell_set := _build_deterministic_fallback_cell_set(active_lookup, width, height)
	var fallback_candidate := {
		"frozen_cells": _assign_fallback_layers(fallback_cell_set, safe_rules),
		"selected_patterns": [ICE_SHAPE_PRESET_SCRIPT.MIRRORED_BLOCK_2X4],
		"cell_set": fallback_cell_set,
		"center_cell_set": {},
	}
	var fallback_validation := _validate(fallback_candidate, active_cells, safe_rules, safe_rules.max_ice_cells, width, height)
	var fallback_ice_count: int = int(fallback_validation.get("ice_count", 0))

	return {
		"frozen_cells": fallback_candidate.get("frozen_cells", []),
		"metadata": _build_metadata({
			"layout_source": "fallback_symmetric_ice",
			"ice_variant": safe_rules.ice_variant,
			"selected_patterns": fallback_candidate.get("selected_patterns", []),
			"target_ice_count": target_count,
			"ice_count": fallback_ice_count,
			"weak_count": fallback_validation.get("weak_count", 0),
			"strong_count": fallback_validation.get("strong_count", 0),
			"attempts_used": attempts_used,
			"fallback_used": true,
			"fallback_symmetric_used": true,
			"reasons": last_reasons,
			"center_ice_roll": center_ice_roll,
			"center_ice_used": false,
			"center_ice_cell_count": 0,
			"symmetric_ice_used": true,
			"rectangular_completion_used": false,
			"center_shape_removed_for_completion": center_ice_used,
			"incomplete_rectangles_detected": false,
			"completed_rectangle_count": 0,
			"rectangle_shapes_used": [ICE_SHAPE_PRESET_SCRIPT.MIRRORED_BLOCK_2X4],
			"absolute_rectangular_cap_used": false,
			"final_ice_cell_count": fallback_ice_count,
		}),
	}


## Tries every shape in rules.allowed_center_shape_types, in a random order
## (seeded from rng so results stay reproducible per generation seed), and
## returns the first one whose active-filtered cell count is non-empty and
## fits under both rules.max_ice_cells and rules.max_center_ice_cells.
## Returns {} if no allowed center shape could be placed at all. The result
## is only ever used as a seed candidate for _build_rectangular_candidate() —
## it is not a complete candidate by itself.
func _pick_center_shape_cells(rng: RandomNumberGenerator, active_lookup: Dictionary, rules: IceGenerationRules, width: int, height: int) -> Dictionary:
	if rules.allowed_center_shape_types.is_empty():
		return {}

	var ordered_shapes := _shuffled(rng, rules.allowed_center_shape_types)

	@warning_ignore("integer_division")
	var center := Vector2i(width / 2, height / 2)
	var cap: int = mini(rules.max_ice_cells, rules.max_center_ice_cells) if rules.max_center_ice_cells > 0 else rules.max_ice_cells

	for shape_type in ordered_shapes:
		var offsets := ICE_SHAPE_PRESET_SCRIPT.get_center_shape_offsets(shape_type)
		if offsets.is_empty():
			continue

		var cell_set := {}
		for offset in offsets:
			var cell: Vector2i = center + offset
			if active_lookup.has(cell):
				cell_set[cell] = true

		if cell_set.is_empty() or cell_set.size() > cap:
			continue

		return {"cell_set": cell_set, "shape_type": shape_type}

	return {}


## Stage 57.4: builds one candidate as an *atomic* pairing of (optionally) the
## center seed with exactly one complete mirrored-block rectangle — never a
## partially-added shape, and never more than one non-center rectangle, so
## "stair-step"/incomplete-cluster layouts can no longer occur. Tries every
## allowed rectangle shape (random order, seed-reproducible) and, for each,
## first tries pairing it with the center seed (if any) under the normal
## max_ice_cells cap; if that doesn't fit, tries the rectangle alone —
## dropping the center seed entirely rather than truncating the rectangle —
## allowing the enlarged absolute_rectangular_max_ice_cells cap if needed.
## Picks whichever valid option lands closest to target_count. Returns {} if
## no allowed shape produces a usable option at all.
func _build_rectangular_candidate(rng: RandomNumberGenerator, active_lookup: Dictionary, width: int, height: int, target_count: int, rules: IceGenerationRules, center_seed: Dictionary, center_shape_type: String, center_ice_used: bool) -> Dictionary:
	if rules.allowed_symmetric_shape_types.is_empty():
		return {}

	var ordered_shapes := _shuffled(rng, rules.allowed_symmetric_shape_types)

	var best: Dictionary = {}
	var best_diff := -1

	for shape_type in ordered_shapes:
		var rect_cells := _generate_mirrored_block_cells(rng, shape_type, active_lookup, width, height)
		if rect_cells.is_empty():
			continue

		var rect_set := {}
		for cell in rect_cells:
			rect_set[cell] = true

		## Defensive completion pass: by construction a single atomically
		## generated mirrored block is always already a clean rectangle, but
		## this keeps the fill-in machinery real (not dead code) and guards
		## against a future active_lookup shape (e.g. combined archetypes)
		## unexpectedly punching a hole in it.
		var analysis := _analyze_quadrant_rectangles(rect_set, width, height)
		var completion_used := false
		var completed_rectangle_count := 0
		var incomplete_detected := not bool(analysis.get("complete", true))
		if incomplete_detected:
			var completion := _complete_rectangle_gaps(rect_set, active_lookup, width, height)
			rect_set = completion.get("cell_set", rect_set)
			completed_rectangle_count = int(completion.get("completed_rectangle_count", 0))
			completion_used = completed_rectangle_count > 0
			analysis = _analyze_quadrant_rectangles(rect_set, width, height)
			if not bool(analysis.get("complete", true)):
				continue

		## Option 1: pair with the center seed, staying under the normal cap.
		if center_ice_used and not center_seed.is_empty():
			var combined: Dictionary = center_seed.duplicate()
			for cell in rect_set.keys():
				combined[cell] = true
			if combined.size() >= rules.min_ice_cells and combined.size() <= rules.max_ice_cells:
				var diff := absi(combined.size() - target_count)
				if best.is_empty() or diff < best_diff:
					best_diff = diff
					best = {
						"cell_set": combined,
						"center_cell_set": center_seed.duplicate(),
						"selected_patterns": [center_shape_type, shape_type],
						"used_absolute_cap": false,
						"center_removed": false,
						"completion_used": completion_used,
						"incomplete_detected": incomplete_detected,
						"completed_rectangle_count": completed_rectangle_count,
						"rectangle_shapes_used": [shape_type],
					}

		## Option 2: the rectangle alone — center dropped entirely (never
		## truncated) if it can't also fit. May use the enlarged absolute cap.
		var alone_size := rect_set.size()
		if alone_size >= rules.min_ice_cells:
			var used_absolute := alone_size > rules.max_ice_cells
			var cap: int = rules.absolute_rectangular_max_ice_cells if used_absolute else rules.max_ice_cells
			if alone_size <= cap:
				var diff2 := absi(alone_size - target_count)
				if best.is_empty() or diff2 < best_diff:
					best_diff = diff2
					best = {
						"cell_set": rect_set.duplicate(),
						"center_cell_set": {},
						"selected_patterns": [shape_type],
						"used_absolute_cap": used_absolute,
						"center_removed": center_ice_used,
						"completion_used": completion_used,
						"incomplete_detected": incomplete_detected,
						"completed_rectangle_count": completed_rectangle_count,
						"rectangle_shapes_used": [shape_type],
					}

	if best.is_empty():
		return {}

	var cell_set: Dictionary = best.get("cell_set", {})
	return {
		"candidate": {
			"frozen_cells": _assign_layers(rng, cell_set, rules),
			"selected_patterns": best.get("selected_patterns", []),
			"cell_set": cell_set,
			"center_cell_set": best.get("center_cell_set", {}),
		},
		"used_absolute_cap": best.get("used_absolute_cap", false),
		"center_removed": best.get("center_removed", false),
		"completion_used": best.get("completion_used", false),
		"incomplete_detected": best.get("incomplete_detected", false),
		"completed_rectangle_count": best.get("completed_rectangle_count", 0),
		"rectangle_shapes_used": best.get("rectangle_shapes_used", []),
	}


func _candidate_used_symmetric_shape(candidate: Dictionary) -> bool:
	var mirrored_types := ICE_SHAPE_PRESET_SCRIPT.get_mirrored_block_shape_types()
	for pattern in candidate.get("selected_patterns", []):
		if pattern in mirrored_types:
			return true
	return false


## Places one copy of a mirrored-block shape (any IceShapePreset rectangle
## size, 2x2 up to 4x3/3x2 up to 3x4) anchored inside the board's upper-left
## quadrant, then mirrors it across all four quadrants via
## BoardMaskSymmetry.get_mirrored_block_cells() — on a 9x9 board this is
## exactly (x,y)/(8-x,y)/(x,8-y)/(8-x,8-y), matching how BoardMaskGenerator
## places hole blocks. Anchoring strictly inside the quadrant (never past the
## center row/column) keeps the four mirrored copies non-overlapping, so
## every shape's mirrored cell count is exactly 4x its single-quadrant area
## with no truncation. Filters to active cells only, so a mirrored copy
## landing on an inactive cell (not possible yet since `ice` always uses a
## full active mask, but safe for a future combined archetype) is simply
## dropped — this is the only way this function's output can end up smaller
## than the full 4x area, which _build_rectangular_candidate() detects via
## _analyze_quadrant_rectangles() rather than silently accepting a partial
## shape.
func _generate_mirrored_block_cells(rng: RandomNumberGenerator, shape_type: String, active_lookup: Dictionary, width: int, height: int) -> Array[Vector2i]:
	var block_size := ICE_SHAPE_PRESET_SCRIPT.get_block_size(shape_type)
	var block_width: int = block_size.x
	var block_height: int = block_size.y

	@warning_ignore("integer_division")
	var quadrant_width := width / 2
	@warning_ignore("integer_division")
	var quadrant_height := height / 2

	var max_top_left_x := quadrant_width - block_width
	var max_top_left_y := quadrant_height - block_height
	if max_top_left_x < 0 or max_top_left_y < 0:
		return []

	var top_left := Vector2i(rng.randi_range(0, max_top_left_x), rng.randi_range(0, max_top_left_y))
	var mirrored_cells := BOARD_MASK_SYMMETRY_SCRIPT.get_mirrored_block_cells(top_left, block_width, block_height, width, height)
	return mirrored_cells.filter(func(cell: Vector2i) -> bool: return active_lookup.has(cell))


## Stage 57.4: deterministic (non-random) fallback layout — a single clean
## mirrored 2x4 rectangle (8 cells/quadrant x 4 = 32 = MIN_ICE_CELLS) on a
## full active 9x9 board, guaranteed regardless of rng state.
func _build_deterministic_fallback_cell_set(active_lookup: Dictionary, width: int, height: int) -> Dictionary:
	var mirrored := BOARD_MASK_SYMMETRY_SCRIPT.get_mirrored_block_cells(FALLBACK_RECTANGLE_ANCHOR, FALLBACK_RECTANGLE_SIZE.x, FALLBACK_RECTANGLE_SIZE.y, width, height)
	var cell_set := {}
	for cell in mirrored:
		if active_lookup.has(cell):
			cell_set[cell] = true
	return cell_set


## Splits non_center_cell_set into the board's four quadrants (relative to
## the exact center) and checks that each non-empty quadrant's cells exactly
## fill their own bounding rectangle (no gaps) and that every non-empty
## quadrant's rectangle has the same width/height as every other (4-way
## congruent, i.e. actually mirrored rather than four different shapes).
## center_cell_set is deliberately excluded by the caller before this runs —
## center-specific shapes are handled separately and are never treated as a
## quadrant rectangle.
func _analyze_quadrant_rectangles(non_center_cell_set: Dictionary, width: int, height: int) -> Dictionary:
	if non_center_cell_set.is_empty():
		return {"complete": true, "quadrant_sizes": []}

	var quadrants := _group_cells_by_quadrant(non_center_cell_set, width, height)
	var complete := true
	var quadrant_sizes: Array[Vector2i] = []

	for q in quadrants.keys():
		var cells: Array = quadrants[q]
		if cells.is_empty():
			continue

		var bounds := _bounding_rect(cells)
		var rect_size: Vector2i = bounds["size"]
		var expected_count: int = rect_size.x * rect_size.y
		if cells.size() != expected_count:
			complete = false
		quadrant_sizes.append(rect_size)

	for i in range(1, quadrant_sizes.size()):
		if quadrant_sizes[i] != quadrant_sizes[0]:
			complete = false
			break

	return {"complete": complete, "quadrant_sizes": quadrant_sizes}


## Fills any active, missing cells inside each quadrant's own bounding
## rectangle so an incomplete cluster becomes a complete one wherever
## possible. Returns the (possibly enlarged) cell_set plus how many
## quadrants actually needed filling.
func _complete_rectangle_gaps(non_center_cell_set: Dictionary, active_lookup: Dictionary, width: int, height: int) -> Dictionary:
	var quadrants := _group_cells_by_quadrant(non_center_cell_set, width, height)
	var completed_cell_set: Dictionary = non_center_cell_set.duplicate()
	var completed_rectangle_count := 0

	for q in quadrants.keys():
		var cells: Array = quadrants[q]
		if cells.is_empty():
			continue

		var bounds := _bounding_rect(cells)
		var min_cell: Vector2i = bounds["min"]
		var rect_size: Vector2i = bounds["size"]
		var filled_any := false

		for y in range(min_cell.y, min_cell.y + rect_size.y):
			for x in range(min_cell.x, min_cell.x + rect_size.x):
				var cell := Vector2i(x, y)
				if not completed_cell_set.has(cell) and active_lookup.has(cell):
					completed_cell_set[cell] = true
					filled_any = true

		if filled_any:
			completed_rectangle_count += 1

	return {"cell_set": completed_cell_set, "completed_rectangle_count": completed_rectangle_count}


func _group_cells_by_quadrant(cell_set: Dictionary, width: int, height: int) -> Dictionary:
	@warning_ignore("integer_division")
	var center_x := width / 2
	@warning_ignore("integer_division")
	var center_y := height / 2

	var quadrants := {0: [], 1: [], 2: [], 3: []}
	for cell_key in cell_set.keys():
		var cell: Vector2i = cell_key
		var is_right: bool = cell.x >= center_x
		var is_bottom: bool = cell.y >= center_y
		var q := 0
		if is_right and not is_bottom:
			q = 1
		elif not is_right and is_bottom:
			q = 2
		elif is_right and is_bottom:
			q = 3
		quadrants[q].append(cell)

	return quadrants


func _bounding_rect(cells: Array) -> Dictionary:
	var first: Vector2i = cells[0]
	var min_x := first.x
	var max_x := first.x
	var min_y := first.y
	var max_y := first.y

	for cell in cells:
		min_x = mini(min_x, cell.x)
		max_x = maxi(max_x, cell.x)
		min_y = mini(min_y, cell.y)
		max_y = maxi(max_y, cell.y)

	return {
		"min": Vector2i(min_x, min_y),
		"size": Vector2i(max_x - min_x + 1, max_y - min_y + 1),
	}


func _shuffled(rng: RandomNumberGenerator, values: Array[String]) -> Array[String]:
	var remaining := values.duplicate()
	var ordered: Array[String] = []
	while not remaining.is_empty():
		var index := rng.randi_range(0, remaining.size() - 1)
		ordered.append(remaining[index])
		remaining.remove_at(index)
	return ordered


## Stage 56 output contract: a bare Vector2i means 1-layer ice, a
## {"cell": Vector2i, "layers": 2} Dictionary means double ice.
## Stage 57.2: rules.ice_variant now decides layer assignment deterministically
## (WEAK -> every cell 1-layer, STRONG -> every cell 2-layer); IceVariant.NONE
## keeps the original Stage 57/57.1 probability-based assignment, capped by
## rules.max_double_ice_cells, for any caller that doesn't resolve a variant.
func _assign_layers(rng: RandomNumberGenerator, cell_set: Dictionary, rules: IceGenerationRules) -> Array:
	match rules.ice_variant:
		ICE_VARIANT_SCRIPT.WEAK:
			return _assign_all_weak(cell_set)
		ICE_VARIANT_SCRIPT.STRONG:
			return _assign_all_strong(cell_set)
		_:
			return _assign_probabilistic_layers(rng, cell_set, rules)


## Stage 57.2: used by the deterministic fallback path, which has no rng of
## its own to roll — the variant alone decides the outcome (defaulting to
## weak for IceVariant.NONE, the safer of the two for an unresolved variant).
func _assign_fallback_layers(cell_set: Dictionary, rules: IceGenerationRules) -> Array:
	if rules.ice_variant == ICE_VARIANT_SCRIPT.STRONG:
		return _assign_all_strong(cell_set)
	return _assign_all_weak(cell_set)


func _assign_all_weak(cell_set: Dictionary) -> Array:
	var frozen_cells: Array = []
	for cell in cell_set.keys():
		frozen_cells.append(cell)
	return frozen_cells


func _assign_all_strong(cell_set: Dictionary) -> Array:
	var frozen_cells: Array = []
	for cell in cell_set.keys():
		frozen_cells.append({"cell": cell, "layers": 2})
	return frozen_cells


func _assign_probabilistic_layers(rng: RandomNumberGenerator, cell_set: Dictionary, rules: IceGenerationRules) -> Array:
	var frozen_cells: Array = []
	var double_budget: int = rules.max_double_ice_cells

	for cell in cell_set.keys():
		var make_double := false
		if double_budget > 0 and rules.double_ice_chance > 0.0 and rng.randf() < rules.double_ice_chance:
			make_double = true
			double_budget -= 1

		if make_double:
			frozen_cells.append({"cell": cell, "layers": 2})
		else:
			frozen_cells.append(cell)

	return frozen_cells


func _generate_pattern_cells(rng: RandomNumberGenerator, pattern_type: String, active_cells: Array[Vector2i], active_lookup: Dictionary, rules: IceGenerationRules, width: int, height: int) -> Array[Vector2i]:
	match pattern_type:
		ICE_GENERATION_RULES_SCRIPT.PATTERN_EDGE_PATCH:
			return _generate_edge_patch(rng, active_lookup, rules, width, height)
		ICE_GENERATION_RULES_SCRIPT.PATTERN_CENTER_PATCH:
			return _generate_center_patch(rng, active_lookup, rules, width, height)
		ICE_GENERATION_RULES_SCRIPT.PATTERN_DIAGONAL_BAND:
			return _generate_diagonal_band(rng, active_cells, active_lookup, rules, width, height)
		_:
			return _generate_small_cluster(rng, active_cells, active_lookup, rules)


## A short random-walk blob grown from a random active anchor cell, orthogonal
## step at a time. Stage 57.4: no longer used by the main generation path
## (which always prefers a clean mirrored rectangle) — kept only as a
## building block if a future rules object supplies allowed_pattern_types
## with no allowed_symmetric_shape_types at all.
func _generate_small_cluster(rng: RandomNumberGenerator, active_cells: Array[Vector2i], active_lookup: Dictionary, rules: IceGenerationRules) -> Array[Vector2i]:
	if active_cells.is_empty():
		return []

	var anchor: Vector2i = active_cells[rng.randi_range(0, active_cells.size() - 1)]
	var low := mini(rules.cluster_size_min, rules.cluster_size_max)
	var high := maxi(rules.cluster_size_min, rules.cluster_size_max)
	var target_size := rng.randi_range(low, high)

	var cluster: Array[Vector2i] = [anchor]
	var seen := {anchor: true}

	while cluster.size() < target_size:
		var base: Vector2i = cluster[rng.randi_range(0, cluster.size() - 1)]
		var candidates := _unclaimed_orthogonal_neighbors(base, active_lookup, seen)
		if candidates.is_empty():
			break

		var neighbor: Vector2i = candidates[rng.randi_range(0, candidates.size() - 1)]
		cluster.append(neighbor)
		seen[neighbor] = true

	return cluster


## A short strip hugging one of the four board edges.
func _generate_edge_patch(rng: RandomNumberGenerator, active_lookup: Dictionary, rules: IceGenerationRules, width: int, height: int) -> Array[Vector2i]:
	var low := mini(rules.cluster_size_min, rules.cluster_size_max)
	var high := maxi(rules.cluster_size_min, rules.cluster_size_max)
	var patch_size := rng.randi_range(low, high)
	var side := rng.randi_range(0, 3)
	var cells: Array[Vector2i] = []

	match side:
		0:
			var start_x := rng.randi_range(0, maxi(width - patch_size, 0))
			for i in range(patch_size):
				cells.append(Vector2i(start_x + i, 0))
		1:
			var start_x := rng.randi_range(0, maxi(width - patch_size, 0))
			for i in range(patch_size):
				cells.append(Vector2i(start_x + i, height - 1))
		2:
			var start_y := rng.randi_range(0, maxi(height - patch_size, 0))
			for i in range(patch_size):
				cells.append(Vector2i(0, start_y + i))
		_:
			var start_y := rng.randi_range(0, maxi(height - patch_size, 0))
			for i in range(patch_size):
				cells.append(Vector2i(width - 1, start_y + i))

	return cells.filter(func(cell: Vector2i) -> bool: return active_lookup.has(cell))


## A small patch grown outward from the board center (not restricted to
## avoiding the exact center cell the way holes are — ice never disconnects
## the board, so there is no equivalent center-safety concern).
func _generate_center_patch(rng: RandomNumberGenerator, active_lookup: Dictionary, rules: IceGenerationRules, width: int, height: int) -> Array[Vector2i]:
	@warning_ignore("integer_division")
	var center := Vector2i(width / 2, height / 2)
	var low := mini(rules.cluster_size_min, rules.cluster_size_max)
	var high := maxi(rules.cluster_size_min, rules.cluster_size_max)
	var patch_size := rng.randi_range(low, high)

	var offsets := [
		Vector2i.ZERO,
		Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1),
	]

	var cells: Array[Vector2i] = []
	for offset in offsets:
		if cells.size() >= patch_size:
			break
		var cell: Vector2i = center + offset
		if active_lookup.has(cell):
			cells.append(cell)

	return cells


## A short diagonal line of cells from a random active anchor.
func _generate_diagonal_band(rng: RandomNumberGenerator, active_cells: Array[Vector2i], active_lookup: Dictionary, rules: IceGenerationRules, width: int, height: int) -> Array[Vector2i]:
	if active_cells.is_empty():
		return []

	var low := mini(rules.cluster_size_min, rules.cluster_size_max)
	var high := maxi(rules.cluster_size_min, rules.cluster_size_max)
	var band_size := rng.randi_range(low, high)
	var direction := Vector2i(1, 1) if rng.randi_range(0, 1) == 0 else Vector2i(1, -1)
	var anchor: Vector2i = active_cells[rng.randi_range(0, active_cells.size() - 1)]

	var cells: Array[Vector2i] = []
	for i in range(band_size):
		var cell: Vector2i = anchor + direction * i
		if cell.x < 0 or cell.x >= width or cell.y < 0 or cell.y >= height:
			break
		if active_lookup.has(cell):
			cells.append(cell)

	return cells


func _unclaimed_orthogonal_neighbors(cell: Vector2i, active_lookup: Dictionary, seen: Dictionary) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for offset in ORTHOGONAL_OFFSETS:
		var neighbor: Vector2i = cell + offset
		if active_lookup.has(neighbor) and not seen.has(neighbor):
			neighbors.append(neighbor)
	return neighbors


## Validates a candidate: every cell must be inside the board and active, the
## output must be duplicate-free, the ice count must be within
## rules.min_ice_cells/effective_max_ice_cells, the weak/strong split must
## match rules.ice_variant exactly (a weak-variant candidate must have zero
## strong cells and vice versa), the board must not end up oversaturated
## with ice, and — Stage 57.4 — if effective_max_ice_cells exceeds the
## normal rules.max_ice_cells (i.e. the enlarged absolute rectangular cap is
## in play), the non-center cells must form one complete, 4-way-symmetric
## mirrored rectangle or the candidate is rejected.
func _validate(candidate: Dictionary, active_cells: Array[Vector2i], rules: IceGenerationRules, effective_max_ice_cells: int = -1, width: int = BoardModel.DEFAULT_WIDTH, height: int = BoardModel.DEFAULT_HEIGHT) -> Dictionary:
	var reasons: Array[String] = []
	var frozen_cells: Array = candidate.get("frozen_cells", [])
	var cell_set: Dictionary = candidate.get("cell_set", {})
	var center_cell_set: Dictionary = candidate.get("center_cell_set", {})
	var max_ice_cells: int = effective_max_ice_cells if effective_max_ice_cells > 0 else rules.max_ice_cells

	var active_lookup := {}
	for cell in active_cells:
		active_lookup[cell] = true

	var unique_check := {}
	var strong_count := 0
	var weak_count := 0
	for entry in frozen_cells:
		var cell: Vector2i = entry.get("cell") if entry is Dictionary else entry
		if unique_check.has(cell):
			reasons.append("duplicate_cells")
		unique_check[cell] = true

		if not active_lookup.has(cell):
			reasons.append("cell_not_active")

		var layers: int = int(entry.get("layers", 1)) if entry is Dictionary else 1
		if layers >= 2:
			strong_count += 1
		else:
			weak_count += 1

	var ice_count := cell_set.size()

	if ice_count < rules.min_ice_cells:
		reasons.append("below_min_ice_cells")
	if ice_count > max_ice_cells:
		reasons.append("above_max_ice_cells")

	if max_ice_cells > rules.max_ice_cells:
		var non_center_cell_set := {}
		for cell in cell_set.keys():
			if not center_cell_set.has(cell):
				non_center_cell_set[cell] = true
		var analysis := _analyze_quadrant_rectangles(non_center_cell_set, width, height)
		if not bool(analysis.get("complete", true)):
			reasons.append("not_rectangular_symmetric_for_absolute_cap")

	match rules.ice_variant:
		ICE_VARIANT_SCRIPT.WEAK:
			if strong_count > 0:
				reasons.append("weak_variant_has_strong_ice")
		ICE_VARIANT_SCRIPT.STRONG:
			if weak_count > 0:
				reasons.append("strong_variant_has_weak_ice")
		_:
			if strong_count > rules.max_double_ice_cells:
				reasons.append("above_max_double_ice_cells")

	if active_cells.size() > 0 and float(ice_count) / float(active_cells.size()) > MAX_SATURATION_RATIO:
		reasons.append("board_oversaturated")

	return {
		"valid": reasons.is_empty(),
		"reasons": reasons,
		"ice_count": ice_count,
		"weak_count": weak_count,
		"strong_count": strong_count,
	}


## Stats is a loosely-typed Dictionary of whatever fields the caller has on
## hand (see call sites in generate_frozen_cells()) — kept as a single
## Dictionary parameter rather than a long positional argument list since
## each stage has added several more metadata fields on top of the last.
func _build_metadata(stats: Dictionary) -> Dictionary:
	var selected_patterns: Array = stats.get("selected_patterns", [])
	var strong_count: int = int(stats.get("strong_count", 0))
	return {
		"generator_version": "0.1",
		"layout_source": stats.get("layout_source", "procedural_ice"),
		"ice_variant": stats.get("ice_variant", ICE_VARIANT_SCRIPT.NONE),
		"selected_ice_patterns": selected_patterns.duplicate(),
		"selected_ice_shape_types": selected_patterns.duplicate(),
		"target_ice_count": int(stats.get("target_ice_count", 0)),
		"ice_cell_count": int(stats.get("ice_count", 0)),
		"weak_ice_cell_count": int(stats.get("weak_count", 0)),
		"strong_ice_cell_count": strong_count,
		"double_ice_cell_count": strong_count,
		"ice_attempts_used": int(stats.get("attempts_used", 0)),
		"ice_fallback_used": bool(stats.get("fallback_used", false)),
		"fallback_symmetric_used": bool(stats.get("fallback_symmetric_used", false)),
		"ice_validation_reasons": (stats.get("reasons", []) as Array).duplicate(),
		"center_ice_roll": float(stats.get("center_ice_roll", 0.0)),
		"center_ice_used": bool(stats.get("center_ice_used", false)),
		"center_ice_cell_count": int(stats.get("center_ice_cell_count", 0)),
		"symmetric_ice_used": bool(stats.get("symmetric_ice_used", false)),
		"rectangular_completion_used": bool(stats.get("rectangular_completion_used", false)),
		"center_shape_removed_for_completion": bool(stats.get("center_shape_removed_for_completion", false)),
		"incomplete_rectangles_detected": bool(stats.get("incomplete_rectangles_detected", false)),
		"completed_rectangle_count": int(stats.get("completed_rectangle_count", 0)),
		"rectangle_shapes_used": (stats.get("rectangle_shapes_used", []) as Array).duplicate(),
		"absolute_rectangular_cap_used": bool(stats.get("absolute_rectangular_cap_used", false)),
		"final_ice_cell_count": int(stats.get("final_ice_cell_count", stats.get("ice_count", 0))),
	}


func _resolve_tier(difficulty_budget) -> String:
	if difficulty_budget != null and "difficulty_tier" in difficulty_budget:
		return difficulty_budget.difficulty_tier

	return DifficultyBudget.TIER_EARLY


func _mask_dimensions(board_mask: Array) -> Vector2i:
	if board_mask.is_empty():
		return Vector2i(BoardModel.DEFAULT_WIDTH, BoardModel.DEFAULT_HEIGHT)

	var height := board_mask.size()
	var width := 0
	if height > 0 and board_mask[0] is Array:
		width = (board_mask[0] as Array).size()

	if width <= 0:
		width = BoardModel.DEFAULT_WIDTH
	if height <= 0:
		height = BoardModel.DEFAULT_HEIGHT

	return Vector2i(width, height)


func _active_cells_from_mask(board_mask: Array, width: int, height: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(height):
		if y >= board_mask.size():
			continue
		var row: Array = board_mask[y]
		for x in range(width):
			if x >= row.size():
				continue
			if bool(row[x]):
				cells.append(Vector2i(x, y))
	return cells
