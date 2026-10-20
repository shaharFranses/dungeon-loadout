extends Control
## Post-fight reward: gold, plus a take-or-skip weapon offer when one dropped.

const GearData = preload("res://scripts/gear_data.gd")
const UiUtil = preload("res://scripts/ui_util.gd")

var decided: bool = false
var take_button: Button
var skip_button: Button
var continue_button: Button
var status_label: Label


func _ready():
	DisplayServer.window_set_title("dungeon_loadout")
	var title := "Elite Defeated" if RunState.current_node_type == "elite" else "Victory"
	var box := UiUtil.make_screen(self, title)
	box.add_child(UiUtil.make_label("+%d gold" % RunState.last_gold_reward, 22, UiUtil.GOLD))
	status_label = UiUtil.make_label("", 18, UiUtil.TEXT)
	box.add_child(status_label)
	var drop: Dictionary = RunState.pending_drop
	if drop.is_empty():
		box.add_child(UiUtil.make_label("No gear dropped.", 18, UiUtil.DIM))
		decided = true
	else:
		box.add_child(UiUtil.make_label("Weapon found: " + GearData.describe(drop), 20,
				GearData.RARITY_COLORS[drop.rarity]))
		box.add_child(UiUtil.make_label("Taking it replaces %s." % RunState.weapon_label(), 16, UiUtil.DIM))
		take_button = UiUtil.make_button("Take %s" % drop.name, _on_take_pressed)
		box.add_child(take_button)
		skip_button = UiUtil.make_button("Skip", _on_skip_pressed)
		box.add_child(skip_button)
	continue_button = UiUtil.make_button("Continue", _on_continue_pressed)
	box.add_child(continue_button)
	_update_ui()


func _update_ui():
	status_label.text = UiUtil.status_line()
	if take_button:
		take_button.disabled = decided
		skip_button.disabled = decided
	continue_button.disabled = not decided
	RunState.qa_dump_ui(self, "reward", {"drop": RunState.pending_drop, "node": RunState.current_node_type})


func _on_take_pressed():
	if decided:
		return
	RunState.equip_weapon(RunState.pending_drop)
	RunState.pending_drop = {}
	decided = true
	_update_ui()


func _on_skip_pressed():
	RunState.pending_drop = {}
	decided = true
	_update_ui()


func _on_continue_pressed():
	if decided:
		get_tree().change_scene_to_file("res://scenes/map.tscn")
