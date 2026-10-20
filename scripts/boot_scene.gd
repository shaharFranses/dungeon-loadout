extends Control

func _ready():
	RunState.reset_run()
	RunState.qa_dump_ui(self, "boot")

func _on_begin_pressed():
	get_tree().change_scene_to_file("res://scenes/map.tscn")
