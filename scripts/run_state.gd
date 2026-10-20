extends Node

signal gear_equipped(gear_id: String)
signal talent_picked(talent_id: String)
signal gold_changed(new_gold: int)

const GearData = preload("res://scripts/gear_data.gd")
const TalentData = preload("res://scripts/talent_data.gd")
const MapGen = preload("res://scripts/map_gen.gd")
const Encounters = preload("res://scripts/encounters.gd")
const MetaStore = preload("res://scripts/meta_store.gd")

const REST_HEAL_PCT: float = 0.3
const SHOP_HEAL_AMOUNT: int = 10
const SHOP_HEAL_PRICE: int = 20
const SHOP_HEAL_MAX_BUYS: int = 2
const HONE_PRICE: int = 20
const REINFORCE_PRICE: int = 25
const ELITE_GOLD: int = 60
const BOSS_GOLD: int = 100
const BASE_GUARD: int = 5
const BASE_FOCUS_MAX: int = 2
const FINAL_ACT: int = 3

const ACT_MAX_HP := {1: 36, 2: 48, 3: 60}  # v3.4: +12 per act

# ---- Stage D meta (LOOP_SPEC section 5) ----
const RENOWN_PER_ACT: int = 10
const RENOWN_PER_ELITE: int = 3
const RENOWN_PER_BOSS: int = 10
const RENOWN_WIN_BONUS: int = 20
const MAX_ASCENSION: int = 5
const ASCENSION_HP_STEP: float = 0.10
const UNLOCKS := {
	"arcane": {"name": "Arcane talent tree", "cost": 30,
			"text": "Firebolt, Deep Focus, Flow and Prepared join talent offers."},
	"gear_sunken": {"name": "Gear: Sunken Armory", "cost": 20,
			"text": "Coral Spear, Harpoon, Kelp Wrap, Tide Pearl, Shark's Tooth."},
	"gear_hoard": {"name": "Gear: Dragon Hoard", "cost": 20,
			"text": "Ember Glaive, Gilded Cuirass, Drakehide, Dragon Eye, Hoard Coin."},
	"start_item": {"name": "Starting item", "cost": 50,
			"text": "Before each run, pick 1 of 3 Common items (one per slot)."},
}
const UNLOCK_ORDER := ["arcane", "gear_sunken", "gear_hoard", "start_item"]

var meta: Dictionary = {}
var meta_storage_ok: bool = true
var ascension: int = 0
var bosses_killed: int = 0
var run_renown: int = 0
var run_finished: bool = false
var start_item_taken: bool = false
var player_max_hp: int = 36
var player_hp: int = 36

var gold: int = 0
var gold_earned: int = 0
var gear := {"weapon": {}, "armor": {}, "trinket": {}}
var weapon_honed: bool = false
var armor_reinforced: bool = false
var talents: Dictionary = {}
var skill_id: String = ""

var rng := RandomNumberGenerator.new()
var run_seed: int = 0
var forced_seed: int = -1
# QA only (?qa=1&act=N): start the run at act N.
var forced_act: int = 1
var qa_mode: bool = false

var act: int = 1
var acts_cleared: int = 0
var elites_killed: int = 0

# Act map state. current_row -1 means the act has not entered row 1 yet.
var map: Dictionary = {}
var current_row: int = -1
var current_index: int = -1
var visited: Array = []
var current_node_type: String = ""
var current_encounter: Array = []

# Filled after a won fight for the reward screen.
var last_gold_reward: int = 0
var last_fight_heal: int = 0
var pending_offers: Array = []
# "skill" (Skill Point node) or "elite" (bonus point after an Elite).
var talent_pick_source: String = "skill"

var weapon: Dictionary:
	get:
		return gear.weapon


func _ready():
	meta = MetaStore.load_meta()
	_read_url_options()
	_apply_unlocks()


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
		elif kv[0] == "act" and kv.size() > 1 and kv[1].is_valid_int():
			forced_act = clampi(int(kv[1]), 1, FINAL_ACT)
		elif kv[0] == "meta" and kv.size() > 1:
			qa_meta_ops.append(kv[1])
		elif kv[0] == "renown" and kv.size() > 1 and kv[1].is_valid_int():
			qa_renown = int(kv[1])
	# QA only: ?qa=1&meta=reset wipes saved progress, &renown=N sets unspent Renown.
	if qa_mode:
		if qa_meta_ops.has("reset"):
			MetaStore.clear_meta()
			meta = MetaStore.default_meta()
		if qa_renown >= 0:
			meta.renown = qa_renown
		if qa_meta_ops.has("reset") or qa_renown >= 0:
			save_meta()


