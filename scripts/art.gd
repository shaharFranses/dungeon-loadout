extends RefCounted
## Art pass A: Kenney Tiny Dungeon (CC0) 16x16 sprites, nearest filter, integer scaling,
## LOOP_SPEC section 7 palette. Only the tiles listed here are shipped (res://art/).

const BG := Color("#1B1A24")
const PANEL := Color("#2E2C3B")
const EDGE := Color("#5A5670")
const BONE := Color("#E8E2D0")
const GOLD := Color("#E3B341")
const RED := Color("#C8433A")
const BLUE := Color("#4A8FD8")
const PURPLE := Color("#9B5DE5")
const GREEN := Color("#5DBB63")
const RARE := Color("#3FA7D6")

const HERO := 98
const FLOOR := 49

# enemy id -> [tile, tint]. Tints use palette-derived colours so shared tiles read apart.
const ENEMIES := {
	"enemy_rat": [123, Color(1, 1, 1)],
	"enemy_skeleton": [121, Color("#E8E2D0")],
	"enemy_cultist": [111, Color(1, 1, 1)],
	"enemy_ghoul": [108, Color(1, 1, 1)],
	"enemy_bone_warden": [96, Color("#E8E2D0")],
	"enemy_drowned": [108, Color("#7FB4E8")],
	"enemy_bog_witch": [100, Color("#B8E0A0")],
	"enemy_gnoll": [112, Color(1, 1, 1)],
	"enemy_troll": [87, Color("#8FD394")],
	"enemy_drowned_king": [84, Color("#7FB4E8")],
	"enemy_kobold": [124, Color(1, 1, 1)],
	"enemy_golem": [109, Color("#A9A4C0")],
	"enemy_wraith": [121, Color("#C3A2F0")],
	"enemy_death_knight": [97, Color("#B07A80")],
	"enemy_red_dragon": [110, Color(1, 1, 1)],
}

const ITEMS := {
	"rusty_shortsword": 103, "iron_longsword": 104, "steel_longsword": 106,
	"knights_greatsword": 106, "flame_blade": 107, "moonblade": 105, "vorpal_sword": 105,
	"hand_axe": 119, "steel_axe": 118, "oak_cudgel": 117, "spiked_mace": 117, "war_pick": 117,
	"coral_spear": 131, "harpoon": 131, "ember_glaive": 131, "sharks_tooth": 103,
	"padded_jerkin": 101, "leather_armor": 101, "hide_vest": 101, "kelp_wrap": 101,
	"drakehide": 101, "splint_vest": 101,
	"ring_shirt": 102, "chain_shirt": 102, "scale_mail": 102, "brigandine": 102,
	"half_plate": 102, "spiked_plate": 102, "gilded_cuirass": 102, "wardens_mail": 102,
	"dragonscale": 102,
	"bandage_roll": 114, "healers_locket": 114, "vampire_fang": 115, "ember_stone": 115,
	"focus_crystal": 128, "sages_hourglass": 127, "tide_pearl": 116, "dragon_eye": 116,
	"whetstone_charm": 113, "bone_charm": 113, "guard_talisman": 125,
	"lucky_coin": 90, "hoard_coin": 90, "duelists_token": 126, "crown_of_ages": 89,
}
const SLOT_FALLBACK := {"weapon": 104, "armor": 102, "trinket": 113}

const TALENTS := {
	"talent_bloodied_edge": 105, "talent_strike_bonus": 104, "talent_cleave": 118,
	"talent_kill_heal": 114, "talent_iron_posture": 102, "talent_guard_bonus": 101,
	"talent_keep_block": 56, "talent_thorns": 41, "talent_firebolt": 130,
	"talent_max_focus": 128, "talent_free_skill": 116, "talent_start_focus": 129,
}

const NODES := {"battle": 104, "skill": 130, "shop": 74, "rest": 114}

static var _cache := {}


## Tile scaled by an integer factor with nearest-neighbour (crisp pixels at any size).
static func tex(tile: int, scale: int = 4) -> Texture2D:
	var key := "%d@%d" % [tile, scale]
	if _cache.has(key):
		return _cache[key]
	var base: Texture2D = load("res://art/tile_%04d.png" % tile)
	if base == null:
		return null
	var out: Texture2D = base
	if scale > 1:
		var img := base.get_image()
		if img.is_compressed():
			img.decompress()
		img.resize(img.get_width() * scale, img.get_height() * scale, Image.INTERPOLATE_NEAREST)
		out = ImageTexture.create_from_image(img)
	_cache[key] = out
	return out


static func enemy_tile(id: String) -> Array:
	return ENEMIES.get(id, [108, Color(1, 1, 1)])


static func enemy_tex(id: String, scale: int = 4) -> Texture2D:
	return tex(int(enemy_tile(id)[0]), scale)


static func enemy_tint(id: String) -> Color:
	return enemy_tile(id)[1]


static func item_tex(item: Dictionary, scale: int = 2) -> Texture2D:
	if item.is_empty():
		return null
	return tex(int(ITEMS.get(item.get("id", ""), SLOT_FALLBACK.get(item.get("slot", "weapon"), 104))), scale)


static func talent_tex(id: String, scale: int = 2) -> Texture2D:
	if not TALENTS.has(id):
		return null
	return tex(int(TALENTS[id]), scale)


## Map node icon; elite / boss use the act's own elite and boss sprites.
static func node_tex(type: String, act_def: Dictionary, scale: int = 2) -> Texture2D:
	if type == "elite":
		return enemy_tex(act_def.elite.id, scale)
	if type == "boss":
		return enemy_tex(act_def.boss.id, scale)
	return tex(int(NODES.get(type, 104)), scale)


## Deep-stone backdrop: palette BG plus a dim tiled 16x16 floor at x4.
static func add_backdrop(root: Control, at_index: int = 0) -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	root.move_child(bg, at_index)
	var floor_rect := TextureRect.new()
	floor_rect.texture = tex(FLOOR, 4)
	floor_rect.stretch_mode = TextureRect.STRETCH_TILE
	floor_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	floor_rect.modulate = Color(0.42, 0.40, 0.55, 0.22)
	floor_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(floor_rect)
	root.move_child(floor_rect, at_index + 1)


static func _box(bg: Color, edge: Color, width: int = 2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = edge
	s.set_border_width_all(width)
	s.set_corner_radius_all(2)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s


## Global palette theme (set on the root window by RunState).
static func make_theme() -> Theme:
	var t := Theme.new()
	t.set_stylebox("normal", "Button", _box(PANEL, EDGE))
	t.set_stylebox("hover", "Button", _box(PANEL.lightened(0.08), BONE.darkened(0.25)))
	t.set_stylebox("pressed", "Button", _box(BG, GOLD))
	t.set_stylebox("disabled", "Button", _box(PANEL.darkened(0.25), EDGE.darkened(0.3)))
	t.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), GOLD.darkened(0.2)))
	t.set_color("font_color", "Button", BONE)
	t.set_color("font_hover_color", "Button", BONE)
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_focus_color", "Button", BONE)
	t.set_color("font_disabled_color", "Button", EDGE)
	t.set_color("icon_disabled_color", "Button", Color(1, 1, 1, 0.45))
	t.set_constant("h_separation", "Button", 8)
	t.set_stylebox("panel", "Panel", _box(PANEL, EDGE))
	t.set_stylebox("panel", "PanelContainer", _box(PANEL, EDGE))
	t.set_color("font_color", "Label", BONE)
	return t
