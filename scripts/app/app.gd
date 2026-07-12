extends Control

const MAIN_MENU_SCREEN := preload("res://scenes/screens/MainMenuScreen.tscn")
const LEVEL_SELECT_SCREEN := preload("res://scenes/screens/LevelSelectScreen.tscn")
const GAME_SCREEN := preload("res://scenes/screens/GameScreen.tscn")
const UPGRADE_SCREEN := preload("res://scenes/screens/UpgradeScreen.tscn")
const TEAM_SELECT_SCREEN := preload("res://scenes/screens/TeamSelectScreen.tscn")
const SETTINGS_SCREEN := preload("res://scenes/screens/SettingsScreen.tscn")
const SHOP_SCREEN := preload("res://scenes/screens/ShopScreen.tscn")
const PROGRESS_MANAGER_SCRIPT := preload("res://scripts/game/progression/progress_manager.gd")
const SETTINGS_MANAGER_SCRIPT := preload("res://scripts/game/settings/settings_manager.gd")
const LEVEL_CATALOG_SCRIPT := preload("res://scripts/game/config/level_catalog.gd")
const PLAY_LEVEL_RESOLVER_SCRIPT := preload("res://scripts/game/progression/play_level_resolver.gd")
const SHOP_CATALOG_SCRIPT := preload("res://scripts/game/shop/shop_catalog.gd")
const PLATFORM_PURCHASE_COORDINATOR_SCRIPT := preload("res://scripts/game/shop/platform_purchase_coordinator.gd")
const CLOUD_SAVE_COORDINATOR_SCRIPT := preload("res://scripts/game/save/cloud_save_coordinator.gd")

@onready var screen_host: Control = %ScreenHost

var _router: ScreenRouter
var _progress_manager
var _settings_manager
var _level_catalog
var _play_level_resolver
var _settings_return_screen := "main_menu"
var _shop_catalog
var _purchase_coordinator
var _cloud_save_coordinator


## Stage 69.4: startup order matters here — local progress loads and the
## first screen shows before Platform/cloud is touched at all, so a slow or
## unavailable network never delays getting into the game. See
## _bootstrap_platform() for the cloud-reconciliation-then-purchase-recovery
## ordering that follows.
func _ready() -> void:
	_router = ScreenRouter.new(screen_host)
	_progress_manager = PROGRESS_MANAGER_SCRIPT.new()
	_progress_manager.load()
	_settings_manager = SETTINGS_MANAGER_SCRIPT.new()
	_settings_manager.load()
	_level_catalog = LEVEL_CATALOG_SCRIPT.new()
	_play_level_resolver = PLAY_LEVEL_RESOLVER_SCRIPT.new()
	_shop_catalog = SHOP_CATALOG_SCRIPT.new(get_node_or_null("/root/LocalizationManager"))
	_purchase_coordinator = PLATFORM_PURCHASE_COORDINATOR_SCRIPT.new(_shop_catalog, _progress_manager)
	_apply_audio_settings()
	_show_main_menu()
	_bootstrap_platform()


## Stage 69.1: platform foundation bootstrap. Syncs LocalizationManager to
## the platform's reported language (falls back to LocalizationManager's own
## default when the platform has none yet) and signals the platform that the
## first screen is up. Platform itself re-syncs the language whenever the
## Yandex SDK becomes ready, since its language is only known once
## window.ysdk.environment exists.
##
## Stage 69.4: cloud reconciliation now runs before purchase recovery.
## CloudSaveCoordinator may apply a cloud snapshot that replaces local
## progress (including its purchase-token ledgers), so starting
## PlatformPurchaseCoordinator's unprocessed-purchase/consume-retry recovery
## before that finishes could recover purchases against a progress snapshot
## that's about to be discarded. `await`s the coordinator's own signal
## rather than blocking _ready() itself — this whole function is fire-and-
## forget from _ready()'s point of view, so a slow/unavailable network only
## delays purchase recovery and the cloud mirror, never entering the game.
func _bootstrap_platform() -> void:
	var platform := get_node_or_null("/root/Platform")
	if platform == null:
		return
	platform.sync_language_to_localization()
	platform.game_ready()

	_cloud_save_coordinator = CLOUD_SAVE_COORDINATOR_SCRIPT.new(_progress_manager, platform)
	_cloud_save_coordinator.initial_reconciliation_completed.connect(_on_initial_cloud_reconciliation_completed)
	_cloud_save_coordinator.start_initial_reconciliation()
	# LocalDebugPlatform (and an unavailable/null platform) can finish
	# reconciliation synchronously inside start_initial_reconciliation()
	# above, before this line runs — awaiting the signal unconditionally in
	# that case would hang forever, since `await` only ever catches a
	# *future* emission.
	if not _cloud_save_coordinator.is_initial_reconciliation_completed():
		await _cloud_save_coordinator.initial_reconciliation_completed

	_purchase_coordinator.connect_platform(platform)
	platform.check_unprocessed_purchases()
	_purchase_coordinator.retry_pending_consume_tokens()


## Stage 69.4: only "cloud" means local progress was actually replaced.
## Refreshes whichever screen is currently visible through its existing
## refresh_progress_state() API rather than recreating it — GameScreen has
## no such method, so an active level is left completely alone by this
## has_method() gate; the reconciled progress still applies the moment the
## player next saves or opens a screen that does refresh (LevelSelect, Shop,
## MainMenu, results).
func _on_initial_cloud_reconciliation_completed(result: String) -> void:
	if result != "cloud":
		return
	var screen := _router.get_current_screen()
	if screen != null and screen.has_method("refresh_progress_state"):
		screen.refresh_progress_state()


