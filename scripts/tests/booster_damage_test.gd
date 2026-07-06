extends SceneTree

const BOOSTER_CATALOG_SCRIPT := preload("res://scripts/game/config/booster_catalog.gd")
const BOOSTER_RESOLVER_SCRIPT := preload("res://scripts/game/battle/booster_resolver.gd")

var _failures := 0


func _initialize() -> void:
	print("Running booster damage tests...")

	var resolver = BOOSTER_RESOLVER_SCRIPT.new()
	var board := BoardModel.new()
	for cell in board.get_all_cells():
		board.set_tile(cell, TileType.BLUE)
	board.set_tile(Vector2i(4, 4), TileType.RED)
	board.set_tile(Vector2i(3, 4), TileType.RED)
	board.set_tile(Vector2i(5, 4), TileType.RED)

	var state := BattleState.new([], EnemyConfig.training_dummy().to_enemy_data(), EnemyConfig.training_dummy().to_enemy_intent(), 10)
	state.enemy.current_hp = 100
	state.enemy.max_hp = 100
	state.board = board
	state.get("booster_state").setup_from_catalog(BOOSTER_CATALOG_SCRIPT.new())
	var red_x3 := RoundModifierConfig.new("red_x3", "Red Surge", "Red crystals deal x3 damage", {TileType.RED: 3.0})
	var result = resolver.resolve_targeted_booster(state, "hammer", Vector2i(4, 4), red_x3)

	_expect_true(result.is_valid, "hammer with modifier resolves")
	_expect_equal(result.damage_to_enemy, 15, "red cells use x3 and other known colors use x1")
	_expect_equal(state.enemy.current_hp, 85, "booster damage is applied to enemy HP")

	var rocket_board := BoardModel.new()
	for cell in rocket_board.get_all_cells():
		rocket_board.set_tile(cell, TileType.GREEN)
	rocket_board.set_tile(Vector2i(0, 0), TileType.RED)
	rocket_board.set_tile(Vector2i(1, 0), TileType.RED)
	var rocket_state := BattleState.new([], EnemyConfig.training_dummy().to_enemy_data(), EnemyConfig.training_dummy().to_enemy_intent(), 10)
	rocket_state.enemy.current_hp = 100
	rocket_state.enemy.max_hp = 100
	rocket_state.board = rocket_board
	rocket_state.get("booster_state").setup_from_catalog(BOOSTER_CATALOG_SCRIPT.new())
	var rocket_result = resolver.resolve_targeted_booster(rocket_state, "rocket_barrage", Vector2i(0, 0), red_x3)
	_expect_true(rocket_result.is_valid, "rocket resolves")
	_expect_equal(rocket_result.cleared_cells.size(), 2, "rocket clears selected color")
	_expect_equal(rocket_result.damage_to_enemy, 6, "rocket applies selected color modifier")

	_finish()


func _finish() -> void:
	if _failures == 0:
		print("Booster damage tests passed.")
		quit(0)
	else:
		push_error("Booster damage tests failed: %d" % _failures)
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
