extends Control
## Act 1 map: 6 generated rows plus the boss, drawn top (row 1) to bottom (boss).

const Art = preload("res://scripts/art.gd")
const MapLinks = preload("res://scripts/map_links.gd")
const Encounters = preload("res://scripts/encounters.gd")

const NODE_SIZE := Vector2(210, 48)
const ROW_TOP: float = 160.0
const ROW_STEP: float = 80.0
const COL_STEP: float = 290.0

const TYPE_LABELS := {
	"battle": "Battle", "elite": "Elite", "skill": "Skill Point",
	"shop": "Shop + Smith", "rest": "Rest", "boss": "Boss",
}
const TYPE_COLORS := {
	"battle": Color("#E8E2D0"), "elite": Color("#C8433A"), "skill": Color("#9B5DE5"),
	"shop": Color("#E3B341"), "rest": Color("#5DBB63"), "boss": Color("#C8433A"),
}

@onready var hp_label = $Header/HPLabel
@onready var gold_label = $Header/GoldLabel
@onready var gear_label = $Header/GearLabel
@onready var title_label = $Header/Title

var links_layer: Control
var row_top: float = ROW_TOP     # art-a4: portrait spreads rows over the tall canvas
var row_step: float = ROW_STEP
var node_buttons := {}


func _ready():
	DisplayServer.window_set_title("dungeon_loadout")
	$ColorRect.color = Art.BG
	preload("res://scripts/art.gd").add_backdrop(self, 1)
	_fit_header()
	links_layer = MapLinks.new()
	links_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	links_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(links_layer)
	_build_nodes()
	_update_ui()


func _node_center(row: int, index: int) -> Vector2:
	var count: int = 1 if row == RunState.map.boss_row else RunState.map.rows[row].size()
	var w := get_viewport_rect().size.x
	var step := minf(COL_STEP, (w - NODE_SIZE.x - 30.0) / 2.0)   # 3 columns fit a 720 portrait canvas
	var x := w / 2.0 + (index - (count - 1) / 2.0) * step
	return Vector2(x, row_top + row * row_step)


## art-a4: HP / Gold split the width around the centre (they were fixed at x 340-940, so
## "Gold" ran off a 720-wide portrait canvas). On portrait the gear line word-wraps and
## the map rows are spread down the tall canvas instead of bunching at the top.
func _fit_header():
	var vp := get_viewport_rect().size
	var mid := vp.x / 2.0
	hp_label.position = Vector2(12.0, hp_label.position.y)
	hp_label.size = Vector2(mid - 32.0, hp_label.size.y)
	gold_label.position = Vector2(mid + 20.0, gold_label.position.y)
	gold_label.size = Vector2(mid - 32.0, gold_label.size.y)
	gold_label.clip_text = true
	if not RunState.portrait:
		return
	gear_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gear_label.offset_left = 16.0
	gear_label.offset_right = -16.0
	gear_label.offset_top = 104.0
	gear_label.offset_bottom = 104.0 + 4.0 * 34.0
	var rows: int = RunState.map.boss_row
	row_top = 330.0
	var bottom := vp.y - 90.0
	row_step = clampf((bottom - row_top) / maxf(1.0, float(rows)), ROW_STEP, 200.0)


func _build_nodes():
	var map: Dictionary = RunState.map
	for row in range(map.boss_row + 1):
		var count: int = 1 if row == map.boss_row else map.rows[row].size()
		for index in range(count):
			var type := RunState.node_type(row, index)
			var button := Button.new()
			button.custom_minimum_size = NODE_SIZE
			button.size = NODE_SIZE
			button.position = _node_center(row, index) - NODE_SIZE / 2.0
			button.add_theme_font_size_override("font_size", Art.fs(18))
			button.icon = Art.node_tex(type, Encounters.ACTS[RunState.act], 2)
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.add_theme_color_override("font_color", TYPE_COLORS[type])
			button.add_theme_color_override("font_disabled_color", TYPE_COLORS[type].darkened(0.55))
			button.pressed.connect(_on_node_pressed.bind(row, index))
			add_child(button)
			node_buttons[[row, index]] = button


func _update_ui():
	hp_label.text = "HP: %d/%d" % [RunState.player_hp, RunState.player_max_hp]
	gold_label.text = "Gold: %d" % RunState.gold
	title_label.text = RunState.act_title()
	gear_label.text = "%s\nTalents: %s" % [RunState.gear_line(), RunState.talent_label()]

	var available: Array = RunState.available_nodes()
	for key in node_buttons:
		var button: Button = node_buttons[key]
		var type := RunState.node_type(key[0], key[1])
		var done: bool = RunState.visited.has(key)
		var label: String = TYPE_LABELS[type]
		if type == "boss":
			label = "Boss: %s" % Encounters.ACTS[RunState.act].boss.name
		if done:
			label += " (done)"
		button.text = label
		button.disabled = not available.has(key)
		button.modulate = Color(1, 1, 1) if (done or available.has(key)) else Color(0.75, 0.75, 0.75)
	_update_links(available)
	RunState.qa_dump_ui(self, "map", {"row": RunState.current_row + 1, "map": RunState.map_summary(), "act": RunState.act})


func _update_links(available: Array):
	var map: Dictionary = RunState.map
	var segments: Array = []
	var half := NODE_SIZE.y / 2.0
	for row in range(map.boss_row):
		for index in range(map.rows[row].size()):
			var targets: Array = [0] if row == map.boss_row - 1 else map.rows[row][index].links
			for t in targets:
				var from := _node_center(row, index) + Vector2(0, half)
				var to := _node_center(row + 1, t) - Vector2(0, half)
				var color := Color("#5A5670")
				var width := 2.0
				if RunState.visited.has([row, index]) and RunState.visited.has([row + 1, t]):
					color = Color("#E8E2D0")
					width = 4.0
				elif row == RunState.current_row and index == RunState.current_index and available.has([row + 1, t]):
					color = Color("#E3B341")
					width = 3.0
				segments.append([from, to, color, width])
	links_layer.segments = segments
	links_layer.queue_redraw()


func _on_node_pressed(row: int, index: int):
	if not RunState.available_nodes().has([row, index]):
		return
	for key in node_buttons:
		node_buttons[key].disabled = true
	RunState.change_scene(RunState.enter_node(row, index))
