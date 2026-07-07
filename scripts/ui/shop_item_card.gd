extends PanelContainer
class_name ShopItemCard

signal purchase_pressed(item_id: String)

const SHOP_ITEM_FORMATTER_SCRIPT := preload("res://scripts/game/shop/shop_item_formatter.gd")

@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var rewards_label: Label = %RewardsLabel
@onready var price_label: Label = %PriceLabel
@onready var buy_button: Button = %BuyButton

var _item_id := ""


func _ready() -> void:
	buy_button.pressed.connect(_on_buy_button_pressed)


func set_item(item) -> void:
	if item == null:
		return

	_item_id = item.item_id
	title_label.text = SHOP_ITEM_FORMATTER_SCRIPT.format_item_title(item)
	description_label.text = SHOP_ITEM_FORMATTER_SCRIPT.format_item_description(item)
	price_label.text = SHOP_ITEM_FORMATTER_SCRIPT.format_price(item)
	rewards_label.text = SHOP_ITEM_FORMATTER_SCRIPT.format_rewards(item)


func _on_buy_button_pressed() -> void:
	if _item_id == "":
		return
	purchase_pressed.emit(_item_id)
