extends RefCounted
class_name BoardAnimationSequence

var _requests: Array = []


func add_request(request) -> void:
	if request == null:
		return
	if not request.has_method("is_valid"):
		return
	if not request.is_valid():
		return

	_requests.append(request)


func add_requests(requests: Array) -> void:
	for request in requests:
		add_request(request)


func get_requests() -> Array:
	return _requests.duplicate()


func is_empty() -> bool:
	return _requests.is_empty()


func clear() -> void:
	_requests.clear()


func size() -> int:
	return _requests.size()