var qa_meta_ops: Array = []
var qa_renown: int = -1


func reset_run():
	if forced_seed >= 0:
		run_seed = forced_seed
	else:
		run_seed = randi()
	rng.seed = run_seed
	act = forced_act if qa_mode else 1
	player_max_hp = ACT_MAX_HP[act]
	player_hp = player_max_hp
	gold = 0
	gold_earned = 0
	gear = {"weapon": {}, "armor": {}, "trinket": {}}
	weapon_honed = false
	armor_reinforced = false
	talents = {}
	skill_id = ""
	acts_cleared = act - 1
	elites_killed = 0
	bosses_killed = 0
	run_renown = 0
	run_finished = false
	start_item_taken = false
	ascension = clampi(int(meta.get("ascension", 0)), 0, int(meta.get("max_ascension", 0)))
	_apply_unlocks()
	_start_act()


func _start_act():
	map = MapGen.generate(rng)
	current_row = -1
	current_index = -1
	visited = []
	current_node_type = ""
	current_encounter = []
	last_gold_reward = 0
	pending_offers = []
	qa_log("ACT", {"act": act, "seed": run_seed, "map": map_summary()})


func advance_act():
	## Called after an act boss (not the last). Full heal; gold, gear and talents carry over.
	acts_cleared = act
	act += 1
	player_max_hp = ACT_MAX_HP[act]
	player_hp = player_max_hp
	_start_act()


func act_title() -> String:
	return "%s - Act %d" % [Encounters.act_name(act), act]


# ---- Gear ----

func trinket_value(key: String) -> int:
	return int(gear.trinket.get(key, 0))


func get_strike_damage() -> int:
	var base := GearData.BASE_STRIKE
	if not gear.weapon.is_empty():
		base = int(gear.weapon.strike) + (GearData.HONE_BONUS if weapon_honed else 0)
	return base + talent_value("talent_strike_bonus") + trinket_value("strike_bonus")


func get_guard_amount() -> int:
	return BASE_GUARD + int(gear.armor.get("guard", 0)) + talent_value("talent_guard_bonus") + trinket_value("guard")


func get_start_block() -> int:
	var block := trinket_value("start_block")
	if not gear.armor.is_empty():
		block += int(gear.armor.block) + (GearData.REINFORCE_BONUS if armor_reinforced else 0)
	return block


func get_max_focus() -> int:
	return BASE_FOCUS_MAX + talent_value("talent_max_focus") + trinket_value("max_focus")


func get_start_focus() -> int:
	return mini(maxi(1, maxi(talent_value("talent_start_focus"), trinket_value("start_focus"))), get_max_focus())


func get_thorns() -> int:
	return talent_value("talent_thorns") + int(gear.armor.get("thorns", 0))


func get_kill_heal() -> int:
	return talent_value("talent_kill_heal") + trinket_value("kill_heal")


func get_first_strike_bonus() -> int:
	return trinket_value("first_strike")


func get_keep_block_pct() -> int:
	return talent_value("talent_keep_block")


func get_cleave_pct() -> int:
	return talent_value("talent_cleave")


func get_free_skill_every() -> int:
	return talent_value("talent_free_skill")


func item_label(slot: String) -> String:
	var item: Dictionary = gear[slot]
	if item.is_empty():
		return "Fists" if slot == "weapon" else "none"
	var suffix := ""
	if slot == "weapon" and weapon_honed:
		suffix = " (honed)"
	elif slot == "armor" and armor_reinforced:
		suffix = " (reinforced)"
	return String(item.name) + suffix


func weapon_label() -> String:
	return item_label("weapon")


func gear_line() -> String:
	return "Weapon: %s (Strike %d)   Armor: %s   Trinket: %s" % [
			item_label("weapon"), get_strike_damage(), item_label("armor"), item_label("trinket")]


func add_gold(amount: int):
	gold += amount
	gold_earned += amount
	gold_changed.emit(gold)


func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		gold_changed.emit(gold)
		return true
	return false


func equip(item: Dictionary):
	var slot := String(item.get("slot", "weapon"))
	gear[slot] = item.duplicate()
	if slot == "weapon":
		weapon_honed = false
	elif slot == "armor":
		armor_reinforced = false
	gear_equipped.emit(String(item.id))


func equip_weapon(item: Dictionary):
	equip(item)


