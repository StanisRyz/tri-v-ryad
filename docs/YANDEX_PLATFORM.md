# Yandex Platform Foundation

Stage 69.1 adds a safe platform foundation for future Yandex Games SDK
integration. This document describes the architecture, what each piece is
responsible for, and what is intentionally **not** implemented yet.

## Why this exists

Game code (screens, shop, ads, localization, save) must never call
`JavaScriptBridge` directly. A single unified `Platform` API keeps every
Yandex-specific detail isolated behind one autoload, so:

- gameplay/UI code stays platform-agnostic and testable in the editor;
- swapping or extending the underlying SDK integration only touches
  `scripts/platform/` and `autoload/YandexBridge.gd`;
- local/editor development never depends on a browser or the Yandex SDK.

## Architecture

```
Game code (screens, shop, popups, LocalizationManager, ...)
        │
        ▼
   Platform (autoload)              <- the only entry point game code uses
        │
        ├── WebYandexPlatform  (extends PlatformServices)   [when OS.has_feature("web")]
        │        │
        │        ▼
        │   YandexBridge (autoload)  <- the ONLY script allowed to call
        │        │                      JavaScriptBridge.eval/create_callback/
        │        ▼                      get_interface("window")
        │   window.ysdk (Yandex Games SDK, loaded by the web shell)
        │
        └── LocalDebugPlatform (extends PlatformServices)   [editor / non-web builds]
```

### `res://scripts/platform/PlatformServices.gd`

Base class (`class_name PlatformServices`) defining the full platform
interface and signal set: SDK readiness, rewarded ads, fullscreen ads,
payments, payment catalog, unprocessed purchases, platform lifecycle,
platform language, and placeholder cloud-save signals for a later stage.
Every method fails safely (neutral return values, error signals) so a
missing/unready platform never crashes game code.

### `res://autoload/YandexBridge.gd` (autoload)

The only file allowed to touch `JavaScriptBridge`. Responsibilities:

- detects a Web export (`OS.has_feature("web")`);
- polls `window.ysdkReady` / `window.ysdk` until the SDK is available, then
  emits `yandex_sdk_ready`;
- exposes `get_debug_state()` for safe runtime diagnostics;
- reads the Yandex language from `window.ysdk.environment.i18n.lang`;
- calls `window.ysdk.features.LoadingAPI.ready()` via `game_ready()`;
- calls `window.ysdk.features.GameplayAPI.start()/stop()` via
  `gameplay_start()/gameplay_stop()`;
- shows rewarded video / fullscreen (interstitial) ads through
  `window.ysdk.adv`, bridging the JS callback object to Godot signals with
  `JavaScriptBridge.create_callback` and a safety timeout so a stuck/absent
  JS callback never leaves the game waiting forever;
- loads/caches the payment catalog, starts a purchase, consumes a purchase,
  and checks for unprocessed purchases through `window.ysdk.getPayments()`,
  again bridged through JS callbacks with timeouts;
- converts every JS return value defensively (`_to_bool`, `_to_string_safe`)
  so int/float/string/bool/null values from `JavaScriptBridge.eval` never
  crash the bridge.

### `res://scripts/platform/WebYandexPlatform.gd`

`extends PlatformServices`. Pure delegation to the `YandexBridge` autoload
and signal forwarding — it contains no raw `JavaScriptBridge` calls itself.

### `res://scripts/platform/LocalDebugPlatform.gd`

`extends PlatformServices`. Keeps the editor and non-Web builds fully
playable without a Yandex SDK:

- `get_platform_key()` → `"debug"`;
- `get_platform_language()` → current `LocalizationManager` language, or
  `"en"` if unavailable;
- rewarded/fullscreen ads simulate open → (rewarded →) closed after a short
  timer, always succeeding;
- payment catalog is empty by default;
- `purchase_product()` only succeeds when `debug_purchases_enabled` is set
  on the instance (off by default); otherwise it emits
  `payment_purchase_error`;
