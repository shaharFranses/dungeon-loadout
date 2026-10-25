extends Control

func _ready():
	$ColorRect.color = preload("res://scripts/art.gd").BG   # art-a5: palette BG (was #1A1A26)
	if RunState.portrait:
		# art-a5: phone font is bigger; the title column spans the screen and wraps
		var w := get_viewport_rect().size.x - 40.0
		$VBox.offset_left = -w / 2.0
		$VBox.offset_right = w / 2.0
		$VBox/Title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		# the boot scene is in the tree before RunState hooks node_added, so apply the
		# phone font scale and tap floor here directly
		for n in [$VBox/Title, $VBox/BeginButton]:
			RunState._portrait_scene_fonts(n)
		preload("res://scripts/art.gd").tap($VBox/BeginButton)
	RunState.reset_run()
	RunState.qa_dump_ui(self, "boot")
	if RunState.qa_mode and RunState.qa_scene != "":
		_qa_jump(RunState.qa_scene)


## art-a5 QA only (?qa=1&scene=...): open one screen directly for layout screenshots.
func _qa_jump(scene: String):
	await get_tree().create_timer(0.5).timeout
	match scene:
		"result_win":
			RunState.acts_cleared = RunState.FINAL_ACT
			RunState.change_scene("res://scenes/result.tscn")
		"result_loss":
			RunState.player_hp = 0
			RunState.change_scene("res://scenes/result.tscn")
		"shop":
			RunState.gold = 120
			RunState.change_scene("res://scenes/shop_smith.tscn")
		"skill":
			RunState.talent_pick_source = "skill"
			RunState.change_scene("res://scenes/skill_pick.tscn")
		"rest":
			RunState.player_hp = 20
			RunState.change_scene("res://scenes/rest.tscn")
		"reward", "reward_boss":
			RunState.current_node_type = "boss" if scene == "reward_boss" else "elite"
			RunState.on_combat_won()
			RunState.change_scene("res://scenes/reward.tscn")
		"camp":
			RunState.change_scene("res://scenes/camp.tscn")

func _on_begin_pressed():
	# Stage D: the camp (Renown unlocks, Ascension) comes before every run.
	RunState.change_scene("res://scenes/camp.tscn")
