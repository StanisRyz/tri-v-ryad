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
## is only a *seed* now — generation always keeps adding symmetric (and, if
## needed, scattered) cells until the target count is reached, instead of
## returning immediately with just the center shape's 5-13 cells. Non-center
## symmetric placement uses true 4-way quadrant mirroring (reusing
## BoardMaskSymmetry, matching (x,y)/(8-x,y)/(x,8-y)/(8-x,8-y) on a 9x9
## board) instead of Stage 57.1's single-axis 2-copy mirror, since reaching
## 32-40 cells needs the larger 4-copy footprint. Every generated cell's
## layer count is now decided by rules.ice_variant (IceVariant.WEAK forces
## every cell to 1 layer, STRONG forces every cell to 2 layers) rather than
## a random per-cell chance; IceVariant.NONE keeps the old probabilistic
## behavior for any caller that doesn't resolve a variant. If random
## generation can't produce a valid candidate within the attempt budget, a
## deterministic (non-random) fallback layout guarantees at least
## MIN_ICE_CELLS of ice rather than ever returning an empty frozen_cells
## array for an ice level.

const ICE_GENERATION_RULES_SCRIPT := preload("res://scripts/game/config/ice_generation_rules.gd")
const ICE_SHAPE_PRESET_SCRIPT := preload("res://scripts/game/board/ice_shape_preset.gd")
const ICE_VARIANT_SCRIPT := preload("res://scripts/game/config/ice_variant.gd")
const BOARD_MASK_SYMMETRY_SCRIPT := preload("res://scripts/game/board/board_mask_symmetry.gd")

const DEFAULT_VALIDATION_ATTEMPTS := 20
## Never freeze more than this fraction of the active board, regardless of
## what a (possibly hand-built) rules object's max_ice_cells allows. 40/81
## (today's max_ice_cells on a full 9x9 board) stays safely under this.
const MAX_SATURATION_RATIO := 0.5
const ORTHOGONAL_OFFSETS: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0),
]
## Stage 57.2 v0.1: deterministic fallback anchors for two non-overlapping
## 2x2 blocks inside the upper-left quadrant of a 9x9 board (quadrant
## columns/rows 0-3). Quadrant-mirrored, each anchor contributes 16 cells;
## together (16 cells apart on the y-axis, so no overlap) they total exactly
## MIN_ICE_CELLS (32) cells on a full active board — no randomness involved,
## so this can never fail to produce ice the way a randomized candidate can.
const FALLBACK_BLOCK_ANCHORS: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 2)]


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

	## Stage 57.2: the center shape (if any) only ever seeds the candidate —
	## every attempt still tops it up with symmetric/scattered cells until
	## target_count is reached, then validates the *full* candidate.
	for attempt in range(max_attempts):
		attempts_used += 1
		var seed_patterns: Array[String] = []
		if center_ice_used:
			seed_patterns.append(center_shape_type)
		var candidate := _build_symmetric_candidate(safe_rng, active_cells, active_lookup, width, height, target_count, safe_rules, center_seed, seed_patterns)
		var validation := _validate(candidate, active_cells, safe_rules)
		last_reasons = validation.get("reasons", [])
		if bool(validation.get("valid", false)):
			return {
				"frozen_cells": candidate.get("frozen_cells", []),
				"metadata": _build_metadata({
					"layout_source": "procedural_ice_center" if center_ice_used else "procedural_ice",
					"ice_variant": safe_rules.ice_variant,
					"selected_patterns": candidate.get("selected_patterns", []),
					"target_ice_count": target_count,
					"ice_count": validation.get("ice_count", 0),
					"weak_count": validation.get("weak_count", 0),
					"strong_count": validation.get("strong_count", 0),
					"attempts_used": attempts_used,
					"fallback_used": false,
					"reasons": last_reasons,
					"center_ice_roll": center_ice_roll,
					"center_ice_used": center_ice_used,
					"center_ice_cell_count": center_seed.size(),
					"symmetric_ice_used": _candidate_used_symmetric_shape(candidate),
				}),
			}

	## Stage 57.2: random generation exhausted its attempt budget without a
	## valid candidate — fall back to a deterministic, guaranteed-safe
	## symmetric layout so an ice level never ends up with empty
	## frozen_cells, honoring the resolved weak/strong variant.
	var fallback_cell_set := _build_deterministic_fallback_cell_set(active_lookup, width, height)
	var fallback_candidate := {
		"frozen_cells": _assign_fallback_layers(fallback_cell_set, safe_rules),
		"selected_patterns": ["deterministic_fallback"],
		"cell_set": fallback_cell_set,
	}
	var fallback_validation := _validate(fallback_candidate, active_cells, safe_rules)

	return {
		"frozen_cells": fallback_candidate.get("frozen_cells", []),
		"metadata": _build_metadata({
			"layout_source": "fallback_symmetric_ice",
			"ice_variant": safe_rules.ice_variant,
			"selected_patterns": fallback_candidate.get("selected_patterns", []),
			"target_ice_count": target_count,
			"ice_count": fallback_validation.get("ice_count", 0),
			"weak_count": fallback_validation.get("weak_count", 0),
			"strong_count": fallback_validation.get("strong_count", 0),
			"attempts_used": attempts_used,
			"fallback_used": true,
			"fallback_symmetric_used": true,
			"reasons": last_reasons,
			"center_ice_roll": center_ice_roll,
			"center_ice_used": center_ice_used,
			"center_ice_cell_count": center_seed.size(),
			"symmetric_ice_used": false,
		}),
	}


