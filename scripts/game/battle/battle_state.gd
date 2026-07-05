extends RefCounted
class_name BattleState

enum Status {
	IN_PROGRESS,
	VICTORY,
	DEFEAT,
}

var heroes: Array[HeroData] = []
var enemy: EnemyData
var enemy_intent: EnemyIntent
var moves_left := 0
var turn_number := 0
var status := Status.IN_PROGRESS


func _init(
	battle_heroes: Array[HeroData] = [],
	battle_enemy: EnemyData = null,
	battle_enemy_intent: EnemyIntent = null,
	starting_moves: int = 0
) -> void:
	heroes = battle_heroes.duplicate()
	enemy = battle_enemy if battle_enemy != null else EnemyData.new()
	enemy_intent = battle_enemy_intent if battle_enemy_intent != null else EnemyIntent.new()
	moves_left = starting_moves
	update_status()


func is_finished() -> bool:
	return status != Status.IN_PROGRESS


func get_alive_heroes() -> Array[HeroData]:
	var alive_heroes: Array[HeroData] = []
	for hero in heroes:
		if hero.is_alive():
			alive_heroes.append(hero)
	return alive_heroes


func get_hero_by_lane(lane_index: int) -> HeroData:
	for hero in heroes:
		if hero.lane_index == lane_index:
			return hero
	return null


func update_status() -> void:
	if enemy != null and enemy.current_hp <= 0:
		status = Status.VICTORY
		return

	if moves_left <= 0:
		status = Status.DEFEAT
		return

	if FeatureFlags.HERO_SYSTEMS_ENABLED and get_alive_heroes().is_empty():
		status = Status.DEFEAT
		return

	status = Status.IN_PROGRESS
