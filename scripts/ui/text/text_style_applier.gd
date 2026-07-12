extends RefCounted
class_name TextStyleApplier

## Stage 66.2: applies TextStyleCatalog style blocks to Controls as
## theme_override_* properties only. Never touches anchors, offsets,
## layout_mode, alignment, scale, textures, position, size, visibility,
## or text content (including localized text).

const TEXT_STYLE_CATALOG_SCRIPT := preload("res://scripts/ui/text/text_style_catalog.gd")


## Applies style_id to any Control. Labels and Buttons get font overrides
## directly; other Control types are a safe no-op (nothing to style).
static func apply(control: Control, style_id: String) -> void:
	if control == null:
		return
	if control is Label:
		apply_to_label(control, style_id)
	elif control is Button:
		apply_to_button(control, style_id)


static func apply_to_label(label: Label, style_id: String) -> void:
	if label == null:
		return
	_apply_font_overrides(label, TEXT_STYLE_CATALOG_SCRIPT.get_style(style_id))


static func apply_to_button(button: Button, style_id: String) -> void:
	if button == null:
		return
	_apply_font_overrides(button, TEXT_STYLE_CATALOG_SCRIPT.get_style(style_id))


## For custom texture buttons (PressableTextureButton, ShopTabButton, etc.)
## whose visible text lives in a child Label overlay rather than Button.text.
## label_node_name is a relative NodePath from root, e.g. "TextMargin/Label".
static func apply_to_child_label(root: Node, label_node_name: String, style_id: String) -> void:
	if root == null:
		return
	var label := root.get_node_or_null(label_node_name)
	if label == null or not (label is Label):
		return
	apply_to_label(label, style_id)


static func _apply_font_overrides(control: Control, style: Dictionary) -> void:
	if style.has("font_size"):
		control.add_theme_font_size_override("font_size", int(style["font_size"]))
	if style.has("outline_size"):
		control.add_theme_constant_override("outline_size", int(style["outline_size"]))
	if style.has("font_color"):
		control.add_theme_color_override("font_color", style["font_color"])
	if style.has("outline_color"):
		control.add_theme_color_override("font_outline_color", style["outline_color"])
