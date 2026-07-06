extends RefCounted
class_name BoardMaskValidationResult

var valid := false
var reasons: Array[String] = []
var active_cell_count := 0
var hole_cell_count := 0
var connected_component_count := 0
var enclosed_active_cell_count := 0


func _init(
	is_valid: bool = false,
	validation_reasons: Array[String] = [],
	active_count: int = 0,
	hole_count: int = 0,
	component_count: int = 0,
	enclosed_count: int = 0
) -> void:
	valid = is_valid
	reasons = validation_reasons.duplicate()
	active_cell_count = active_count
	hole_cell_count = hole_count
	connected_component_count = component_count
	enclosed_active_cell_count = enclosed_count
