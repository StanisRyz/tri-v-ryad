extends Control

signal back_pressed

const SHOP_CATALOG_SCRIPT := preload("res://scripts/game/shop/shop_catalog.gd")
const SHOP_ITEM_CATEGORY_SCRIPT := preload("res://scripts/game/shop/shop_item_category.gd")
const SHOP_PURCHASE_RESOLVER_SCRIPT := preload("res://scripts/game/shop/shop_purchase_resolver.gd")
const SHOP_PURCHASE_FORMATTER_SCRIPT := preload("res://scripts/game/shop/shop_purchase_formatter.gd")
const SHOP_REWARD_TYPE_SCRIPT := preload("res://scripts/game/shop/shop_reward_type.gd")
const SHOP_PURCHASE_KIND_SCRIPT := preload("res://scripts/game/shop/shop_purchase_kind.gd")
const CURRENCY_TYPE_SCRIPT := preload("res://scripts/game/economy/currency_type.gd")
const BOOSTER_CATALOG_SCRIPT := preload("res://scripts/game/config/booster_catalog.gd")
const ASSET_KEY_RESOLVER_SCRIPT := preload("res://scripts/game/config/asset_key_resolver.gd")
const GAME_ASSET_CATALOG := preload("res://scripts/game/config/game_asset_catalog.gd")
const SHOP_BOOSTER_TILE_SCENE := preload("res://scenes/ui/shop/ShopBoosterTile.tscn")
const SHOP_PRODUCT_TILE_SCENE := preload("res://scenes/ui/shop/ShopProductTile.tscn")
const TEXT_STYLE_APPLIER_SCRIPT := preload("res://scripts/ui/text/text_style_applier.gd")

const BOOSTER_IDS := [
	BOOSTER_CATALOG_SCRIPT.HAMMER,
	BOOSTER_CATALOG_SCRIPT.FREEZE_TIME,
	BOOSTER_CATALOG_SCRIPT.ROCKET_BARRAGE,
]

const GEM_PRODUCT_IDS := ["gems_50", "gems_150", "gems_250", "gems_500"]
const BUNDLE_IDS := ["bundle_small", "bundle_medium", "bundle_large", "bundle_mega"]
const OFFER_IDS := ["offer_watch_ad", "offer_gems", "offer_mega_gems", "offer_boosters"]
const AD_OFFER_ITEM_ID := "offer_watch_ad"
const REWARDED_AD_PLACEMENT_SHOP_OFFER_GEMS := "shop_offer_gems_3"
const PLATFORM_KEY_YANDEX := "yandex"

@onready var background_rect: FallbackImageSlot = %Background
@onready var shop_window_visual: FallbackImageSlot = %WindowVisual
@onready var back_button: PressableTextureButton = %BackButton
@onready var boosters_tab_button: ShopTabButton = %BoostersTabButton
@onready var gems_tab_button: ShopTabButton = %GemsTabButton
@onready var bundles_tab_button: ShopTabButton = %BundlesTabButton
@onready var offers_tab_button: ShopTabButton = %OffersTabButton
@onready var gold_label: Label = %GoldLabel
@onready var gems_label: Label = %GemsLabel
@onready var boosters_content: Control = %BoostersContent
@onready var gems_content: Control = %GemsContent
@onready var bundles_content: Control = %BundlesContent
@onready var offers_content: Control = %OffersContent
@onready var feedback_label: Label = %FeedbackLabel

var _progress_manager
var _shop_catalog
var _purchase_resolver = SHOP_PURCHASE_RESOLVER_SCRIPT.new()
var _selected_category := SHOP_ITEM_CATEGORY_SCRIPT.BOOSTERS
var _ad_offer_tile: ShopProductTile
var _shop_ad_active := false
var _shop_ad_rewarded := false
var _shop_ad_item_id := ""
var _purchase_coordinator
var _payment_tiles: Dictionary = {}
var _payment_catalog: Dictionary = {}
var _payment_catalog_ready := false
var _pending_payment_item_id := ""
var _pending_payment_product_id := ""


