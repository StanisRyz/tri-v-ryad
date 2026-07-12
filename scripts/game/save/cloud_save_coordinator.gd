extends RefCounted
class_name CloudSaveCoordinator

## Stage 69.4: owns the whole Yandex cloud-sync lifecycle — initial
## reconciliation against the local save, and every later upload. Local save
## is always the mandatory primary: ProgressManager already wrote to disk
## (see ProgressManager.local_save_completed) before this class ever gets
## involved, so a cloud outage never blocks a save, only the cloud mirror of
## it.

signal initial_reconciliation_completed(result: String)

const CLOUD_SAVE_ENVELOPE_SCRIPT := preload("res://scripts/game/save/cloud_save_envelope.gd")
const CLOUD_SAVE_CONFLICT_RESOLVER_SCRIPT := preload("res://scripts/game/save/cloud_save_conflict_resolver.gd")

const RESULT_LOCAL := CLOUD_SAVE_CONFLICT_RESOLVER_SCRIPT.RESULT_LOCAL
const RESULT_CLOUD := CLOUD_SAVE_CONFLICT_RESOLVER_SCRIPT.RESULT_CLOUD
const RESULT_NONE := CLOUD_SAVE_CONFLICT_RESOLVER_SCRIPT.RESULT_NONE
const RESULT_UNAVAILABLE := "unavailable"

## Suggested normal-save debounce: enough to collapse a burst of currency/
## booster mutations (e.g. a bundle purchase's several rewards) into one
## upload, without meaningfully delaying an eventual cloud mirror.
const NORMAL_UPLOAD_DEBOUNCE_SECONDS := 15.0

var _progress_manager
var _platform

var _reconciliation_started := false
var _reconciliation_completed := false

var _upload_in_flight := false
var _debounce_pending := false
var _queued_snapshot: Dictionary = {}
var _queued_is_critical := false


func _init(progress_manager = null, platform = null) -> void:
	set_progress_manager(progress_manager)
	if platform != null:
		connect_platform(platform)


func set_progress_manager(progress_manager) -> void:
	_progress_manager = progress_manager
	if progress_manager != null and not progress_manager.local_save_completed.is_connected(_on_local_save_completed):
		progress_manager.local_save_completed.connect(_on_local_save_completed)


## Idempotent — safe to call more than once.
func connect_platform(platform) -> void:
	if platform == null:
		return
	_platform = platform
	if not platform.cloud_save_loaded.is_connected(_on_cloud_save_loaded):
		platform.cloud_save_loaded.connect(_on_cloud_save_loaded)
	if not platform.cloud_save_load_error.is_connected(_on_cloud_save_load_error):
		platform.cloud_save_load_error.connect(_on_cloud_save_load_error)
	if not platform.cloud_save_completed.is_connected(_on_cloud_save_completed):
		platform.cloud_save_completed.connect(_on_cloud_save_completed)
	if not platform.cloud_save_error.is_connected(_on_cloud_save_error):
		platform.cloud_save_error.connect(_on_cloud_save_error)


## Kicks off the one-time initial reconciliation: requests the cloud
## snapshot and, once it (or an error) arrives, picks the authoritative
## snapshot and applies it. Safe to call once; a missing/unavailable
## platform (or cloud load error) completes reconciliation immediately with
## local progress rather than blocking startup.
func start_initial_reconciliation() -> void:
	if _reconciliation_started:
		return
	_reconciliation_started = true

	if _platform == null or not _platform.is_cloud_save_available():
		_finish_initial_reconciliation(RESULT_UNAVAILABLE)
		return

	_platform.load_cloud_save()


func is_initial_reconciliation_completed() -> bool:
	return _reconciliation_completed


func _on_cloud_save_loaded(cloud_data: Dictionary) -> void:
	if _reconciliation_completed:
		return
	_reconcile(cloud_data)


## Cloud load failure must complete reconciliation using local progress —
## never blocks the game waiting on a cloud round trip that already failed.
func _on_cloud_save_load_error(_message: String) -> void:
	if _reconciliation_completed:
		return
	_finish_initial_reconciliation(RESULT_LOCAL)


func _reconcile(cloud_envelope: Dictionary) -> void:
	var local_envelope := _build_local_envelope()
	var winner := CLOUD_SAVE_CONFLICT_RESOLVER_SCRIPT.resolve(local_envelope, cloud_envelope)

	match winner:
		RESULT_CLOUD:
			var progress_data := CLOUD_SAVE_ENVELOPE_SCRIPT.get_progress_data(cloud_envelope)
			if _progress_manager != null and _progress_manager.replace_progress_from_cloud(progress_data):
				_finish_initial_reconciliation(RESULT_CLOUD)
			else:
				# Applying the cloud snapshot failed (e.g. local write
				# failed) — keep local progress rather than leaving the
				# game without any usable progress.
				_finish_initial_reconciliation(RESULT_LOCAL)
		RESULT_LOCAL:
			_finish_initial_reconciliation(RESULT_LOCAL)
			_upload_current_progress(true)
		_:
			_finish_initial_reconciliation(RESULT_NONE)


