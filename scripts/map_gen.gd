extends RefCounted
## Act map generator, LOOP_SPEC v3.1 section 1.
## 6 rows + boss, 2-3 nodes per row, each node links to 1-2 nodes in the next row,
## links never cross. Whole-map counts: Battle 6-7, Elite 1-2, Skill Point 2,
## Shop+Smith 2, Rest 2-3 (v3.2: row 6 is 2 Rests, at most 1 more in rows 4-5).

const ROWS: int = 6
const MAX_TRIES: int = 500

const ALLOWED := [
	["battle"],
	["battle", "skill", "shop"],
	["battle", "skill", "shop"],
	["elite", "battle", "rest"],
	["battle", "shop", "skill", "rest"],
	["rest"],
]


## Returns {"rows": [[{"type": String, "links": [int]}]], "boss_row": ROWS}.
static func generate(rng: RandomNumberGenerator) -> Dictionary:
	for _attempt in range(MAX_TRIES):
		var sizes: Array = []
		for _r in range(ROWS - 1):
			sizes.append(rng.randi_range(2, 3))
		sizes.append(2)
		var types = _assign_types(rng, sizes)
		if types.is_empty():
			continue
		var links = _make_links(rng, sizes)
		if links.is_empty():
			continue
		var rows: Array = []
		for r in range(ROWS):
			var row: Array = []
			for i in range(sizes[r]):
				row.append({"type": types[r][i], "links": links[r][i]})
			rows.append(row)
		return {"rows": rows, "boss_row": ROWS}
	push_error("map_gen: no valid map after %d tries" % MAX_TRIES)
	return {}


static func _assign_types(rng: RandomNumberGenerator, sizes: Array) -> Array:
	var rest_extra: int = rng.randi_range(0, 1)
	var elites := rng.randi_range(1, 2)
	var bag: Array = []
	for _i in range(elites):
		bag.append("elite")
	bag.append_array(["skill", "skill", "shop", "shop"])
	for _i in range(rest_extra):
		bag.append("rest")
	var middle_slots := 0
	for r in range(1, 5):
		middle_slots += int(sizes[r])
	var battles_middle := middle_slots - bag.size()
	var battles_total := battles_middle + int(sizes[0])
	if battles_middle < 0 or battles_total < 6 or battles_total > 7:
		return []
	for _i in range(battles_middle):
		bag.append("battle")
	_shuffle(rng, bag)

	var types: Array = []
	var cursor := 0
	for r in range(ROWS):
		var row: Array = []
		for _i in range(sizes[r]):
			if r == 0:
				row.append("battle")
			elif r == 5:
				row.append("rest")
			else:
				row.append(bag[cursor])
				cursor += 1
		types.append(row)

	for r in range(1, 5):
		var seen := {}
		for t in types[r]:
			if not ALLOWED[r].has(t):
				return []
			# Two Skill Points or two Shops side by side waste a pick.
			if t != "battle" and t != "elite" and seen.has(t):
				return []
			seen[t] = true
	return types


static func _make_links(rng: RandomNumberGenerator, sizes: Array) -> Array:
	var all_links: Array = []
	for r in range(ROWS):
		var row_links: Array = []
		if r == ROWS - 1:
			for _i in range(sizes[r]):
				row_links.append([0])
			all_links.append(row_links)
			continue
		var a: int = sizes[r]
		var b: int = sizes[r + 1]
		var ok := false
		for _try in range(50):
			row_links = []
			for i in range(a):
				var primary := roundi(float(i) * float(b - 1) / float(a - 1))
				var targets: Array = [primary]
				if rng.randf() < 0.5:
					var side := primary + (1 if rng.randf() < 0.5 else -1)
					if side >= 0 and side < b:
						targets.append(side)
				targets.sort()
				row_links.append(targets)
			if _links_valid(row_links, b):
				ok = true
				break
		if not ok:
			return []
		all_links.append(row_links)
	return all_links


static func _links_valid(row_links: Array, next_size: int) -> bool:
	var incoming := []
	incoming.resize(next_size)
	incoming.fill(0)
	for i in range(row_links.size()):
		for t in row_links[i]:
			incoming[t] += 1
		if i > 0 and int(row_links[i - 1].max()) > int(row_links[i].min()):
			return false
	for count in incoming:
		if count == 0:
			return false
	return true


static func _shuffle(rng: RandomNumberGenerator, arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


static func count_types(map: Dictionary) -> Dictionary:
	var counts := {}
	for row in map.rows:
		for node in row:
			counts[node.type] = int(counts.get(node.type, 0)) + 1
	return counts