func _ready() -> void:
	_shop_catalog = SHOP_CATALOG_SCRIPT.new(get_node_or_null("/root/LocalizationManager"))
	_bind_static_ui_assets()
	back_button.delayed_pressed.connect(_on_back_button_delayed_pressed)
	boosters_tab_button.pressed.connect(_on_boosters_tab_pressed)
	gems_tab_button.pressed.connect(_on_gems_tab_pressed)
	bundles_tab_button.pressed.connect(_on_bundles_tab_pressed)
	offers_tab_button.pressed.connect(_on_offers_tab_pressed)
	feedback_label.text = ""
	_build_boosters_content()
	_build_gems_content()
	_build_bundles_content()
	_build_offers_content()
	_refresh_wallet()
	_show_category(_selected_category)
	_localize_ui()
	_apply_text_styles()
	var localization_manager := get_node_or_null("/root/LocalizationManager")
	if localization_manager != null:
		localization_manager.language_changed.connect(_localize_ui)
	_connect_platform_rewarded_ad_signals()
	_connect_platform_payment_signals()


## Stage 69.2: Offers tab "+3 Gems watch AD" routes through
## Platform.show_rewarded_ad(REWARDED_AD_PLACEMENT_SHOP_OFFER_GEMS). Same
## auto-disconnect-on-screen-change reasoning as GameScreen's identical
## helper — see game_screen.gd._connect_platform_rewarded_ad_signals().
func _connect_platform_rewarded_ad_signals() -> void:
	var platform := get_node_or_null("/root/Platform")
	if platform == null:
		return
	if not platform.rewarded_ad_opened.is_connected(_on_platform_rewarded_ad_opened):
		platform.rewarded_ad_opened.connect(_on_platform_rewarded_ad_opened)
	if not platform.rewarded_ad_rewarded.is_connected(_on_platform_rewarded_ad_rewarded):
		platform.rewarded_ad_rewarded.connect(_on_platform_rewarded_ad_rewarded)
	if not platform.rewarded_ad_closed.is_connected(_on_platform_rewarded_ad_closed):
		platform.rewarded_ad_closed.connect(_on_platform_rewarded_ad_closed)
	if not platform.rewarded_ad_error.is_connected(_on_platform_rewarded_ad_error):
		platform.rewarded_ad_error.connect(_on_platform_rewarded_ad_error)


func _apply_text_styles() -> void:
	TEXT_STYLE_APPLIER_SCRIPT.apply_to_label(gold_label, "shop.wallet")
	TEXT_STYLE_APPLIER_SCRIPT.apply_to_label(gems_label, "shop.wallet")
	TEXT_STYLE_APPLIER_SCRIPT.apply_to_label(feedback_label, "shop.feedback")
	TEXT_STYLE_APPLIER_SCRIPT.apply_to_child_label(boosters_tab_button, "TextMargin/Label", "shop.tab")
	TEXT_STYLE_APPLIER_SCRIPT.apply_to_child_label(gems_tab_button, "TextMargin/Label", "shop.tab")
	TEXT_STYLE_APPLIER_SCRIPT.apply_to_child_label(bundles_tab_button, "TextMargin/Label", "shop.tab")
	TEXT_STYLE_APPLIER_SCRIPT.apply_to_child_label(offers_tab_button, "TextMargin/Label", "shop.tab")
	TEXT_STYLE_APPLIER_SCRIPT.apply_to_child_label(back_button, "TextMargin/Label", "global.button")


func set_progress_manager(progress_manager) -> void:
	_progress_manager = progress_manager
	if is_inside_tree():
		_refresh_wallet()


## Stage 69.3.1: PlatformPurchaseCoordinator is the single owner of the
## payment_purchase_success/cancelled/error and payment_consume_success/error
## lifecycle — ShopScreen only starts a purchase and reacts to the
## coordinator's UI-facing signals (see _connect_purchase_coordinator_signals()).
func set_purchase_coordinator(purchase_coordinator) -> void:
	_purchase_coordinator = purchase_coordinator
	_connect_purchase_coordinator_signals()


