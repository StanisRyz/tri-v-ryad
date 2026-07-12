extends RefCounted
class_name CloudSaveConflictResolver

## Stage 69.4: picks exactly one authoritative snapshot (local, cloud, or
## neither) — it never merges currency/boosters/level state/purchase tokens
## field by field. Merging could resurrect spent currency or re-grant a
## purchase whose consume already succeeded on a different device; applying
## one complete snapshot as a unit is the only safe option here.

const CLOUD_SAVE_ENVELOPE_SCRIPT := preload("res://scripts/game/save/cloud_save_envelope.gd")

const RESULT_LOCAL := "local"
const RESULT_CLOUD := "cloud"
const RESULT_NONE := "none"


## Rules: only a valid local envelope -> local; only a valid cloud envelope
## -> cloud; neither valid -> none; both valid: newer saved_at_unix wins, a
## tie breaks on higher save_revision, and a further tie breaks to local.
static func resolve(local_envelope: Dictionary, cloud_envelope: Dictionary) -> String:
	var local_valid := CLOUD_SAVE_ENVELOPE_SCRIPT.is_valid(local_envelope)
	var cloud_valid := CLOUD_SAVE_ENVELOPE_SCRIPT.is_valid(cloud_envelope)

	if local_valid and not cloud_valid:
		return RESULT_LOCAL
	if cloud_valid and not local_valid:
		return RESULT_CLOUD
	if not local_valid and not cloud_valid:
		return RESULT_NONE

	var local_time := CLOUD_SAVE_ENVELOPE_SCRIPT.get_saved_at_unix(local_envelope)
	var cloud_time := CLOUD_SAVE_ENVELOPE_SCRIPT.get_saved_at_unix(cloud_envelope)
	if local_time != cloud_time:
		return RESULT_LOCAL if local_time > cloud_time else RESULT_CLOUD

	var local_revision := CLOUD_SAVE_ENVELOPE_SCRIPT.get_save_revision(local_envelope)
	var cloud_revision := CLOUD_SAVE_ENVELOPE_SCRIPT.get_save_revision(cloud_envelope)
	if local_revision != cloud_revision:
		return RESULT_LOCAL if local_revision > cloud_revision else RESULT_CLOUD

	return RESULT_LOCAL
