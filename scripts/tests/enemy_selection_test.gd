extends SceneTree

const ENEMY_CATALOG_SCRIPT := "res://scripts/game/config/enemy_catalog.gd"
const ENEMY_SELECTION_RESOLVER_SCRIPT := "res://scripts/game/config/enemy_selection_resolver.gd"
const LEVEL_CATALOG_SCRIPT := "res://scripts/game/config/level_catalog.gd"

var _failures := 0


class EmptyEnemyCatalog:
	func get_all_enemies() -> Array:
		return []


func _initialize() -> void:
	print("Running enemy selection tests...")

	var catalog = load(ENEMY_CATALOG_SCRIPT).new()
	var resolver = load(ENEMY_SELECTION_RESOLVER_SCRIPT).new()
	_test_selects_enemy_from_catalog(resolver, catalog)
	_test_seeded_rng_is_reproducible(resolver, catalog)
	_test_empty_catalog_falls_back(resolver)
	_test_level_fallback_when_catalog_empty(resolver)

	if _failures == 0:
		print("Enemy selection tests passed.")
		quit(0)
	else:
		push_error("Enemy selection tests failed: %d" % _failures)
		quit(1)


func _test_selects_enemy_from_catalog(resolver, catalog) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 24
	var selected = resolver.select_enemy(catalog, rng)
	_expect_true(selected != null, "resolver selects an enemy")
	_expect_true(catalog.has_enemy(selected.enemy_id), "selected enemy exists in catalog")
	print("ok - resolver selects from enemy catalog")


func _test_seeded_rng_is_reproducible(resolver, catalog) -> void:
	var first_rng := RandomNumberGenerator.new()
	var second_rng := RandomNumberGenerator.new()
	first_rng.seed = 12345
	second_rng.seed = 12345

	var first_selected = resolver.select_enemy(catalog, first_rng)
	var second_selected = resolver.select_enemy(catalog, second_rng)
	_expect_equal(first_selected.enemy_id, second_selected.enemy_id, "seeded selection is reproducible")
	print("ok - seeded enemy selection is reproducible")


func _test_empty_catalog_falls_back(resolver) -> void:
	var selected = resolver.select_enemy(EmptyEnemyCatalog.new(), RandomNumberGenerator.new())
	_expect_true(selected != null, "empty catalog returns fallback")
	_expect_equal(selected.enemy_id, "enemy_1", "empty catalog fallback is safe default")
	print("ok - empty catalog uses safe default")


func _test_level_fallback_when_catalog_empty(resolver) -> void:
	var level_config = load(LEVEL_CATALOG_SCRIPT).new().get_level("level_4")
	var selected = resolver.select_enemy_for_level(level_config, EmptyEnemyCatalog.new(), RandomNumberGenerator.new())
	_expect_true(selected != null, "empty catalog with level returns fallback")
	_expect_equal(selected.enemy_id, level_config.enemy_config.enemy_id, "level enemy remains compatibility fallback")
	print("ok - level enemy remains fallback when catalog is empty")


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