## Tries every shape in rules.allowed_center_shape_types, in a random order
## (seeded from rng so results stay reproducible per generation seed), and
## returns the first one whose active-filtered cell count is non-empty and
## fits under both rules.max_ice_cells and rules.max_center_ice_cells.
## Returns {} if no allowed center shape could be placed at all. The result
## is only ever used as a seed for _build_symmetric_candidate() — it is not
## a complete candidate by itself (Stage 57.2).
func _pick_center_shape_cells(rng: RandomNumberGenerator, active_lookup: Dictionary, rules: IceGenerationRules, width: int, height: int) -> Dictionary:
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

		return {"cell_set": cell_set, "shape_type": shape_type}

	return {}


## Builds one candidate seeded from seed_cell_set/seed_selected_patterns (a
## center shape's cells, or empty if no center shape was used) and keeps
## adding cells — preferring symmetric mirrored-block shapes
## (rules.allowed_symmetric_shape_types) when rules.prefer_symmetry is set
## and the pool isn't empty, falling back to the original scattered patterns
## (rules.allowed_pattern_types) otherwise — until target_count is reached or
## a placement-attempt budget runs out.
func _build_symmetric_candidate(rng: RandomNumberGenerator, active_cells: Array[Vector2i], active_lookup: Dictionary, width: int, height: int, target_count: int, rules: IceGenerationRules, seed_cell_set: Dictionary = {}, seed_selected_patterns: Array[String] = []) -> Dictionary:
	var symmetric_pool: Array[String] = rules.allowed_symmetric_shape_types
	var scatter_pool: Array[String] = rules.allowed_pattern_types.duplicate()
	if scatter_pool.is_empty():
		scatter_pool.append(ICE_GENERATION_RULES_SCRIPT.PATTERN_SMALL_CLUSTER)
	var use_symmetric_pool := rules.prefer_symmetry and not symmetric_pool.is_empty()

	var cell_set: Dictionary = seed_cell_set.duplicate()
	var selected_patterns: Array[String] = seed_selected_patterns.duplicate()
	var placement_attempts := 0
	var max_placement_attempts := maxi(target_count, 1) * 8

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
		"frozen_cells": _assign_layers(rng, cell_set, rules),
		"selected_patterns": selected_patterns,
		"cell_set": cell_set,
	}


func _candidate_used_symmetric_shape(candidate: Dictionary) -> bool:
	var mirrored_types := ICE_SHAPE_PRESET_SCRIPT.get_mirrored_block_shape_types()
	for pattern in candidate.get("selected_patterns", []):
		if pattern in mirrored_types:
			return true
	return false


## Places one copy of a mirrored-block shape (2x2/2x3/3x2) anchored inside
## the board's upper-left quadrant, then mirrors it across all four
## quadrants via BoardMaskSymmetry.get_mirrored_block_cells() — on a 9x9
## board this is exactly (x,y)/(8-x,y)/(x,8-y)/(8-x,8-y), matching how
## BoardMaskGenerator places hole blocks. Stage 57.1 used a single-axis
## (2-copy) mirror instead, which couldn't reach Stage 57.2's much larger
## 32-40 cell target; anchoring strictly inside the quadrant (never past the
## center row/column) keeps the four mirrored copies non-overlapping, so a
## 2x2 block contributes 16 cells and a 2x3/3x2 block contributes 24 —
## reaching the target range in only 1-2 placements, roughly evenly spread
## across all four quadrants. Filters to active cells only, so a mirrored
## copy landing on an inactive cell (not possible yet since `ice` always
## uses a full active mask, but safe for a future combined archetype) is
## simply dropped.
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


## Stage 57.2: deterministic (non-random) fallback layout. Two fixed,
## non-overlapping 2x2 block anchors, each quadrant-mirrored, together
## always total exactly MIN_ICE_CELLS (32) cells on a full active 9x9 board —
## guaranteed regardless of rng state, so this can never fail the way a
## randomized candidate can.
func _build_deterministic_fallback_cell_set(active_lookup: Dictionary, width: int, height: int) -> Dictionary:
	var cell_set := {}
	for anchor in FALLBACK_BLOCK_ANCHORS:
		var mirrored := BOARD_MASK_SYMMETRY_SCRIPT.get_mirrored_block_cells(anchor, 2, 2, width, height)
		for cell in mirrored:
			if active_lookup.has(cell):
				cell_set[cell] = true
	return cell_set


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
## output must be duplicate-free, the ice count must be within
## rules.min_ice_cells/max_ice_cells, the weak/strong split must match
## rules.ice_variant exactly (Stage 57.2: a weak-variant candidate must have
## zero strong cells and vice versa), and the board must not end up
## oversaturated with ice regardless of what the rules object allows.
func _validate(candidate: Dictionary, active_cells: Array[Vector2i], rules: IceGenerationRules) -> Dictionary:
	var reasons: Array[String] = []
	var frozen_cells: Array = candidate.get("frozen_cells", [])
	var cell_set: Dictionary = candidate.get("cell_set", {})

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
	if ice_count > rules.max_ice_cells:
		reasons.append("above_max_ice_cells")

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
## Stage 57.2 added several more metadata fields on top of Stage 57/57.1's.
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
