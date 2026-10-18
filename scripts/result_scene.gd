extends Control

@onready var result_text = $VBox/ResultText
@onready var sub_text = $VBox/SubText

func _ready():
	DisplayServer.window_set_title("dungeon_loadout")
	if RunState.player_hp > 0:
		result_text.text = "Crypt Cleared"
		sub_text.text = "Victory!"
		$ColorRect.color = Color(0.1, 0.15, 0.1)
	else:
		result_text.text = "Fallen"
		sub_text.text = "Defeat..."
		$ColorRect.color = Color(0.15, 0.1, 0.1)

func _on_play_again_pressed():
	get_tree().change_scene_to_file("res://scenes/boot.tscn")
