extends SceneTree

const LEVEL_CATALOG_SCRIPT := "res://scripts/game/config/level_catalog.gd"
const BATTLE_FACTORY_SCRIPT := "res://scripts/game/battle/battle_factory.gd"
const PLAYER_PROGRESS_SCRIPT := "res://scripts/game/progression/player_progress.gd"
const ECONOMY_CONFIG := preload("res://scripts/game/progression/upgrade_economy_config.gd")

var _failures := 0


func _initialize() -> void:
	print("Running battle factory progress tests...")

	var level_config = load(LEVEL_CATALOG_SCRIPT).new().get_level("level_1")
	var factory = load(BATTLE_FACTORY_SCRIPT).new()

	var base_state = factory.create_state(level_config)
	_expect_true(base_state != null, "factory without progress still works")
	_expect_equal(base_state.heroes[0].attack_level, 0, "base hero attack level is 0")
	_expect_equal(base_state.heroes[0].hp_level, 0, "base hero hp level is 0")

	var progress = load(PLAYER_PROGRESS_SCRIPT).create_default()
	progress.get_hero_upgrade("hero_1").attack_level = 3
	progress.get_hero_upgrade("hero_1").hp_level = 2
	var upgraded_state = factory.create_state(level_config, progress)
	var upgraded_hero = upgraded_state.heroes[0]

	_expect_equal(upgraded_hero.attack_level, 3, "factory applies attack level")
	_expect_equal(upgraded_hero.hp_level, 2, "factory applies hp level")
	_expect_equal(upgraded_hero.get_attack(), level_config.hero_configs[0].base_attack + 3 * ECONOMY_CONFIG.ATTACK_GROWTH_PER_LEVEL, "upgraded attack value is derived")
	_expect_equal(upgraded_hero.get_max_hp(), level_config.hero_configs[0].base_max_hp + 2 * ECONOMY_CONFIG.HP_GROWTH_PER_LEVEL, "upgraded max hp is derived")
	_expect_equal(upgraded_hero.current_hp, upgraded_hero.get_max_hp(), "upgraded current hp starts full")
	_expect_equal(level_config.hero_configs[0].base_attack, 10, "base HeroConfig attack is not mutated")
	_expect_equal(level_config.hero_configs[0].base_max_hp, 100, "base HeroConfig hp is not mutated")

	if _failures == 0:
		print("Battle factory progress tests passed.")
		quit(0)
	else:
		push_error("Battle factory progress tests failed: %d" % _failures)
		quit(1)


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