- `consume_purchase()` is a no-op; `check_unprocessed_purchases()` completes
  immediately with nothing found.

### `res://autoload/Platform.gd` (autoload)

Chooses `WebYandexPlatform` when `OS.has_feature("web")` is true, otherwise
`LocalDebugPlatform`. Forwards every signal from the active implementation
(or from `YandexBridge` on Web) and exposes the single public API game code
should call: `game_ready()`, `gameplay_start()`, `gameplay_stop()`,
`refresh_platform_ready()`, `get_platform_key()`, `get_platform_language()`,
`show_rewarded_ad()`, `show_fullscreen_ad()`, `purchase_product()`,
`consume_purchase()`, `check_unprocessed_purchases()`,
`load_payment_catalog()`, `get_cached_payment_catalog()`,
`get_catalog_product()`, `is_ad_in_progress()`, and
`sync_language_to_localization()`.

## Autoload order

```
AudioManager
LocalizationManager
YandexBridge
Platform
```

`YandexBridge` must load before `Platform`, since `Platform` looks up
`/root/YandexBridge` (through `WebYandexPlatform`) as soon as it picks an
implementation.

## SDK readiness flow

1. `YandexBridge._ready()` starts a poll timer (every 0.5s, up to 20s) that
   checks `window.ysdkReady === true && window.ysdk !== undefined`.
2. The moment that check passes, `YandexBridge` emits `yandex_sdk_ready` and
   `Platform` re-emits it as `sdk_ready`.
3. Any code can also call `Platform.refresh_platform_ready()` to force an
   immediate check and get a `bool` back.

## Language flow into LocalizationManager

1. `app.gd._bootstrap_platform()` runs once at startup (after the main menu
   is shown) and calls `Platform.sync_language_to_localization()`.
2. That method reads `Platform.get_platform_language()` and, if non-empty,
   calls `LocalizationManager.set_language(language)`. Unsupported codes
   naturally fall back to `"en"` inside `LocalizationManager`.
3. `Platform` also connects its own `sdk_ready` signal to
   `sync_language_to_localization()`, so the language is refreshed again
   once `window.ysdk.environment` actually becomes available (it is not
   known before the SDK finishes initializing).

## Gameplay lifecycle hooks

- `Platform.game_ready()` is called once from `app.gd` right after the first
  screen (main menu) is shown.
- `Platform.gameplay_start()` is called from `game_screen.gd._start_new_battle()`
  — the single place every new level/battle begins.
- `Platform.gameplay_stop()` is called from `game_screen.gd._show_battle_result()`
  — the single place a battle result (victory or defeat) is first shown.

The "continue after defeat" flow (`_grant_continue_moves` /
`_resume_after_continue`) does **not** call `gameplay_start()` again yet;
if a later stage wants `GameplayAPI` to track continued play as part of the
same session, wire it there.

## Ad foundation (Stage 69.1)

Signals available on both `YandexBridge` and `Platform`:
`rewarded_ad_opened`, `rewarded_ad_rewarded`, `rewarded_ad_closed(was_shown)`,
`rewarded_ad_error(message)`, `fullscreen_ad_opened`,
`fullscreen_ad_closed(was_shown)`, `fullscreen_ad_error(message)`.

## Rewarded ads (Stage 69.2)

Two placements now call `Platform.show_rewarded_ad(placement_id)`:

- `"lose_continue"` — `LoseContinuePopup`'s Watch Ad button, wired from
  `game_screen.gd._try_continue_with_ad()`.
- `"shop_offer_gems_3"` — the Offers tab's "+3 Gems watch AD" tile
  (`offer_watch_ad`), wired from `shop_screen.gd._start_shop_rewarded_ad()`.

Neither `GameScreen` nor `ShopScreen` calls `YandexBridge` or
`JavaScriptBridge` — both go through `Platform` only, per the platform
boundary rule.

