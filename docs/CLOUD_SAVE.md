# Cloud Save (Stage 69.4 Foundation)

Stage 69.4 adds Yandex cloud synchronization for `PlayerProgress` on top of
the existing local save. **Local save is always the mandatory primary** —
every gameplay mutation still saves to `user://save_v1.json` first, exactly
as before this stage. Cloud sync is a mirror layered on top of that, never
a replacement for it, and it is fully asynchronous: a slow or unavailable
network never blocks startup, gameplay, or a local save.

## Local-first policy

Nothing changed about *how* a local save happens (`SaveManager.save_progress()`,
atomic temp-file-then-rename). What Stage 69.4 adds is a way to also mirror
that already-successful save to the cloud, plus a way to reconcile with
whatever the cloud already has once, at startup, before anything else
touches purchase recovery.

## Payment reliability polish (start of this patch)

Two gaps from Stage 69.3.1 were closed before cloud work began:

- `ProgressManager.apply_platform_purchase_atomic()`'s `already_granted`
  branch (an already-processed token missing its pending-consume record)
  now goes through the same isolated-candidate-snapshot / one-save-or-nothing
  pattern as the `granted` branch, instead of mutating live progress
  directly.
- `PlatformPurchaseCoordinator` now records `_foreground_consume_tokens`
  (token → item id) at the moment consume is requested, independent of the
  transient `_active_foreground_item_id` marker. Previously a synchronous
  `LocalDebugPlatform` consume could emit `purchase_completed` (resolves
  before the marker clears) while a real async Yandex consume never could
  (resolves after) — both paths now behave identically, and a screen that
  already closed simply has no listener left (its connections were freed
  with it), so nothing unsafe happens either way.

## Yandex Player Data API flow

`YandexBridge` (the only script allowed to touch `JavaScriptBridge`) uses:

```
ysdk.getPlayer({ scopes: false })   // cached as window.__godot_player after first use
player.getData(['save_v1'])
player.setData({ save_v1: <json> }, flush)
```

- `is_cloud_save_available()` → `true` once the SDK is ready (Web) or
  always for `LocalDebugPlatform`'s own debug backend.
- `load_cloud_save()` → emits `cloud_save_loaded(data)` with an **empty
  Dictionary** (not an error) when the player has no cloud save yet, or
  `cloud_save_load_error(message)` on a real failure (including malformed
  JSON, which degrades to an empty Dictionary rather than propagating
  garbage).
- `save_cloud_save(data, flush)` → emits `cloud_save_completed` or
  `cloud_save_error(message)`.

These four are forwarded through `PlatformServices` → `WebYandexPlatform`/
`LocalDebugPlatform` → `Platform`. **Game code must call `Platform`, never
`YandexBridge` directly.**

## Cloud key and envelope format

Everything is stored under a single Player Data key, `save_v1`
(`YandexBridge.CLOUD_KEY`) — one atomic key instead of many small ones that
could observe each other mid-update.

`res://scripts/game/save/cloud_save_envelope.gd` (`CloudSaveEnvelope`)
defines the wrapper shape stored at that key:

```jsonc
{
  "cloud_schema_version": 1,
  "save_revision": 42,
  "saved_at_unix": 1732300000,
  "progress": { /* full PlayerProgress.to_dictionary() */ }
}
```

`CloudSaveEnvelope.is_valid()` rejects: a missing/non-Dictionary/empty
`progress`, an unsupported `cloud_schema_version`, a malformed (non-numeric
or negative) `save_revision`/`saved_at_unix`, and a serialized payload above
`MAX_CLOUD_PAYLOAD_BYTES` (190000 — safely under Yandex's 200 KB Player Data
limit). **It never truncates** — an oversized envelope is simply invalid,
and the upload is refused with a `push_warning`, keeping local progress
untouched.

## Revision/timestamp metadata

`PlayerProgress` gained `save_revision: int` and `last_save_unix_time: int`,
both defaulting to `0` for saves written before this stage. `bump_save_metadata()`
increments the revision and refreshes the timestamp, called **only** by
`SaveManager.save_progress()` right before an actual write (`bump_metadata`
parameter, default `true`) — never by loading, `duplicate_progress()`, or
`ProgressManager.replace_progress_from_cloud()` (which passes `bump_metadata
= false`, since applying an already-authoritative cloud snapshot as-is is a
passive sync, not a new local mutation).

## Conflict policy: last snapshot wins, no field merging

`res://scripts/game/save/cloud_save_conflict_resolver.gd`
(`CloudSaveConflictResolver.resolve(local_envelope, cloud_envelope)`)
returns exactly one of `"local"` / `"cloud"` / `"none"`:

- only a valid local envelope → `local`
- only a valid cloud envelope → `cloud`
- neither valid → `none`
- both valid → newer `saved_at_unix` wins; a tie breaks on higher
  `save_revision`; a further tie breaks to `local`

**Currency, boosters, level state, and purchase tokens are never merged
field by field.** The whole envelope's `progress` Dictionary is applied as
one unit. Merging two independently-evolved snapshots field by field could
resurrect spent currency or re-grant a purchase whose consume already
succeeded on a different device — applying one complete, chosen snapshot is
the only safe option.

## Initial reconciliation order

`res://scripts/game/save/cloud_save_coordinator.gd` (`CloudSaveCoordinator`)
owns this. `App._bootstrap_platform()` runs, in order:

1. Local progress already loaded and the first screen already shown before
   any of this starts (unchanged from Stage 69.1 — see `app.gd._ready()`).
2. `Platform.sync_language_to_localization()` / `Platform.game_ready()`.
3. Create `CloudSaveCoordinator`, connect it to `Platform`'s cloud signals
   and `ProgressManager.local_save_completed`.
