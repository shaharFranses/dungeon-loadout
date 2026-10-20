extends RefCounted
## Act 1 (Crypt) enemies, LOOP_SPEC v3.1 section 2.

const RAT := {"id": "enemy_rat", "name": "Crypt Rat", "hp": 8, "pattern": [
	{"type": "strike", "value": 4},
	{"type": "strike", "value": 4},
	{"type": "guard", "value": 3},
]}
const SKELETON := {"id": "enemy_skeleton", "name": "Skeleton", "hp": 14, "pattern": [
	{"type": "strike", "value": 6},
	{"type": "guard", "value": 5},
	{"type": "strike", "value": 6},
]}
const CULTIST := {"id": "enemy_cultist", "name": "Cultist", "hp": 12, "pattern": [
	{"type": "buff", "value": 2},
	{"type": "strike", "value": 5},
	{"type": "strike", "value": 5},
]}
const GHOUL := {"id": "enemy_ghoul", "name": "Ghoul", "hp": 30, "elite": true, "pattern": [
	{"type": "strike", "value": 6},
	{"type": "rend", "value": 4, "bleed": 2, "bleed_turns": 2},
	{"type": "strike", "value": 9},
]}
const BONE_WARDEN := {"id": "enemy_bone_warden", "name": "Bone Warden", "hp": 33, "boss": true, "pattern": [
	{"type": "strike", "value": 7},
	{"type": "strike", "value": 7},
	{"type": "heavy", "value": 11},
]}


## Builds the enemy list for a map node. The first battle is always Crypt Rats x2;
## later battles draw from Rats x2, Skeleton or Cultist. Non-boss enemies start
## their intent cycle at a random point so packs do not sync.
static func build(rng: RandomNumberGenerator, node_type: String, row: int) -> Array:
	var defs: Array = []
	match node_type:
		"boss":
			defs = [BONE_WARDEN]
		"elite":
			defs = [GHOUL]
		_:
			if row == 0:
				defs = [RAT, RAT]
			else:
				var options := [[RAT, RAT], [SKELETON], [CULTIST]]
				defs = options[rng.randi_range(0, options.size() - 1)]
	var setup: Array = []
	for def in defs:
		var entry: Dictionary = def.duplicate(true)
		entry["offset"] = 0 if entry.get("boss", false) else rng.randi_range(0, entry.pattern.size() - 1)
		setup.append(entry)
	return setup
