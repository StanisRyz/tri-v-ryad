extends RefCounted
class_name CloudSaveEnvelope

## Stage 69.4: the shape stored under YandexBridge.CLOUD_KEY ("save_v1").
## Wraps a full PlayerProgress.to_dictionary() snapshot with just enough
## metadata for CloudSaveConflictResolver to compare a local and a cloud
## snapshot without opening either one's internals.
##
## Shape: {cloud_schema_version, save_revision, saved_at_unix, progress}

const CLOUD_SCHEMA_VERSION := 1

## Stage 69.4: Yandex Player Data enforces a 200 KB limit on the whole
## payload; this stays safely under that so a borderline-sized envelope is
## rejected locally instead of failing after a round trip through the SDK.
const MAX_CLOUD_PAYLOAD_BYTES := 190000


static func create(progress_data: Dictionary, save_revision: int, saved_at_unix: int) -> Dictionary:
	return {
		"cloud_schema_version": CLOUD_SCHEMA_VERSION,
		"save_revision": save_revision,
		"saved_at_unix": saved_at_unix,
		"progress": progress_data,
	}


## Rejects a missing/non-Dictionary/empty progress payload, an unsupported
## cloud_schema_version, a malformed (non-numeric or negative) revision or
## timestamp, and a serialized payload above MAX_CLOUD_PAYLOAD_BYTES. Never
## truncates progress to fit — an oversized envelope is simply invalid and
## the caller must keep local progress instead of uploading/applying it.
static func is_valid(envelope: Dictionary) -> bool:
	if envelope.is_empty():
		return false
	if int(envelope.get("cloud_schema_version", -1)) != CLOUD_SCHEMA_VERSION:
		return false

	var progress_data = envelope.get("progress")
	if not (progress_data is Dictionary) or progress_data.is_empty():
		return false

	if not _is_non_negative_number(envelope.get("save_revision")):
		return false
	if not _is_non_negative_number(envelope.get("saved_at_unix")):
		return false

	if estimate_byte_size(envelope) > MAX_CLOUD_PAYLOAD_BYTES:
		return false

	return true


static func get_save_revision(envelope: Dictionary) -> int:
	return int(envelope.get("save_revision", 0))


static func get_saved_at_unix(envelope: Dictionary) -> int:
	return int(envelope.get("saved_at_unix", 0))


static func get_progress_data(envelope: Dictionary) -> Dictionary:
	var progress_data = envelope.get("progress", {})
	return progress_data if progress_data is Dictionary else {}


## UTF-8 byte size of the envelope as it would actually be transmitted
## (JSON.stringify with no indent, matching how YandexBridge serializes it).
static func estimate_byte_size(envelope: Dictionary) -> int:
	return JSON.stringify(envelope).to_utf8_buffer().size()


static func _is_non_negative_number(value) -> bool:
	if value is int:
		return value >= 0
	if value is float:
		return value >= 0.0
	return false
