extends RefCounted
class_name IcePatternGenerator

## Stage 57 v0.1: generates real procedural frozen_cells for `ice` archetype
## levels — readable patterns (small_cluster/edge_patch/center_patch/
## diagonal_band), not random per-cell noise. Ice never disconnects or
## hides board area (unlike holes), so validation here only needs to check
## active-cell safety, duplicate-free output, count caps, and saturation —
## there is no connectivity/enclosed-pocket concern to worry about.
##
## Stage 57.1 v0.1: generation now prefers symmetric, shape-based placement
## over scattered patterns, closer to how BoardMaskGenerator generates holes.
## Each call first rolls rules.center_ice_chance; on success it tries a
## center-anchored shape (IceShapePreset center presets, self-symmetric about
## the exact board center) before anything else, so roughly every other ice
## battle includes center ice. If the roll fails, or the center shape can't
## find room / fails validation, generation falls back to symmetric mirrored
## blocks (IceShapePreset mirrored-block presets, one copy mirrored across a
## single random axis) topped up by the original scattered patterns if
## needed. The old scattered-pattern path is fully preserved as the ultimate
## fallback (and the only path for tiers with no symmetric/center shapes
## configured), so generation can never become stricter than Stage 57.

const ICE_GENERATION_RULES_SCRIPT := preload("res://scripts/game/config/ice_generation_rules.gd")
const ICE_SHAPE_PRESET_SCRIPT := preload("res://scripts/game/board/ice_shape_preset.gd")

const DEFAULT_VALIDATION_ATTEMPTS := 20
## Never freeze more than this fraction of the active board, regardless of
## what a (possibly hand-built) rules object's max_ice_cells allows.
const MAX_SATURATION_RATIO := 0.5
const ORTHOGONAL_OFFSETS: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0),
]


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
	var max_attempts := safe_rules.validation_attempts if safe_rules.validation_attempts > 0 else DEFAULT_VALIDATION_ATTEMPTS

	if active_cells.is_empty():
		return {
			"frozen_cells": [],
			"metadata": _build_metadata([], true, 0, 0, 0, ["no_active_cells"], 0.0, false, 0, false),
		}

	var active_lookup := {}
	for cell in active_cells:
		active_lookup[cell] = true

	var low := mini(safe_rules.min_ice_cells, safe_rules.max_ice_cells)
	var high := maxi(safe_rules.min_ice_cells, safe_rules.max_ice_cells)
	var target_count: int = clampi(safe_rng.randi_range(low, high), 0, active_cells.size())

	var center_ice_roll := safe_rng.randf()
	var last_reasons: Array[String] = []
	var attempts_used := 0

	## Stage 57.1: try center ice first when the roll succeeds. A single
	## attempt is enough here — _try_generate_center_candidate() already
	## tries every allowed center shape in a random order, and a fixed-offset
	## shape's validity does not change between attempts (unlike the
	## randomized scattered/symmetric paths below), so retrying wouldn't
	## change the outcome.
	if center_ice_roll < safe_rules.center_ice_chance:
		attempts_used += 1
		var center_candidate := _try_generate_center_candidate(safe_rng, active_lookup, safe_rules, width, height)
		if not center_candidate.is_empty():
			var center_validation := _validate(center_candidate, active_cells, safe_rules)
			last_reasons = center_validation.get("reasons", [])
			if bool(center_validation.get("valid", false)):
				return {
					"frozen_cells": center_candidate.get("frozen_cells", []),
					"metadata": _build_metadata(
						center_candidate.get("selected_patterns", []),
						false,
						attempts_used,
						int(center_validation.get("ice_count", 0)),
						int(center_validation.get("double_count", 0)),
						last_reasons,
						center_ice_roll,
						true,
						int(center_validation.get("ice_count", 0)),
						false
					),
				}
		## No allowed center shape fit/validated: fall back to symmetric/
		## scattered generation below, per the Stage 57.1 spec.

	for attempt in range(max_attempts):
		attempts_used += 1
		var candidate := _build_symmetric_candidate(safe_rng, active_cells, active_lookup, width, height, target_count, safe_rules)
		var validation := _validate(candidate, active_cells, safe_rules)
		last_reasons = validation.get("reasons", [])
		if bool(validation.get("valid", false)):
			return {
				"frozen_cells": candidate.get("frozen_cells", []),
				"metadata": _build_metadata(
					candidate.get("selected_patterns", []),
					false,
					attempts_used,
					int(validation.get("ice_count", 0)),
					int(validation.get("double_count", 0)),
					last_reasons,
					center_ice_roll,
					false,
					0,
					_candidate_used_symmetric_shape(candidate)
				),
			}

	return {
		"frozen_cells": [],
		"metadata": _build_metadata([], true, attempts_used, 0, 0, last_reasons, center_ice_roll, false, 0, false),
	}