func can_hone() -> bool:
	return not gear.weapon.is_empty() and not weapon_honed


func hone_edge():
	if can_hone():
		weapon_honed = true


func can_reinforce() -> bool:
	return not gear.armor.is_empty() and not armor_reinforced


func reinforce_armor():
	if can_reinforce():
		armor_reinforced = true


func heal(amount: int) -> int:
	var before := player_hp
	player_hp = mini(player_hp + amount, player_max_hp)
	return player_hp - before


func rest_heal_amount() -> int:
	return roundi(player_max_hp * REST_HEAL_PCT)


# ---- Talents ----

func talent_rank(talent_id: String) -> int:
	return int(talents.get(talent_id, 0))


func talent_value(talent_id: String) -> int:
	return TalentData.value(talent_id, talent_rank(talent_id))


func trainable_talents() -> Array:
	var result: Array = []
	for talent_id in talents:
		if int(talents[talent_id]) < TalentData.MAX_RANK:
			result.append(talent_id)
	return result


func can_train() -> bool:
	return not trainable_talents().is_empty()


func pick_talent(talent_id: String):
	## Takes a new talent at rank 1 or ranks up an owned one (max 2).
	var def := TalentData.get_def(talent_id)
	if def.is_empty():
		return
	talents[talent_id] = mini(talent_rank(talent_id) + 1, TalentData.MAX_RANK)
	if def.get("skill", false) and skill_id == "":
		skill_id = talent_id
	talent_picked.emit(talent_id)


func talent_offer() -> Array:
	return TalentData.roll_offer(rng, talents, skill_id, locked_trees())


func get_skill_effect() -> Dictionary:
	var rank := talent_rank(skill_id)
	match skill_id:
		"talent_bloodied_edge":
			return {"type": "damage", "value": TalentData.value(skill_id, rank)}
		"talent_iron_posture":
			# v3.3: max(6, floor(Strike / 2)) damage + 4 Block; rank 2 adds +2 damage, Block stays 4.
			var posture_damage: int = maxi(6, floori(get_strike_damage() / 2.0)) + TalentData.value(skill_id, rank)
			return {"type": "strike_and_block", "damage": posture_damage, "block": 4}
		"talent_firebolt":
			return {"type": "damage_all", "value": TalentData.value(skill_id, rank)}
		_:
			return {"type": "none", "value": 0}


func talent_label() -> String:
	if talents.is_empty():
		return "none"
	var parts: Array = []
	for talent_id in talents:
		parts.append("%s r%d" % [TalentData.get_def(talent_id).name, talents[talent_id]])
	return ", ".join(parts)


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
	qa_log("ENTER", {"act": act, "row": row + 1, "index": index, "type": current_node_type})
	match current_node_type:
		"battle", "elite", "boss":
			current_encounter = Encounters.build(rng, current_node_type, row, act)
			return "res://scenes/combat.tscn"
		"shop":
			return "res://scenes/shop_smith.tscn"
		"skill":
			talent_pick_source = "skill"
			return "res://scenes/skill_pick.tscn"
		"rest":
			return "res://scenes/rest.tscn"
	return "res://scenes/map.tscn"


func _roll_drop(table: Dictionary) -> Dictionary:
	var slot: String = GearData.SLOTS[rng.randi_range(0, GearData.SLOTS.size() - 1)]
	var rarity := GearData.roll_rarity(rng, table)
	var exclude: Array = [] if gear[slot].is_empty() else [gear[slot].id]
	return GearData.pick_item(rng, slot, rarity, exclude)


func on_combat_won():
	## Grants gold, after-fight healing and the gear offer(s) for the fight just won.
	pending_offers = []
	match current_node_type:
		"battle":
			last_gold_reward = rng.randi_range(30, 40)
			if rng.randf() < GearData.BATTLE_DROP_CHANCE:
				pending_offers.append(_roll_drop(GearData.BATTLE_RARITY))
		"elite":
			last_gold_reward = ELITE_GOLD
			elites_killed += 1
			pending_offers.append(_roll_drop(GearData.ELITE_RARITY))
		"boss":
			last_gold_reward = BOSS_GOLD
			bosses_killed += 1
			if act < FINAL_ACT:
				var taken: Array = []
				for _i in range(3):
					var offer := _roll_drop(GearData.BOSS_RARITY)
					while taken.has(offer.id):
						offer = _roll_drop(GearData.BOSS_RARITY)
					taken.append(offer.id)
					pending_offers.append(offer)
	last_gold_reward += trinket_value("bonus_gold")
	add_gold(last_gold_reward)
	last_fight_heal = heal(trinket_value("heal_after_fight"))
	qa_log("WON", {"act": act, "type": current_node_type, "gold": last_gold_reward, "offers": pending_offers,
			"hp": player_hp, "healed": last_fight_heal})


