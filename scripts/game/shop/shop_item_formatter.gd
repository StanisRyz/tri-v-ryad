extends RefCounted
class_name ShopItemFormatter

const SHOP_PURCHASE_KIND_SCRIPT := preload("res://scripts/game/shop/shop_purchase_kind.gd")
const SHOP_REWARD_TYPE_SCRIPT := preload("res://scripts/game/shop/shop_reward_type.gd")
const CURRENCY_TYPE_SCRIPT := preload("res://scripts/game/economy/currency_type.gd")
const BOOSTER_CATALOG_SCRIPT := preload("res://scripts/game/config/booster_catalog.gd")

const CURRENCY_DISPLAY_NAMES := {
	"gold": "Gold",
	"gems": "Gems",
}


static func format_item_title(item) -> String:
	if item == null:
		return ""
	return item.display_name


static func format_item_description(item) -> String:
	if item == null:
		return ""
	return item.description


static func format_price(item) -> String:
	if item == null:
		return ""
	if item.purchase_kind == SHOP_PURCHASE_KIND_SCRIPT.EXTERNAL_PAYMENT:
		return "Price: not available"
	return "Price: %d %s" % [item.price_amount, _currency_display_name(item.price_currency_id)]


static func format_rewards(item) -> String:
	if item == null:
		return ""

	var booster_catalog = BOOSTER_CATALOG_SCRIPT.new()
	var parts: Array[String] = []
	for reward in item.rewards:
		match str(reward.get("type", "")):
			SHOP_REWARD_TYPE_SCRIPT.CURRENCY:
				var currency_id := str(reward.get("currency_id", ""))
				var amount := int(reward.get("amount", 0))
				parts.append("%d %s" % [amount, _currency_display_name(currency_id)])
			SHOP_REWARD_TYPE_SCRIPT.BOOSTER:
				var booster_id := str(reward.get("booster_id", ""))
				var amount := int(reward.get("amount", 0))
				parts.append("+%d %s" % [amount, _booster_display_name(booster_id, booster_catalog)])

	return "Gives: %s" % ", ".join(parts)


static func _currency_display_name(currency_id: String) -> String:
	return str(CURRENCY_DISPLAY_NAMES.get(currency_id, currency_id.capitalize()))


static func _booster_display_name(booster_id: String, booster_catalog) -> String:
	var config = booster_catalog.get_booster(booster_id)
	if config != null:
		return config.display_name
	return booster_id.capitalize()