**Reward gating.** The reward (+3 continue moves / +3 gems) is granted
exactly once, from each screen's `_on_platform_rewarded_ad_rewarded()`
handler — never from the button-press handler and never from the
`rewarded_ad_closed` handler. A local `_..._ad_rewarded` flag on each screen
guards against a duplicate `rewarded_ad_rewarded` signal granting twice.
`rewarded_ad_closed`/`rewarded_ad_error` only ever unlock the UI again and,
for a successful reward, hide the popup / resume play (`GameScreen`) or show
the success message and refresh the wallet (`ShopScreen`) — they never grant
anything themselves.

**No cross-screen leakage.** Each screen only reacts to `Platform`'s
rewarded-ad signals while its own `_..._ad_active` flag is `true` (set right
before calling `show_rewarded_ad()`, cleared on `closed`/`error`). Since
`ScreenRouter.change_screen()` frees the previous screen — which Godot
auto-disconnects signals from — `GameScreen` and `ShopScreen` are never both
listening at once, so a signal from one screen's ad attempt cannot be
picked up by the other.

**UI locking during an attempt.** `LoseContinuePopup.set_actions_enabled()`
disables Watch Ad/Buy Moves/Close; `ShopProductTile.set_buy_enabled()`
disables just the ad-offer tile's buy button. Both re-enable on
`rewarded_ad_closed` (without reward) or `rewarded_ad_error`; on a
successful `lose_continue` reward the popup is hidden instead of
re-enabled.

**Audio.** `AudioManager.pause_for_ad()`/`resume_after_ad()` mute the
Music/SFX buses around an ad without touching the player's Music/Sound
Effects settings toggles — `resume_after_ad()` never restarts music the
player had turned off, since it only unmutes the bus rather than calling
`play_main_music()`.

**`LocalDebugPlatform` simulates the whole flow** (open → rewarded → closed,
always succeeding on a short timer), so both placements are fully testable
in the editor with no Yandex SDK.

Fullscreen ads remain foundation-only — no placement was added this stage.

## Payment foundation (Stage 69.1)

Signals: `payment_purchase_started(product_id)`,
`payment_purchase_success(product_id, purchase_token)`,
`payment_purchase_cancelled(product_id)`,
`payment_purchase_error(product_id, message)`,
`payment_consume_success(purchase_token)` (Stage 69.3.1),
`payment_consume_error(purchase_token, message)` (Stage 69.3.1),
`payment_catalog_loaded(products)`, `payment_catalog_error(message)`,
`unprocessed_purchase_found(product_id, purchase_token)`,
`unprocessed_purchase_check_completed`,
`unprocessed_purchase_check_error(message)`.

Methods: `load_payment_catalog()`, `purchase_product(platform_product_id,
local_product_id = "")`, `consume_purchase(purchase_token)`,
`check_unprocessed_purchases()`, `get_cached_payment_catalog()`,
`get_catalog_product(local_product_id)`.

`YandexBridge` caches catalog products by their Yandex product id, with
`id`, `title`, `description`, `price`, `priceValue`, `priceCurrencyCode`,
and `priceCurrencyImage` when the SDK provides them. A failed or timed-out
catalog load emits `payment_catalog_error` and leaves the cache empty.

## Client-side payments mode (Stage 69.3)

Every `getPayments()` call in `YandexBridge` (purchase, consume,
`getPurchases`, `getCatalog`) intentionally omits `{ signed: true }`.
Signed mode is for server-side purchase-receipt verification; this project
has no verification server, so it stays in plain client-side mode, which
returns directly usable `productID`/`purchaseToken` fields to
`purchase()`/`getPurchases()` callers without needing a signature to be
checked anywhere.

## Yandex payments integration (Stage 69.3)

Real purchases are wired into `ShopScreen` for every `EXTERNAL_PAYMENT`
shop item except the rewarded-ad offer.

