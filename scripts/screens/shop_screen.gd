extends Control

signal back_pressed

const SHOP_CATALOG_SCRIPT := preload("res://scripts/game/shop/shop_catalog.gd")
const SHOP_ITEM_CATEGORY_SCRIPT := preload("res://scripts/game/shop/shop_item_category.gd")
const SHOP_PURCHASE_RESOLVER_SCRIPT := preload("res://scripts/game/shop/shop_purchase_resolver.gd")
const SHOP_PURCHASE_FORMATTER_SCRIPT := preload("res://scripts/game/shop/shop_purchase_formatter.gd")
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
	_resolve_purchase(item_id, 1)


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
