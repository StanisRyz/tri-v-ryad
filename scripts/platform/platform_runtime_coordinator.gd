extends Node
class_name PlatformRuntimeCoordinator

## Stage 69.5: application-lifetime owner of platform/browser pause state.
## It intentionally does not pause SceneTree: Platform callbacks, ad UI and
## the resume path must continue running while battle interaction is blocked.

var _platform: Node
var _current_screen: Node
var _pause_reasons: Dictionary = {}
var _gameplay_was_active_before_pause := false


func setup(platform: Node) -> void:
	_platform = platform
	if _platform == null:
		return
	if not _platform.platform_pause_requested.is_connected(_on_platform_pause_requested):
		_platform.platform_pause_requested.connect(_on_platform_pause_requested)
	if not _platform.platform_resume_requested.is_connected(_on_platform_resume_requested):
		_platform.platform_resume_requested.connect(_on_platform_resume_requested)


func set_current_screen(screen: Node) -> void:
	_current_screen = screen
	_apply_pause_state_to_screen()
	if not _pause_reasons.is_empty() and _is_active_gameplay_screen():
		_gameplay_was_active_before_pause = true
		if _platform != null:
			_platform.gameplay_stop()


func _notification(what: int) -> void:
	if not OS.has_feature("web"):
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_on_platform_pause_requested("browser_focus")
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_on_platform_resume_requested("browser_focus")


func _on_platform_pause_requested(reason: String) -> void:
	if reason == "" or _pause_reasons.has(reason):
		return
	var had_no_reasons := _pause_reasons.is_empty()
	_pause_reasons[reason] = true
	if had_no_reasons:
		_gameplay_was_active_before_pause = _is_active_gameplay_screen()
		if _gameplay_was_active_before_pause and _platform != null:
			_platform.gameplay_stop()
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.pause_audio(reason)
	_apply_pause_state_to_screen()


func _on_platform_resume_requested(reason: String) -> void:
	if reason == "" or not _pause_reasons.has(reason):
		return
	_pause_reasons.erase(reason)
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.resume_audio(reason)
	if not _pause_reasons.is_empty():
		return
	_apply_pause_state_to_screen()
	if _gameplay_was_active_before_pause and _is_active_gameplay_screen() and _platform != null:
		_platform.gameplay_start()
	_gameplay_was_active_before_pause = false


func _apply_pause_state_to_screen() -> void:
	if _current_screen != null and _current_screen.has_method("set_platform_paused"):
		_current_screen.set_platform_paused(not _pause_reasons.is_empty())


func _is_active_gameplay_screen() -> bool:
	return _current_screen != null and _current_screen.has_method("is_platform_gameplay_active") and _current_screen.is_platform_gameplay_active()
