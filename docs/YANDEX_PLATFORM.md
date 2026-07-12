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

**Grant order on `payment_purchase_success(product_id, purchase_token)`:**
grant rewards → save progress → consume purchase — enforced by new
`res://scripts/game/shop/shop_platform_purchase_handler.gd`
(`ShopPlatformPurchaseHandler`, deliberately independent of `ShopScreen`'s
UI so `App` can reuse it too). Its `grant_purchase(item_id, purchase_token)`
looks up the local item, applies every currency/booster reward through the
existing `ProgressManager.add_currency()`/`add_booster()` APIs (which each
save), marks the token processed, and returns `true` only if it actually
granted something. `ShopScreen` calls `Platform.consume_purchase()` **only**
if `grant_purchase()` returned `true` — a failed grant leaves the token
unconsumed so it can be recovered later via `check_unprocessed_purchases()`,
and shows "purchase error" feedback instead. Success shows localized
"Purchased!" feedback, refreshes the wallet, and plays the existing
purchase-success sound.

**Duplicate-grant protection.** `PlayerProgress` gained a
`processed_purchase_tokens` set (capped at 500 oldest-first, persisted in
the save file) with `has_processed_purchase_token(token)`/
`mark_processed_purchase_token(token)`, wrapped on `ProgressManager`.
`grant_purchase()` checks this before granting anything, so the same
`purchase_token` can never grant twice — whether it arrives twice from a
live `payment_purchase_success`, or once live and once later from an
unprocessed-purchase restore.

**Cancel/error handling.** `payment_purchase_cancelled`/`payment_purchase_error`
never grant anything or consume anything; they just re-enable the tile and
show localized "cancelled"/"error" feedback. All four purchase-lifecycle
handlers ignore a `product_id` that doesn't match the screen's own pending
purchase, the same no-cross-leakage pattern Stage 69.2 established for ads.

**Unprocessed purchase restoration.** `app.gd` now builds its own
`ShopCatalog`/`ShopPlatformPurchaseHandler` pair at startup, connects
`Platform.unprocessed_purchase_found`, and calls
`Platform.check_unprocessed_purchases()` right after `game_ready()` — so a
purchase that completed but was never consumed (app closed mid-flow,
`ShopScreen` never reopened) still gets granted, saved, and consumed the
next time the app starts, with no shop UI involved and no noisy feedback.

**Local booster purchases are completely untouched** — they still go
through `ShopPurchaseResolver`/`CURRENCY` purchase kind, no `Platform` call,
no catalog dependency, no platform product id.

**`LocalDebugPlatform`** exposes a small `MOCK_CATALOG_PRODUCT_IDS` mock
catalog (placeholder `"Debug"` price text, never real money) that only
populates when `debug_purchases_enabled` is explicitly set to `true` on the
instance; with it `false` (the default), every external-payment tile stays
disabled/"not available" exactly like before this stage. When enabled,
`purchase_product()` still emits the same `payment_purchase_started`/
`payment_purchase_success` signals a real Yandex purchase would, so it
exercises the exact same grant → save → consume path as a real purchase.

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

## What is explicitly NOT done as of Stage 69.3

- No cloud save flow — only placeholder signals/methods exist on
  `PlatformServices` for a future stage to implement.
- No fullscreen (interstitial) ad placements were added.
- No Web export preset or custom HTML shell file was added — only this
  documentation.
- Tests were not added, updated, touched, or run for this stage.