**Local item id → Yandex product id mapping.** `ShopItemConfig` gained a
`platform_product_ids: Dictionary` field (e.g. `{"yandex": "gems_50"}`)
with `get_platform_product_id(platform_key)`/`has_platform_product_id(platform_key)`
helpers. `ShopCatalog` sets this mapping for every gem product
(`gems_50`/`150`/`250`/`500`), bundle (`bundle_small`/`medium`/`large`/`mega`),
and paid offer (`offer_gems`, `offer_mega_gems`, `offer_boosters`) — each
item's own `item_id` doubles as its Yandex product id in this project.
`offer_watch_ad` explicitly gets **no** mapping and stays `AD_WATCH`/rewarded-ad
based (placement `"shop_offer_gems_3"`, unchanged from Stage 69.2).
`ShopCatalog.get_item_by_platform_product_id("yandex", platform_product_id)`
is the reverse lookup, used whenever a Platform signal only carries the
platform's product id (e.g. an unprocessed purchase).

**Payment catalog loading and price display.** `ShopScreen` connects
`Platform`'s payment signals and calls `Platform.load_payment_catalog()` in
`_ready()`, after building every tile (so `payment_catalog_loaded` — which
can fire synchronously from `LocalDebugPlatform`/`YandexBridge` — always has
a listener and populated `_payment_tiles` to react against). Every
external-payment `ShopProductTile` starts locked with `"..."` loading text
(new `ShopProductTile.set_price_text()`/small `%PriceLabel`, hidden by
default so the untouched rewarded-ad tile looks exactly as before). On
`payment_catalog_loaded`, each tile looks up its Yandex product id in
`Platform.get_cached_payment_catalog()`: a match shows that product's
catalog `price` string and enables the buy button; no match (or
`payment_catalog_error`) shows a localized "not available" state and keeps
the button disabled. Real money prices are **never hardcoded** — the label
only ever shows text that came from the catalog.

**Purchase flow.** Clicking an enabled external-payment tile calls
`shop_screen.gd._start_payment_purchase()`, which calls
`Platform.purchase_product(platform_product_id, item_id)` — never
`YandexBridge`/`JavaScriptBridge` directly. `payment_purchase_started`
locks that tile's button and shows localized "purchase started" feedback.

**Grant/consume orchestration** for `payment_purchase_success` and
`unprocessed_purchase_found` was fully reworked in Stage 69.3.1 (below) —
see that section for the current atomic grant, consume-tracking, and
retry design. The original Stage 69.3 implementation (a `ShopPlatformPurchaseHandler`
calling `ProgressManager.add_currency()`/`add_booster()` per-reward, each
saving independently) has been replaced.

**Local booster purchases are completely untouched** — they still go
through `ShopPurchaseResolver`/`CURRENCY` purchase kind, no `Platform` call,
no catalog dependency, no platform product id.

## Payment reliability and atomic grant (Stage 69.3.1)

Stage 69.3 could, in principle, leave a purchase half-applied: a bundle's
five rewards were each granted (and saved) through separate
`ProgressManager.add_currency()`/`add_booster()` calls, and the processed-token
mark was a further save after that — an interrupted app or a mid-sequence
save failure could grant some rewards but not others, or grant rewards
without ever marking the token processed (risking a duplicate grant later).
Stage 69.3.1 makes the whole grant atomic and makes consume failures
recoverable without ever re-granting.

**Atomic grant: candidate copy, one save, replace-on-success.** New
`ProgressManager.apply_platform_purchase_atomic(item, purchase_token,
platform_product_id) -> Dictionary` is now the single entry point for
granting a paid item's rewards:

1. Validate the item, token, and every reward *before* touching anything.
2. If the token is already processed, just make sure it's tracked in
   `pending_consume_tokens` (for a consume retry) and return
   `"already_granted"` — no reward is ever re-applied.
3. Otherwise, build an isolated copy of the live progress
   (`PlayerProgress.duplicate_progress()`, routed through
   `to_dictionary()`/`from_dictionary()` so nothing is shared by reference
   with the original), apply every reward to *that copy*, mark the token
   processed on the copy, and record it in the copy's
   `pending_consume_tokens`.