func refresh_progress_state() -> void:
	if is_inside_tree():
		_refresh_wallet()


func _bind_static_ui_assets() -> void:
	_bind_texture_slot(background_rect, "shared_background")
	_bind_texture_slot(shop_window_visual, "shop_window")
	_bind_back_button_textures()
	_bind_tab_button_textures()


func _bind_texture_slot(slot: FallbackImageSlot, ui_id: String) -> void:
	if slot == null or slot.texture != null:
		return
	var texture := GAME_ASSET_CATALOG.try_load_texture_cached(ASSET_KEY_RESOLVER_SCRIPT.get_ui_asset_key(ui_id))
	if texture != null:
		slot.texture = texture


func _bind_back_button_textures() -> void:
	if back_button == null:
		return

	if back_button.normal_texture == null:
		var normal_texture := GAME_ASSET_CATALOG.try_load_texture_cached(ASSET_KEY_RESOLVER_SCRIPT.get_ui_asset_key("shared_back_button_default"))
		if normal_texture != null:
			back_button.set_normal_texture(normal_texture)

	if back_button.pressed_texture == null:
		var pressed_texture := GAME_ASSET_CATALOG.try_load_texture_cached(ASSET_KEY_RESOLVER_SCRIPT.get_ui_asset_key("shared_back_button_pressed"))
		if pressed_texture != null:
			back_button.set_pressed_texture(pressed_texture)


func _bind_tab_button_textures() -> void:
	var default_texture := GAME_ASSET_CATALOG.try_load_texture_cached(ASSET_KEY_RESOLVER_SCRIPT.get_ui_asset_key("shop_tab_default"))
	var selected_texture := GAME_ASSET_CATALOG.try_load_texture_cached(ASSET_KEY_RESOLVER_SCRIPT.get_ui_asset_key("shop_tab_pressed"))
	for tab_button in [boosters_tab_button, gems_tab_button, bundles_tab_button, offers_tab_button]:
		if tab_button == null:
			continue
		if tab_button.default_texture == null and default_texture != null:
			tab_button.default_texture = default_texture
		if tab_button.selected_texture == null and selected_texture != null:
			tab_button.selected_texture = selected_texture


func _refresh_wallet() -> void:
	if gold_label == null or gems_label == null:
		return

	var gold := 0
	var gems := 0
	if _progress_manager != null:
		gold = _progress_manager.get_currency(CURRENCY_TYPE_SCRIPT.GOLD)
		gems = _progress_manager.get_currency(CURRENCY_TYPE_SCRIPT.GEMS)

	var localization_manager := get_node_or_null("/root/LocalizationManager")
	if localization_manager != null:
		gold_label.text = localization_manager.format_key("ui.common.gold", {"gold": gold})
		gems_label.text = localization_manager.format_key("ui.common.gems", {"gems": gems})
	else:
		gold_label.text = "Gold: %d" % gold
		gems_label.text = "Gems: %d" % gems


func _localize_ui() -> void:
	var localization_manager := get_node_or_null("/root/LocalizationManager")
	if localization_manager == null:
		return
	boosters_tab_button.set_button_text(localization_manager.tr_key("ui.shop.tab.boosters"))
	gems_tab_button.set_button_text(localization_manager.tr_key("ui.shop.tab.gems"))
	bundles_tab_button.set_button_text(localization_manager.tr_key("ui.shop.tab.bundles"))
	offers_tab_button.set_button_text(localization_manager.tr_key("ui.shop.tab.offers"))
	if back_button != null:
		back_button.button_text = localization_manager.tr_key("ui.common.back")


func _show_category(category: String) -> void:
	_selected_category = category
	_update_tab_visuals()
	boosters_content.visible = category == SHOP_ITEM_CATEGORY_SCRIPT.BOOSTERS
	gems_content.visible = category == SHOP_ITEM_CATEGORY_SCRIPT.GEMS
	bundles_content.visible = category == SHOP_ITEM_CATEGORY_SCRIPT.BUNDLES
	offers_content.visible = category == SHOP_ITEM_CATEGORY_SCRIPT.OFFERS


