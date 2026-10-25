extends Control
## Rest node (LOOP_SPEC section 1): heal 30% max HP, or Train (+1 rank to a talent you have).

const TalentData = preload("res://scripts/talent_data.gd")
const UiUtil = preload("res://scripts/ui_util.gd")


func _ready():
	DisplayServer.window_set_title(ProjectSettings.get_setting("application/config/name"))
	var box := UiUtil.make_screen(self, "Rest")
	box.add_child(UiUtil.make_status(18, UiUtil.GOLD))
	box.add_child(UiUtil.make_label("Choose one.", 18, UiUtil.DIM))
	var heal_amount := mini(RunState.rest_heal_amount(), RunState.player_max_hp - RunState.player_hp)
	box.add_child(UiUtil.with_icon(UiUtil.make_button("Heal %d HP (30%% of max)" % heal_amount, _on_heal_pressed, 460.0), preload("res://scripts/art.gd").tex(114, 2)))
	var trainable: Array = RunState.trainable_talents()
	if trainable.is_empty():
		var train := UiUtil.make_button("Train: no talent to rank up", _on_heal_pressed, 460.0)
		train.disabled = true
		box.add_child(train)
	for talent_id in trainable:
		var text := "Train: %s to rank 2 (%s)" % [TalentData.get_def(talent_id).name, TalentData.describe(talent_id, 2)]
		box.add_child(UiUtil.with_icon(UiUtil.make_button(text, _on_train_pressed.bind(talent_id), 460.0), preload("res://scripts/art.gd").talent_tex(talent_id, 2)))
	RunState.qa_dump_ui(self, "rest", {"heal": heal_amount})


func _on_heal_pressed():
	var healed := RunState.heal(RunState.rest_heal_amount())
	RunState.qa_log("REST", {"choice": "heal", "healed": healed, "hp": RunState.player_hp})
	RunState.change_scene("res://scenes/map.tscn")


func _on_train_pressed(talent_id: String):
	if not RunState.trainable_talents().has(talent_id):
		return
	RunState.pick_talent(talent_id)
	RunState.qa_log("REST", {"choice": "train", "talent": RunState.talent_label()})
	RunState.change_scene("res://scenes/map.tscn")
