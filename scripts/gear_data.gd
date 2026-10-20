extends RefCounted
## Weapon pool and rarity tables (LOOP_SPEC v3.1 section 3, Stage B: Weapon slot only).

const BASE_STRIKE: int = 6
const HONE_BONUS: int = 2

const RARITY_COLORS := {
	"common": Color("#E8E2D0"),
	"uncommon": Color("#5DBB63"),
	"rare": Color("#3FA7D6"),
	"legendary": Color("#E3B341"),
}

const SHOP_PRICES := {"common": 30, "uncommon": 70, "rare": 120}

# 12 weapons. "burn": damage the struck enemy takes at the start of each enemy turn.
# "instakill": chance (0-1) that a Strike kills a non-boss outright.
const WEAPONS: Array = [
	{"id": "rusty_shortsword", "name": "Rusty Shortsword", "rarity": "common", "strike": 7},
	{"id": "hand_axe", "name": "Hand Axe", "rarity": "common", "strike": 8},
	{"id": "oak_cudgel", "name": "Oak Cudgel", "rarity": "common", "strike": 8},
	{"id": "iron_longsword", "name": "Iron Longsword", "rarity": "common", "strike": 9},
	{"id": "steel_longsword", "name": "Steel Longsword", "rarity": "uncommon", "strike": 11},
	{"id": "war_pick", "name": "War Pick", "rarity": "uncommon", "strike": 11},
	{"id": "steel_axe", "name": "Steel Axe", "rarity": "uncommon", "strike": 12},
	{"id": "spiked_mace", "name": "Spiked Mace", "rarity": "uncommon", "strike": 12},
	{"id": "flame_blade", "name": "Flame Blade", "rarity": "rare", "strike": 13, "burn": 2},
	{"id": "moonblade", "name": "Moonblade", "rarity": "rare", "strike": 13},
	{"id": "knights_greatsword", "name": "Knight's Greatsword", "rarity": "rare", "strike": 14},
	{"id": "vorpal_sword", "name": "Vorpal Sword", "rarity": "legendary", "strike": 16, "instakill": 0.1},
]

const BATTLE_DROP_CHANCE: float = 0.4
const BATTLE_RARITY := {"common": 70, "uncommon": 25, "rare": 5}
const ELITE_RARITY := {"uncommon": 75, "rare": 25}
const SHOP_RARITY := {"common": 50, "uncommon": 35, "rare": 15}


static func roll_rarity(rng: RandomNumberGenerator, table: Dictionary) -> String:
	var total := 0
	for key in table:
		total += int(table[key])
	var roll := rng.randi_range(1, total)
	for key in table:
		roll -= int(table[key])
		if roll <= 0:
			return key
	return table.keys()[0]


static func pick_weapon(rng: RandomNumberGenerator, rarity: String, exclude_ids: Array = []) -> Dictionary:
	var pool: Array = []
	for weapon in WEAPONS:
		if weapon.rarity == rarity and not exclude_ids.has(weapon.id):
			pool.append(weapon)
	if pool.is_empty():
		for weapon in WEAPONS:
			if weapon.rarity == rarity:
				pool.append(weapon)
	return (pool[rng.randi_range(0, pool.size() - 1)] as Dictionary).duplicate()


static func describe(weapon: Dictionary) -> String:
	var text := "%s (%s): Strike %d" % [weapon.name, String(weapon.rarity).capitalize(), weapon.strike]
	if weapon.get("burn", 0) > 0:
		text += ", +%d burn per turn" % weapon.burn
	if weapon.get("instakill", 0.0) > 0.0:
		text += ", %d%% instakill on non-bosses" % roundi(weapon.instakill * 100.0)
	return text
