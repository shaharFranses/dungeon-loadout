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
	{"id": "rusty_shortsword", "slot": "weapon", "name": "Rusty Shortsword", "rarity": "common", "strike": 7},
	{"id": "hand_axe", "slot": "weapon", "name": "Hand Axe", "rarity": "common", "strike": 8},
	{"id": "oak_cudgel", "slot": "weapon", "name": "Oak Cudgel", "rarity": "common", "strike": 8},
	{"id": "iron_longsword", "slot": "weapon", "name": "Iron Longsword", "rarity": "common", "strike": 9},
	{"id": "steel_longsword", "slot": "weapon", "name": "Steel Longsword", "rarity": "uncommon", "strike": 11},
	{"id": "war_pick", "slot": "weapon", "name": "War Pick", "rarity": "uncommon", "strike": 11},
	{"id": "steel_axe", "slot": "weapon", "name": "Steel Axe", "rarity": "uncommon", "strike": 12},
	{"id": "spiked_mace", "slot": "weapon", "name": "Spiked Mace", "rarity": "uncommon", "strike": 12},
	{"id": "flame_blade", "slot": "weapon", "name": "Flame Blade", "rarity": "rare", "strike": 13, "burn": 2},
	{"id": "moonblade", "slot": "weapon", "name": "Moonblade", "rarity": "rare", "strike": 13},
	{"id": "knights_greatsword", "slot": "weapon", "name": "Knight's Greatsword", "rarity": "rare", "strike": 14},
	{"id": "vorpal_sword", "slot": "weapon", "name": "Vorpal Sword", "rarity": "legendary", "strike": 16, "instakill": 0.1},
]

# Armor: "block" = Block at the start of each fight, "guard" = extra Block when you Guard.
const ARMORS: Array = [
	{"id": "padded_jerkin", "slot": "armor", "name": "Padded Jerkin", "rarity": "common", "block": 2, "guard": 0},
	{"id": "leather_armor", "slot": "armor", "name": "Leather Armor", "rarity": "common", "block": 2, "guard": 1},
	{"id": "hide_vest", "slot": "armor", "name": "Hide Vest", "rarity": "common", "block": 3, "guard": 0},
	{"id": "ring_shirt", "slot": "armor", "name": "Ring Shirt", "rarity": "common", "block": 1, "guard": 2},
	{"id": "chain_shirt", "slot": "armor", "name": "Chain Shirt", "rarity": "uncommon", "block": 4, "guard": 1},
	{"id": "scale_mail", "slot": "armor", "name": "Scale Mail", "rarity": "uncommon", "block": 3, "guard": 3},
	{"id": "brigandine", "slot": "armor", "name": "Brigandine", "rarity": "uncommon", "block": 5, "guard": 1},
	{"id": "splint_vest", "slot": "armor", "name": "Splint Vest", "rarity": "uncommon", "block": 4, "guard": 2},
	{"id": "half_plate", "slot": "armor", "name": "Half Plate", "rarity": "rare", "block": 6, "guard": 2},
	{"id": "wardens_mail", "slot": "armor", "name": "Warden's Mail", "rarity": "rare", "block": 5, "guard": 3},
	{"id": "spiked_plate", "slot": "armor", "name": "Spiked Plate", "rarity": "rare", "block": 6, "guard": 1, "thorns": 2},
	{"id": "dragonscale", "slot": "armor", "name": "Dragonscale", "rarity": "legendary", "block": 8, "guard": 3},
]

