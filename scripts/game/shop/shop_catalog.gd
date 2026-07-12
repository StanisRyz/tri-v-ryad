extends RefCounted
class_name ShopCatalog

const SHOP_ITEM_CONFIG_SCRIPT := preload("res://scripts/game/shop/shop_item_config.gd")
const SHOP_ITEM_CATEGORY_SCRIPT := preload("res://scripts/game/shop/shop_item_category.gd")
const SHOP_PURCHASE_KIND_SCRIPT := preload("res://scripts/game/shop/shop_purchase_kind.gd")
const SHOP_REWARD_TYPE_SCRIPT := preload("res://scripts/game/shop/shop_reward_type.gd")
const CURRENCY_TYPE_SCRIPT := preload("res://scripts/game/economy/currency_type.gd")
const BOOSTER_CATALOG_SCRIPT := preload("res://scripts/game/config/booster_catalog.gd")

var _items: Dictionary = {}
var _item_order: Array[String] = []
var _localization_manager = null


func _init(localization_manager = null) -> void:
	_localization_manager = localization_manager
	_register_items()


func _tr(key: String, fallback: String) -> String:
	if _localization_manager != null:
		return _localization_manager.tr_key(key)
	return fallback


func _fmt(key: String, fallback_template: String, values: Dictionary) -> String:
	if _localization_manager != null:
		return _localization_manager.format_key(key, values)
	var text: String = fallback_template
	for placeholder_key in values.keys():
		text = text.replace("{%s}" % str(placeholder_key), str(values[placeholder_key]))
	return text


func get_all_items() -> Array:
	var items: Array = []
	for item_id in _item_order:
		items.append(_items[item_id])
	return items


func get_items_by_category(category: String) -> Array:
	var items: Array = []
	for item_id in _item_order:
		var item = _items[item_id]
		if item.category == category:
			items.append(item)
	return items


func get_item(item_id: String):
	if has_item(item_id):
		return _items[item_id]
	return null


func has_item(item_id: String) -> bool:
	return _items.has(item_id)


func _register_items() -> void:
	_register_booster_items()
	_register_gem_items()
	_register_bundle_items()
	_register_offer_items()


func _register_booster_items() -> void:
	var boosters := [
		[BOOSTER_CATALOG_SCRIPT.HAMMER, "shop.item.hammer", "Hammer"],
		[BOOSTER_CATALOG_SCRIPT.FREEZE_TIME, "shop.item.time_freeze", "Time Freeze"],
		[BOOSTER_CATALOG_SCRIPT.ROCKET_BARRAGE, "shop.item.rocket_barrage", "Rocket Barrage"],
	]

	for booster in boosters:
		var booster_id: String = booster[0]
		var booster_name: String = _tr(booster[1], booster[2])

		_add_item(SHOP_ITEM_CONFIG_SCRIPT.new(
			"booster_%s_gold" % booster_id,
			SHOP_ITEM_CATEGORY_SCRIPT.BOOSTERS,
			booster_name,
			_fmt("shop.item.booster_desc_gold", "Buy one {name} with gold.", {"name": booster_name}),
			SHOP_PURCHASE_KIND_SCRIPT.CURRENCY,
			CURRENCY_TYPE_SCRIPT.GOLD,
			20,
			[SHOP_REWARD_TYPE_SCRIPT.make_booster_reward(booster_id, 1)]
		))

		_add_item(SHOP_ITEM_CONFIG_SCRIPT.new(
			"booster_%s_gems" % booster_id,
			SHOP_ITEM_CATEGORY_SCRIPT.BOOSTERS,
			booster_name,
			_fmt("shop.item.booster_desc_gems", "Buy one {name} with gems.", {"name": booster_name}),
			SHOP_PURCHASE_KIND_SCRIPT.CURRENCY,
			CURRENCY_TYPE_SCRIPT.GEMS,
			10,
			[SHOP_REWARD_TYPE_SCRIPT.make_booster_reward(booster_id, 1)]
		))


func _register_gem_items() -> void:
	var gem_products := [
		["gems_50", 50],
		["gems_150", 150],
		["gems_250", 250],
		["gems_500", 500],
	]

	for product in gem_products:
		var product_id: String = product[0]
		var gem_amount: int = product[1]

		_add_item(SHOP_ITEM_CONFIG_SCRIPT.new(
			product_id,
			SHOP_ITEM_CATEGORY_SCRIPT.GEMS,
			_fmt("shop.item.gems_title", "{amount} Gems", {"amount": gem_amount}),
			_fmt("shop.item.gems_desc", "{amount} gems.", {"amount": gem_amount}),
			SHOP_PURCHASE_KIND_SCRIPT.EXTERNAL_PAYMENT,
			"",
			0,
			[SHOP_REWARD_TYPE_SCRIPT.make_currency_reward(CURRENCY_TYPE_SCRIPT.GEMS, gem_amount)]
		))


