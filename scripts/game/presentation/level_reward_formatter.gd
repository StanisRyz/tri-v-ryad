extends RefCounted
class_name LevelRewardFormatter

## Stage 62.3 v0.1: formats structured star-milestone reward data (see
## LevelStarRewardResolver) into display-ready lines for the victory result
## overlay.

const BOOSTER_CATALOG_SCRIPT := preload("res://scripts/game/config/booster_catalog.gd")
const CURRENCY_TYPE_SCRIPT := preload("res://scripts/game/economy/currency_type.gd")
const LEVEL_STAR_REWARD_RESOLVER_SCRIPT := preload("res://scripts/game/progression/level_star_reward_resolver.gd")

const NO_REWARDS_TEXT := "No new rewards"


static func format_rewards(rewards: Array) -> Array[String]:
	var lines: Array[String] = []
	var booster_catalog := BOOSTER_CATALOG_SCRIPT.new()

	for reward in rewards:
		if not (reward is Dictionary):
			continue
		var line := _format_reward(reward, booster_catalog)
		if line != "":
			lines.append(line)

	return lines


static func format_rewards_text(rewards: Array) -> String:
	var lines := format_rewards(rewards)
	if lines.is_empty():
		return NO_REWARDS_TEXT
	return "\n".join(lines)


static func _format_reward(reward: Dictionary, booster_catalog) -> String:
	match str(reward.get("type", "")):
		LEVEL_STAR_REWARD_RESOLVER_SCRIPT.REWARD_TYPE_UNLOCK_LEVEL:
			return "Next level unlocked"
		LEVEL_STAR_REWARD_RESOLVER_SCRIPT.REWARD_TYPE_CURRENCY:
			return _format_currency_reward(reward)
		LEVEL_STAR_REWARD_RESOLVER_SCRIPT.REWARD_TYPE_BOOSTER:
			return _format_booster_reward(reward, booster_catalog)
		_:
			return ""


static func _format_currency_reward(reward: Dictionary) -> String:
	var amount: int = int(reward.get("amount", 0))
	var currency_id := str(reward.get("currency_id", ""))
	var currency_label := "Gold" if currency_id == CURRENCY_TYPE_SCRIPT.GOLD else "Gems"
	return "+%d %s" % [amount, currency_label]


static func _format_booster_reward(reward: Dictionary, booster_catalog) -> String:
	var amount: int = int(reward.get("amount", 0))
	var booster_id := str(reward.get("booster_id", ""))
	var config = booster_catalog.get_booster(booster_id) if booster_catalog != null else null
	var booster_label: String = config.display_name if config != null else booster_id.capitalize()
	return "+%d %s" % [amount, booster_label]
