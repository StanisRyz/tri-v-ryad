extends SceneTree

const ROUND_MODIFIER_CATALOG_SCRIPT := "res://scripts/game/config/round_modifier_catalog.gd"
const ROUND_MODIFIER_SELECTION_RESOLVER_SCRIPT := "res://scripts/game/config/round_modifier_selection_resolver.gd"

var _failures := 0


func _initialize() -> void:
	print("Running round modifier balance tests...")

	_test_all_x2_remains_valid_default()
	_test_random_pool_is_single_color_surges()
	_test_random_pool_excludes_all_x2()
	_test_seeded_selection_is_reproducible()
	_test_null_modifier_keeps_stage_32_behavior()
	_test_color_modifiers_still_multiply_damage()

	if _failures == 0:
		print("Round modifier balance tests passed.")
		quit(0)
	else:
		push_error("Round modifier balance tests failed: %d" % _failures)
		quit(1)


func _test_all_x2_remains_valid_default() -> void:
	var catalog = load(ROUND_MODIFIER_CATALOG_SCRIPT).new()
	var default_modifier = catalog.get_default_modifier()
	_expect_true(default_modifier != null, "all_x2 default modifier exists")
	_expect_equal(default_modifier.modifier_id, "all_x2", "default modifier is all_x2")
	_expect_true(catalog.is_valid_modifier(default_modifier), "all_x2 default modifier is valid")
	_expect_true(catalog.get_modifier("all_x2") != null, "all_x2 is still directly lookup-able")
	print("ok - all_x2 remains a valid default/fallback modifier")


func _test_random_pool_is_single_color_surges() -> void:
	var catalog = load(ROUND_MODIFIER_CATALOG_SCRIPT).new()
	var pool: Array = catalog.get_random_pool_modifiers()
	var expected_ids := ["red_x3", "blue_x3", "green_x3", "yellow_x3", "purple_x3"]

	_expect_equal(pool.size(), expected_ids.size(), "random pool has exactly the 5 single-color surges")
	var seen_ids := {}
	for modifier in pool:
		seen_ids[modifier.modifier_id] = true
		_expect_true(catalog.is_valid_modifier(modifier), "%s in random pool is valid" % modifier.modifier_id)
	for expected_id in expected_ids:
		_expect_true(seen_ids.has(expected_id), "random pool contains %s" % expected_id)
	print("ok - random pool is the 5 single-color x3 surges")


func _test_random_pool_excludes_all_x2() -> void:
	var catalog = load(ROUND_MODIFIER_CATALOG_SCRIPT).new()
	var pool: Array = catalog.get_random_pool_modifiers()
	for modifier in pool:
		_expect_true(modifier.modifier_id != "all_x2", "random pool excludes all_x2")
	print("ok - random pool excludes all_x2 so battles stay color-focused")


func _test_seeded_selection_is_reproducible() -> void:
	var catalog = load(ROUND_MODIFIER_CATALOG_SCRIPT).new()
	var resolver = load(ROUND_MODIFIER_SELECTION_RESOLVER_SCRIPT).new()

	var first_rng := RandomNumberGenerator.new()
	first_rng.seed = 321
	var second_rng := RandomNumberGenerator.new()
	second_rng.seed = 321

	var first_modifier = resolver.select_modifier(catalog, first_rng)
	var second_modifier = resolver.select_modifier(catalog, second_rng)
	_expect_equal(first_modifier.modifier_id, second_modifier.modifier_id, "seeded modifier selection is reproducible")
	print("ok - seeded modifier selection stays reproducible with the color-focused pool")


func _test_null_modifier_keeps_stage_32_behavior() -> void:
	var matches: Array[MatchResult] = [MatchResult.new([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], TileType.RED, MatchResult.Direction.HORIZONTAL)]
	var result: Dictionary = DirectMatchDamageResolver.new().calculate_damage_for_matches(matches, null)
	_expect_equal(result.get("total_damage"), 3, "null round modifier keeps 1 cleared crystal = 1 damage")
	print("ok - null round modifier preserves Stage 32 direct damage behavior")


func _test_color_modifiers_still_multiply_damage() -> void:
	var catalog = load(ROUND_MODIFIER_CATALOG_SCRIPT).new()
	var red_x3 = catalog.get_modifier("red_x3")
	var matches: Array[MatchResult] = [MatchResult.new([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], TileType.RED, MatchResult.Direction.HORIZONTAL)]
	var result: Dictionary = DirectMatchDamageResolver.new().calculate_damage_for_matches(matches, red_x3)
	_expect_equal(result.get("total_damage"), 9, "red_x3 still triples red match damage (Stage 33 behavior intact)")
	print("ok - Stage 33 color damage multipliers still work")


func _expect_true(value: bool, message: String) -> void:
	if value:
		return

	_failures += 1
	push_error("FAILED: %s" % message)


func _expect_equal(actual, expected, message: String) -> void:
	if actual == expected:
		return

	_failures += 1
	push_error("FAILED: %s | expected=%s actual=%s" % [message, expected, actual])
