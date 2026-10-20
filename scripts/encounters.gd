extends RefCounted
## Enemies for Acts 1-3, LOOP_SPEC section 2. HP values are taken from the act tables.

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
const GHOUL := {"id": "enemy_ghoul", "name": "Ghoul", "hp": 26, "elite": true, "pattern": [
	{"type": "strike", "value": 6},
	{"type": "rend", "value": 4, "bleed": 2, "bleed_turns": 2},
	{"type": "strike", "value": 8},
]}
const BONE_WARDEN := {"id": "enemy_bone_warden", "name": "Bone Warden", "hp": 33, "boss": true, "pattern": [
	{"type": "strike", "value": 7},
	{"type": "strike", "value": 7},
	{"type": "heavy", "value": 11},
]}


# ---- Act 2: Sunken Halls ----
const DROWNED := {"id": "enemy_drowned", "name": "Drowned", "hp": 14, "pattern": [
	{"type": "strike", "value": 6},
	{"type": "strike", "value": 6},
	{"type": "guard", "value": 4},
]}
# v3.5: the Drowned King's summon is weaker than a regular Drowned.
const DROWNED_SUMMON := {"id": "enemy_drowned", "name": "Drowned", "hp": 10, "pattern": [
	{"type": "strike", "value": 4},
	{"type": "strike", "value": 4},
	{"type": "guard", "value": 4},
]}
const BOG_WITCH := {"id": "enemy_bog_witch", "name": "Bog Witch", "hp": 20, "pattern": [
	{"type": "hex", "value": 3},
	{"type": "strike", "value": 8},
	{"type": "guard", "value": 6},
]}
const GNOLL := {"id": "enemy_gnoll", "name": "Gnoll", "hp": 24, "pattern": [
	{"type": "strike", "value": 5, "hits": 2},
	{"type": "strike", "value": 9},
]}
const TROLL := {"id": "enemy_troll", "name": "Troll", "hp": 44, "elite": true, "pattern": [
	{"type": "strike", "value": 10},
	{"type": "regen", "value": 6},
	{"type": "heavy", "value": 12},
]}
const DROWNED_KING := {"id": "enemy_drowned_king", "name": "Drowned King", "hp": 52, "boss": true, "pattern": [
	{"type": "summon", "value": 1, "after_strike": 8},  # once per fight, then Strike 8
	{"type": "strike", "value": 8},
	{"type": "tidal", "value": 12},
]}

# ---- Act 3: Dragon's Vault ----
const KOBOLD := {"id": "enemy_kobold", "name": "Kobold", "hp": 10, "pattern": [
	{"type": "strike", "value": 5},
	{"type": "strike", "value": 5},
	{"type": "strike", "value": 5},
]}
const GOLEM := {"id": "enemy_golem", "name": "Golem", "hp": 40, "pattern": [
	{"type": "guard", "value": 10},
	{"type": "heavy", "value": 18},
]}
const WRAITH := {"id": "enemy_wraith", "name": "Wraith", "hp": 26, "pattern": [
	{"type": "drain", "value": 8},
	{"type": "strike", "value": 7},
]}
const DEATH_KNIGHT := {"id": "enemy_death_knight", "name": "Death Knight", "hp": 64, "elite": true, "pattern": [
	{"type": "strike", "value": 12},
	{"type": "guard", "value": 10},
	{"type": "heavy", "value": 16},
]}
const RED_DRAGON := {"id": "enemy_red_dragon", "name": "Young Red Dragon", "hp": 85, "boss": true, "pattern": [
	{"type": "strike", "value": 12},
	{"type": "heavy", "value": 15, "label": "Breath"},
	{"type": "guard", "value": 8},
	{"type": "strike", "value": 12},
]}

const ACTS := {
	1: {"name": "The Crypt", "battles": [[RAT, RAT], [SKELETON], [CULTIST]], "elite": GHOUL, "boss": BONE_WARDEN},
	2: {"name": "Sunken Halls", "battles": [[DROWNED, DROWNED], [BOG_WITCH], [GNOLL]], "elite": TROLL, "boss": DROWNED_KING},
	3: {"name": "Dragon's Vault", "battles": [[KOBOLD, KOBOLD, KOBOLD], [GOLEM], [WRAITH]], "elite": DEATH_KNIGHT, "boss": RED_DRAGON},
}


static func act_name(act: int) -> String:
	return String(ACTS[act].name)


## Builds the enemy list for a map node. Act 1's first battle is always Crypt Rats x2;
## other battles draw from the act's pool. Non-boss enemies start their intent
## cycle at a random point so packs do not sync.
static func build(rng: RandomNumberGenerator, node_type: String, row: int, act: int = 1) -> Array:
	var data: Dictionary = ACTS[act]
	var defs: Array = []
	match node_type:
		"boss":
			defs = [data.boss]
		"elite":
			defs = [data.elite]
		_:
			if act == 1 and row == 0:
				defs = [RAT, RAT]
			else:
				var options: Array = data.battles
				defs = options[rng.randi_range(0, options.size() - 1)]
	var setup: Array = []
	for def in defs:
		setup.append(make_enemy(rng, def))
	return setup


static func make_enemy(rng: RandomNumberGenerator, def: Dictionary) -> Dictionary:
	var entry: Dictionary = def.duplicate(true)
	entry["offset"] = 0 if entry.get("boss", false) else rng.randi_range(0, entry.pattern.size() - 1)
	return entry