func _update_tab_visuals() -> void:
	boosters_tab_button.set_selected(_selected_category == SHOP_ITEM_CATEGORY_SCRIPT.BOOSTERS)
	gems_tab_button.set_selected(_selected_category == SHOP_ITEM_CATEGORY_SCRIPT.GEMS)
	bundles_tab_button.set_selected(_selected_category == SHOP_ITEM_CATEGORY_SCRIPT.BUNDLES)
	offers_tab_button.set_selected(_selected_category == SHOP_ITEM_CATEGORY_SCRIPT.OFFERS)


func _build_boosters_content() -> void:
	if boosters_content == null:
		return

	var top_row := boosters_content.get_node_or_null("TopRow")
	var bottom_row := boosters_content.get_node_or_null("BottomRow")
	if top_row == null or bottom_row == null:
		return

	for booster_id in BOOSTER_IDS:
		_add_booster_tile(top_row, "booster_%s_gold" % booster_id, booster_id)
	for booster_id in BOOSTER_IDS:
		_add_booster_tile(bottom_row, "booster_%s_gems" % booster_id, booster_id)


func _add_booster_tile(row: Node, item_id: String, booster_id: String) -> void:
	var item = _shop_catalog.get_item(item_id)
	if item == null:
		return

	var tile: ShopBoosterTile = SHOP_BOOSTER_TILE_SCENE.instantiate()
	row.add_child(tile)
	var icon := GAME_ASSET_CATALOG.try_load_texture_cached(ASSET_KEY_RESOLVER_SCRIPT.get_shop_booster_tile_icon_asset_key(booster_id))
	tile.set_item(item, icon)
	tile.buy_pressed.connect(_on_booster_buy_pressed)


func _build_gems_content() -> void:
	if gems_content == null:
		return

	var row1 := gems_content.get_node_or_null("Row1")
	var row2 := gems_content.get_node_or_null("Row2")
	if row1 == null or row2 == null:
		return

	_add_product_tile(row1, GEM_PRODUCT_IDS[0], ASSET_KEY_RESOLVER_SCRIPT.get_shop_gem_product_icon_asset_key(GEM_PRODUCT_IDS[0]))
	_add_product_tile(row1, GEM_PRODUCT_IDS[1], ASSET_KEY_RESOLVER_SCRIPT.get_shop_gem_product_icon_asset_key(GEM_PRODUCT_IDS[1]))
	_add_product_tile(row2, GEM_PRODUCT_IDS[2], ASSET_KEY_RESOLVER_SCRIPT.get_shop_gem_product_icon_asset_key(GEM_PRODUCT_IDS[2]))
	_add_product_tile(row2, GEM_PRODUCT_IDS[3], ASSET_KEY_RESOLVER_SCRIPT.get_shop_gem_product_icon_asset_key(GEM_PRODUCT_IDS[3]))


func _build_bundles_content() -> void:
	if bundles_content == null:
		return

	var row1 := bundles_content.get_node_or_null("Row1")
	var row2 := bundles_content.get_node_or_null("Row2")
	if row1 == null or row2 == null:
		return

	_add_product_tile(row1, BUNDLE_IDS[0], ASSET_KEY_RESOLVER_SCRIPT.get_shop_bundle_icon_asset_key(BUNDLE_IDS[0]))
	_add_product_tile(row1, BUNDLE_IDS[1], ASSET_KEY_RESOLVER_SCRIPT.get_shop_bundle_icon_asset_key(BUNDLE_IDS[1]))
	_add_product_tile(row2, BUNDLE_IDS[2], ASSET_KEY_RESOLVER_SCRIPT.get_shop_bundle_icon_asset_key(BUNDLE_IDS[2]))
	_add_product_tile(row2, BUNDLE_IDS[3], ASSET_KEY_RESOLVER_SCRIPT.get_shop_bundle_icon_asset_key(BUNDLE_IDS[3]))


