extends RefCounted
class_name ShopPurchaseFormatter

const SHOP_PURCHASE_RESOLVER_SCRIPT := preload("res://scripts/game/shop/shop_purchase_resolver.gd")

const MESSAGE_PURCHASED := "Purchased!"
const MESSAGE_NOT_ENOUGH_GOLD := "Not enough gold"
const MESSAGE_NOT_ENOUGH_GEMS := "Not enough gems"
const MESSAGE_PAYMENT_NOT_CONNECTED := "Payments are not connected yet"
const MESSAGE_AD_NOT_CONNECTED := "Ads are not connected yet"
const MESSAGE_ITEM_UNAVAILABLE := "Item unavailable"
const MESSAGE_PURCHASE_FAILED := "Purchase failed"


static func format_purchase_result(result: Dictionary) -> String:
	if bool(result.get("accepted", false)):
		return MESSAGE_PURCHASED

	match str(result.get("reason", "")):
		SHOP_PURCHASE_RESOLVER_SCRIPT.REASON_NOT_ENOUGH_GOLD:
			return MESSAGE_NOT_ENOUGH_GOLD
		SHOP_PURCHASE_RESOLVER_SCRIPT.REASON_NOT_ENOUGH_GEMS:
			return MESSAGE_NOT_ENOUGH_GEMS
		SHOP_PURCHASE_RESOLVER_SCRIPT.REASON_PAYMENT_NOT_CONNECTED:
			return MESSAGE_PAYMENT_NOT_CONNECTED
		SHOP_PURCHASE_RESOLVER_SCRIPT.REASON_AD_NOT_CONNECTED:
			return MESSAGE_AD_NOT_CONNECTED
		SHOP_PURCHASE_RESOLVER_SCRIPT.REASON_INVALID_ITEM:
			return MESSAGE_ITEM_UNAVAILABLE
		_:
			return MESSAGE_PURCHASE_FAILED
