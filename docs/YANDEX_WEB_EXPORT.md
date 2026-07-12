# Yandex Web export

Stage 69.5 adds the production-oriented **Yandex Web** preset. Export it to
`builds/yandex/index.html` using matching Godot Web export templates. The
standard Godot shell remains in use; its `html/head_include` loads `/sdk.js`,
creates `window.ysdkReadyPromise`, calls `YaGames.init()`, and only sets
`window.ysdkReady` after success.

The shell removes page margins and scrolling, disables overscroll and canvas
touch gestures/selection, focuses the canvas at launch, and blocks a context
menu only on the canvas. Portrait enforcement remains in the game.

## Release workflow

1. Install matching Godot Web export templates and export with **Yandex Web**.
2. Run `python tools/package_yandex_web.py` from the repository root.
3. Inspect `builds/yandex_release.zip`; `index.html` and all export files are
   at the ZIP root, with no parent directory.
4. Upload the ZIP to a Yandex Games draft, configure portrait orientation,
   and configure product IDs to match `ShopCatalog`.
5. In the draft, manually test ads, purchases, cloud save, tab switching, and
   reload. This Yandex-draft validation is Stage 69.6.

The helper validates the SDK bootstrap, early pause-buffer markers,
JavaScript/PCK/WASM export files, ASCII/no-space file names, and configurable
uncompressed size (default 100000000 bytes). Generated exports and ZIPs are
ignored and are never committed.

Stage 69.5.1 also uses `variant/thread_support=false`, freezes active gameplay
timelines for runtime pause, and gates terminal results behind one fullscreen
attempt per run. Draft/manual validation remains Stage 69.6; tests were not
added, updated, touched, or run.

## Runtime readiness and pause behavior

`YandexBridge` is the only JavaScript bridge owner. It queues `game_ready()`
until the SDK is ready and sends `LoadingAPI.ready()` once per session. It
keeps only the latest desired GameplayAPI state, applying it after readiness.
Cloud reconciliation waits once for `Platform.sdk_ready` on Web, then falls
back to local progress after its bounded timeout; late cloud data is ignored.

Yandex Game API and browser focus events become pause reasons. The app-wide
`PlatformRuntimeCoordinator` blocks active GameScreen input while any reason
is present, and resumes only an active battle after every reason clears.
Audio uses the same reason set, so rewarded-ad and platform pause signals
cannot prematurely unmute buses or change player audio preferences.