func _build_offers_content() -> void:
	if offers_content == null:
		return

	var row1 := offers_content.get_node_or_null("Row1")
	var row2 := offers_content.get_node_or_null("Row2")
	if row1 == null or row2 == null:
		return

	_add_product_tile(row1, OFFER_IDS[0], ASSET_KEY_RESOLVER_SCRIPT.get_shop_offer_icon_asset_key(OFFER_IDS[0]))
	_add_product_tile(row1, OFFER_IDS[1], ASSET_KEY_RESOLVER_SCRIPT.get_shop_offer_icon_asset_key(OFFER_IDS[1]))
	_add_product_tile(row2, OFFER_IDS[2], ASSET_KEY_RESOLVER_SCRIPT.get_shop_offer_icon_asset_key(OFFER_IDS[2]))
	_add_product_tile(row2, OFFER_IDS[3], ASSET_KEY_RESOLVER_SCRIPT.get_shop_offer_icon_asset_key(OFFER_IDS[3]))


func _add_product_tile(row: Node, item_id: String, icon_asset_key: String) -> void:
	var item = _shop_catalog.get_item(item_id)
	if item == null:
		return

	var tile: ShopProductTile = SHOP_PRODUCT_TILE_SCENE.instantiate()
	row.add_child(tile)
	var icon := GAME_ASSET_CATALOG.try_load_texture_cached(icon_asset_key)
	tile.set_item(item, icon)
	tile.buy_pressed.connect(_on_product_buy_pressed)
	if item_id == AD_OFFER_ITEM_ID:
		_ad_offer_tile = tile
	elif item.purchase_kind == SHOP_PURCHASE_KIND_SCRIPT.EXTERNAL_PAYMENT:
		_payment_tiles[item_id] = tile
		tile.set_buy_enabled(false)
		tile.set_price_text(_localized_payment_feedback("ui.shop.price.loading", "..."))


func _on_boosters_tab_pressed() -> void:
	_play_button_click()
	_show_category(SHOP_ITEM_CATEGORY_SCRIPT.BOOSTERS)


func _on_gems_tab_pressed() -> void:
	_play_button_click()
	_show_category(SHOP_ITEM_CATEGORY_SCRIPT.GEMS)


func _on_bundles_tab_pressed() -> void:
	_play_button_click()
	_show_category(SHOP_ITEM_CATEGORY_SCRIPT.BUNDLES)


func _on_offers_tab_pressed() -> void:
	_play_button_click()
	_show_category(SHOP_ITEM_CATEGORY_SCRIPT.OFFERS)


func _on_booster_buy_pressed(item_id: String, quantity: int) -> void:
	_play_button_click()
	_resolve_purchase(item_id, quantity)


func _on_product_buy_pressed(item_id: String) -> void:
	_play_button_click()
	if item_id == AD_OFFER_ITEM_ID:
		_start_shop_rewarded_ad(item_id)
		return
	var item = _shop_catalog.get_item(item_id) if _shop_catalog != null else null
	if item != null and item.purchase_kind == SHOP_PURCHASE_KIND_SCRIPT.EXTERNAL_PAYMENT:
		_start_payment_purchase(item_id)
		return
	_resolve_purchase(item_id, 1)


## Stage 69.2 v0.1: "+3 Gems watch AD" offer. Gems are only granted from
## _on_platform_rewarded_ad_rewarded(), never from here — this only starts
## the ad attempt and locks the offer button/shows loading feedback.
func _start_shop_rewarded_ad(item_id: String) -> void:
	var platform := get_node_or_null("/root/Platform")
	if platform == null:
		feedback_label.text = _localized_ad_feedback("ui.rewarded_ad.unavailable", "Ad unavailable")
		return

	_shop_ad_active = true
	_shop_ad_rewarded = false
	_shop_ad_item_id = item_id
	_set_ad_offer_enabled(false)
	feedback_label.text = _localized_ad_feedback("ui.rewarded_ad.loading", "Loading ad...")
	platform.show_rewarded_ad(REWARDED_AD_PLACEMENT_SHOP_OFFER_GEMS)


