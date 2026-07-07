extends RefCounted
class_name LevelStarRewardResolver

## Stage 62.3 v0.1: resolves one-time rewards for newly earned star milestones
## on level completion. Pure/stateless aside from the injected RNG for the
## 3-star random booster pick - callers own persistence (ProgressManager).

const BOOSTER_CATALOG_SCRIPT := preload("res://scripts/game/config/booster_catalog.gd")
const CURRENCY_TYPE_SCRIPT := preload("res://scripts/game/economy/currency_type.gd")

const GOLD_MILESTONE_REWARD := 10

const REWARD_TYPE_UNLOCK_LEVEL := "unlock_level"
const REWARD_TYPE_CURRENCY := "currency"
const REWARD_TYPE_BOOSTER := "booster"


func get_booster_reward_pool() -> Array[String]:
	return [
		BOOSTER_CATALOG_SCRIPT.HAMMER,
		BOOSTER_CATALOG_SCRIPT.FREEZE_TIME,
		BOOSTER_CATALOG_SCRIPT.ROCKET_BARRAGE,
	]


func pick_random_booster_id(rng: RandomNumberGenerator = null) -> String:
	var pool := get_booster_reward_pool()
	if pool.is_empty():
		return ""

	var use_rng := rng
	if use_rng == null:
		use_rng = RandomNumberGenerator.new()
		use_rng.randomize()

	return pool[use_rng.randi_range(0, pool.size() - 1)]


## previous_stars/new_stars are the level's best-ever stars before and after
## this completion. Only star thresholds newly crossed (previous < N <= new)
## produce a reward, so replaying an already-earned milestone grants nothing.
func resolve_milestone_rewards(previous_stars: int, new_stars: int, next_level_id: String, rng: RandomNumberGenerator = null) -> Array[Dictionary]:
	var rewards: Array[Dictionary] = []
	var safe_previous: int = clampi(previous_stars, 0, 3)
	var safe_new: int = clampi(new_stars, 0, 3)

	if safe_previous < 1 and safe_new >= 1 and next_level_id != "":
		rewards.append({
			"type": REWARD_TYPE_UNLOCK_LEVEL,
			"level_id": next_level_id,
			"milestone_star": 1,
		})

	if safe_previous < 2 and safe_new >= 2:
		rewards.append({
			"type": REWARD_TYPE_CURRENCY,
			"currency_id": CURRENCY_TYPE_SCRIPT.GOLD,
			"amount": GOLD_MILESTONE_REWARD,
			"milestone_star": 2,
		})

	if safe_previous < 3 and safe_new >= 3:
		var booster_id := pick_random_booster_id(rng)
		if booster_id != "":
			rewards.append({
				"type": REWARD_TYPE_BOOSTER,
				"booster_id": booster_id,
				"amount": 1,
				"milestone_star": 3,
			})

	return rewards
