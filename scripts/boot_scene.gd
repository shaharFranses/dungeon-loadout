extends Control

func _ready():
	RunState.reset_run()
	RunState.qa_dump_ui(self, "boot")

func _on_begin_pressed():
	# Stage D: the camp (Renown unlocks, Ascension) comes before every run.
	get_tree().change_scene_to_file("res://scenes/camp.tscn")