func _on_platform_rewarded_ad_opened() -> void:
	if not _shop_ad_active:
		return
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.pause_for_ad()


func _on_platform_rewarded_ad_rewarded() -> void:
	if not _shop_ad_active or _shop_ad_rewarded:
		return
	_shop_ad_rewarded = true
	_grant_shop_ad_reward(_shop_ad_item_id)


func _grant_shop_ad_reward(item_id: String) -> void:
	if _progress_manager == null or _shop_catalog == null:
		feedback_label.text = _localized_ad_feedback("ui.rewarded_ad.error", "Ad error")
		return

	var item = _shop_catalog.get_item(item_id)
	if item == null:
		return

	for reward in item.rewards:
		if str(reward.get("type", "")) == SHOP_REWARD_TYPE_SCRIPT.CURRENCY:
			var currency_id := str(reward.get("currency_id", ""))
			var amount := int(reward.get("amount", 0))
			_progress_manager.add_currency(currency_id, amount)

	_refresh_wallet()


func _on_platform_rewarded_ad_closed(_was_shown: bool) -> void:
	if not _shop_ad_active:
		return
	_shop_ad_active = false
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.resume_after_ad()
	_set_ad_offer_enabled(true)

	if _shop_ad_rewarded:
		_shop_ad_rewarded = false
		feedback_label.text = _localized_ad_feedback("ui.shop.feedback.ad_reward_gems", "+3 gems received")
		_play_purchase_result_sfx(true)
	else:
		feedback_label.text = _localized_ad_feedback("ui.rewarded_ad.cancelled", "Reward was not granted")
	_shop_ad_item_id = ""


func _on_platform_rewarded_ad_error(_message: String) -> void:
	if not _shop_ad_active:
		return
	_shop_ad_active = false
	_shop_ad_rewarded = false
	_shop_ad_item_id = ""
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.resume_after_ad()
	_set_ad_offer_enabled(true)
	feedback_label.text = _localized_ad_feedback("ui.rewarded_ad.error", "Ad error")
	_play_purchase_result_sfx(false)


func _set_ad_offer_enabled(enabled: bool) -> void:
	if _ad_offer_tile != null and is_instance_valid(_ad_offer_tile):
		_ad_offer_tile.set_buy_enabled(enabled)


func _localized_ad_feedback(key: String, fallback_text: String) -> String:
	var localization_manager := get_node_or_null("/root/LocalizationManager")
	if localization_manager == null:
		return fallback_text
	return localization_manager.tr_key(key)


## Stage 69.3: connects Platform's payment catalog/purchase-started signals
## and kicks off a catalog load. Must run after _build_offers_content() etc.
## so _payment_tiles is already populated — LocalDebugPlatform/YandexBridge
## can both emit payment_catalog_loaded synchronously from inside
## load_payment_catalog(), so the signal has to already be connected first.
## Stage 69.3.1: payment_purchase_success/cancelled/error are no longer
## connected here — PlatformPurchaseCoordinator owns those (and the
## grant/consume logic behind them); see _connect_purchase_coordinator_signals().
func _connect_platform_payment_signals() -> void:
	var platform := get_node_or_null("/root/Platform")
	if platform == null:
		return
	if not platform.payment_catalog_loaded.is_connected(_on_platform_payment_catalog_loaded):
		platform.payment_catalog_loaded.connect(_on_platform_payment_catalog_loaded)
	if not platform.payment_catalog_error.is_connected(_on_platform_payment_catalog_error):
		platform.payment_catalog_error.connect(_on_platform_payment_catalog_error)
	if not platform.payment_purchase_started.is_connected(_on_platform_payment_purchase_started):
		platform.payment_purchase_started.connect(_on_platform_payment_purchase_started)
	platform.load_payment_catalog()


func _on_platform_payment_catalog_loaded(_products: Array) -> void:
	_payment_catalog_ready = true
	var platform := get_node_or_null("/root/Platform")
	_payment_catalog = platform.get_cached_payment_catalog() if platform != null else {}
	_refresh_payment_tiles()


