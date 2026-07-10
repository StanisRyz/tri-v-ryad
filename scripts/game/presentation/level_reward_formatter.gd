extends RefCounted
class_name LevelRewardFormatter

## Stage 62.3 v0.1: formats structured star-milestone reward data (see
## LevelStarRewardResolver) into display-ready lines for the victory result
## overlay.
## Stage 64.17 v0.1: localized to Russian to match the new result panel's
## expected reward text ("Открыт следующий уровень" / "+10 золота" /
## "Получен случайный бустер"); the underlying reward data/logic is untouched.

const CURRENCY_TYPE_SCRIPT := preload("res://scripts/game/economy/currency_type.gd")
const LEVEL_STAR_REWARD_RESOLVER_SCRIPT := preload("res://scripts/game/progression/level_star_reward_resolver.gd")

const NO_REWARDS_TEXT := "Новых наград нет"


static func format_rewards(rewards: Array) -> Array[String]:
	var lines: Array[String] = []

	for reward in rewards:
		if not (reward is Dictionary):
			continue
		var line := _format_reward(reward)
		if line != "":
			lines.append(line)

	return lines


static func format_rewards_text(rewards: Array) -> String:
	var lines := format_rewards(rewards)
	if lines.is_empty():
		return NO_REWARDS_TEXT
	return "\n".join(lines)


static func _format_reward(reward: Dictionary) -> String:
	match str(reward.get("type", "")):
		LEVEL_STAR_REWARD_RESOLVER_SCRIPT.REWARD_TYPE_UNLOCK_LEVEL:
			return "Открыт следующий уровень"
		LEVEL_STAR_REWARD_RESOLVER_SCRIPT.REWARD_TYPE_CURRENCY:
			return _format_currency_reward(reward)
		LEVEL_STAR_REWARD_RESOLVER_SCRIPT.REWARD_TYPE_BOOSTER:
			return "Получен случайный бустер"
		_:
			return ""


static func _format_currency_reward(reward: Dictionary) -> String:
	var amount: int = int(reward.get("amount", 0))
	var currency_id := str(reward.get("currency_id", ""))
	var currency_label := "золота" if currency_id == CURRENCY_TYPE_SCRIPT.GOLD else "кристаллов"
	return "+%d %s" % [amount, currency_label]
