extends Node

signal gear_equipped(gear_id: String)
signal talent_picked(talent_id: String)
signal gold_changed(new_gold: int)

const GearData = preload("res://scripts/gear_data.gd")
const MapGen = preload("res://scripts/map_gen.gd")
const Encounters = preload("res://scripts/encounters.gd")

const REST_HEAL_PCT: float = 0.3
const SHOP_HEAL_AMOUNT: int = 10
const SHOP_HEAL_PRICE: int = 20
const SHOP_HEAL_MAX_BUYS: int = 2
const HONE_PRICE: int = 20
const ELITE_GOLD: int = 60
const BOSS_GOLD: int = 100

var player_max_hp: int = 36
var player_hp: int = 36
var player_focus_max: int = 2

var gold: int = 0
var weapon: Dictionary = {}
var weapon_honed: bool = false
var selected_talent: String = ""
var talent_rank: int = 0

var rng := RandomNumberGenerator.new()
var run_seed: int = 0
var forced_seed: int = -1
var qa_mode: bool = false

# Act map state. current_row -1 means the run has not entered row 1 yet.
var map: Dictionary = {}
var current_row: int = -1
var current_index: int = -1
var visited: Array = []
var current_node_type: String = ""
var current_encounter: Array = []

# Filled after a won fight for the reward screen.
var last_gold_reward: int = 0
var pending_drop: Dictionary = {}

func _ready():
	_read_url_options()


func _read_url_options():
	if not OS.has_feature("web"):
		return
	var query = JavaScriptBridge.eval("window.location.search", true)
	if typeof(query) != TYPE_STRING:
		return
	for part in String(query).trim_prefix("?").split("&", false):
		var kv = part.split("=")
		if kv[0] == "seed" and kv.size() > 1 and kv[1].is_valid_int():
			forced_seed = int(kv[1])
		elif kv[0] == "qa":
			qa_mode = kv.size() < 2 or kv[1] != "0"


func reset_run():
	if forced_seed >= 0:
		run_seed = forced_seed
	else:
		run_seed = randi()
	rng.seed = run_seed
	player_hp = player_max_hp
	gold = 0
	weapon = {}
	weapon_honed = false
	selected_talent = ""
	talent_rank = 0
	map = MapGen.generate(rng)
	current_row = -1
	current_index = -1
	visited = []
	current_node_type = ""
	current_encounter = []
	last_gold_reward = 0
	pending_drop = {}
	qa_log("RUN", {"seed": run_seed, "map": map_summary()})


func get_strike_damage() -> int:
	if weapon.is_empty():
		return GearData.BASE_STRIKE
	return int(weapon.strike) + (GearData.HONE_BONUS if weapon_honed else 0)


func weapon_label() -> String:
	if weapon.is_empty():
		return "Fists"
	return "%s%s" % [weapon.name, " (honed)" if weapon_honed else ""]


func add_gold(amount: int):
	gold += amount
	gold_changed.emit(gold)


func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		gold_changed.emit(gold)
		return true
	return false


func equip_weapon(new_weapon: Dictionary):
	weapon = new_weapon.duplicate()
	weapon_honed = false
	gear_equipped.emit(String(weapon.id))


func can_hone() -> bool:
	return not weapon.is_empty() and not weapon_honed


func hone_edge():
	if can_hone():
		weapon_honed = true


func heal(amount: int) -> int:
	var before := player_hp
	player_hp = mini(player_hp + amount, player_max_hp)
	return player_hp - before


func rest_heal_amount() -> int:
	return roundi(player_max_hp * REST_HEAL_PCT)


func can_train() -> bool:
	return selected_talent != "" and talent_rank < 2


func pick_talent(talent_id: String):
	if talent_id == selected_talent:
		talent_rank = mini(talent_rank + 1, 2)
	else:
		selected_talent = talent_id
		talent_rank = 1
	talent_picked.emit(talent_id)


func train_talent():
	if can_train():
		talent_rank += 1


func get_skill_effect() -> Dictionary:
	match selected_talent:
		"talent_bloodied_edge":
			return {"type": "damage", "value": 15 if talent_rank >= 2 else 11}
		"talent_iron_posture":
			# v3.3: max(6, floor(Strike / 2)) damage + 4 Block; rank 2 adds +2 damage, Block stays 4.
			var posture_damage: int = maxi(6, floori(get_strike_damage() / 2.0)) + (2 if talent_rank >= 2 else 0)
			return {"type": "strike_and_block", "damage": posture_damage, "block": 4}
		_:
			return {"type": "none", "value": 0}


