extends HBoxContainer


func _ready() -> void:
	_refresh_cards()


func set_heroes(heroes: Array[HeroData]) -> void:
	for index in range(get_child_count()):
		var card := get_child(index)
		var hero: HeroData = heroes[index] if index < heroes.size() else null
		if card.has_method("set_hero"):
			card.set_hero(hero)


func _refresh_cards() -> void:
	for child in get_children():
		if child.has_method("refresh"):
			child.refresh()
