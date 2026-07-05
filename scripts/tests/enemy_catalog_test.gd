extends SceneTree

const ENEMY_CATALOG_SCRIPT := "res://scripts/game/config/enemy_catalog.gd"

const EXPECTED_ENEMY_IDS := [
	"training_dummy",
	"small_slime",
	"goblin_scout",
	"goblin_fighter",
	"armored_goblin",
	"wild_wolf",
	"bandit",
	"orc_brute",
	"cave_shaman",
	"gatekeeper",
]

var _failures := 0


func _initialize() -> void:
	print("Running enemy catalog tests...")

	var catalog = load(ENEMY_CATALOG_SCRIPT).new()
	_test_enemy_count(catalog)
	_test_enemy_ids(catalog)
	_test_enemy_configs_are_valid(catalog)
	_test_get_enemy(catalog)

	if _failures == 0:
		print("Enemy catalog tests passed.")
		quit(0)
	else:
		push_error("Enemy catalog tests failed: %d" % _failures)
		quit(1)


func _test_enemy_count(catalog) -> void:
	_expect_equal(catalog.get_all_enemies().size(), 10, "catalog contains exactly 10 enemies")
	print("ok - enemy catalog contains 10 enemies")


func _test_enemy_ids(catalog) -> void:
	var seen_ids := {}
	for enemy_config in catalog.get_all_enemies():
		_expect_true(enemy_config.enemy_id != "", "enemy id is not empty")
		_expect_false(seen_ids.has(enemy_config.enemy_id), "%s is unique" % enemy_config.enemy_id)
		seen_ids[enemy_config.enemy_id] = true

	for enemy_id in EXPECTED_ENEMY_IDS:
		_expect_true(catalog.has_enemy(enemy_id), "catalog has %s" % enemy_id)

	print("ok - enemy ids are unique and expected")


func _test_enemy_configs_are_valid(catalog) -> void:
	for enemy_config in catalog.get_all_enemies():
		_expect_true(catalog.is_valid_enemy(enemy_config), "%s is valid" % enemy_config.enemy_id)

	print("ok - all enemy configs are valid")


func _test_get_enemy(catalog) -> void:
	var slime = catalog.get_enemy("small_slime")
	_expect_true(slime != null, "get_enemy returns known enemy")
	if slime != null:
		_expect_equal(slime.display_name, "Small Slime", "known enemy keeps display name")
	_expect_equal(catalog.get_enemy("missing_enemy"), null, "unknown enemy returns null")
	_expect_equal(catalog.get_default_enemy().enemy_id, "training_dummy", "default enemy is training dummy")
	print("ok - get_enemy and default enemy are predictable")


func _expect_true(value: bool, message: String) -> void:
	if value:
		return

	_failures += 1
	push_error("FAILED: %s" % message)


func _expect_false(value: bool, message: String) -> void:
	_expect_true(not value, message)


func _expect_equal(actual, expected, message: String) -> void:
	if actual == expected:
		return

	_failures += 1
	push_error("FAILED: %s | expected=%s actual=%s" % [message, expected, actual])
