extends RefCounted
class_name LevelRewardFormatter

## Stage 62.3 v0.1: formats structured star-milestone reward data (see
## LevelStarRewardResolver) into display-ready lines for the victory result
## overlay.
## Stage 65.20 v0.1: every string routed through LocalizationManager
## (ui.result.reward.gold/gems/booster/none); English/Russian text lives in
## game_text.csv, not here. The literal fallbacks below only fire if the
## LocalizationManager autoload is somehow missing.

const CURRENCY_TYPE_SCRIPT := preload("res://scripts/game/economy/currency_type.gd")
const LEVEL_STAR_REWARD_RESOLVER_SCRIPT := preload("res://scripts/game/progression/level_star_reward_resolver.gd")

const NO_REWARDS_TEXT := "No new rewards"


static func format_rewards(rewards: Array, localization_manager = null) -> Array[String]:
	var lines: Array[String] = []

	for reward in rewards:
		if not (reward is Dictionary):
			continue
		var line := _format_reward(reward, localization_manager)
		if line != "":
			lines.append(line)

	return lines


static func format_rewards_text(rewards: Array, localization_manager = null) -> String:
	var lines := format_rewards(rewards, localization_manager)
	if lines.is_empty():
		if localization_manager != null:
			return localization_manager.tr_key("ui.result.reward.none")
		return NO_REWARDS_TEXT
	return "\n".join(lines)


static func _format_reward(reward: Dictionary, localization_manager) -> String:
	match str(reward.get("type", "")):
		LEVEL_STAR_REWARD_RESOLVER_SCRIPT.REWARD_TYPE_UNLOCK_LEVEL:
			return ""
		LEVEL_STAR_REWARD_RESOLVER_SCRIPT.REWARD_TYPE_CURRENCY:
			return _format_currency_reward(reward, localization_manager)
		LEVEL_STAR_REWARD_RESOLVER_SCRIPT.REWARD_TYPE_BOOSTER:
			if localization_manager != null:
				return localization_manager.tr_key("ui.result.reward.booster")
			return "Booster received"
		_:
			return ""


static func _format_currency_reward(reward: Dictionary, localization_manager) -> String:
	var amount: int = int(reward.get("amount", 0))
	var currency_id := str(reward.get("currency_id", ""))
	if localization_manager != null:
		var key := "ui.result.reward.gold" if currency_id == CURRENCY_TYPE_SCRIPT.GOLD else "ui.result.reward.gems"
		return localization_manager.format_key(key, {"gold": amount, "gems": amount})
	var currency_label := "gold" if currency_id == CURRENCY_TYPE_SCRIPT.GOLD else "gems"
	return "+%d %s" % [amount, currency_label]
