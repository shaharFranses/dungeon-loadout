extends Control

@onready var result_text = $VBox/ResultText
@onready var sub_text = $VBox/SubText


func _ready():
	DisplayServer.window_set_title("dungeon_loadout")
	var build := "HP %d/%d  Gold %d  Weapon: %s  Talent: %s" % [RunState.player_hp, RunState.player_max_hp,
			RunState.gold, RunState.weapon_label(), RunState.talent_label()]
	if RunState.player_hp > 0:
		result_text.text = "Crypt Cleared"
		sub_text.text = "Victory!\n" + build
		$ColorRect.color = Color(0.1, 0.15, 0.1)
	else:
		result_text.text = "Fallen"
		sub_text.text = "Defeat... (row %d)\n%s" % [RunState.current_row + 1, build]
		$ColorRect.color = Color(0.15, 0.1, 0.1)
	RunState.qa_dump_ui(self, "result", {"won": RunState.player_hp > 0})


func _on_play_again_pressed():
	get_tree().change_scene_to_file("res://scenes/boot.tscn")
