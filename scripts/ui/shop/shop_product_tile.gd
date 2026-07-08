extends PanelContainer
class_name ShopProductTile

## Icon-only product purchase tile (gems / bundles): square icon and a single
## buy button. No description text by design (Stage 63.3 visual shop tiles).
## Purchases for these items are always external_payment for now.

signal buy_pressed(item_id: String)

@onready var _icon_slot: FallbackImageSlot = %IconSlot
@onready var _buy_button: Button = %BuyButton

var _item_id := ""


func _ready() -> void:
	if _buy_button != null:
		_buy_button.pressed.connect(_on_buy_pressed)


func set_item(item, icon: Texture2D) -> void:
	_item_id = item.item_id
	if _icon_slot != null:
		_icon_slot.texture = icon
	if _buy_button != null:
		_buy_button.text = item.display_name


func _on_buy_pressed() -> void:
	buy_pressed.emit(_item_id)