## Tries every shape in rules.allowed_center_shape_types, in a random order
## (seeded from rng so results stay reproducible per generation seed), and
## returns the first one whose active-filtered cell count is non-empty and
## fits under both rules.max_ice_cells and rules.max_center_ice_cells.
## Returns {} if no allowed center shape could be placed at all.
func _try_generate_center_candidate(rng: RandomNumberGenerator, active_lookup: Dictionary, rules: IceGenerationRules, width: int, height: int) -> Dictionary:
	if rules.allowed_center_shape_types.is_empty():
		return {}

	var remaining: Array[String] = rules.allowed_center_shape_types.duplicate()
	var ordered_shapes: Array[String] = []
	while not remaining.is_empty():
		var index := rng.randi_range(0, remaining.size() - 1)
		ordered_shapes.append(remaining[index])
		remaining.remove_at(index)

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

		return {
			"frozen_cells": _assign_double_ice(rng, cell_set, rules),
			"selected_patterns": [shape_type],
			"cell_set": cell_set,
		}

	return {}


## Builds one candidate that prefers symmetric mirrored-block shapes
## (rules.allowed_symmetric_shape_types) when rules.prefer_symmetry is set and
## the pool isn't empty, falling back to the original scattered patterns
## (rules.allowed_pattern_types) otherwise — the same pool Stage 57 always
## used, so a tier with no symmetric shapes configured (today: early) behaves
## exactly as before.
func _build_symmetric_candidate(rng: RandomNumberGenerator, active_cells: Array[Vector2i], active_lookup: Dictionary, width: int, height: int, target_count: int, rules: IceGenerationRules) -> Dictionary:
	var symmetric_pool: Array[String] = rules.allowed_symmetric_shape_types
	var scatter_pool: Array[String] = rules.allowed_pattern_types if not rules.allowed_pattern_types.is_empty() else [ICE_GENERATION_RULES_SCRIPT.PATTERN_SMALL_CLUSTER]
	var use_symmetric_pool := rules.prefer_symmetry and not symmetric_pool.is_empty()

	var cell_set := {}
	var selected_patterns: Array[String] = []
	var placement_attempts := 0
	var max_placement_attempts := maxi(target_count, 1) * 6

	while cell_set.size() < target_count and placement_attempts < max_placement_attempts:
		placement_attempts += 1
		var pattern_label: String
		var pattern_cells: Array[Vector2i]

		if use_symmetric_pool:
			pattern_label = symmetric_pool[rng.randi_range(0, symmetric_pool.size() - 1)]
			pattern_cells = _generate_mirrored_block_cells(rng, pattern_label, active_lookup, width, height)
		else:
			pattern_label = scatter_pool[rng.randi_range(0, scatter_pool.size() - 1)]
			pattern_cells = _generate_pattern_cells(rng, pattern_label, active_cells, active_lookup, rules, width, height)

		if pattern_cells.is_empty():
			continue

		var added := false
		for cell in pattern_cells:
			if cell_set.size() >= rules.max_ice_cells or cell_set.size() >= target_count:
				break
			if cell_set.has(cell):
				continue
			cell_set[cell] = true
			added = true

		if added:
			selected_patterns.append(pattern_label)

	return {
		"frozen_cells": _assign_double_ice(rng, cell_set, rules),
		"selected_patterns": selected_patterns,
		"cell_set": cell_set,
	}


func _candidate_used_symmetric_shape(candidate: Dictionary) -> bool:
	var mirrored_types := ICE_SHAPE_PRESET_SCRIPT.get_mirrored_block_shape_types()
	for pattern in candidate.get("selected_patterns", []):
		if pattern in mirrored_types:
			return true
	return false