func _on_platform_payment_catalog_error(_message: String) -> void:
	_payment_catalog_ready = true
	_payment_catalog = {}
	_refresh_payment_tiles()


func _refresh_payment_tiles() -> void:
	for item_id in _payment_tiles.keys():
		_refresh_payment_tile(item_id)


## Shows the catalog price (or loading/unavailable text) and enables the buy
## button only for a product actually present in the loaded catalog. Skips a
## tile with a purchase currently pending so a mid-flight catalog refresh
## can't re-enable a button the player already tapped.
func _refresh_payment_tile(item_id: String) -> void:
	if item_id == _pending_payment_item_id:
		return

	var tile: ShopProductTile = _payment_tiles.get(item_id)
	if tile == null or not is_instance_valid(tile):
		return

	var item = _shop_catalog.get_item(item_id) if _shop_catalog != null else null
	if item == null:
		return

	if not _payment_catalog_ready:
		tile.set_price_text(_localized_payment_feedback("ui.shop.price.loading", "..."))
		tile.set_buy_enabled(false)
		return

	var platform_product_id: String = item.get_platform_product_id(PLATFORM_KEY_YANDEX)
	var product: Dictionary = _payment_catalog.get(platform_product_id, {}) if platform_product_id != "" else {}
	if product.is_empty():
		tile.set_price_text(_localized_payment_feedback("ui.shop.price.unavailable", "Not available"))
		tile.set_buy_enabled(false)
		return

	var price_text := str(product.get("price", ""))
	tile.set_price_text(price_text if price_text != "" else _localized_payment_feedback("ui.shop.price.unavailable", "Not available"))
	tile.set_buy_enabled(true)


## Stage 69.3.1 v0.1: routes an external-payment tile's buy press to
## Platform.purchase_product(), after telling the coordinator this item_id is
## the one whose UI-facing signals should fire. Rewards are only ever
## granted inside PlatformPurchaseCoordinator/ProgressManager, never here.
func _start_payment_purchase(item_id: String) -> void:
	var item = _shop_catalog.get_item(item_id) if _shop_catalog != null else null
	if item == null:
		feedback_label.text = _localized_payment_feedback("ui.shop.feedback.purchase_unavailable", "Purchase unavailable")
		return

	var platform_product_id: String = item.get_platform_product_id(PLATFORM_KEY_YANDEX)
	if platform_product_id == "" or not _payment_catalog.has(platform_product_id):
		feedback_label.text = _localized_payment_feedback("ui.shop.feedback.purchase_unavailable", "Purchase unavailable")
		return

	var platform := get_node_or_null("/root/Platform")
	if platform == null:
		feedback_label.text = _localized_payment_feedback("ui.shop.feedback.purchase_unavailable", "Purchase unavailable")
		return

	_pending_payment_item_id = item_id
	_pending_payment_product_id = platform_product_id
	if _purchase_coordinator != null:
		_purchase_coordinator.start_foreground_purchase(item_id)
	platform.purchase_product(platform_product_id, item_id)


func _on_platform_payment_purchase_started(product_id: String) -> void:
	if product_id != _pending_payment_product_id:
		return
	_set_payment_tile_enabled(_pending_payment_item_id, false)
	feedback_label.text = _localized_payment_feedback("ui.shop.feedback.purchase_started", "Purchase started")


## Stage 69.3.1: connects to PlatformPurchaseCoordinator's UI-facing signals
## instead of Platform's raw payment_purchase_success/cancelled/error — the
## coordinator already filtered these to "belongs to the item this screen is
## actively waiting on" (see start_foreground_purchase() above), so no
## product_id matching is needed here anymore.
func _connect_purchase_coordinator_signals() -> void:
	if _purchase_coordinator == null:
		return
	if not _purchase_coordinator.purchase_reward_granted.is_connected(_on_purchase_reward_granted):
		_purchase_coordinator.purchase_reward_granted.connect(_on_purchase_reward_granted)
	if not _purchase_coordinator.purchase_already_granted.is_connected(_on_purchase_already_granted):
		_purchase_coordinator.purchase_already_granted.connect(_on_purchase_already_granted)
	if not _purchase_coordinator.purchase_consume_pending.is_connected(_on_purchase_consume_pending):
		_purchase_coordinator.purchase_consume_pending.connect(_on_purchase_consume_pending)
	if not _purchase_coordinator.purchase_completed.is_connected(_on_purchase_completed):
		_purchase_coordinator.purchase_completed.connect(_on_purchase_completed)
	if not _purchase_coordinator.purchase_cancelled.is_connected(_on_purchase_cancelled):
		_purchase_coordinator.purchase_cancelled.connect(_on_purchase_cancelled)
	if not _purchase_coordinator.purchase_failed.is_connected(_on_purchase_failed):
		_purchase_coordinator.purchase_failed.connect(_on_purchase_failed)