# Trinkets: one passive rule each.
const TRINKETS: Array = [
	{"id": "bandage_roll", "slot": "trinket", "name": "Bandage Roll", "rarity": "common", "heal_after_fight": 3},
	{"id": "whetstone_charm", "slot": "trinket", "name": "Whetstone Charm", "rarity": "common", "first_strike": 5},
	{"id": "lucky_coin", "slot": "trinket", "name": "Lucky Coin", "rarity": "common", "bonus_gold": 6},
	{"id": "bone_charm", "slot": "trinket", "name": "Bone Charm", "rarity": "common", "start_block": 3},
	{"id": "focus_crystal", "slot": "trinket", "name": "Focus Crystal", "rarity": "uncommon", "max_focus": 1},
	{"id": "healers_locket", "slot": "trinket", "name": "Healer's Locket", "rarity": "uncommon", "heal_after_fight": 6},
	{"id": "duelists_token", "slot": "trinket", "name": "Duelist's Token", "rarity": "uncommon", "first_strike": 8},
	{"id": "guard_talisman", "slot": "trinket", "name": "Guard Talisman", "rarity": "uncommon", "guard": 2},
	{"id": "ember_stone", "slot": "trinket", "name": "Ember Stone", "rarity": "rare", "strike_bonus": 2},
	{"id": "vampire_fang", "slot": "trinket", "name": "Vampire Fang", "rarity": "rare", "kill_heal": 3},
	{"id": "sages_hourglass", "slot": "trinket", "name": "Sage's Hourglass", "rarity": "rare", "start_focus": 2},
	{"id": "crown_of_ages", "slot": "trinket", "name": "Crown of Ages", "rarity": "legendary", "max_focus": 1, "heal_after_fight": 5},
]

const SLOTS := ["weapon", "armor", "trinket"]
const REINFORCE_BONUS: int = 2
const BOSS_RARITY := {"rare": 90, "legendary": 10}

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


static func items_for(slot: String) -> Array:
	match slot:
		"armor":
			return ARMORS
		"trinket":
			return TRINKETS
	return WEAPONS


static func pick_item(rng: RandomNumberGenerator, slot: String, rarity: String, exclude_ids: Array = []) -> Dictionary:
	var items: Array = items_for(slot)
	var pool: Array = []
	for item in items:
		if item.rarity == rarity and not exclude_ids.has(item.id):
			pool.append(item)
	if pool.is_empty():
		for item in items:
			if item.rarity == rarity:
				pool.append(item)
	return (pool[rng.randi_range(0, pool.size() - 1)] as Dictionary).duplicate()


static func pick_weapon(rng: RandomNumberGenerator, rarity: String, exclude_ids: Array = []) -> Dictionary:
	return pick_item(rng, "weapon", rarity, exclude_ids)


static func describe(item: Dictionary) -> String:
	var parts: Array = []
	match String(item.get("slot", "weapon")):
		"weapon":
			parts.append("Strike %d" % item.strike)
			if item.get("burn", 0) > 0:
				parts.append("+%d burn per turn" % item.burn)
			if item.get("instakill", 0.0) > 0.0:
				parts.append("%d%% instakill on non-bosses" % roundi(item.instakill * 100.0))
		"armor":
			parts.append("Block %d at fight start" % item.block)
			if item.get("guard", 0) > 0:
				parts.append("Guard +%d" % item.guard)
			if item.get("thorns", 0) > 0:
				parts.append("Thorns %d" % item.thorns)
		"trinket":
			if item.has("heal_after_fight"):
				parts.append("heal %d after each fight" % item.heal_after_fight)
			if item.has("first_strike"):
				parts.append("first Strike each fight +%d" % item.first_strike)
			if item.has("bonus_gold"):
				parts.append("+%d gold per fight" % item.bonus_gold)
			if item.has("start_block"):
				parts.append("+%d Block at fight start" % item.start_block)
			if item.has("max_focus"):
				parts.append("+%d max Focus" % item.max_focus)
			if item.has("guard"):
				parts.append("Guard +%d" % item.guard)
			if item.has("strike_bonus"):
				parts.append("all Strikes +%d" % item.strike_bonus)
			if item.has("kill_heal"):
				parts.append("heal %d per kill" % item.kill_heal)
			if item.has("start_focus"):
				parts.append("start fights with %d Focus" % item.start_focus)
	return "%s (%s %s): %s" % [item.name, String(item.rarity).capitalize(),
			String(item.get("slot", "weapon")).capitalize(), ", ".join(parts)]