func after_reward_scene() -> String:
	## Where the reward screen's Continue leads.
	if current_node_type == "elite":
		talent_pick_source = "elite"
		return "res://scenes/skill_pick.tscn"
	if current_node_type == "boss":
		if act >= FINAL_ACT:
			acts_cleared = act
			return "res://scenes/result.tscn"
		advance_act()
	return "res://scenes/map.tscn"


func after_combat_scene() -> String:
	if current_node_type == "boss" and act >= FINAL_ACT:
		acts_cleared = act
		return "res://scenes/result.tscn"
	return "res://scenes/reward.tscn"


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
		"armor": item_label("armor"), "trinket": item_label("trinket"), "act": act,
		"talents": talents, "skill_id": skill_id, "guard": get_guard_amount(),
		"renown": int(meta.get("renown", 0)), "ascension": ascension,
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


# ---- Meta progress: Renown, unlocks, Ascension (Stage D) ----

func save_meta() -> bool:
	meta_storage_ok = MetaStore.save_meta(meta)
	return meta_storage_ok


func is_unlocked(unlock_id: String) -> bool:
	return bool(meta.get("unlocks", {}).get(unlock_id, false))


func can_buy_unlock(unlock_id: String) -> bool:
	return UNLOCKS.has(unlock_id) and not is_unlocked(unlock_id) \
			and int(meta.renown) >= int(UNLOCKS[unlock_id].cost)


func buy_unlock(unlock_id: String) -> bool:
	if not can_buy_unlock(unlock_id):
		return false
	meta.renown = int(meta.renown) - int(UNLOCKS[unlock_id].cost)
	meta.unlocks[unlock_id] = true
	_apply_unlocks()
	save_meta()
	qa_log("UNLOCK", {"id": unlock_id, "renown": meta.renown})
	return true


func _apply_unlocks():
	var batches: Array = []
	for batch in ["gear_sunken", "gear_hoard"]:
		if is_unlocked(batch):
			batches.append(batch)
	GearData.unlocked_batches = batches


func locked_trees() -> Array:
	return [] if is_unlocked("arcane") else ["Arcane"]


func set_ascension(level: int):
	meta.ascension = clampi(level, 0, int(meta.max_ascension))
	save_meta()


func enemy_hp(base_hp: int) -> int:
	## Ascension: +10% enemy HP per level, rounded.
	return roundi(base_hp * (1.0 + ASCENSION_HP_STEP * ascension))


func renown_for_run(won: bool) -> int:
	## LOOP_SPEC 5: acts cleared x10 + elites killed x3 + bosses x10, +20 for a win.
	return acts_cleared * RENOWN_PER_ACT + elites_killed * RENOWN_PER_ELITE \
			+ bosses_killed * RENOWN_PER_BOSS + (RENOWN_WIN_BONUS if won else 0)


func finish_run(won: bool) -> int:
	## Called once by the results screen. Banks Renown and, on a win, opens the next
	## Ascension level (a win at your current top level unlocks one more, up to 5).
	if run_finished:
		return run_renown
	run_finished = true
	run_renown = renown_for_run(won)
	meta.renown = int(meta.renown) + run_renown
	meta.renown_total = int(meta.renown_total) + run_renown
	meta.runs = int(meta.runs) + 1
	if won:
		meta.wins = int(meta.wins) + 1
		if ascension >= int(meta.max_ascension) and int(meta.max_ascension) < MAX_ASCENSION:
			meta.max_ascension = ascension + 1
	save_meta()
	qa_log("RENOWN", {"won": won, "earned": run_renown, "acts": acts_cleared, "elites": elites_killed,
			"bosses": bosses_killed, "ascension": ascension, "meta": meta})
	return run_renown


func start_item_options() -> Array:
	## One Common per slot. Uses its own RNG so taking or skipping does not change the run's seed.
	var pick_rng := RandomNumberGenerator.new()
	pick_rng.seed = hash(str(run_seed) + ":start_item")
	var options: Array = []
	for slot in GearData.SLOTS:
		options.append(GearData.pick_item(pick_rng, slot, "common"))
	return options


func take_start_item(item: Dictionary):
	if not start_item_taken and not item.is_empty():
		equip(item)
	start_item_taken = true