4. `coordinator.start_initial_reconciliation()` → `Platform.load_cloud_save()`
   (or, if `Platform`/cloud is unavailable, finishes immediately with
   `"unavailable"` — no network round trip attempted).
5. `App` awaits `initial_reconciliation_completed` (guarded against a
   platform that resolves **synchronously**, like `LocalDebugPlatform` —
   `await`ing an already-fired signal would hang forever, so `App` checks
   `is_initial_reconciliation_completed()` first).
6. Only after that: `PlatformPurchaseCoordinator.connect_platform()`,
   `Platform.check_unprocessed_purchases()`, `retry_pending_consume_tokens()`.

Purchase recovery is deliberately delayed until after reconciliation:
`CloudSaveCoordinator` may replace local progress (including its purchase
ledgers) with the cloud's, so recovering purchases against a soon-to-be-discarded
snapshot would be wrong.

**Cloud load failure completes reconciliation using local progress** — never
blocks, never loses local data.

## Refreshing the screen after reconciliation

If `initial_reconciliation_completed` reports `"cloud"` (local progress was
replaced), `App` refreshes whichever screen is currently visible via its
existing `refresh_progress_state()` API (`ScreenRouter.get_current_screen()`)
— no screen is recreated. `GameScreen` has no `refresh_progress_state()`
method, so this `has_method()` gate naturally never touches an active level;
the reconciled progress simply applies the next time the player saves or
opens a screen that does refresh (MainMenu, LevelSelect, Shop, results).

## Upload debounce and critical saves

`ProgressManager.local_save_completed(snapshot, importance)` fires only
after a real local save succeeds. `importance` is `"normal"` (most gameplay
mutations) or `"critical"`:

- paid purchase reward granted (`apply_platform_purchase_atomic()`)
- pending-consume state changed (`remove_pending_consume_token()`, and the
  `already_granted` pending-record fix above)
- level completion (`complete_level()` / `complete_level_with_rewards()`)
- explicit reset (`reset_progress()`)

`CloudSaveCoordinator` queues the **latest** snapshot only (never a
FIFO — a new save always overwrites the queued one). A normal save starts (or
extends into) a 15-second debounce (`NORMAL_UPLOAD_DEBOUNCE_SECONDS`); a
critical save uploads immediately, even cutting an in-progress debounce
short. Only one upload is ever in flight; if another snapshot lands while
one is uploading, it stays queued and gets flushed (immediately if critical,
debounced otherwise) once the in-flight upload's `cloud_save_completed`/
`cloud_save_error` arrives. A failed upload does **not** retry automatically
within the session — the next real local save (or the next app launch's
reconciliation) naturally re-attempts with the latest snapshot, which is
what keeps this from becoming a retry loop.

## 200 KB payload protection

Before every upload, `CloudSaveCoordinator` builds the envelope and calls
`CloudSaveEnvelope.is_valid()`, which checks `estimate_byte_size()` (UTF-8
byte length of the compact JSON, matching exactly how `YandexBridge`
serializes it) against `MAX_CLOUD_PAYLOAD_BYTES` (190000). An oversized or
otherwise invalid envelope is never submitted — local progress is
untouched, and a `push_warning` is emitted for diagnostics.

## LocalDebug cloud backend

`LocalDebugPlatform` implements the same four cloud methods/signals against
a separate file, `user://debug_cloud_save_v1.json` — **never** the real
local save file. Manual editor testing scenarios:

- delete the debug file → "no cloud save"
- write to it before the real local save has ever run → "cloud-only save"
- hand-edit `save_revision`/`saved_at_unix` relative to the local save →
  "local newer" / "cloud newer" / "equal snapshots"
- write invalid JSON into it → "malformed cloud JSON" (`cloud_save_load_error`)
- `debug_cloud_available_override = false` → "cloud unavailable"
- `debug_cloud_load_should_fail` / `debug_cloud_save_should_fail` → simulated
  load/save errors

All default to success/available, matching real Yandex behavior when
nothing is misconfigured.

## Purchase ledger preservation and recovery ordering

`processed_purchase_tokens` and `pending_consume_tokens` are part of the
same `PlayerProgress.to_dictionary()`/`from_dictionary()` round trip as
everything else, so they travel through the cloud envelope unchanged. After
`CloudSaveCoordinator` applies the authoritative snapshot (local or cloud):

- already-processed purchases are never granted again (`apply_platform_purchase_atomic()`
  checks `has_processed_purchase_token()` before touching anything)
- pending consume tokens are retried (`retry_pending_consume_tokens()`,
  called only after reconciliation completes)
- an unknown Yandex product id (no local item maps to it) is never granted
  or consumed — `PlatformPurchaseCoordinator._resolve_item()` returns `null`
  and the signal is ignored

## Non-blocking guarantee

Cloud errors at any point — load, save, or an unavailable platform — never
prevent entering MainMenu, opening Shop, starting a level, local rewards,
local saves, rewarded ads, or purchases. No mandatory cloud loading screen
was added.

## Stage 69.5 Web readiness guard

`LocalDebugPlatform` reconciles immediately. `WebYandexPlatform` now waits
for `Platform.sdk_ready` while the SDK initializes, with one bounded timeout
owned by `CloudSaveCoordinator`. SDK readiness begins normal cloud loading;
timeout completes with local progress exactly once. A late cloud snapshot is
ignored after completion, so active gameplay is never replaced. Purchase
recovery still begins only after reconciliation.

## What is explicitly NOT done in Stage 69.5

- No Yandex-draft validation or submission audit; that is Stage 69.6.
- Tests were not added, updated, touched, or run for this stage. Manual
  validation will be performed in Godot, and later in a real Yandex draft
  build.
