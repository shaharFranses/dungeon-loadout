extends RefCounted
## Small helpers for the code-built Stage B screens (palette from LOOP_SPEC section 7).

const Art = preload("res://scripts/art.gd")
# art-a5: aliases of the single palette source in art.gd (no hex values here).
const BG := Art.BG
const TEXT := Art.BONE
const DIM := Art.TXT_DIM   # art-a6: was EDGE (2.18:1); STYLE_GUIDE 10 dim text role
const GOLD := Art.GOLD
const HP := Art.TXT_NEG   # art-a6: used as text (RED is a fill colour)
const HEAL := Art.GREEN


static func make_screen(root: Control, title: String) -> VBoxContainer:
	Art.add_backdrop(root, root.get_child_count())
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(minf(760.0, root.get_viewport_rect().size.x - 40.0), 0)
	box.add_theme_constant_override("separation", 14)
	if Art.is_portrait():
		# art-a5: phone text and tap targets are much bigger, so a long screen (shop, camp,
		# 3 stacked talent cards) can outgrow a short phone. The column scrolls vertically
		# (drag) instead of running off the bottom; it is centred when it fits.
		var scroll := ScrollContainer.new()
		scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		root.add_child(scroll)
		center.set_anchors_preset(Control.PRESET_TOP_LEFT)
		center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		center.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.add_child(center)
		var pad := MarginContainer.new()
		pad.add_theme_constant_override("margin_top", 16)
		pad.add_theme_constant_override("margin_bottom", 16)
		center.add_child(pad)
		pad.add_child(box)
	else:
		root.add_child(center)
		center.add_child(box)
	box.add_child(make_label(title, 34, TEXT))
	return box


static func make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", Art.fs(size))
	label.add_theme_color_override("font_color", Art.text_color(color))   # art-a6: text roles only
	# art-a6.1: no plate here - these screens' lines sit on the plain backdrop (DL Art: the
	# a6 plates made shop / reward read as stacked bars)
	return label


static func make_button(text: String, callback: Callable, width: float = 360.0) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(width, 50)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", Art.fs(18))
	if Art.is_portrait():
		# art-a5: phones - full column width (narrow requests, e.g. the
		# two Ascension buttons, which get half the column each), word-wrapped text, >= 88 canvas px (47 CSS px) tall.
		var col := minf(760.0, RunState.get_viewport().get_visible_rect().size.x - 40.0)
		button.custom_minimum_size = Vector2(col if width >= 300.0 else floorf((col - 16.0) / 2.0), Art.PHONE_TAP)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(callback)
	return button


## Art pass A: optional 16x16 icon (already integer-scaled) on the left of a button.
static func with_icon(button: Button, icon: Texture2D) -> Button:
	if icon != null:
		button.icon = icon
		button.expand_icon = false
	return button


static func status_line() -> String:
	return "HP: %d/%d    Gold: %d    Strike %d    Guard %d" % [
			RunState.player_hp, RunState.player_max_hp, RunState.gold,
			RunState.get_strike_damage(), RunState.get_guard_amount()]


## art-a6.1: the status line as one Label per pair in a centred HFlowContainer, so a pair
## ("Strike 6") never splits across lines on phones (Kenney Pixel has no U+00A0).
static func make_status(size: int, color: Color) -> HFlowContainer:
	var flow := HFlowContainer.new()
	flow.alignment = FlowContainer.ALIGNMENT_CENTER
	flow.add_theme_constant_override("h_separation", 32 if Art.is_portrait() else 24)
	flow.add_theme_constant_override("v_separation", 0)
	for k in range(4):
		var l := Label.new()
		l.add_theme_font_size_override("font_size", Art.fs(size))
		l.add_theme_color_override("font_color", Art.text_color(color))
		flow.add_child(l)
	update_status(flow)
	return flow


static func status_parts() -> Array:
	return ["HP: %d/%d" % [RunState.player_hp, RunState.player_max_hp], "Gold: %d" % RunState.gold,
			"Strike %d" % RunState.get_strike_damage(), "Guard %d" % RunState.get_guard_amount()]


static func update_status(flow: Control) -> void:
	var parts := status_parts()
	for k in range(mini(parts.size(), flow.get_child_count())):
		(flow.get_child(k) as Label).text = parts[k]


static func gear_line() -> String:
	return "Weapon: %s   Armor: %s   Trinket: %s" % [
			RunState.item_label("weapon"), RunState.item_label("armor"), RunState.item_label("trinket")]
