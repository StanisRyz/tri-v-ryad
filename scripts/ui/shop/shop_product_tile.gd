extends PanelContainer
class_name ShopProductTile

## Icon-only product purchase tile (gems / bundles): square icon and a single
## buy button. No description text by design (Stage 63.3 visual shop tiles).
## Purchases for these items are always external_payment for now.

signal buy_pressed(item_id: String)

const GAME_ASSET_CATALOG_SCRIPT := preload("res://scripts/game/config/game_asset_catalog.gd")
const ASSET_KEY_RESOLVER_SCRIPT := preload("res://scripts/game/config/asset_key_resolver.gd")
const TEXT_STYLE_APPLIER_SCRIPT := preload("res://scripts/ui/text/text_style_applier.gd")

@onready var _icon_slot: FallbackImageSlot = %IconSlot
@onready var _buy_button: PressableTextureButton = %BuyButton
@onready var _price_label: Label = %PriceLabel

var _item_id := ""


func _ready() -> void:
	if _buy_button != null:
		_buy_button.delayed_pressed.connect(_on_buy_pressed)
	_bind_buy_button_textures()
	TEXT_STYLE_APPLIER_SCRIPT.apply_to_child_label(_buy_button, "TextMargin/Label", "shop.tile_product_button")
	TEXT_STYLE_APPLIER_SCRIPT.apply_to_label(_price_label, "shop.tile_product_price")


## Target height for the buy button; its width is derived from this and the
## source texture's own aspect ratio (see below), never the other way
## around, so a fixed compact height is guaranteed regardless of art size.
const BUY_BUTTON_HEIGHT := 60.0


## Reuses the shared back-button plaque art for the buy button. The button's
## own custom_minimum_size is recomputed from the real texture's aspect
## ratio (not hardcoded), so its size always matches the source art's
## proportions regardless of the texture's actual pixel dimensions — only
## the height is fixed (BUY_BUTTON_HEIGHT); width follows from that.
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
	if _icon_slot != null:
		_icon_slot.texture = icon
	if _buy_button != null:
		_buy_button.set_button_text(item.display_name)


## Stage 69.2: lets ShopScreen lock the buy button while a rewarded-ad
## attempt for this tile's item is in flight.
func set_buy_enabled(enabled: bool) -> void:
	if _buy_button != null:
		_buy_button.disabled = not enabled


## Stage 69.3: Yandex payment catalog price / loading / unavailable text for
## external-payment products. Hidden (rather than shown empty) whenever no
## text is set, so tiles that never call this (the rewarded-ad offer) look
## exactly as they did before this stage.
func set_price_text(text: String) -> void:
	if _price_label == null:
		return
	_price_label.text = text
	_price_label.visible = text != ""


func _on_buy_pressed() -> void:
	buy_pressed.emit(_item_id)
