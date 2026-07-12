extends RefCounted
class_name TextStyleCatalog

## Stage 66.2: centralized typography catalog. Edit the values below to
## change font size/outline across the game without touching scenes or
## screen scripts. Each style is a Dictionary that may define:
## - font_size: int
## - outline_size: int
## - font_color: Color (optional)
## - outline_color: Color (optional)
## Missing keys simply aren't overridden by TextStyleApplier.

const DEFAULT_STYLE := {
	"font_size": 22,
	"outline_size": 4,
	"font_color": Color(1, 1, 1, 1),
	"outline_color": Color(0, 0, 0, 1),
}

const STYLES := {
	# Global/common
	"global.label": {"font_size": 22, "outline_size": 4},
	"global.button": {"font_size": 24, "outline_size": 4},
	"global.popup_title": {"font_size": 30, "outline_size": 5},
	"global.popup_body": {"font_size": 18, "outline_size": 3},
	"global.small_hint": {"font_size": 14, "outline_size": 2},

	# Main menu
	"main_menu.title": {"font_size": 36, "outline_size": 5},
	"main_menu.button": {"font_size": 65, "outline_size": 7},
	"main_menu.currency": {"font_size": 35, "outline_size": 5},

	# Settings
	"settings.title": {"font_size": 50, "outline_size": 7},
	"settings.option_label": {"font_size": 50, "outline_size": 7},
	"settings.option_value": {"font_size": 50, "outline_size": 7},
	"settings.button": {"font_size": 50, "outline_size": 7},

	# Shop
	"shop.wallet": {"font_size": 35, "outline_size": 5},
	"shop.tab": {"font_size": 30, "outline_size": 5},
	"shop.tile_quantity": {"font_size": 18, "outline_size": 3},
	"shop.tile_price_button": {"font_size": 28, "outline_size": 5},
	"shop.tile_product_button": {"font_size": 28, "outline_size": 5},
	"shop.feedback": {"font_size": 22, "outline_size": 5},
	"shop.offer_placeholder": {"font_size": 18, "outline_size": 3},

	# Level select
	"level_select.zone_dropdown": {"font_size": 26, "outline_size": 5},
	"level_select.level_button": {"font_size": 26, "outline_size": 4},
	"level_select.back_button": {"font_size": 40, "outline_size": 7},
	"level_select.popup_title": {"font_size": 50, "outline_size": 7},
	"level_select.popup_stars": {"font_size": 22, "outline_size": 3},
	"level_select.popup_button": {"font_size": 30, "outline_size": 7},

	# Game HUD
	"game_hud.level": {"font_size": 35, "outline_size": 7},
	"game_hud.moves": {"font_size": 35, "outline_size": 7},
	"game_hud.menu_button": {"font_size": 33, "outline_size": 7},
	"game_hud.hp": {"font_size": 30, "outline_size": 5},
	"game_hud.modifier": {"font_size": 30, "outline_size": 7},
	"game_hud.booster_count": {"font_size": 25, "outline_size": 5},

	# Result UI
	"result.title": {"font_size": 32, "outline_size": 5},
	"result.reward": {"font_size": 25, "outline_size": 7},
	"result.button": {"font_size": 35, "outline_size": 7},

	# Lose continue popup
	"lose_continue.title": {"font_size": 35, "outline_size": 7},
	"lose_continue.description": {"font_size": 16, "outline_size": 2},
	"lose_continue.button": {"font_size": 30, "outline_size": 5},
	"lose_continue.feedback": {"font_size": 30, "outline_size": 5},

	# Debug/dev
	"debug.message": {"font_size": 16, "outline_size": 2},
	"debug.small": {"font_size": 12, "outline_size": 1},
}


## Returns a fully-populated style Dictionary for style_id, merged over
## DEFAULT_STYLE. Always returns a usable Dictionary, even for an unknown
## style_id (falls back to DEFAULT_STYLE), so callers never need a null check.
static func get_style(style_id: String) -> Dictionary:
	var style: Dictionary = DEFAULT_STYLE.duplicate()
	if STYLES.has(style_id):
		style.merge(STYLES[style_id], true)
	return style


static func has_style(style_id: String) -> bool:
	return STYLES.has(style_id)
