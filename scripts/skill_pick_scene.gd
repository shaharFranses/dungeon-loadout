extends Control
## Skill Point: take Bloodied Edge or Iron Posture. Picking the talent you already
## have ranks it up (max rank 2); picking the other one switches to it at rank 1.

@onready var bloodied_button = $VBox/TalentCards/BloodiedEdge/Button
@onready var bloodied_effect = $VBox/TalentCards/BloodiedEdge/Panel/VBox/Effect
@onready var posture_button = $VBox/TalentCards/IronPosture/Button
@onready var posture_effect = $VBox/TalentCards/IronPosture/Panel/VBox/Effect


func _ready():
	DisplayServer.window_set_title("dungeon_loadout")
	_setup_card("talent_bloodied_edge", bloodied_button, bloodied_effect,
			"Skill: Deal 11 damage\n(rank 2: 15)\nCosts 1 Focus")
	_setup_card("talent_iron_posture", posture_button, posture_effect,
			"Skill: Deal max(6, half Strike)\ndamage + gain 4 Block\n(rank 2: +2 dmg)\nCosts 1 Focus")
	RunState.qa_dump_ui(self, "skill")


func _setup_card(talent_id: String, button: Button, effect: Label, text: String):
	effect.text = text
	if RunState.selected_talent == talent_id:
		if RunState.talent_rank >= 2:
			button.text = "Maxed"
			button.disabled = true
		else:
			button.text = "Rank up to 2"
	elif RunState.selected_talent != "":
		button.text = "Switch (rank 1)"
	else:
		button.text = "Select"


func _pick(talent_id: String):
	RunState.pick_talent(talent_id)
	RunState.qa_log("TALENT", {"talent": RunState.talent_label()})
	get_tree().change_scene_to_file("res://scenes/map.tscn")


func _on_bloodied_edge_pressed():
	_pick("talent_bloodied_edge")


func _on_iron_posture_pressed():
	_pick("talent_iron_posture")
