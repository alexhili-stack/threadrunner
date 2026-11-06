class_name ThreadStyle
extends RefCounted

const PAPER: Color = Color("f2f3e9")
const SECONDARY: Color = Color("afb3bb")
const THREAD: Color = Color("008cff")
const TEXT_ACCENT: Color = Color("299dff")
const INK: Color = Color("08090b")
const LINE: Color = Color("35383e")
const DANGER: Color = Color("ff3aba")
const SAW: Color = Color("b68aff")
const HEAT: Color = Color("ffae42")
const PLATFORM: Color = Color("303237")
const LANDING: Color = Color("c6c9cf")
const GOLD: Color = Color("f5cc83")
const DISPLAY: Font = preload("res://assets/fonts/BarlowCondensed-SemiBold.ttf")
const BODY: Font = preload("res://assets/fonts/Manrope.ttf")


static func panel(color: Color, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(1 if border.a > 0 else 0)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 3
	box.content_margin_bottom = 3
	return box


static func make_theme() -> Theme:
	var theme: Theme = Theme.new()
	var body: FontVariation = FontVariation.new()
	body.base_font = BODY
	body.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 550.0}
	theme.default_font = body
	theme.default_font_size = 12
	for type: String in ["Button", "Label", "CheckButton"]:
		theme.set_color("font_color", type, PAPER)
	theme.set_color("font_hover_color", "Button", PAPER)
	theme.set_color("font_focus_color", "Button", PAPER)
	theme.set_color("font_pressed_color", "Button", TEXT_ACCENT)
	theme.set_color("font_disabled_color", "Button", Color("718991"))
	var normal: StyleBoxFlat = panel(Color(0.10, 0.11, 0.13, 0.75))
	normal.border_width_bottom = 1
	normal.border_color = LINE
	theme.set_stylebox("normal", "Button", normal)
	theme.set_stylebox("hover", "Button", panel(Color("30343c")))
	theme.set_stylebox("pressed", "Button", panel(Color("222936")))
	theme.set_stylebox("focus", "Button", panel(Color.TRANSPARENT, THREAD))
	theme.set_stylebox("disabled", "Button", panel(Color("141519")))
	var rail: StyleBoxFlat = panel(LINE)
	rail.content_margin_top = 2
	rail.content_margin_bottom = 2
	theme.set_stylebox("slider", "HSlider", rail)
	theme.set_stylebox("grabber_area", "HSlider", panel(THREAD))
	theme.set_stylebox("grabber_area_highlight", "HSlider", panel(PAPER))
	theme.set_stylebox("focus", "HSlider", panel(Color.TRANSPARENT, THREAD))
	for icon_name: String in ["grabber", "grabber_highlight", "grabber_disabled"]:
		theme.set_icon(icon_name, "HSlider", preload("res://assets/ui/slider_knot.svg"))
	return theme


static func primary(control: Button) -> void:
	control.add_theme_stylebox_override("normal", panel(THREAD))
	control.add_theme_stylebox_override("hover", panel(PAPER))
	control.add_theme_stylebox_override("pressed", panel(Color("9bccff")))
	control.add_theme_stylebox_override("focus", panel(Color.TRANSPARENT, PAPER))
	for state: String in [
		"font_color", "font_hover_color", "font_focus_color", "font_pressed_color"
	]:
		control.add_theme_color_override(state, INK)
