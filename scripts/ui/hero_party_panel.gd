extends HBoxContainer


func _ready() -> void:
	_refresh_cards()


func _refresh_cards() -> void:
	for child in get_children():
		if child.has_method("refresh"):
			child.refresh()