func talent_label() -> String:
	match selected_talent:
		"talent_bloodied_edge":
			return "Bloodied Edge r%d" % talent_rank
		"talent_iron_posture":
			return "Iron Posture r%d" % talent_rank
		_:
			return "none"


# ---- Map navigation ----

func available_nodes() -> Array:
	## Returns [[row, index], ...] the player may enter next.
	var result: Array = []
	if map.is_empty():
		return result
	if current_row < 0:
		for i in range(map.rows[0].size()):
			result.append([0, i])
	elif current_row < map.boss_row - 1:
		for t in map.rows[current_row][current_index].links:
			result.append([current_row + 1, t])
	elif current_row == map.boss_row - 1:
		result.append([map.boss_row, 0])
	return result


func node_type(row: int, index: int) -> String:
	if row == map.boss_row:
		return "boss"
	return String(map.rows[row][index].type)


func enter_node(row: int, index: int) -> String:
	## Moves onto a node and returns the scene path to load.
	current_row = row
	current_index = index
	visited.append([row, index])
	current_node_type = node_type(row, index)
	qa_log("ENTER", {"row": row + 1, "index": index, "type": current_node_type})
	match current_node_type:
		"battle", "elite", "boss":
			current_encounter = Encounters.build(rng, current_node_type, row)
			return "res://scenes/combat.tscn"
		"shop":
			return "res://scenes/shop_smith.tscn"
		"skill":
			return "res://scenes/skill_pick.tscn"
		"rest":
			return "res://scenes/rest.tscn"
	return "res://scenes/map.tscn"


func on_combat_won():
	## Grants gold and rolls the gear drop for the fight just won.
	pending_drop = {}
	var exclude: Array = [] if weapon.is_empty() else [weapon.id]
	match current_node_type:
		"battle":
			last_gold_reward = rng.randi_range(30, 40)
			if rng.randf() < GearData.BATTLE_DROP_CHANCE:
				var rarity := GearData.roll_rarity(rng, GearData.BATTLE_RARITY)
				pending_drop = GearData.pick_weapon(rng, rarity, exclude)
		"elite":
			last_gold_reward = ELITE_GOLD
			var rarity := GearData.roll_rarity(rng, GearData.ELITE_RARITY)
			pending_drop = GearData.pick_weapon(rng, rarity, exclude)
		"boss":
			last_gold_reward = BOSS_GOLD
	add_gold(last_gold_reward)
	qa_log("WON", {"type": current_node_type, "gold": last_gold_reward, "drop": pending_drop, "hp": player_hp})


func map_summary() -> String:
	if map.is_empty():
		return ""
	var letters := {"battle": "B", "elite": "E", "skill": "S", "shop": "H", "rest": "R"}
	var parts: Array = []
	for r in range(map.rows.size()):
		var nodes: Array = []
		for n in map.rows[r]:
			nodes.append("%s>%s" % [letters[n.type], ",".join(n.links.map(func(x): return str(x)))])
		parts.append("r%d[%s]" % [r + 1, " ".join(nodes)])
	return " ".join(parts)


# ---- QA telemetry (only with ?qa=1 in the page URL) ----

func qa_log(tag: String, data: Dictionary):
	if qa_mode:
		print("DL%s %s" % [tag, JSON.stringify(data)])


func qa_dump_ui(root: Node, scene_name: String, extra: Dictionary = {}):
	if not qa_mode:
		return
	await get_tree().process_frame
	if not is_instance_valid(root) or not root.is_inside_tree():
		return
	var buttons: Array = []
	_collect_buttons(root, buttons)
	var data := {
		"scene": scene_name, "hp": player_hp, "max_hp": player_max_hp, "gold": gold,
		"weapon": weapon_label(), "strike": get_strike_damage(), "talent": talent_label(),
		"buttons": buttons,
	}
	data.merge(extra)
	print("DLUI " + JSON.stringify(data))


func _collect_buttons(node: Node, out: Array):
	if node is BaseButton and node.is_visible_in_tree():
		var rect: Rect2 = node.get_global_rect()
		out.append({
			"text": String(node.text).replace("\n", " | "),
			"x": roundi(rect.get_center().x), "y": roundi(rect.get_center().y),
			"disabled": node.disabled,
		})
	for child in node.get_children():
		_collect_buttons(child, out)