func _show_main_menu() -> void:
	var screen := _router.change_screen(MAIN_MENU_SCREEN)
	if screen.has_method("set_progress_manager"):
		screen.set_progress_manager(_progress_manager)
	if screen.has_method("refresh_progress_state"):
		screen.refresh_progress_state()
	screen.play_pressed.connect(_on_main_menu_play_pressed)
	screen.level_select_pressed.connect(_on_main_menu_level_select_pressed)
	screen.shop_pressed.connect(_on_main_menu_shop_pressed)
	screen.heroes_pressed.connect(_on_upgrades_pressed)
	screen.settings_pressed.connect(_on_main_menu_settings_pressed)


func _show_level_select() -> void:
	var screen := _router.change_screen(LEVEL_SELECT_SCREEN)
	if screen.has_method("set_progress_manager"):
		screen.set_progress_manager(_progress_manager)
	if screen.has_method("set_settings_manager"):
		screen.set_settings_manager(_settings_manager)
	if screen.has_method("refresh_progress_state"):
		screen.refresh_progress_state()
	screen.level_selected.connect(_on_level_selected)
	screen.back_pressed.connect(_on_level_select_back_pressed)
	screen.settings_pressed.connect(_on_level_select_settings_pressed)


func _show_shop_screen() -> void:
	var screen := _router.change_screen(SHOP_SCREEN)
	if screen.has_method("set_progress_manager"):
		screen.set_progress_manager(_progress_manager)
	if screen.has_method("set_purchase_coordinator"):
		screen.set_purchase_coordinator(_purchase_coordinator)
	if screen.has_method("refresh_progress_state"):
		screen.refresh_progress_state()
	screen.back_pressed.connect(_on_shop_back_pressed)


func _show_game_screen(level_id: String) -> void:
	var screen := _router.change_screen(GAME_SCREEN)
	if screen.has_method("set_progress_manager"):
		screen.set_progress_manager(_progress_manager)
	if screen.has_method("set_settings_manager"):
		screen.set_settings_manager(_settings_manager)
	if screen.has_method("set_level_id"):
		screen.set_level_id(level_id)
	screen.back_pressed.connect(_on_game_back_pressed)
	screen.upgrades_pressed.connect(_on_upgrades_pressed)


func _show_upgrade_screen() -> void:
	var screen := _router.change_screen(UPGRADE_SCREEN)
	if screen.has_method("set_progress_manager"):
		screen.set_progress_manager(_progress_manager)
	if screen.has_method("set_settings_manager"):
		screen.set_settings_manager(_settings_manager)
	screen.back_pressed.connect(_on_upgrade_back_pressed)


func _show_team_select_screen(level_id: String) -> void:
	var screen := _router.change_screen(TEAM_SELECT_SCREEN)
	if screen.has_method("set_progress_manager"):
		screen.set_progress_manager(_progress_manager)
	if screen.has_method("set_settings_manager"):
		screen.set_settings_manager(_settings_manager)
	if screen.has_method("set_level_id"):
		screen.set_level_id(level_id)
	screen.back_pressed.connect(_on_team_select_back_pressed)
	screen.start_battle_pressed.connect(_on_team_start_battle_pressed)


func _show_settings_screen() -> void:
	var screen := _router.change_screen(SETTINGS_SCREEN)
	if screen.has_method("set_settings_manager"):
		screen.set_settings_manager(_settings_manager)
	screen.back_pressed.connect(_on_settings_back_pressed)


func _on_main_menu_play_pressed() -> void:
	var level_id: String = _play_level_resolver.resolve_play_level_id(_progress_manager, _level_catalog)
	_show_game_screen(level_id)


func _on_main_menu_level_select_pressed() -> void:
	_show_level_select()


func _on_main_menu_shop_pressed() -> void:
	_show_shop_screen()


func _on_main_menu_settings_pressed() -> void:
	_settings_return_screen = "main_menu"
	_show_settings_screen()


func _on_level_select_settings_pressed() -> void:
	_settings_return_screen = "level_select"
	_show_settings_screen()


func _on_level_selected(level_id: String) -> void:
	# Stage 32: hero systems are frozen, so LevelSelect opens GameScreen directly.
	# _show_team_select_screen remains available for a future hero-systems revisit.
	_show_game_screen(level_id)


func _on_team_start_battle_pressed(level_id: String) -> void:
	_show_game_screen(level_id)


func _on_upgrades_pressed() -> void:
	_show_upgrade_screen()


func _on_level_select_back_pressed() -> void:
	_show_main_menu()


func _on_shop_back_pressed() -> void:
	_show_main_menu()


func _on_game_back_pressed() -> void:
	_show_main_menu()


func _on_upgrade_back_pressed() -> void:
	_show_main_menu()


func _on_team_select_back_pressed() -> void:
	_show_level_select()


func _on_settings_back_pressed() -> void:
	if _settings_return_screen == "level_select":
		_show_level_select()
	else:
		_show_main_menu()


func _apply_audio_settings() -> void:
	if _settings_manager == null:
		return

	var settings: PlayerSettings = _settings_manager.get_settings()
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager == null:
		return
	audio_manager.set_music_enabled(settings.music_enabled)
	audio_manager.set_sound_effects_enabled(settings.sound_effects_enabled)
	audio_manager.play_main_music()
