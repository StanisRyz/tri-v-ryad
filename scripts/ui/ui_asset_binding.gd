extends RefCounted
class_name UiAssetBinding

const ASSET_KEY_RESOLVER_SCRIPT := preload("res://scripts/game/config/asset_key_resolver.gd")
const GAME_ASSET_CATALOG := preload("res://scripts/game/config/game_asset_catalog.gd")

const META_UI_ID := "ui_asset_id"
const META_ASSET_KEY := "asset_key"
const META_HAS_TEXTURE := "has_asset_texture"


static func bind_ui_asset(control: Object, ui_id: String) -> Texture2D:
	if control == null:
		return null

	var asset_key := ASSET_KEY_RESOLVER_SCRIPT.get_ui_asset_key(ui_id)
	return bind_asset_key(control, asset_key, ui_id)


static func bind_asset_key(control: Object, asset_key: String, ui_id: String = "") -> Texture2D:
	if control == null:
		return null

	var texture := GAME_ASSET_CATALOG.try_load_texture_cached(asset_key)
	control.set_meta(META_UI_ID, ui_id)
	control.set_meta(META_ASSET_KEY, asset_key)
	control.set_meta(META_HAS_TEXTURE, texture != null)
	if control is ImageSlot:
		(control as ImageSlot).set_asset_key(asset_key)
	return texture


static func get_bound_asset_key(control: Object) -> String:
	if control == null or not control.has_meta(META_ASSET_KEY):
		return ""

	return str(control.get_meta(META_ASSET_KEY))
