extends Control
## Post-fight reward: gold, plus take-or-skip gear offers (1 after Battle/Elite,
## a choice of 3 Rare+ after an act boss). Taking replaces that slot.

const GearData = preload("res://scripts/gear_data.gd")
const UiUtil = preload("res://scripts/ui_util.gd")

var decided: bool = false
var offer_buttons: Array = []
var skip_button: Button
var continue_button: Button
var status_label: Label
var gear_label: Label


func _ready():
	DisplayServer.window_set_title("dungeon_loadout")
	var node_type := RunState.current_node_type
	var title := "Victory"
	if node_type == "elite":
		title = "Elite Defeated"
	elif node_type == "boss":
		title = "Act %d Cleared" % RunState.act
	var box := UiUtil.make_screen(self, title)
	box.add_theme_constant_override("separation", 10)
	var gold_text := "+%d gold" % RunState.last_gold_reward
	if RunState.last_fight_heal > 0:
		gold_text += "   +%d HP" % RunState.last_fight_heal
	box.add_child(UiUtil.make_label(gold_text, 22, UiUtil.GOLD))
	if node_type == "boss":
		box.add_child(UiUtil.make_label("Next act: full heal. Gold, gear and talents carry over.", 16, UiUtil.HEAL))
	status_label = UiUtil.make_label("", 17, UiUtil.TEXT)
	box.add_child(status_label)
	gear_label = UiUtil.make_label("", 15, UiUtil.DIM)
	box.add_child(gear_label)
	var offers: Array = RunState.pending_offers
	if offers.is_empty():
		box.add_child(UiUtil.make_label("No gear dropped.", 18, UiUtil.DIM))
		decided = true
	else:
		var header := "Choose one (or skip):" if offers.size() > 1 else "Gear found:"
		box.add_child(UiUtil.make_label(header, 18, UiUtil.TEXT))
		for item in offers:
			box.add_child(UiUtil.make_label(GearData.describe(item), 17, GearData.RARITY_COLORS[item.rarity]))
			var button := UiUtil.make_button("Take %s" % item.name, _on_take_pressed.bind(item), 420.0)
			box.add_child(button)
			offer_buttons.append(button)
		skip_button = UiUtil.make_button("Skip", _on_skip_pressed, 420.0)
		box.add_child(skip_button)
	continue_button = UiUtil.make_button("Continue", _on_continue_pressed, 420.0)
	box.add_child(continue_button)
	_update_ui()


func _update_ui():
	status_label.text = UiUtil.status_line()
	gear_label.text = UiUtil.gear_line()
	for button in offer_buttons:
		button.disabled = decided
	if skip_button:
		skip_button.disabled = decided
	continue_button.disabled = not decided
	RunState.qa_dump_ui(self, "reward", {"offers": RunState.pending_offers, "node": RunState.current_node_type})


func _on_take_pressed(item: Dictionary):
	if decided:
		return
	RunState.equip(item)
	RunState.qa_log("TAKE", {"item": item.id, "slot": item.slot})
	decided = true
	_update_ui()


func _on_skip_pressed():
	decided = true
	_update_ui()


func _on_continue_pressed():
	if decided:
		RunState.pending_offers = []
		get_tree().change_scene_to_file(RunState.after_reward_scene())
