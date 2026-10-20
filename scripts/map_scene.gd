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
var node_buttons := {}


func _ready():
	DisplayServer.window_set_title("dungeon_loadout")
	$ColorRect.color = Art.BG
	preload("res://scripts/art.gd").add_backdrop(self, 1)
	links_layer = MapLinks.new()
	links_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	links_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(links_layer)
	_build_nodes()
	_update_ui()


func _node_center(row: int, index: int) -> Vector2:
	var count: int = 1 if row == RunState.map.boss_row else RunState.map.rows[row].size()
	var x := 640.0 + (index - (count - 1) / 2.0) * COL_STEP
	return Vector2(x, ROW_TOP + row * ROW_STEP)


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
			button.add_theme_font_size_override("font_size", 18)
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
	get_tree().change_scene_to_file(RunState.enter_node(row, index))
