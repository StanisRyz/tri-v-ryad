extends RefCounted
class_name BattleTestFactory


static func create_default_state() -> BattleState:
	var heroes: Array[HeroData] = [
		HeroData.new("hero_1", "Hero 1", 0, 10, 100),
		HeroData.new("hero_2", "Hero 2", 1, 8, 120),
		HeroData.new("hero_3", "Hero 3", 2, 12, 80),
	]
	var enemy := EnemyData.new("enemy_training", "Training Enemy", 300, 20)
	var enemy_intent := EnemyIntent.new(3, 1)
	return BattleState.new(heroes, enemy, enemy_intent, 20)
