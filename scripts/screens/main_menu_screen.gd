extends Control

signal play_pressed
signal level_select_pressed
signal shop_pressed
signal heroes_pressed
signal settings_pressed

@onready var play_button: Button = %PlayButton
@onready var level_select_button: Button = %LevelSelectButton
@onready var shop_button: Button = %ShopButton
@onready var heroes_button: Button = %HeroesButton
@onready var settings_button: Button = %SettingsButton


func _ready() -> void:
	play_button.pressed.connect(_on_play_button_pressed)
	level_select_button.pressed.connect(_on_level_select_button_pressed)
	shop_button.pressed.connect(_on_shop_button_pressed)
	heroes_button.pressed.connect(_on_heroes_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	heroes_button.visible = FeatureFlags.HERO_SYSTEMS_ENABLED


func _on_play_button_pressed() -> void:
	play_pressed.emit()


func _on_level_select_button_pressed() -> void:
	level_select_pressed.emit()


func _on_shop_button_pressed() -> void:
	shop_pressed.emit()


func _on_heroes_button_pressed() -> void:
	heroes_pressed.emit()


func _on_settings_button_pressed() -> void:
	settings_pressed.emit()