func _finish_initial_reconciliation(result: String) -> void:
	if _reconciliation_completed:
		return
	_reconciliation_completed = true
	initial_reconciliation_completed.emit(result)

	if _queued_snapshot.is_empty():
		return
	if _queued_is_critical:
		_flush_queue_now()
	else:
		_start_debounce_timer()


## ProgressManager.local_save_completed listener. Every real local save
## (local-first policy: this always already happened before any cloud call)
## replaces the queued snapshot with the latest one — normal saves wait out
## the debounce window, a critical save (or a critical save arriving while a
## normal one is still debouncing) uploads right away. Saves that land
## before initial reconciliation finishes are queued and flushed once
## reconciliation completes, so they can never race the cloud comparison.
func _on_local_save_completed(snapshot: Dictionary, importance: String) -> void:
	_queued_snapshot = snapshot
	if importance == "critical":
		_queued_is_critical = true

	if not _reconciliation_completed:
		return

	if _queued_is_critical:
		_flush_queue_now()
	else:
		_start_debounce_timer()


func _start_debounce_timer() -> void:
	if _debounce_pending:
		return
	_debounce_pending = true

	var tree := _get_scene_tree()
	if tree == null:
		_debounce_pending = false
		_flush_queue_now()
		return

	await tree.create_timer(NORMAL_UPLOAD_DEBOUNCE_SECONDS).timeout
	_debounce_pending = false
	_flush_queue_now()


## Only one cloud upload in flight at a time; if one is already running, the
## queued snapshot stays queued and gets picked up by _on_cloud_save_completed()/
## _on_cloud_save_error() once that upload finishes — always the latest
## queued snapshot, never a stale one.
func _flush_queue_now() -> void:
	if _queued_snapshot.is_empty() or _upload_in_flight:
		return

	var snapshot := _queued_snapshot
	var is_critical := _queued_is_critical
	_queued_snapshot = {}
	_queued_is_critical = false
	_upload_snapshot(snapshot, is_critical)


func _upload_current_progress(is_critical: bool) -> void:
	if _progress_manager == null:
		return
	var progress = _progress_manager.get_progress()
	if progress == null:
		return
	_upload_snapshot(progress.to_dictionary(), is_critical)


func _upload_snapshot(progress_data: Dictionary, is_critical: bool) -> void:
	if _platform == null or not _platform.is_cloud_save_available():
		return

	var revision := int(progress_data.get("save_revision", 0))
	var saved_at := int(progress_data.get("last_save_unix_time", 0))
	var envelope := CLOUD_SAVE_ENVELOPE_SCRIPT.create(progress_data, revision, saved_at)

	if not CLOUD_SAVE_ENVELOPE_SCRIPT.is_valid(envelope):
		push_warning("CloudSaveCoordinator: refusing to upload an invalid/oversized envelope (%d bytes)" % CLOUD_SAVE_ENVELOPE_SCRIPT.estimate_byte_size(envelope))
		return

	_upload_in_flight = true
	_platform.save_cloud_save(envelope, is_critical)


## Upload succeeded — if a newer snapshot was queued while this one was in
## flight, submit it now (debounced for a normal save, immediate for a
## critical one), otherwise stay idle. No automatic retry of a *successful*
## upload, obviously.
func _on_cloud_save_completed() -> void:
	_upload_in_flight = false
	if _queued_snapshot.is_empty():
		return
	if _queued_is_critical:
		_flush_queue_now()
	else:
		_start_debounce_timer()


## Upload failed — nothing to roll back locally (the local save already
## succeeded independently). Deliberately does not retry automatically: the
## next real local_save_completed (or the next app launch's reconciliation)
## naturally re-attempts with the latest snapshot, so a persistent cloud
## error can't spin in a retry loop within one session.
func _on_cloud_save_error(_message: String) -> void:
	_upload_in_flight = false


func _build_local_envelope() -> Dictionary:
	if _progress_manager == null:
		return {}
	var progress = _progress_manager.get_progress()
	if progress == null:
		return {}
	var progress_data: Dictionary = progress.to_dictionary()
	var revision := int(progress_data.get("save_revision", 0))
	var saved_at := int(progress_data.get("last_save_unix_time", 0))
	return CLOUD_SAVE_ENVELOPE_SCRIPT.create(progress_data, revision, saved_at)


func _get_scene_tree() -> SceneTree:
	var loop := Engine.get_main_loop()
	return loop if loop is SceneTree else null
