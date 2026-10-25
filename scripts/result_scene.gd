extends Control

@onready var result_text = $VBox/ResultText
@onready var sub_text = $VBox/SubText


const Art = preload("res://scripts/art.gd")


func _ready():
	DisplayServer.window_set_title(ProjectSettings.get_setting("application/config/name"))
	# art-a5: the normal backdrop (palette BG + dim floor) like every other screen; the
	# outcome is carried by the title colour (GOLD win / RED loss), not a tinted background.
	$ColorRect.color = Art.BG
	Art.add_backdrop(self, 1)
	if RunState.portrait:
		# phones: full-width column, word-wrapped lines at the 56 px phone font
		var w := get_viewport_rect().size.x - 40.0
		$VBox.offset_left = -w / 2.0
		$VBox.offset_right = w / 2.0
		result_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sub_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
		result_text.add_theme_color_override("font_color", Art.GOLD)
	else:
		result_text.text = "Fallen"
		sub_text.text = "Defeat in Act %d, row %d\n%s" % [RunState.act, RunState.current_row + 1, "\n".join(lines)]
		result_text.add_theme_color_override("font_color", Art.TXT_NEG)   # art-a6: RED is a fill colour
	RunState.qa_dump_ui(self, "result", {"won": won, "acts_cleared": RunState.acts_cleared, "gold_earned": RunState.gold_earned,
			"renown_earned": renown, "meta": RunState.meta,
			"renown_lines": RunState.renown_breakdown(won), "next_unlock": RunState.next_unlock()})


func _on_play_again_pressed():
	RunState.change_scene("res://scenes/camp.tscn")
