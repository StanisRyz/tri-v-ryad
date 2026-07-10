extends Control
class_name CrystalBurstEffect

## Stage 64.12/64.13/64.15 v0.1: lightweight, code-built, texture-aware
## crystal destruction burst — the destroyed crystal's own texture split into
## an NxN grid of pieces that first reassemble the whole crystal, then fly
## outward symmetrically: each piece's flight direction is derived directly
## from its own position in that grid relative to the crystal's center, so
## opposite pieces always fly in opposite directions — a real radial
## shatter, not fragments scattered at arbitrary angles. No separate flash/
## flat-color shape is drawn (Stage 64.15 removed it — it read as a plain
## white square rather than part of the crystal); only the flying texture
## pieces themselves. Entirely code-built (no scene children to instance) so
## it stays cheap to spawn many times per turn; call the static spawn()
## factory and the effect frees itself once its tweens finish. Complements
## (does not replace) the Stage 64.8 line blast effect: line blast shows the
## row/column sweep, this shows each individual crystal breaking apart.

const NORMAL_GRID_SIZE := 2
const SPECIAL_GRID_SIZE := 3
const REDUCED_MOTION_GRID_SIZE := 2
const NORMAL_DURATION := 0.22
const SPECIAL_DURATION := 0.30
## Stage 64.14 v0.1: tuned down from the Stage 64.13 values (0.42/0.62 spread,
## 0.8/0.95 crystal-visual ratio) — the burst's total outer bound (piece
## reassembly radius + travel distance + piece half-size, worst-case with
## random jitter) must stay within 100% of the cell size end to end, so the
## effect never visually spills past neighboring cells. See the worked
## radius math in Stage 64.14's README/AGENTS/design-doc entries.
const NORMAL_SPREAD_RATIO := 0.13
const SPECIAL_SPREAD_RATIO := 0.15
const NORMAL_CRYSTAL_VISUAL_RATIO := 0.5
const SPECIAL_CRYSTAL_VISUAL_RATIO := 0.5
const FALLBACK_FRAGMENT_COLOR := Color(0.82, 0.85, 0.92, 1.0)
const REDUCED_MOTION_SPREAD_FACTOR := 0.6
const REDUCED_MOTION_DURATION_FACTOR := 0.7

var _reduced_motion_enabled := false


## Builds and plays a burst, then frees itself once finished.
## `parent` must already be inside the scene tree (e.g. BoardView's
## AnimationLayer). `center` and `cell_size` are in `parent`'s local
## coordinate space — `cell_size` is the destroyed crystal's own cell/ghost
## size, so fragment/flash sizing and travel distance scale correctly with
## the current board size (portrait/landscape, any device). `crystal_texture`
## may be null — a small flat-color fragment fallback (arranged in the same
## symmetric grid) is used instead, so a missing texture never skips or
## breaks the effect. Does nothing if `animations_enabled` is false (matches
## every other board FX in this project skipping playback when disabled).
static func spawn(parent: Control, center: Vector2, cell_size: Vector2, crystal_texture: Texture2D, is_special: bool, animations_enabled: bool, reduced_motion_enabled: bool) -> void:
	if parent == null or not is_instance_valid(parent) or not animations_enabled:
		return
	if cell_size.x <= 0.0:
		return

	var effect := CrystalBurstEffect.new()
	effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect.size = Vector2.ZERO
	effect._reduced_motion_enabled = reduced_motion_enabled
	parent.add_child(effect)
	effect.position = center
	effect.move_to_front()
	effect._play(crystal_texture, is_special, cell_size)


func _play(crystal_texture: Texture2D, is_special: bool, cell_size: Vector2) -> void:
	var grid_size := SPECIAL_GRID_SIZE if is_special else NORMAL_GRID_SIZE
	var duration := SPECIAL_DURATION if is_special else NORMAL_DURATION
	var spread := cell_size.x * (SPECIAL_SPREAD_RATIO if is_special else NORMAL_SPREAD_RATIO)
	var crystal_visual_size := cell_size.x * (SPECIAL_CRYSTAL_VISUAL_RATIO if is_special else NORMAL_CRYSTAL_VISUAL_RATIO)

	if _reduced_motion_enabled:
		grid_size = REDUCED_MOTION_GRID_SIZE
		duration *= REDUCED_MOTION_DURATION_FACTOR
		spread *= REDUCED_MOTION_SPREAD_FACTOR

	_spawn_fragments(crystal_texture, grid_size, duration, spread, crystal_visual_size)

	var cleanup_tween := create_tween()
	cleanup_tween.tween_interval(duration)
	cleanup_tween.tween_callback(func() -> void:
		if is_instance_valid(self):
			queue_free()
	)