4. Save the copy once (`SaveManager.save_progress()`). Only if that save
   succeeds does `progress = candidate` replace the live progress. If it
   fails, the live progress is completely untouched and the result status
   is `"save_failed"`.

Result statuses: `granted`, `already_granted`, `invalid_token`,
`invalid_item`, `invalid_reward`, `save_failed`. A paid item's rewards can
never be partially saved — either the whole candidate (every reward +
processed mark + pending-consume record) commits in one `save()`, or the
live progress doesn't change at all.

**Processed vs. pending-consume token state.** `PlayerProgress` now tracks
two related but distinct token sets:

- `processed_purchase_tokens` (unchanged from Stage 69.3, capped at 500
  oldest-first) — "this token's reward has been granted, ever."
- `pending_consume_tokens: Dictionary` (token → `{"product_id", "item_id"}`,
  **never capped** — losing an entry here would leave a real purchase
  permanently unconfirmed with the SDK) — "this token's reward was granted
  but `Platform.consume_purchase()` hasn't succeeded for it yet." New
  `PlayerProgress`/`ProgressManager` methods: `has_pending_consume_token()`,
  `add_pending_consume_token()`, `remove_pending_consume_token()`,
  `get_pending_consume_tokens()`. Both sets serialize into the save file;
  an old save without `pending_consume_tokens` loads with an empty
  Dictionary — no version bump needed, matching how `processed_purchase_tokens`
  was added in Stage 69.3.

**`payment_consume_success(purchase_token)`/`payment_consume_error(purchase_token,
message)`** are new signals on `PlatformServices`/`Platform`/`WebYandexPlatform`/
`LocalDebugPlatform`/`YandexBridge`. `YandexBridge.consume_purchase()` now
keeps JS callbacks referenced, calls `payments.consumePurchase(token)`, and
only emits success once the promise actually resolves — a rejection (or a
thrown/missing `getPayments()`) emits `payment_consume_error` with the
underlying message instead of being silently swallowed; an empty token is
rejected immediately with `"invalid_token"`. `LocalDebugPlatform.consume_purchase()`
simulates success by default, with an opt-in `debug_consume_should_fail`
flag (default `false`) for manually exercising the retry path.

**New `res://scripts/game/shop/platform_purchase_coordinator.gd`
(`PlatformPurchaseCoordinator`)** is now the single owner of
`payment_purchase_success`/`cancelled`/`error`, `payment_consume_success`/`error`,
and `unprocessed_purchase_found`. Neither `ShopScreen` nor `App` grant
rewards, mark tokens, or call `Platform.consume_purchase()` directly
anymore — `ShopPlatformPurchaseHandler` was deleted.

- **Live purchase** (`payment_purchase_success`): resolves the local item
  via `ShopCatalog.get_item_by_platform_product_id("yandex", product_id)`,
  calls `apply_platform_purchase_atomic()`, and on `granted`/`already_granted`
  requests `Platform.consume_purchase(token)` — never on any other status.
- **Restored purchase** (`unprocessed_purchase_found`): identical atomic-grant
  call. An unknown product id (no local item maps to it) is never granted or
  consumed — it's simply ignored.
- **Already-granted retry:** when `apply_platform_purchase_atomic()` returns
  `"already_granted"` (the token was processed by an earlier attempt whose
  consume never confirmed), the coordinator requests consume again but
  applies zero rewards — an already-granted purchase can never grant twice,
  only its consume gets retried.
- **UI-facing signals** (`purchase_reward_granted`, `purchase_already_granted`,
  `purchase_cancelled`, `purchase_failed`, `purchase_consume_pending`,
  `purchase_completed`) only fire for the item a screen marked via
  `start_foreground_purchase(item_id)` right before calling
  `Platform.purchase_product()` — a restored/background purchase (or one for
  a different item) never surfaces UI feedback, matching "ShopScreen shows
  feedback only for active foreground purchases."

