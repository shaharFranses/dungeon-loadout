extends Control

@onready var result_text = $VBox/ResultText
@onready var sub_text = $VBox/SubText


func _ready():
	DisplayServer.window_set_title("dungeon_loadout")
	var won := RunState.player_hp > 0
	var lines: Array = [
		"Acts cleared: %d / %d    Gold earned: %d    Elites killed: %d" % [
				RunState.acts_cleared, RunState.FINAL_ACT, RunState.gold_earned, RunState.elites_killed],
		"HP %d/%d    %s" % [RunState.player_hp, RunState.player_max_hp, RunState.gear_line()],
		"Talents: %s" % RunState.talent_label(),
	]
	if won:
		result_text.text = "Dragon's Vault Cleared"
		sub_text.text = "Victory!\n" + "\n".join(lines)
		$ColorRect.color = Color(0.1, 0.15, 0.1)
	else:
		result_text.text = "Fallen"
		sub_text.text = "Defeat in Act %d, row %d\n%s" % [RunState.act, RunState.current_row + 1, "\n".join(lines)]
		$ColorRect.color = Color(0.15, 0.1, 0.1)
	RunState.qa_dump_ui(self, "result", {"won": won, "acts_cleared": RunState.acts_cleared, "gold_earned": RunState.gold_earned})


func _on_play_again_pressed():
	get_tree().change_scene_to_file("res://scenes/boot.tscn")
