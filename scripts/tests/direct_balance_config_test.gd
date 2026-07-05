extends SceneTree

const DIRECT_BALANCE_CONFIG_SCRIPT := "res://scripts/game/config/direct_balance_config.gd"

var _failures := 0
var _config


func _initialize() -> void:
	print("Running direct balance config tests...")
	_config = load(DIRECT_BALANCE_CONFIG_SCRIPT)

	_test_get_level_number()
	_test_moves_valid_for_all_levels()
	_test_moves_do_not_jump_sharply()
	_test_enemy_hp_valid_for_all_levels()
	_test_enemy_hp_does_not_jump_sharply()
	_test_required_damage_per_move_is_positive()
	_test_required_damage_grows_softly_across_checkpoints()
	_test_early_levels_are_forgiving()
	_test_level_100_harder_but_not_absurd()
	_test_wall_levels_are_not_spikes()
	_test_checkpoint_levels()

	if _failures == 0:
		print("Direct balance config tests passed.")
		quit(0)
	else:
		push_error("Direct balance config tests failed: %d" % _failures)
		quit(1)


func _test_get_level_number() -> void:
	_expect_equal(_config.get_level_number("level_1"), 1, "level_1 resolves to level number 1")
	_expect_equal(_config.get_level_number("level_100"), 100, "level_100 resolves to level number 100")
	_expect_equal(_config.get_level_number("not_a_level"), 1, "malformed level id falls back to level 1")
	print("ok - get_level_number resolves valid and malformed ids")


func _test_moves_valid_for_all_levels() -> void:
	for level_number in range(1, 101):
		var moves: int = _config.get_moves_for_level(level_number)
		_expect_true(moves > 0, "level %d has positive moves" % level_number)
		_expect_true(moves >= 15 and moves <= 24, "level %d moves stay in a safe range" % level_number)
	print("ok - moves are valid for levels 1-100")


func _test_moves_do_not_jump_sharply() -> void:
	for level_number in range(2, 101):
		var previous: int = _config.get_moves_for_level(level_number - 1)
		var current: int = _config.get_moves_for_level(level_number)
		_expect_true(abs(current - previous) <= 2, "moves do not jump more than 2 between level %d and %d" % [level_number - 1, level_number])
	print("ok - moves change gently between neighboring levels")


func _test_enemy_hp_valid_for_all_levels() -> void:
	for level_number in range(1, 101):
		var hp: int = _config.get_enemy_hp_for_level(400, level_number)
		_expect_true(hp > 0, "level %d has positive enemy hp" % level_number)
	print("ok - enemy hp is valid for levels 1-100")


func _test_enemy_hp_does_not_jump_sharply() -> void:
	for level_number in range(2, 101):
		var previous: int = _config.get_enemy_hp_for_level(400, level_number - 1)
		var current: int = _config.get_enemy_hp_for_level(400, level_number)
		_expect_true(current >= previous, "enemy hp does not decrease from level %d to %d" % [level_number - 1, level_number])
		_expect_true(current - previous <= 5, "enemy hp does not spike more than 5 between level %d and %d" % [level_number - 1, level_number])
	print("ok - enemy hp changes gently between neighboring levels")


func _test_required_damage_per_move_is_positive() -> void:
	for level_number in range(1, 101):
		var moves: int = _config.get_moves_for_level(level_number)
		var hp: int = _config.get_enemy_hp_for_level(400, level_number)
		var required: float = _config.get_required_damage_per_move(hp, moves)
		_expect_true(required > 0.0, "level %d required damage per move is positive" % level_number)
	print("ok - required damage per move is positive across the campaign")


func _test_required_damage_grows_softly_across_checkpoints() -> void:
	var checkpoints: Array[int] = _config.get_balance_checkpoint_levels()
	var previous_required := -1.0
	for level_number in checkpoints:
		var moves: int = _config.get_moves_for_level(level_number)
		var hp: int = _config.get_enemy_hp_for_level(400, level_number)
		var required: float = _config.get_required_damage_per_move(hp, moves)
		_expect_true(required >= previous_required, "required damage per move does not shrink at checkpoint level %d" % level_number)
		previous_required = required
	print("ok - required damage per move grows softly across checkpoints")


func _test_early_levels_are_forgiving() -> void:
	var moves: int = _config.get_moves_for_level(1)
	var hp: int = _config.get_enemy_hp_for_level(400, 1)
	var required: float = _config.get_required_damage_per_move(hp, moves)
	var expected: float = _config.get_expected_damage_per_move(1)
	_expect_true(required < expected * 0.6, "level 1 required damage per move stays well below expected damage")
	print("ok - level 1 is forgiving relative to expected damage per move")


func _test_level_100_harder_but_not_absurd() -> void:
	var moves_1: int = _config.get_moves_for_level(1)
	var hp_1: int = _config.get_enemy_hp_for_level(400, 1)
	var required_1: float = _config.get_required_damage_per_move(hp_1, moves_1)

	var moves_100: int = _config.get_moves_for_level(100)
	var hp_100: int = _config.get_enemy_hp_for_level(400, 100)
	var required_100: float = _config.get_required_damage_per_move(hp_100, moves_100)
	var expected_100: float = _config.get_expected_damage_per_move(100)

	_expect_true(required_100 > required_1, "level 100 requires more damage per move than level 1")
	_expect_true(required_100 <= expected_100, "level 100 required damage per move stays at or below expected damage")
	print("ok - level 100 is harder than level 1 but stays plausible")


func _test_wall_levels_are_not_spikes() -> void:
	for wall_level in [10, 20, 30, 50, 100]:
		_expect_true(_config.is_wall_level(wall_level), "multiples of 10 are wall levels")
	_expect_true(not _config.is_wall_level(75), "level 75 is not a wall level")

	for level_number in [10, 20, 30, 50, 100]:
		var before: int = _config.get_enemy_hp_for_level(400, level_number - 1)
		var at_wall: int = _config.get_enemy_hp_for_level(400, level_number)
		var after: int = _config.get_enemy_hp_for_level(400, level_number + 1)
		_expect_true(at_wall - before <= 5, "wall level %d hp jump-in is mild" % level_number)
		_expect_true(after - at_wall <= 5, "wall level %d hp jump-out is mild" % level_number)
	print("ok - wall levels do not introduce harsh progression spikes")


func _test_checkpoint_levels() -> void:
	var checkpoints: Array[int] = _config.get_balance_checkpoint_levels()
	var expected: Array[int] = [1, 5, 10, 20, 30, 50, 75, 100]
	_expect_equal(checkpoints, expected, "balance checkpoint levels match the documented list")
	print("ok - balance checkpoint levels are the expected safety rails")


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
