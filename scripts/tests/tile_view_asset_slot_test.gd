extends SceneTree

const TILE_VIEW_SCENE := preload("res://scenes/game/TileView.tscn")
const GAME_ASSET_CATALOG := preload("res://scripts/game/config/game_asset_catalog.gd")

var _failures := 0


func _initialize() -> void:
	print("Running tile view asset slot test...")
	_run()


func _run() -> void:
	GAME_ASSET_CATALOG.clear_texture_cache()
	var tile_view := TILE_VIEW_SCENE.instantiate() as TileView
	root.add_child(tile_view)
	await process_frame

	tile_view.set_tile(Vector2i(1, 2), TileType.RED)
	await process_frame
	_expect_equal(tile_view.get_tile_asset_key(), "tile_red", "red tile resolves asset key")
	_expect_false(tile_view.has_tile_texture(), "missing tile texture keeps icon empty")
	_expect_equal(tile_view.text, "", "normal tile has no special marker")

	tile_view.set_special_tile(SpecialTileData.from_type(SpecialTileType.LINE_HORIZONTAL))
	await process_frame
	_expect_equal(tile_view.get_special_tile_asset_key(), "tile_special_horizontal", "horizontal special resolves asset key")
	_expect_equal(tile_view.text, "H", "horizontal special marker remains visible")

	tile_view.set_special_tile(SpecialTileData.from_type(SpecialTileType.LINE_VERTICAL))
	await process_frame
	_expect_equal(tile_view.get_special_tile_asset_key(), "tile_special_vertical", "vertical special resolves asset key")
	_expect_equal(tile_view.text, "V", "vertical special marker remains visible")

	tile_view.set_special_tile(SpecialTileData.from_type(SpecialTileType.COLOR_BOMB))
	await process_frame
	_expect_equal(tile_view.get_special_tile_asset_key(), "tile_color_bomb", "color bomb resolves asset key")
	_expect_equal(tile_view.text, "B", "color bomb marker remains visible")

	tile_view.set_tile(Vector2i.ZERO, BoardModel.EMPTY)
	await process_frame
	_expect_equal(tile_view.get_tile_asset_key(), "", "empty tile resolves safely")
	_expect_false(tile_view.has_tile_texture(), "empty tile has no texture")

	tile_view.queue_free()

	if _failures == 0:
		print("Tile view asset slot test passed.")
		quit(0)
	else:
		push_error("Tile view asset slot test failed: %d" % _failures)
		quit(1)


func _expect_false(value: bool, message: String) -> void:
	_expect_true(not value, message)


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
