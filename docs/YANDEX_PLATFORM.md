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

## Ad foundation (Stage 69.1 only)

Signals available on both `YandexBridge` and `Platform`:
`rewarded_ad_opened`, `rewarded_ad_rewarded`, `rewarded_ad_closed(was_shown)`,
`rewarded_ad_error(message)`, `fullscreen_ad_opened`,
`fullscreen_ad_closed(was_shown)`, `fullscreen_ad_error(message)`.

**`LoseContinuePopup`'s existing placeholder behavior is untouched.**
`game_screen.gd._try_continue_with_ad()` still grants the continue reward
directly, with no real ad shown. Wiring `Platform.show_rewarded_ad()` into
that flow (and only granting the reward on `rewarded_ad_rewarded`) is
Stage 69.2 work.

## Payment foundation (Stage 69.1 only)

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

`check_unprocessed_purchases()` calls `payments.getPurchases()` when the SDK
is ready; each found purchase emits `unprocessed_purchase_found`, and the
scan finishes with `unprocessed_purchase_check_completed`. **No reward is
granted for unprocessed purchases yet** — reward processing is deferred to
the payments integration stage.

**`ShopScreen`'s existing `external_payment` behavior is untouched.** Gem/
bundle/offer products are still listed but not purchasable through a real
SDK. Wiring `Platform.purchase_product()`/`consume_purchase()` into
`shop_purchase_resolver.gd` is Stage 69.3 work.

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

## What is explicitly NOT done in Stage 69.1

- No real rewarded-ad gameplay integration — `LoseContinuePopup`'s
  placeholder flow is untouched.
- No real shop payment integration — `ShopScreen`'s `external_payment`
  behavior is untouched.
- No cloud save flow — only placeholder signals/methods exist on
  `PlatformServices` for a future stage to implement.
- No unprocessed-purchase reward granting.
- No Web export preset or custom HTML shell file was added — only this
  documentation.
- Tests were not added, updated, touched, or run for this stage.
