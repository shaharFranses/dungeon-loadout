extends Node

signal gear_equipped(gear_id: String)
signal talent_picked(talent_id: String)
signal gold_changed(new_gold: int)

var player_max_hp: int = 36
var player_hp: int = 36
var player_focus_max: int = 2

var gold: int = 0
var equipped_gear: String = ""
var selected_talent: String = ""
var hone_edge_used: bool = false

var map_progress: int = 0
var middle_node_choice: String = ""

var strike_damage: int = 6

func reset_run():
	player_hp = player_max_hp
	gold = 0
	equipped_gear = ""
	selected_talent = ""
	hone_edge_used = false
	map_progress = 0
	middle_node_choice = ""
	strike_damage = 6

func add_gold(amount: int):
	gold += amount
	gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		gold_changed.emit(gold)
		return true
	return false

func equip_gear_iron_longsword():
	equipped_gear = "gear_iron_longsword"
	strike_damage = 9
	gear_equipped.emit(equipped_gear)

func hone_edge():
	if not hone_edge_used:
		strike_damage += 2
		hone_edge_used = true

func pick_talent(talent_id: String):
	selected_talent = talent_id
	talent_picked.emit(talent_id)

func advance_map():
	map_progress += 1

func choose_middle_node(node_id: String):
	middle_node_choice = node_id

func get_skill_effect() -> Dictionary:
	match selected_talent:
		"talent_bloodied_edge":
			return {"type": "damage", "value": 11}
		"talent_iron_posture":
			return {"type": "strike_and_block", "damage": strike_damage, "block": 6}
		_:
			return {"type": "none", "value": 0}
