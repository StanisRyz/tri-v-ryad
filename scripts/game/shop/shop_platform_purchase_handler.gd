extends RefCounted
class_name ShopPlatformPurchaseHandler

## Stage 69.3: grants a local shop item's rewards for a completed Yandex
## purchase and marks its token processed, so the same purchase can never
## grant twice whether it arrived from a live payment_purchase_success or a
## later check_unprocessed_purchases() restore. Deliberately independent of
## ShopScreen/App UI — both call the same grant_purchase() here.

const SHOP_REWARD_TYPE_SCRIPT := preload("res://scripts/game/shop/shop_reward_type.gd")

var _shop_catalog
var _progress_manager


func _init(shop_catalog = null, progress_manager = null) -> void:
	_shop_catalog = shop_catalog
	_progress_manager = progress_manager


func set_shop_catalog(shop_catalog) -> void:
	_shop_catalog = shop_catalog


func set_progress_manager(progress_manager) -> void:
	_progress_manager = progress_manager


## Applies item_id's reward list and marks purchase_token processed. Returns
## false (granting nothing) if the token is empty/already processed, the
## item/catalog/progress manager is missing, or the item has no rewards to
## grant — callers must not call Platform.consume_purchase() unless this
## returns true.
func grant_purchase(item_id: String, purchase_token: String) -> bool:
	if _progress_manager == null or _shop_catalog == null:
		return false
	if purchase_token == "" or _progress_manager.has_processed_purchase_token(purchase_token):
		return false

	var item = _shop_catalog.get_item(item_id)
	if item == null or item.rewards.is_empty():
		return false

	for reward in item.rewards:
		match str(reward.get("type", "")):
			SHOP_REWARD_TYPE_SCRIPT.CURRENCY:
				var currency_id := str(reward.get("currency_id", ""))
				var amount := int(reward.get("amount", 0))
				_progress_manager.add_currency(currency_id, amount)
			SHOP_REWARD_TYPE_SCRIPT.BOOSTER:
				var booster_id := str(reward.get("booster_id", ""))
				var booster_amount := int(reward.get("amount", 0))
				_progress_manager.add_booster(booster_id, booster_amount)

	_progress_manager.mark_processed_purchase_token(purchase_token)
	return true
