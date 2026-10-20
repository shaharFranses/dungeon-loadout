extends Control
## Rest node (LOOP_SPEC v3.1 section 1): heal 30% max HP, or Train (+1 talent rank).

const UiUtil = preload("res://scripts/ui_util.gd")


func _ready():
	DisplayServer.window_set_title("dungeon_loadout")
	var box := UiUtil.make_screen(self, "Rest")
	box.add_child(UiUtil.make_label(UiUtil.status_line(), 18, UiUtil.GOLD))
	box.add_child(UiUtil.make_label("Choose one.", 18, UiUtil.DIM))
	var heal_amount := mini(RunState.rest_heal_amount(), RunState.player_max_hp - RunState.player_hp)
	box.add_child(UiUtil.make_button("Heal %d HP (30%% of max)" % heal_amount, _on_heal_pressed, 420.0))
	var train := UiUtil.make_button("", _on_train_pressed, 420.0)
	if RunState.selected_talent == "":
		train.text = "Train: no talent yet"
		train.disabled = true
	elif not RunState.can_train():
		train.text = "Train: %s is maxed" % RunState.talent_label()
		train.disabled = true
	else:
		train.text = "Train: %s to rank %d" % [RunState.talent_label().split(" r")[0], RunState.talent_rank + 1]
	box.add_child(train)
	RunState.qa_dump_ui(self, "rest", {"heal": heal_amount})


func _on_heal_pressed():
	var healed := RunState.heal(RunState.rest_heal_amount())
	RunState.qa_log("REST", {"choice": "heal", "healed": healed, "hp": RunState.player_hp})
	get_tree().change_scene_to_file("res://scenes/map.tscn")


func _on_train_pressed():
	if not RunState.can_train():
		return
	RunState.train_talent()
	RunState.qa_log("REST", {"choice": "train", "talent": RunState.talent_label()})
	get_tree().change_scene_to_file("res://scenes/map.tscn")