func _on_purchase_reward_granted(item_id: String) -> void:
	if item_id != _pending_payment_item_id:
		return
	_refresh_wallet()
	_play_purchase_result_sfx(true)
	feedback_label.text = _localized_payment_feedback("ui.shop.feedback.purchase_success", "Purchased!")


func _on_purchase_already_granted(item_id: String) -> void:
	if item_id != _pending_payment_item_id:
		return
	_refresh_wallet()
	feedback_label.text = _localized_payment_feedback("ui.shop.feedback.purchase_restored", "Purchase restored")


## The reward is already granted and saved by the time this fires (see
## PlatformPurchaseCoordinator._handle_grant_result()) — consuming the
## purchase with the SDK is a background bookkeeping step from here on, so
## the tile unlocks now rather than waiting for purchase_completed, which may
## not arrive this session if consume fails (it gets retried on next launch).
func _on_purchase_consume_pending(item_id: String) -> void:
	if item_id != _pending_payment_item_id:
		return
	_clear_pending_payment()
	_set_payment_tile_enabled(item_id, true)


func _on_purchase_completed(_item_id: String) -> void:
	pass


func _on_purchase_cancelled(item_id: String) -> void:
	if item_id != _pending_payment_item_id:
		return
	_clear_pending_payment()
	_set_payment_tile_enabled(item_id, true)
	feedback_label.text = _localized_payment_feedback("ui.shop.feedback.purchase_cancelled", "Purchase cancelled")
	_play_purchase_result_sfx(false)


func _on_purchase_failed(item_id: String, _message: String) -> void:
	if item_id != _pending_payment_item_id:
		return
	_clear_pending_payment()
	_set_payment_tile_enabled(item_id, true)
	feedback_label.text = _localized_payment_feedback("ui.shop.feedback.purchase_error", "Purchase error")
	_play_purchase_result_sfx(false)


func _clear_pending_payment() -> void:
	_pending_payment_item_id = ""
	_pending_payment_product_id = ""


func _set_payment_tile_enabled(item_id: String, enabled: bool) -> void:
	var tile: ShopProductTile = _payment_tiles.get(item_id)
	if tile != null and is_instance_valid(tile):
		tile.set_buy_enabled(enabled)


func _localized_payment_feedback(key: String, fallback_text: String) -> String:
	var localization_manager := get_node_or_null("/root/LocalizationManager")
	if localization_manager == null:
		return fallback_text
	return localization_manager.tr_key(key)


func _resolve_purchase(item_id: String, quantity: int) -> void:
	var result: Dictionary = _purchase_resolver.purchase(item_id, _progress_manager, _shop_catalog, quantity)
	var localization_manager := get_node_or_null("/root/LocalizationManager")
	feedback_label.text = SHOP_PURCHASE_FORMATTER_SCRIPT.format_purchase_result(result, localization_manager)
	_play_purchase_result_sfx(bool(result.get("accepted", false)))
	_refresh_wallet()


func _play_purchase_result_sfx(accepted: bool) -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager == null:
		return
	if accepted:
		audio_manager.play_purchase_success()
	else:
		audio_manager.play_purchase_error()


func _on_back_button_delayed_pressed() -> void:
	_play_button_click()
	back_pressed.emit()


func _play_button_click() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.play_button_click()