## Places one copy of a mirrored-block shape (2x2/2x3/3x2) anchored anywhere
## on the board, then mirrors it across a single random axis (horizontal:
## x -> width-1-x, or vertical: y -> height-1-y) rather than the full 4-way
## quadrant mirror BoardMaskSymmetry provides — a full quadrant mirror would
## produce up to 4x the block's cell count, which would blow past ice's much
## smaller per-tier caps (IceGenerationRules.for_tier()) compared to holes'
## larger hole budget. Filters to active cells only, so a mirrored copy that
## lands on an inactive cell (not possible yet since `ice` always uses a full
## active mask, but safe for a future combined archetype) is simply dropped.
func _generate_mirrored_block_cells(rng: RandomNumberGenerator, shape_type: String, active_lookup: Dictionary, width: int, height: int) -> Array[Vector2i]:
	var block_size := ICE_SHAPE_PRESET_SCRIPT.get_block_size(shape_type)
	var block_width: int = block_size.x
	var block_height: int = block_size.y

	var max_top_left_x := width - block_width
	var max_top_left_y := height - block_height
	if max_top_left_x < 0 or max_top_left_y < 0:
		return []

	var top_left := Vector2i(rng.randi_range(0, max_top_left_x), rng.randi_range(0, max_top_left_y))
	var mirror_horizontal := rng.randi_range(0, 1) == 0

	var cells: Array[Vector2i] = []
	var seen := {}
	for local_y in range(block_height):
		for local_x in range(block_width):
			var cell := Vector2i(top_left.x + local_x, top_left.y + local_y)
			if not seen.has(cell):
				seen[cell] = true
				cells.append(cell)

			var mirrored_cell: Vector2i = Vector2i(width - 1 - cell.x, cell.y) if mirror_horizontal else Vector2i(cell.x, height - 1 - cell.y)
			if not seen.has(mirrored_cell):
				seen[mirrored_cell] = true
				cells.append(mirrored_cell)

	return cells.filter(func(cell: Vector2i) -> bool: return active_lookup.has(cell))


## Stage 56 output contract: a bare Vector2i means 1-layer ice, a
## {"cell": Vector2i, "layers": 2} Dictionary means double ice. Never assigns
## more double-ice cells than rules.max_double_ice_cells.
func _assign_double_ice(rng: RandomNumberGenerator, cell_set: Dictionary, rules: IceGenerationRules) -> Array:
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
## step at a time — reads as one small readable "frozen patch" rather than
## scattered noise.
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
## output must be duplicate-free, ice/double-ice counts must respect the
## rules' caps, and the board must not end up oversaturated with ice
## regardless of what the rules object allows.
func _validate(candidate: Dictionary, active_cells: Array[Vector2i], rules: IceGenerationRules) -> Dictionary:
	var reasons: Array[String] = []
	var frozen_cells: Array = candidate.get("frozen_cells", [])
	var cell_set: Dictionary = candidate.get("cell_set", {})

	var active_lookup := {}
	for cell in active_cells:
		active_lookup[cell] = true

	var unique_check := {}
	var double_count := 0
	for entry in frozen_cells:
		var cell: Vector2i = entry.get("cell") if entry is Dictionary else entry
		if unique_check.has(cell):
			reasons.append("duplicate_cells")
		unique_check[cell] = true

		if not active_lookup.has(cell):
			reasons.append("cell_not_active")

		if entry is Dictionary:
			double_count += 1

	var ice_count := cell_set.size()

	if ice_count < rules.min_ice_cells:
		reasons.append("below_min_ice_cells")
	if ice_count > rules.max_ice_cells:
		reasons.append("above_max_ice_cells")
	if double_count > rules.max_double_ice_cells:
		reasons.append("above_max_double_ice_cells")
	if active_cells.size() > 0 and float(ice_count) / float(active_cells.size()) > MAX_SATURATION_RATIO:
		reasons.append("board_oversaturated")

	return {
		"valid": reasons.is_empty(),
		"reasons": reasons,
		"ice_count": ice_count,
		"double_count": double_count,
	}


func _build_metadata(selected_patterns: Array, fallback_used: bool, attempts_used: int, ice_count: int, double_count: int, reasons: Array, center_ice_roll: float, center_ice_used: bool, center_ice_cell_count: int, symmetric_ice_used: bool) -> Dictionary:
	return {
		"generator_version": "0.1",
		"layout_source": "fallback_no_ice" if fallback_used else ("procedural_ice_center" if center_ice_used else "procedural_ice"),
		"selected_ice_patterns": (selected_patterns as Array).duplicate(),
		"selected_ice_shape_types": (selected_patterns as Array).duplicate(),
		"ice_cell_count": ice_count,
		"double_ice_cell_count": double_count,
		"ice_attempts_used": attempts_used,
		"ice_fallback_used": fallback_used,
		"ice_validation_reasons": (reasons as Array).duplicate(),
		"center_ice_roll": center_ice_roll,
		"center_ice_used": center_ice_used,
		"center_ice_cell_count": center_ice_cell_count,
		"symmetric_ice_used": symmetric_ice_used,
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
