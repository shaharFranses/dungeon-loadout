extends Control
## Talent pick: 3 options drawn from talents you have not maxed (LOOP_SPEC section 4).
## Used by Skill Point nodes and by the Elite bonus point.

const TalentData = preload("res://scripts/talent_data.gd")
const UiUtil = preload("res://scripts/ui_util.gd")

const CARD_SIZE := Vector2(330, 230)

var offer: Array = []


func _ready():
	DisplayServer.window_set_title("dungeon_loadout")
	offer = RunState.talent_offer()
	var title := "Elite bonus: choose a talent" if RunState.talent_pick_source == "elite" else "Choose a Talent"
	var box := UiUtil.make_screen(self, title)
	var narrow := get_viewport_rect().size.x < 1100.0   # art-a2: portrait phones stack the cards
	box.custom_minimum_size = Vector2(minf(1080.0, get_viewport_rect().size.x - 40.0), 0)
	box.add_child(UiUtil.make_label(UiUtil.status_line(), 16, UiUtil.GOLD))
	box.add_child(UiUtil.make_label("Talents: " + RunState.talent_label(), 16, UiUtil.DIM))
	var row: BoxContainer = VBoxContainer.new() if narrow else HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	box.add_child(row)
	for talent_id in offer:
		row.add_child(_make_card(talent_id))
	if offer.is_empty():
		box.add_child(UiUtil.make_label("Every talent is maxed.", 18, UiUtil.DIM))
		box.add_child(UiUtil.make_button("Continue", _finish))
	RunState.qa_dump_ui(self, "skill", {"offer": offer, "source": RunState.talent_pick_source})


func _make_card(talent_id: String) -> Control:
	var def := TalentData.get_def(talent_id)
	var rank := RunState.talent_rank(talent_id)
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 8)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = CARD_SIZE
	card.add_child(panel)
	# Top-aligned content so every card's title sits at the same height,
	# whatever the length of its effect text.
	var inner := VBoxContainer.new()
	inner.alignment = BoxContainer.ALIGNMENT_BEGIN
	inner.add_theme_constant_override("separation", 10)
	panel.add_child(inner)
	var icon := TextureRect.new()
	icon.texture = preload("res://scripts/art.gd").talent_tex(talent_id, 4)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.custom_minimum_size = Vector2(0, 64)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(icon)
	inner.add_child(UiUtil.make_label(String(def.name), 26, UiUtil.TEXT))
	var kind := "Skill" if def.get("skill", false) else "Passive"
	inner.add_child(UiUtil.make_label("%s - %s" % [def.tree, kind], 15, UiUtil.DIM))
	var next_rank := rank + 1
	var text := "Rank %d: %s" % [next_rank, TalentData.describe(talent_id, next_rank)]
	if rank > 0:
		text += "\n(now: %s)" % TalentData.describe(talent_id, rank)
	inner.add_child(UiUtil.make_label(text, 17, UiUtil.TEXT))
	var label := "Rank up to %d" % next_rank if rank > 0 else "Select"
	card.add_child(UiUtil.make_button(label, _on_pick.bind(talent_id), CARD_SIZE.x))
	return card


func _on_pick(talent_id: String):
	RunState.pick_talent(talent_id)
	RunState.qa_log("TALENT", {"talent": RunState.talent_label(), "source": RunState.talent_pick_source})
	_finish()


func _finish():
	RunState.change_scene("res://scenes/map.tscn")
