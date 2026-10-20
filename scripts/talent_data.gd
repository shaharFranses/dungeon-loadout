extends RefCounted
## Talent trees (LOOP_SPEC section 4). 3 trees x 4 talents x 2 ranks.
## "skill" talents become the Skill button; the first one you take is your Skill and
## other trees' Skill talents are no longer offered. Everything else is passive.
## "values" holds the rank 1 / rank 2 numbers.

const TALENTS: Array = [
	{"id": "talent_bloodied_edge", "tree": "Warrior", "name": "Bloodied Edge", "skill": true, "values": [11, 15],
			"text": "Skill: deal %d damage"},
	{"id": "talent_strike_bonus", "tree": "Warrior", "name": "Heavy Hands", "values": [3, 5],
			"text": "Strike +%d"},
	{"id": "talent_cleave", "tree": "Warrior", "name": "Cleave", "values": [50, 75],
			"text": "Strike also hits a 2nd enemy for %d%%"},
	{"id": "talent_kill_heal", "tree": "Warrior", "name": "Bloodlust", "values": [4, 7],
			"text": "Each kill heals %d"},
	{"id": "talent_iron_posture", "tree": "Guardian", "name": "Iron Posture", "skill": true, "values": [0, 2],
			"text": "Skill: deal max(6, half Strike) +%d, gain 4 Block"},
	{"id": "talent_guard_bonus", "tree": "Guardian", "name": "Bulwark", "values": [3, 5],
			"text": "Guard +%d"},
	{"id": "talent_keep_block", "tree": "Guardian", "name": "Steady Stance", "values": [50, 75],
			"text": "Keep %d%% of Block between turns"},
	{"id": "talent_thorns", "tree": "Guardian", "name": "Thorns", "values": [3, 5],
			"text": "Attackers take %d per hit"},
	{"id": "talent_firebolt", "tree": "Arcane", "name": "Firebolt", "skill": true, "values": [9, 13],
			"text": "Skill: deal %d damage to all enemies"},
	{"id": "talent_max_focus", "tree": "Arcane", "name": "Deep Focus", "values": [1, 2],
			"text": "+%d max Focus"},
	{"id": "talent_free_skill", "tree": "Arcane", "name": "Flow", "values": [3, 2],
			"text": "Skill costs 0 every %d turns"},
	{"id": "talent_start_focus", "tree": "Arcane", "name": "Prepared", "values": [2, 3],
			"text": "Start fights with %d Focus"},
]

const MAX_RANK: int = 2
const OFFER_COUNT: int = 3


static func get_def(talent_id: String) -> Dictionary:
	for t in TALENTS:
		if t.id == talent_id:
			return t
	return {}


static func value(talent_id: String, rank: int) -> int:
	if rank <= 0:
		return 0
	return int(get_def(talent_id).values[mini(rank, MAX_RANK) - 1])


static func describe(talent_id: String, rank: int) -> String:
	var def := get_def(talent_id)
	return String(def.text) % value(talent_id, maxi(rank, 1))


## Up to 3 talents drawn from what you have not maxed. Your first pick is always
## one of the 3 tree Skills (it becomes your Skill button); after that, other trees'
## Skill talents are left out.
## locked_trees: trees not unlocked yet (Stage D: Arcane until 30 Renown).
static func roll_offer(rng: RandomNumberGenerator, ranks: Dictionary, skill_id: String, locked_trees: Array = []) -> Array:
	if skill_id == "":
		var skills: Array = []
		for t in TALENTS:
			if t.get("skill", false) and not locked_trees.has(t.tree):
				skills.append(t.id)
		return skills
	var pool: Array = []
	for t in TALENTS:
		var rank := int(ranks.get(t.id, 0))
		if rank >= MAX_RANK or locked_trees.has(t.tree):
			continue
		if t.get("skill", false) and skill_id != "" and t.id != skill_id:
			continue
		pool.append(t.id)
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	return pool.slice(0, OFFER_COUNT)
