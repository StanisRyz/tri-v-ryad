extends PanelContainer
class_name ShopBoosterTile

## Icon-only booster purchase tile: square icon, quantity SpinBox, and a buy
## button whose text is the live total price. No title/description text by
## design (Stage 63.3 visual shop tiles).

signal buy_pressed(item_id: String, quantity: int)

const CURRENCY_TYPE_SCRIPT := preload("res://scripts/game/economy/currency_type.gd")

@onready var _icon_slot: FallbackImageSlot = %IconSlot
@onready var _quantity_spin: SpinBox = %QuantitySpin
@onready var _buy_button: Button = %BuyButton

var _item_id := ""
var _unit_price := 0
var _currency_id := ""


func _ready() -> void:
	if _quantity_spin != null:
		_quantity_spin.value_changed.connect(_on_quantity_changed)
	if _buy_button != null:
		_buy_button.pressed.connect(_on_buy_pressed)
	_update_price_label()


func set_item(item, icon: Texture2D) -> void:
	_item_id = item.item_id
	_unit_price = item.price_amount
	_currency_id = item.price_currency_id
	if _icon_slot != null:
		_icon_slot.texture = icon
	if _quantity_spin != null:
		_quantity_spin.value = 1
	_update_price_label()


func _current_quantity() -> int:
	if _quantity_spin == null:
		return 1
	return int(_quantity_spin.value)


func _on_quantity_changed(_value: float) -> void:
	_update_price_label()


func _update_price_label() -> void:
	if _buy_button == null:
		return
	var total_price := _unit_price * _current_quantity()
	var currency_label := "Gold" if _currency_id == CURRENCY_TYPE_SCRIPT.GOLD else "Gems"
	_buy_button.text = "%d %s" % [total_price, currency_label]


func _on_buy_pressed() -> void:
	buy_pressed.emit(_item_id, _current_quantity())
