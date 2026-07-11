extends RefCounted
class_name ShopPurchaseResolver

const SHOP_PURCHASE_KIND_SCRIPT := preload("res://scripts/game/shop/shop_purchase_kind.gd")
const SHOP_REWARD_TYPE_SCRIPT := preload("res://scripts/game/shop/shop_reward_type.gd")
const CURRENCY_TYPE_SCRIPT := preload("res://scripts/game/economy/currency_type.gd")

const REASON_NONE := ""
const REASON_INVALID_ITEM := "invalid_item"
const REASON_PAYMENT_NOT_CONNECTED := "payment_not_connected"
const REASON_AD_NOT_CONNECTED := "ad_not_connected"
const REASON_NOT_ENOUGH_GOLD := "not_enough_gold"
const REASON_NOT_ENOUGH_GEMS := "not_enough_gems"
const REASON_INVALID_PROGRESS := "invalid_progress"
const REASON_INVALID_PRICE := "invalid_price"
const REASON_INVALID_REWARD := "invalid_reward"


func purchase(item_id: String, progress_manager, shop_catalog, quantity: int = 1) -> Dictionary:
	var normalized_quantity: int = max(1, quantity)
	var result := {
		"accepted": false,
		"reason": REASON_INVALID_ITEM,
		"item_id": item_id,
		"quantity": normalized_quantity,
		"spent": [],
		"granted": [],
	}

	if shop_catalog == null or not shop_catalog.has_item(item_id):
		return result

	var item = shop_catalog.get_item(item_id)
	if item == null or not item.is_valid() or not item.is_available:
		return result

	if item.purchase_kind == SHOP_PURCHASE_KIND_SCRIPT.EXTERNAL_PAYMENT:
		result["reason"] = REASON_PAYMENT_NOT_CONNECTED
		return result

	if item.purchase_kind == SHOP_PURCHASE_KIND_SCRIPT.AD_WATCH:
		result["reason"] = REASON_AD_NOT_CONNECTED
		return result

	if item.purchase_kind == SHOP_PURCHASE_KIND_SCRIPT.CURRENCY:
		return _purchase_with_currency(item, progress_manager, result, normalized_quantity)

	return result


func _purchase_with_currency(item, progress_manager, result: Dictionary, quantity: int) -> Dictionary:
	if progress_manager == null:
		result["reason"] = REASON_INVALID_PROGRESS
		return result

	if not CURRENCY_TYPE_SCRIPT.is_valid(item.price_currency_id) or item.price_amount <= 0:
		result["reason"] = REASON_INVALID_PRICE
		return result

	for reward in item.rewards:
		if not SHOP_REWARD_TYPE_SCRIPT.is_valid(reward):
			result["reason"] = REASON_INVALID_REWARD
			return result

	var total_price: int = item.price_amount * quantity

	if not progress_manager.can_spend_currency(item.price_currency_id, total_price):
		if item.price_currency_id == CURRENCY_TYPE_SCRIPT.GOLD:
			result["reason"] = REASON_NOT_ENOUGH_GOLD
		else:
			result["reason"] = REASON_NOT_ENOUGH_GEMS
		return result

	if not progress_manager.spend_currency(item.price_currency_id, total_price):
		if item.price_currency_id == CURRENCY_TYPE_SCRIPT.GOLD:
			result["reason"] = REASON_NOT_ENOUGH_GOLD
		else:
			result["reason"] = REASON_NOT_ENOUGH_GEMS
		return result

	var spent: Array = [{"currency_id": item.price_currency_id, "amount": total_price}]
	var granted: Array = []

	for reward in item.rewards:
		match str(reward.get("type", "")):
			SHOP_REWARD_TYPE_SCRIPT.CURRENCY:
				var currency_id := str(reward.get("currency_id", ""))
				var amount := int(reward.get("amount", 0)) * quantity
				progress_manager.add_currency(currency_id, amount)
				granted.append({"type": SHOP_REWARD_TYPE_SCRIPT.CURRENCY, "currency_id": currency_id, "amount": amount})
			SHOP_REWARD_TYPE_SCRIPT.BOOSTER:
				var booster_id := str(reward.get("booster_id", ""))
				var booster_amount := int(reward.get("amount", 0)) * quantity
				progress_manager.add_booster(booster_id, booster_amount)
				granted.append({"type": SHOP_REWARD_TYPE_SCRIPT.BOOSTER, "booster_id": booster_id, "amount": booster_amount})

	result["accepted"] = true
	result["reason"] = REASON_NONE
	result["spent"] = spent
	result["granted"] = granted
	return result
