extends RefCounted
class_name ShopRewardType

## Reward dictionary shapes:
## {"type": "currency", "currency_id": "gold", "amount": 50}
## {"type": "booster", "booster_id": "hammer", "amount": 1}
const CURRENCY := "currency"
const BOOSTER := "booster"

const ALL_IDS: Array[String] = [CURRENCY, BOOSTER]

const CURRENCY_TYPE_SCRIPT := preload("res://scripts/game/economy/currency_type.gd")
const BOOSTER_CATALOG_SCRIPT := preload("res://scripts/game/config/booster_catalog.gd")


static func make_currency_reward(currency_id: String, amount: int) -> Dictionary:
	return {"type": CURRENCY, "currency_id": currency_id, "amount": amount}


static func make_booster_reward(booster_id: String, amount: int) -> Dictionary:
	return {"type": BOOSTER, "booster_id": booster_id, "amount": amount}


static func is_valid(reward: Dictionary, booster_catalog = null) -> bool:
	if not reward.has("type"):
		return false

	var reward_type: String = str(reward.get("type", ""))
	var amount: int = int(reward.get("amount", 0))
	if amount <= 0:
		return false

	match reward_type:
		CURRENCY:
			return CURRENCY_TYPE_SCRIPT.is_valid(str(reward.get("currency_id", "")))
		BOOSTER:
			var catalog = booster_catalog if booster_catalog != null else BOOSTER_CATALOG_SCRIPT.new()
			return catalog.has_booster(str(reward.get("booster_id", "")))
		_:
			return false
