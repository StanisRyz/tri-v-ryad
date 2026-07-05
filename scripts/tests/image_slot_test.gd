extends SceneTree

const IMAGE_SLOT_SCRIPT := preload("res://scripts/ui/image_slot.gd")

var _failures := 0


func _initialize() -> void:
	print("Running image slot tests...")
	_run()


func _run() -> void:
	await _test_image_slot_instantiates()
	await _test_empty_asset_key_shows_placeholder()
	await _test_unknown_asset_key_shows_placeholder()
	await _test_missing_known_asset_shows_placeholder()
	await _test_direct_texture_assignment()
	await _test_clear_texture_returns_to_placeholder()
	await _test_placeholder_color_updates()
	await _test_fallback_visibility_modes()

	if _failures == 0:
		print("Image slot tests passed.")
		quit(0)
	else:
		push_error("Image slot tests failed: %d" % _failures)
		quit(1)


func _test_image_slot_instantiates() -> void:
	var image_slot = IMAGE_SLOT_SCRIPT.new()
	root.add_child(image_slot)
	await process_frame
	_expect_true(image_slot != null, "ImageSlot can instantiate")
	_expect_false(image_slot.has_texture(), "new ImageSlot starts without texture")
	image_slot.queue_free()
	print("ok - ImageSlot instantiates")


func _test_empty_asset_key_shows_placeholder() -> void:
	var image_slot = IMAGE_SLOT_SCRIPT.new()
	image_slot.placeholder_color = Color(0.1, 0.2, 0.3, 1.0)
	root.add_child(image_slot)
	await process_frame
	image_slot.set_asset_key("")
	_expect_false(image_slot.has_texture(), "empty asset key has no texture")
	_expect_equal(image_slot.color, Color(0.1, 0.2, 0.3, 1.0), "empty asset key keeps placeholder visible")
	image_slot.queue_free()
	print("ok - empty asset key is safe")


func _test_unknown_asset_key_shows_placeholder() -> void:
	var image_slot = IMAGE_SLOT_SCRIPT.new()
	root.add_child(image_slot)
	await process_frame
	image_slot.set_asset_key("unknown_asset")
	_expect_false(image_slot.has_texture(), "unknown asset key has no texture")
	_expect_equal(image_slot.color, image_slot.placeholder_color, "unknown asset key keeps placeholder visible")
	image_slot.queue_free()
	print("ok - unknown asset key is safe")


func _test_missing_known_asset_shows_placeholder() -> void:
	var image_slot = IMAGE_SLOT_SCRIPT.new()
	root.add_child(image_slot)
	await process_frame
	image_slot.set_asset_key("background_1")
	_expect_false(image_slot.has_texture(), "missing known asset has no texture")
	_expect_equal(image_slot.color, image_slot.placeholder_color, "missing known asset keeps placeholder visible")
	image_slot.queue_free()
	print("ok - missing known asset is safe")


func _test_direct_texture_assignment() -> void:
	var image_slot = IMAGE_SLOT_SCRIPT.new()
	root.add_child(image_slot)
	await process_frame
	image_slot.set_texture(_make_test_texture())
	_expect_true(image_slot.has_texture(), "set_texture makes has_texture true")
	_expect_equal(image_slot.color.a, 0.0, "fallback is hidden when texture exists by default")
	image_slot.queue_free()
	print("ok - direct texture assignment works")


func _test_clear_texture_returns_to_placeholder() -> void:
	var image_slot = IMAGE_SLOT_SCRIPT.new()
	root.add_child(image_slot)
	await process_frame
	image_slot.set_texture(_make_test_texture())
	image_slot.clear_texture()
	_expect_false(image_slot.has_texture(), "clear_texture removes texture")
	_expect_equal(image_slot.color, image_slot.placeholder_color, "clear_texture restores placeholder color")
	image_slot.queue_free()
	print("ok - clear_texture restores placeholder")


func _test_placeholder_color_updates() -> void:
	var image_slot = IMAGE_SLOT_SCRIPT.new()
	root.add_child(image_slot)
	await process_frame
	var new_color := Color(0.7, 0.1, 0.2, 1.0)
	image_slot.set_placeholder_color(new_color)
	_expect_equal(image_slot.color, new_color, "set_placeholder_color updates visible placeholder")
	image_slot.queue_free()
	print("ok - placeholder color updates")


func _test_fallback_visibility_modes() -> void:
	var image_slot = IMAGE_SLOT_SCRIPT.new()
	root.add_child(image_slot)
	await process_frame
	image_slot.set_texture(_make_test_texture())
	image_slot.set_show_fallback_behind_texture(false)
	_expect_equal(image_slot.color.a, 0.0, "fallback hides behind texture when disabled")
	image_slot.set_show_fallback_behind_texture(true)
	_expect_equal(image_slot.color, image_slot.placeholder_color, "fallback remains visible behind texture when enabled")
	image_slot.queue_free()
	print("ok - fallback visibility modes work")


func _make_test_texture() -> Texture2D:
	var image := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 0.0, 0.0, 1.0))
	return ImageTexture.create_from_image(image)


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
