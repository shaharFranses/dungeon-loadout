extends Control

func _ready():
	DisplayServer.window_set_title("dungeon_loadout")

func _on_bloodied_edge_pressed():
	RunState.pick_talent("talent_bloodied_edge")
	RunState.advance_map()
	get_tree().change_scene_to_file("res://scenes/map.tscn")

func _on_iron_posture_pressed():
	RunState.pick_talent("talent_iron_posture")
	RunState.advance_map()
	get_tree().change_scene_to_file("res://scenes/map.tscn")
