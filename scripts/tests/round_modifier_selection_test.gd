extends SceneTree

const ROUND_MODIFIER_CATALOG_SCRIPT := "res://scripts/game/config/round_modifier_catalog.gd"
const ROUND_MODIFIER_SELECTION_RESOLVER_SCRIPT := "res://scripts/game/config/round_modifier_selection_resolver.gd"

var _failures := 0


func _initialize() -> void:
	print("Running round modifier selection tests...")

	_test_seeded_selection_is_reproducible()
	_test_null_catalog_falls_back_to_default()
	_test_empty_catalog_falls_back_to_default()
	_test_invalid_modifiers_are_skipped()
	_test_random_pool_excludes_all_x2()
	_test_fallback_catalog_without_pool_method_still_works()

	if _failures == 0:
		print("Round modifier selection tests passed.")
		quit(0)
	else:
		push_error("Round modifier selection tests failed: %d" % _failures)
		quit(1)


func _test_seeded_selection_is_reproducible() -> void:
	var catalog = load(ROUND_MODIFIER_CATALOG_SCRIPT).new()
	var resolver = load(ROUND_MODIFIER_SELECTION_RESOLVER_SCRIPT).new()

	var first_rng := RandomNumberGenerator.new()
	first_rng.seed = 777
	var second_rng := RandomNumberGenerator.new()
	second_rng.seed = 777

	var first_modifier = resolver.select_modifier(catalog, first_rng)
	var second_modifier = resolver.select_modifier(catalog, second_rng)

	_expect_equal(first_modifier.modifier_id, second_modifier.modifier_id, "seeded modifier selection is reproducible")
	print("ok - seeded modifier selection is reproducible")


func _test_null_catalog_falls_back_to_default() -> void:
	var resolver = load(ROUND_MODIFIER_SELECTION_RESOLVER_SCRIPT).new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1

	var modifier = resolver.select_modifier(null, rng)
	_expect_true(modifier != null, "null catalog falls back to a valid default modifier without crashing")
	print("ok - null catalog does not crash and falls back to default")


func _test_empty_catalog_falls_back_to_default() -> void:
	var resolver = load(ROUND_MODIFIER_SELECTION_RESOLVER_SCRIPT).new()
	var empty_catalog = RefCounted.new()

	var modifier = resolver.select_modifier(empty_catalog, null)
	_expect_true(modifier != null, "empty/invalid catalog falls back to a valid default modifier")
	print("ok - empty/invalid catalog falls back to default without crashing")


func _test_invalid_modifiers_are_skipped() -> void:
	var resolver = load(ROUND_MODIFIER_SELECTION_RESOLVER_SCRIPT).new()

	var fake_catalog := _FakeCatalogWithInvalidModifier.new()
	var modifier = resolver.select_modifier(fake_catalog, null)
	_expect_true(modifier != null, "catalog with only invalid modifiers falls back to default")
	print("ok - invalid modifiers are skipped in favor of a safe fallback")


func _test_random_pool_excludes_all_x2() -> void:
	var catalog = load(ROUND_MODIFIER_CATALOG_SCRIPT).new()
	var resolver = load(ROUND_MODIFIER_SELECTION_RESOLVER_SCRIPT).new()

	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	for attempt in range(50):
		var modifier = resolver.select_modifier(catalog, rng)
		_expect_true(modifier.modifier_id != "all_x2", "random pool selection never returns all_x2")
	print("ok - normal random selection excludes all_x2 in favor of single-color surges")


func _test_fallback_catalog_without_pool_method_still_works() -> void:
	var resolver = load(ROUND_MODIFIER_SELECTION_RESOLVER_SCRIPT).new()
	var fake_catalog := _FakeCatalogWithOnlyAllModifiers.new()

	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var modifier = resolver.select_modifier(fake_catalog, rng)
	_expect_true(modifier != null, "catalogs without get_random_pool_modifiers still select from get_all_modifiers")
	print("ok - fallback catalog without get_random_pool_modifiers still selects a valid modifier")


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


class _FakeCatalogWithInvalidModifier:
	extends RefCounted

	func get_all_modifiers() -> Array:
		return [load("res://scripts/game/config/round_modifier_config.gd").new("", "", "", {})]


class _FakeCatalogWithOnlyAllModifiers:
	extends RefCounted

	func get_all_modifiers() -> Array:
		return load("res://scripts/game/config/round_modifier_catalog.gd").new().get_all_modifiers()
