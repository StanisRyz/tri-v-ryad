extends SceneTree

const BATTLE_BACKGROUND_CATALOG_SCRIPT := "res://scripts/game/config/battle_background_catalog.gd"
const BATTLE_BACKGROUND_SELECTION_RESOLVER_SCRIPT := "res://scripts/game/config/battle_background_selection_resolver.gd"

var _failures := 0


class EmptyBackgroundCatalog:
	func get_all_backgrounds() -> Array:
		return []


func _initialize() -> void:
	print("Running battle background selection tests...")

	var catalog = load(BATTLE_BACKGROUND_CATALOG_SCRIPT).new()
	var resolver = load(BATTLE_BACKGROUND_SELECTION_RESOLVER_SCRIPT).new()
	_test_selects_background_from_catalog(resolver, catalog)
	_test_seeded_rng_is_reproducible(resolver, catalog)
	_test_different_seeds_produce_valid_selections(resolver, catalog)
	_test_empty_catalog_falls_back(resolver)
	_test_resolver_does_not_mutate_catalog(resolver, catalog)

	if _failures == 0:
		print("Battle background selection tests passed.")
		quit(0)
	else:
		push_error("Battle background selection tests failed: %d" % _failures)
		quit(1)


func _test_selects_background_from_catalog(resolver, catalog) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 24
	var selected = resolver.select_background(catalog, rng)
	_expect_true(selected != null, "resolver selects a background")
	_expect_true(catalog.has_background(selected.background_id), "selected background exists in catalog")
	print("ok - resolver selects from background catalog")


func _test_seeded_rng_is_reproducible(resolver, catalog) -> void:
	var first_rng := RandomNumberGenerator.new()
	var second_rng := RandomNumberGenerator.new()
	first_rng.seed = 12345
	second_rng.seed = 12345

	var first_selected = resolver.select_background(catalog, first_rng)
	var second_selected = resolver.select_background(catalog, second_rng)
	_expect_equal(first_selected.background_id, second_selected.background_id, "seeded selection is reproducible")
	print("ok - seeded background selection is reproducible")


func _test_different_seeds_produce_valid_selections(resolver, catalog) -> void:
	for seed_value in [1, 2, 3, 4, 5, 6]:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var selected = resolver.select_background(catalog, rng)
		_expect_true(catalog.has_background(selected.background_id), "seed %d selects a valid background" % seed_value)

	print("ok - different seeds produce valid selections")


func _test_empty_catalog_falls_back(resolver) -> void:
	var selected = resolver.select_background(EmptyBackgroundCatalog.new(), RandomNumberGenerator.new())
	_expect_true(selected != null, "empty catalog returns fallback")
	_expect_equal(selected.background_id, "background_1", "empty catalog fallback is safe default")

	var invalid_selected = resolver.select_background(null, null)
	_expect_true(invalid_selected != null, "null catalog does not crash and returns fallback")
	print("ok - empty/invalid catalog fallback does not crash")


func _test_resolver_does_not_mutate_catalog(resolver, catalog) -> void:
	var before_count: int = catalog.get_all_backgrounds().size()
	var before_ids: Array = []
	for background_config in catalog.get_all_backgrounds():
		before_ids.append(background_config.background_id)

	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	resolver.select_background(catalog, rng)

	var after_count: int = catalog.get_all_backgrounds().size()
	var after_ids: Array = []
	for background_config in catalog.get_all_backgrounds():
		after_ids.append(background_config.background_id)

	_expect_equal(after_count, before_count, "resolver does not add/remove backgrounds")
	_expect_equal(after_ids, before_ids, "resolver does not reorder or mutate catalog ids")
	print("ok - resolver does not mutate catalog")


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
