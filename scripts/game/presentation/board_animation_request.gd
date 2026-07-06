extends RefCounted
class_name BoardAnimationRequest

const TYPE_SWAP := "swap"
const TYPE_INVALID_SWAP := "invalid_swap"
const TYPE_MATCH_CLEAR := "match_clear"
const TYPE_SPECIAL_CLEAR := "special_clear"
const TYPE_SPECIAL_CREATE := "special_create"
const TYPE_GRAVITY_FALL := "gravity_fall"
const TYPE_REFILL := "refill"
const TYPE_CASCADE_STEP := "cascade_step"
const TYPE_BOOSTER_CLEAR := "booster_clear"
const TYPE_DAMAGE_PARTICLES := "damage_particles"
const TYPE_ENEMY_HIT := "enemy_hit"
const SCRIPT_PATH := "res://scripts/game/presentation/board_animation_request.gd"

var animation_type := ""
var cells: Array[Vector2i] = []
var from_cell := Vector2i(-1, -1)
var to_cell := Vector2i(-1, -1)
var duration := 0.08
var payload := {}


static func new_request(type: String):
	var request = load(SCRIPT_PATH).new()
	request.animation_type = type
	return request


func with_cells(value: Array[Vector2i]):
	cells = value.duplicate()
	return self


func with_swap(from: Vector2i, to: Vector2i):
	from_cell = from
	to_cell = to
	return self


func with_duration(value: float):
	duration = maxf(value, 0.0)
	return self


func with_payload(value: Dictionary):
	payload = value.duplicate(true)
	return self


func is_valid() -> bool:
	return animation_type != ""


func to_dictionary() -> Dictionary:
	return {
		"animation_type": animation_type,
		"cells": cells.duplicate(),
		"from_cell": from_cell,
		"to_cell": to_cell,
		"duration": duration,
		"payload": payload.duplicate(true),
	}
