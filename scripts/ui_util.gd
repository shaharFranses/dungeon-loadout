extends RefCounted
## Small helpers for the code-built Stage B screens (palette from LOOP_SPEC section 7).

const BG := Color("#1B1A24")
const TEXT := Color("#E8E2D0")
const DIM := Color("#5A5670")
const GOLD := Color("#E3B341")
const HP := Color("#C8433A")
const HEAL := Color("#5DBB63")


static func make_screen(root: Control, title: String) -> VBoxContainer:
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(760, 0)
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)
	box.add_child(make_label(title, 34, TEXT))
	return box


static func make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


static func make_button(text: String, callback: Callable, width: float = 360.0) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(width, 50)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(callback)
	return button


static func status_line() -> String:
	return "HP: %d/%d    Gold: %d    Strike %d    Guard %d" % [
			RunState.player_hp, RunState.player_max_hp, RunState.gold,
			RunState.get_strike_damage(), RunState.get_guard_amount()]


static func gear_line() -> String:
	return "Weapon: %s   Armor: %s   Trinket: %s" % [
			RunState.item_label("weapon"), RunState.item_label("armor"), RunState.item_label("trinket")]
