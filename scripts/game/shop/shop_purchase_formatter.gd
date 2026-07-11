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


static func format_purchase_result(result: Dictionary, localization_manager = null) -> String:
	if bool(result.get("accepted", false)):
		return _localize(localization_manager, "ui.shop.feedback.purchased", MESSAGE_PURCHASED)

	match str(result.get("reason", "")):
		SHOP_PURCHASE_RESOLVER_SCRIPT.REASON_NOT_ENOUGH_GOLD:
			return _localize(localization_manager, "ui.shop.feedback.not_enough_gold", MESSAGE_NOT_ENOUGH_GOLD)
		SHOP_PURCHASE_RESOLVER_SCRIPT.REASON_NOT_ENOUGH_GEMS:
			return _localize(localization_manager, "ui.shop.feedback.not_enough_gems", MESSAGE_NOT_ENOUGH_GEMS)
		SHOP_PURCHASE_RESOLVER_SCRIPT.REASON_PAYMENT_NOT_CONNECTED:
			return _localize(localization_manager, "ui.shop.feedback.payment_not_connected", MESSAGE_PAYMENT_NOT_CONNECTED)
		SHOP_PURCHASE_RESOLVER_SCRIPT.REASON_AD_NOT_CONNECTED:
			return MESSAGE_AD_NOT_CONNECTED
		SHOP_PURCHASE_RESOLVER_SCRIPT.REASON_INVALID_ITEM:
			return _localize(localization_manager, "ui.shop.feedback.item_unavailable", MESSAGE_ITEM_UNAVAILABLE)
		_:
			return _localize(localization_manager, "ui.shop.feedback.purchase_failed", MESSAGE_PURCHASE_FAILED)


static func _localize(localization_manager, key: String, fallback_text: String) -> String:
	if localization_manager != null:
		return localization_manager.tr_key(key)
	return fallback_text
