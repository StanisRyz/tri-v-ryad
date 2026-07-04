extends HBoxContainer

signal ability_requested(lane_index: int)


func _ready() -> void:
	_connect_card_signals()
	_refresh_cards()


func set_heroes(heroes: Array[HeroData]) -> void:
	for index in range(get_child_count()):
		var card := get_child(index)
		var hero: HeroData = heroes[index] if index < heroes.size() else null
		if card.has_method("set_hero"):
			card.set_hero(hero)
	_connect_card_signals()


func _refresh_cards() -> void:
	for child in get_children():
		if child.has_method("refresh"):
			child.refresh()


func _connect_card_signals() -> void:
	for child in get_children():
		if not child.has_signal("ability_pressed"):
			continue
		if not child.ability_pressed.is_connected(_on_card_ability_pressed):
			child.ability_pressed.connect(_on_card_ability_pressed)


func _on_card_ability_pressed(lane_index: int) -> void:
	ability_requested.emit(lane_index)