func _register_bundle_items() -> void:
	var bundles := [
		["bundle_small", "shop.item.bundle_small", "Small Bundle", 50, 50, 1],
		["bundle_medium", "shop.item.bundle_medium", "Medium Bundle", 100, 100, 2],
		["bundle_large", "shop.item.bundle_large", "Large Bundle", 200, 200, 3],
		["bundle_mega", "shop.item.bundle_mega", "Mega Bundle", 500, 500, 10],
	]

	for bundle in bundles:
		var bundle_id: String = bundle[0]
		var bundle_name: String = _tr(bundle[1], bundle[2])
		var gem_amount: int = bundle[3]
		var gold_amount: int = bundle[4]
		var booster_amount: int = bundle[5]

		var rewards: Array[Dictionary] = [
			SHOP_REWARD_TYPE_SCRIPT.make_currency_reward(CURRENCY_TYPE_SCRIPT.GEMS, gem_amount),
			SHOP_REWARD_TYPE_SCRIPT.make_currency_reward(CURRENCY_TYPE_SCRIPT.GOLD, gold_amount),
			SHOP_REWARD_TYPE_SCRIPT.make_booster_reward(BOOSTER_CATALOG_SCRIPT.HAMMER, booster_amount),
			SHOP_REWARD_TYPE_SCRIPT.make_booster_reward(BOOSTER_CATALOG_SCRIPT.FREEZE_TIME, booster_amount),
			SHOP_REWARD_TYPE_SCRIPT.make_booster_reward(BOOSTER_CATALOG_SCRIPT.ROCKET_BARRAGE, booster_amount),
		]

		_add_item(SHOP_ITEM_CONFIG_SCRIPT.new(
			bundle_id,
			SHOP_ITEM_CATEGORY_SCRIPT.BUNDLES,
			bundle_name,
			_fmt("shop.item.bundle_desc", "{gems} gems, {gold} gold, +{count} of every booster.", {
				"gems": gem_amount,
				"gold": gold_amount,
				"count": booster_amount,
			}),
			SHOP_PURCHASE_KIND_SCRIPT.EXTERNAL_PAYMENT,
			"",
			0,
			rewards
		))


## Offers tab (Stage 65.14): a rewarded-ad stub, two "more gems for the same
## deal shape" special gem offers, and a real-money booster pack. All three
## non-ad items use EXTERNAL_PAYMENT (same "listed, payments not connected
## yet" pattern as the Gems/Bundles tabs); the ad item uses AD_WATCH (same
## shape, distinct reason/message, pending a rewarded-ad SDK).
func _register_offer_items() -> void:
	_add_item(SHOP_ITEM_CONFIG_SCRIPT.new(
		"offer_watch_ad",
		SHOP_ITEM_CATEGORY_SCRIPT.OFFERS,
		_tr("shop.item.offer_watch_ad_title", "Ad"),
		_tr("shop.item.offer_watch_ad_desc", "Watch an ad for a free reward."),
		SHOP_PURCHASE_KIND_SCRIPT.AD_WATCH,
		"",
		0,
		[SHOP_REWARD_TYPE_SCRIPT.make_currency_reward(CURRENCY_TYPE_SCRIPT.GEMS, 3)]
	))

	_add_item(SHOP_ITEM_CONFIG_SCRIPT.new(
		"offer_gems",
		SHOP_ITEM_CATEGORY_SCRIPT.OFFERS,
		_tr("shop.item.offer_gems_title", "Gems"),
		_tr("shop.item.offer_gems_desc", "Limited-time bonus gem offer."),
		SHOP_PURCHASE_KIND_SCRIPT.EXTERNAL_PAYMENT,
		"",
		0,
		[SHOP_REWARD_TYPE_SCRIPT.make_currency_reward(CURRENCY_TYPE_SCRIPT.GEMS, 1000)]
	))

	_add_item(SHOP_ITEM_CONFIG_SCRIPT.new(
		"offer_mega_gems",
		SHOP_ITEM_CATEGORY_SCRIPT.OFFERS,
		_tr("shop.item.offer_mega_gems_title", "Mega Gems"),
		_tr("shop.item.offer_mega_gems_desc", "The biggest bonus gem offer."),
		SHOP_PURCHASE_KIND_SCRIPT.EXTERNAL_PAYMENT,
		"",
		0,
		[SHOP_REWARD_TYPE_SCRIPT.make_currency_reward(CURRENCY_TYPE_SCRIPT.GEMS, 2500)]
	))

	_add_item(SHOP_ITEM_CONFIG_SCRIPT.new(
		"offer_boosters",
		SHOP_ITEM_CATEGORY_SCRIPT.OFFERS,
		_tr("shop.item.offer_boosters_title", "Boosters"),
		_tr("shop.item.offer_boosters_desc", "A pack of every booster."),
		SHOP_PURCHASE_KIND_SCRIPT.EXTERNAL_PAYMENT,
		"",
		0,
		[
			SHOP_REWARD_TYPE_SCRIPT.make_booster_reward(BOOSTER_CATALOG_SCRIPT.HAMMER, 25),
			SHOP_REWARD_TYPE_SCRIPT.make_booster_reward(BOOSTER_CATALOG_SCRIPT.FREEZE_TIME, 25),
			SHOP_REWARD_TYPE_SCRIPT.make_booster_reward(BOOSTER_CATALOG_SCRIPT.ROCKET_BARRAGE, 25),
		]
	))


func _add_item(config) -> void:
	if config == null or not config.is_valid():
		return
	if _items.has(config.item_id):
		return

	_items[config.item_id] = config
	_item_order.append(config.item_id)
