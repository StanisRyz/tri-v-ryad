extends Control

signal back_pressed

const SHOP_CATALOG_SCRIPT := preload("res://scripts/game/shop/shop_catalog.gd")
const SHOP_ITEM_CATEGORY_SCRIPT := preload("res://scripts/game/shop/shop_item_category.gd")
const SHOP_PURCHASE_RESOLVER_SCRIPT := preload("res://scripts/game/shop/shop_purchase_resolver.gd")
const SHOP_PURCHASE_FORMATTER_SCRIPT := preload("res://scripts/game/shop/shop_purchase_formatter.gd")
const CURRENCY_TYPE_SCRIPT := preload("res://scripts/game/economy/currency_type.gd")
const SHOP_ITEM_CARD_SCENE := preload("res://scenes/ui/ShopItemCard.tscn")

const TAB_MODULATE_SELECTED := Color(1, 1, 1, 1)
const TAB_MODULATE_UNSELECTED := Color(0.55, 0.55, 0.55, 1)

@onready var back_button: Button = %BackButton
@onready var gold_label: Label = %GoldLabel
@onready var gems_label: Label = %GemsLabel
@onready var boosters_tab_button: Button = %BoostersTabButton
@onready var gems_tab_button: Button = %GemsTabButton
@onready var bundles_tab_button: Button = %BundlesTabButton
@onready var item_grid: GridContainer = %ItemGrid
@onready var feedback_label: Label = %FeedbackLabel

var _progress_manager
var _shop_catalog = SHOP_CATALOG_SCRIPT.new()
var _purchase_resolver = SHOP_PURCHASE_RESOLVER_SCRIPT.new()
var _selected_category := SHOP_ITEM_CATEGORY_SCRIPT.BOOSTERS


func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
	boosters_tab_button.pressed.connect(_on_boosters_tab_pressed)
	gems_tab_button.pressed.connect(_on_gems_tab_pressed)
	bundles_tab_button.pressed.connect(_on_bundles_tab_pressed)
	feedback_label.text = ""
	_refresh_wallet()
	_show_category(_selected_category)


func set_progress_manager(progress_manager) -> void:
	_progress_manager = progress_manager
	if is_inside_tree():
		_refresh_wallet()
		_refresh_items()


func refresh_progress_state() -> void:
	if is_inside_tree():
		_refresh_wallet()
		_refresh_items()


func _refresh_wallet() -> void:
	if gold_label == null or gems_label == null:
		return

	var gold := 0
	var gems := 0
	if _progress_manager != null:
		gold = _progress_manager.get_currency(CURRENCY_TYPE_SCRIPT.GOLD)
		gems = _progress_manager.get_currency(CURRENCY_TYPE_SCRIPT.GEMS)

	gold_label.text = "Gold: %d" % gold
	gems_label.text = "Gems: %d" % gems


func _show_category(category: String) -> void:
	_selected_category = category
	_update_tab_visuals()
	_refresh_items()


func _refresh_items() -> void:
	if item_grid == null:
		return

	for child in item_grid.get_children():
		child.queue_free()

	var items: Array = _shop_catalog.get_items_by_category(_selected_category)
	for item in items:
		var card: ShopItemCard = SHOP_ITEM_CARD_SCENE.instantiate()
		item_grid.add_child(card)
		card.set_item(item)
		card.purchase_pressed.connect(_on_item_purchase_pressed)


func _update_tab_visuals() -> void:
	boosters_tab_button.modulate = TAB_MODULATE_SELECTED if _selected_category == SHOP_ITEM_CATEGORY_SCRIPT.BOOSTERS else TAB_MODULATE_UNSELECTED
	gems_tab_button.modulate = TAB_MODULATE_SELECTED if _selected_category == SHOP_ITEM_CATEGORY_SCRIPT.GEMS else TAB_MODULATE_UNSELECTED
	bundles_tab_button.modulate = TAB_MODULATE_SELECTED if _selected_category == SHOP_ITEM_CATEGORY_SCRIPT.BUNDLES else TAB_MODULATE_UNSELECTED


func _on_boosters_tab_pressed() -> void:
	_play_button_click()
	_show_category(SHOP_ITEM_CATEGORY_SCRIPT.BOOSTERS)


func _on_gems_tab_pressed() -> void:
	_play_button_click()
	_show_category(SHOP_ITEM_CATEGORY_SCRIPT.GEMS)


func _on_bundles_tab_pressed() -> void:
	_play_button_click()
	_show_category(SHOP_ITEM_CATEGORY_SCRIPT.BUNDLES)


func _on_item_purchase_pressed(item_id: String) -> void:
	_play_button_click()
	var result: Dictionary = _purchase_resolver.purchase(item_id, _progress_manager, _shop_catalog)
	feedback_label.text = SHOP_PURCHASE_FORMATTER_SCRIPT.format_purchase_result(result)
	_refresh_wallet()
	if bool(result.get("accepted", false)):
		_refresh_items()


func _on_back_button_pressed() -> void:
	_play_button_click()
	back_pressed.emit()


func _play_button_click() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null:
		audio_manager.play_button_click()
