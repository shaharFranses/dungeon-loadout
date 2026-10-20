extends Control

@onready var result_text = $VBox/ResultText
@onready var sub_text = $VBox/SubText


func _ready():
	DisplayServer.window_set_title("dungeon_loadout")
	var won := RunState.player_hp > 0
	var renown := RunState.finish_run(won)
	var lines: Array = [
		"Acts cleared: %d / %d    Gold earned: %d    Elites killed: %d" % [
				RunState.acts_cleared, RunState.FINAL_ACT, RunState.gold_earned, RunState.elites_killed],
		"HP %d/%d    %s" % [RunState.player_hp, RunState.player_max_hp, RunState.gear_line()],
		"Talents: %s" % RunState.talent_label(),
	]
	# v3.7 Renown breakdown, line by line.
	lines.append("")
	for line in RunState.renown_breakdown(won):
		lines.append("Renown - %s: +%d" % [line[0], line[1]])
	lines.append("Renown total: +%d%s" % [renown,
			"    (Ascension %d)" % RunState.ascension if RunState.ascension > 0 else ""])
	lines.append("Renown balance: %d" % int(RunState.meta.renown))
	var next := RunState.next_unlock()
	if next.is_empty():
		lines.append("Every camp unlock is owned.")
	else:
		lines.append("Next unlock: %s, %d Renown%s" % [next.name, int(next.cost),
				" (affordable now)" if int(RunState.meta.renown) >= int(next.cost) else ""])
	if won:
		result_text.text = "Dragon's Vault Cleared"
		sub_text.text = "Victory!\n" + "\n".join(lines)
		$ColorRect.color = Color(0.1, 0.15, 0.1)
	else:
		result_text.text = "Fallen"
		sub_text.text = "Defeat in Act %d, row %d\n%s" % [RunState.act, RunState.current_row + 1, "\n".join(lines)]
		$ColorRect.color = Color(0.15, 0.1, 0.1)
	RunState.qa_dump_ui(self, "result", {"won": won, "acts_cleared": RunState.acts_cleared, "gold_earned": RunState.gold_earned,
			"renown_earned": renown, "meta": RunState.meta,
			"renown_lines": RunState.renown_breakdown(won), "next_unlock": RunState.next_unlock()})


func _on_play_again_pressed():
	get_tree().change_scene_to_file("res://scenes/camp.tscn")