**Retry rules.** `App._bootstrap_platform()` calls
`PlatformPurchaseCoordinator.retry_pending_consume_tokens()` once, right
after `Platform.check_unprocessed_purchases()`, attempting every token still
in `pending_consume_tokens` from a previous session. A `_consume_in_flight`
set dedupes concurrent requests for the same token within one session (so
neither the startup retry nor a same-session `unprocessed_purchase_found`
for the same token can double-request consume); on `payment_consume_error`
the token simply stays pending, picked up again on the next launch or the
next `check_unprocessed_purchases()` scan. On `payment_consume_success` the
token is removed from `pending_consume_tokens` (one `save()`), and
`purchase_completed(item_id)` fires if that purchase still belongs to the
active foreground item.

**`ShopScreen` simplification.** It now only: loads/displays the payment
catalog, starts a purchase (`Platform.purchase_product()`, after telling the
coordinator which item is foreground), locks/unlocks the clicked tile, shows
localized feedback, refreshes the wallet, and plays purchase audio — driven
entirely by `PlatformPurchaseCoordinator`'s signals via a `set_purchase_coordinator()`
setter (`App` passes its one coordinator instance in when showing the shop
screen). It never applies rewards, marks tokens, or calls
`Platform.consume_purchase()`.

**`App` simplification.** Builds one `ShopCatalog`/`PlatformPurchaseCoordinator`
pair at startup, calls `coordinator.connect_platform(platform)` once in
`_bootstrap_platform()`, then `Platform.check_unprocessed_purchases()` and
`coordinator.retry_pending_consume_tokens()`. `App` no longer contains any
reward-granting or consume logic itself.

**New localization keys** (en/ru): `ui.shop.feedback.purchase_finalizing`,
`ui.shop.feedback.purchase_pending_confirmation`,
`ui.shop.feedback.purchase_retry_later` (the existing `ui.shop.feedback.consume_error`
from Stage 69.3 covers the same "could not finalize" state) — regenerated
into `localization_data.gd`.

Cloud save was still unimplemented as of Stage 69.3.1 — that stage was
purely about local-save purchase reliability. **Stage 69.4 adds the Yandex
cloud save foundation; see `docs/CLOUD_SAVE.md` for the full design** (local-first
policy, Player Data API flow, cloud envelope format, revision/timestamp
metadata, conflict resolution, initial reconciliation order, upload
debounce/critical uploads, 200 KB payload protection, and the
`LocalDebugPlatform` cloud backend for manual testing).

## Web SDK shell requirements

The project has **no custom Web export shell/template yet** (no
`export_presets.cfg` Web preset, no HTML shell under `res://`). This stage
adds documentation only, so the Godot project itself stays stable; the shell
is a build concern for whoever sets up the Web export.

Whatever HTML shell hosts the exported game **must** initialize the Yandex
SDK before Godot's first `window.ysdk` call — otherwise `YandexBridge`'s
readiness poll will simply time out and the game falls back to behaving as
if no SDK is present (all `Platform` calls stay safe no-ops/errors, nothing
crashes). The required flow:

```html
<script src="/sdk.js"></script>
<script>
  YaGames.init().then(function (ysdk) {
    window.ysdk = ysdk;
    window.ysdkReady = true;
  });
</script>
```

This must run, and `window.ysdkReady` must become `true`, before or
concurrently with the Godot Web build starting — `YandexBridge` polls for
up to 20 seconds after its own `_ready()`, so the SDK script tag should be
loaded as early as possible in the page, ahead of the Godot canvas/engine
script.

## What is explicitly NOT done as of Stage 69.4

- No fullscreen (interstitial) ad placements were added.
- No Web export preset or custom HTML shell file was added — only this
  documentation.
- No release/store submission audit.
- Tests were not added, updated, touched, or run for this stage.

See `docs/CLOUD_SAVE.md` for the full Stage 69.4 cloud save design.
