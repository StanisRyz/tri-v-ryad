extends PanelContainer
class_name ShopBoosterTile

## Icon-only booster purchase tile: square icon and a single textured buy
## button (always quantity 1 — the standalone quantity control was removed).
## No title/description text by design (Stage 63.3 visual shop tiles).

signal buy_pressed(item_id: String, quantity: int)

const CURRENCY_TYPE_SCRIPT := preload("res://scripts/game/economy/currency_type.gd")
const GAME_ASSET_CATALOG_SCRIPT := preload("res://scripts/game/config/game_asset_catalog.gd")
const ASSET_KEY_RESOLVER_SCRIPT := preload("res://scripts/game/config/asset_key_resolver.gd")
const TEXT_STYLE_APPLIER_SCRIPT := preload("res://scripts/ui/text/text_style_applier.gd")

## Target height for the buy button; its width is derived from this and the
## source texture's own aspect ratio, never the other way around, so a fixed
## compact height is guaranteed regardless of art size.
const BUY_BUTTON_HEIGHT := 46.0

@onready var _icon_slot: FallbackImageSlot = %IconSlot
@onready var _buy_button: PressableTextureButton = %BuyButton

var _item_id := ""
var _unit_price := 0
var _currency_id := ""


func _ready() -> void:
	if _buy_button != null:
		_buy_button.delayed_pressed.connect(_on_buy_pressed)
	_bind_buy_button_textures()
	_update_price_label()
	TEXT_STYLE_APPLIER_SCRIPT.apply_to_child_label(_buy_button, "TextMargin/Label", "shop.tile_price_button")


## Reuses the shared back-button plaque art (same as `ShopProductTile`'s buy
## button and `ShopScreen`'s `BackButton`) — boosters share this art rather
## than having their own. The button's own custom_minimum_size is
## recomputed from the real texture's aspect ratio (not hardcoded), so its
## size always matches the source art's proportions regardless of the
## texture's actual pixel dimensions — only the height is fixed
## (BUY_BUTTON_HEIGHT); width follows from that.
func _bind_buy_button_textures() -> void:
	if _buy_button == null:
		return

	if _buy_button.normal_texture == null:
		var normal_texture := GAME_ASSET_CATALOG_SCRIPT.try_load_texture_cached(
			ASSET_KEY_RESOLVER_SCRIPT.get_ui_asset_key("shared_back_button_default")
		)
		if normal_texture != null:
			_buy_button.set_normal_texture(normal_texture)

	if _buy_button.pressed_texture == null:
		var pressed_texture := GAME_ASSET_CATALOG_SCRIPT.try_load_texture_cached(
			ASSET_KEY_RESOLVER_SCRIPT.get_ui_asset_key("shared_back_button_pressed")
		)
		if pressed_texture != null:
			_buy_button.set_pressed_texture(pressed_texture)

	if _buy_button.normal_texture != null:
		var texture_size := _buy_button.normal_texture.get_size()
		if texture_size.y > 0.0:
			_buy_button.custom_minimum_size = Vector2(
				BUY_BUTTON_HEIGHT * (texture_size.x / texture_size.y),
				BUY_BUTTON_HEIGHT
			)


func set_item(item, icon: Texture2D) -> void:
	_item_id = item.item_id
	_unit_price = item.price_amount
	_currency_id = item.price_currency_id
	if _icon_slot != null:
		_icon_slot.texture = icon
	_update_price_label()


func _update_price_label() -> void:
	if _buy_button == null:
		return
	var localization_manager := get_node_or_null("/root/LocalizationManager")
	var currency_key := "currency.gold" if _currency_id == CURRENCY_TYPE_SCRIPT.GOLD else "currency.gems"
	var currency_label: String = localization_manager.tr_key(currency_key) if localization_manager != null else ("Gold" if _currency_id == CURRENCY_TYPE_SCRIPT.GOLD else "Gems")
	_buy_button.set_button_text("%d %s" % [_unit_price, currency_label])


func _on_buy_pressed() -> void:
	buy_pressed.emit(_item_id, 1)
