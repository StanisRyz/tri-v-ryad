extends RefCounted
class_name ShopItemConfig

const SHOP_ITEM_CATEGORY_SCRIPT := preload("res://scripts/game/shop/shop_item_category.gd")
const SHOP_PURCHASE_KIND_SCRIPT := preload("res://scripts/game/shop/shop_purchase_kind.gd")
const SHOP_REWARD_TYPE_SCRIPT := preload("res://scripts/game/shop/shop_reward_type.gd")
const CURRENCY_TYPE_SCRIPT := preload("res://scripts/game/economy/currency_type.gd")

var item_id := ""
var category := ""
var display_name := ""
var description := ""
var purchase_kind := ""
var price_currency_id := ""
var price_amount := 0
var rewards: Array[Dictionary] = []
var is_available := true
var platform_product_ids: Dictionary = {}


func _init(
	config_item_id: String = "",
	config_category: String = "",
	config_display_name: String = "",
	config_description: String = "",
	config_purchase_kind: String = "",
	config_price_currency_id: String = "",
	config_price_amount: int = 0,
	config_rewards: Array[Dictionary] = [],
	config_is_available: bool = true,
	config_platform_product_ids: Dictionary = {}
) -> void:
	item_id = config_item_id
	category = config_category
	display_name = config_display_name
	description = config_description
	purchase_kind = config_purchase_kind
	price_currency_id = config_price_currency_id
	price_amount = config_price_amount
	rewards = config_rewards
	is_available = config_is_available
	platform_product_ids = config_platform_product_ids


## Stage 69.3: local item id -> platform product id mapping, e.g.
## {"yandex": "gems_50"}. Keeps ShopCatalog/ShopScreen from ever needing
## item_id and the platform's product id to be the same string.
func get_platform_product_id(platform_key: String) -> String:
	return str(platform_product_ids.get(platform_key, ""))


func has_platform_product_id(platform_key: String) -> bool:
	return get_platform_product_id(platform_key) != ""


func is_valid() -> bool:
	if item_id == "":
		return false
	if not SHOP_ITEM_CATEGORY_SCRIPT.is_valid(category):
		return false
	if display_name == "":
		return false
	if not SHOP_PURCHASE_KIND_SCRIPT.is_valid(purchase_kind):
		return false
	if rewards.is_empty():
		return false
	for reward in rewards:
		if not SHOP_REWARD_TYPE_SCRIPT.is_valid(reward):
			return false

	if purchase_kind == SHOP_PURCHASE_KIND_SCRIPT.CURRENCY:
		if not CURRENCY_TYPE_SCRIPT.is_valid(price_currency_id):
			return false
		if price_amount <= 0:
			return false

	return true