## Splits the crystal into a `grid_size x grid_size` grid of pieces. Each
## piece starts at the position it actually occupies within the assembled
## crystal texture (so the very first frame reads as "the whole crystal"),
## then flies outward along the direction from the crystal's center to that
## piece's own starting position — i.e. strictly symmetric: the piece at
## top-left always flies toward the top-left, its mirror at bottom-right
## always flies toward the bottom-right, and so on. The grid's true center
## piece (only possible on an odd grid_size, e.g. 3x3) has no defined radial
## direction, so it gets a small random direction instead of standing still.
func _spawn_fragments(crystal_texture: Texture2D, grid_size: int, duration: float, spread: float, crystal_visual_size: float) -> void:
	var piece_visual_size := crystal_visual_size / float(grid_size)
	var fade_delay := duration * 0.4

	for row in range(grid_size):
		for col in range(grid_size):
			var grid_offset := Vector2(
				float(col) - (float(grid_size) - 1.0) * 0.5,
				float(row) - (float(grid_size) - 1.0) * 0.5
			)
			var start_center := grid_offset * piece_visual_size
			var direction: Vector2 = start_center.normalized() if start_center.length() > 0.001 else Vector2.RIGHT.rotated(randf_range(0.0, TAU))
			var travel_distance := spread * randf_range(0.88, 1.12)
			var piece_size := Vector2.ONE * piece_visual_size * randf_range(0.94, 1.05)

			var fragment: Control = _build_fragment_visual(crystal_texture, col, row, grid_size)
			fragment.mouse_filter = Control.MOUSE_FILTER_IGNORE
			fragment.size = piece_size
			fragment.pivot_offset = piece_size * 0.5
			fragment.position = start_center - piece_size * 0.5
			add_child(fragment)

			var target_position := fragment.position + direction * travel_distance
			var target_rotation := randf_range(-1.1, 1.1)
			var target_scale := Vector2.ONE * randf_range(0.2, 0.4)

			# Stage 64.14 v0.1: scale now shrinks with the same EASE_OUT curve
			# as position (both fast-at-first) instead of EASE_IN (slow-at-
			# first) — previously position raced out to ~75% of its travel
			# distance while scale had barely started shrinking, so pieces
			# briefly looked large and far from center at once ("bulky").
			# Shrinking in lockstep with the outward motion keeps the whole
			# burst's visual footprint contained near the piece's actual
			# (small) target size for almost its whole flight.
			var tween := create_tween()
			tween.set_parallel(true)
			tween.tween_property(fragment, "position", target_position, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(fragment, "rotation", target_rotation, duration)
			tween.tween_property(fragment, "scale", target_scale, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(fragment, "modulate:a", 0.0, maxf(duration - fade_delay, 0.01)).set_delay(fade_delay)


## A texture-driven piece shows its own exact region of the destroyed
## crystal's texture (cheap `AtlasTexture` region, no image slicing/
## processing needed) so the burst visually reads as the real crystal
## breaking into pieces, not generic confetti. A texture-less fallback is a
## small flat-color square arranged in the same symmetric grid instead, so a
## missing texture never breaks the effect (task requirement: safe fallback,
## no crash) and the shatter still looks intentional.
func _build_fragment_visual(crystal_texture: Texture2D, col: int, row: int, grid_size: int) -> Control:
	if crystal_texture == null:
		var color_rect := ColorRect.new()
		color_rect.color = FALLBACK_FRAGMENT_COLOR
		return color_rect

	var texture_rect := TextureRect.new()
	texture_rect.texture = _build_fragment_texture(crystal_texture, col, row, grid_size)
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	# Without EXPAND_IGNORE_SIZE, TextureRect's default EXPAND_KEEP_SIZE
	# forces its minimum (and effective rendered) size back up to the
	# assigned texture's own natural pixel size on the next layout pass,
	# silently overriding the small `.size` set by the caller — this was
	# why fragments rendered far larger than every size ratio implied.
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	return texture_rect


func _build_fragment_texture(source: Texture2D, col: int, row: int, grid_size: int) -> Texture2D:
	var full_size := source.get_size()
	if full_size.x <= 0.0 or full_size.y <= 0.0:
		return source

	var piece_size := full_size / float(grid_size)
	var origin := Vector2(piece_size.x * float(col), piece_size.y * float(row))

	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = Rect2(origin, piece_size)
	return atlas
