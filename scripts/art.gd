extends RefCounted
## Art pass A: Kenney Tiny Dungeon (CC0) 16x16 sprites, nearest filter, integer scaling,
## LOOP_SPEC section 7 palette. Only the tiles listed here are shipped (res://art/).

## art-a5.1: BG is the colour the backdrop actually renders (QA pixel samples: #2B2329) and the
## single source for the boot splash bg, the HTML page / canvas / #status background and every
## scene's base. a5 drew the floor tile (#EAA56C) at 22% over #1B1A24, which composited to
## #2B2329 while the boot screen and splash stayed #1B1A24. The floor is now drawn opaque with a
## tint that maps its main colour exactly onto BG (FLOOR_TINT), so base and floor agree.
const BG := Color("#2B2329")
## The former palette BG, kept for the darker accents that sit ON the backdrop (HP bar trough,
## turn banner strip, pressed buttons, popup shadow) so they stay visible against BG.
const BG_DEEP := Color("#1B1A24")
const FLOOR_MAIN := Color("#EAA56C")   # tile_0049's main pixel colour (95% of the tile)
const PANEL := Color("#2E2C3B")
const EDGE := Color("#5A5670")
const BONE := Color("#E8E2D0")
const GOLD := Color("#E3B341")
const RED := Color("#C8433A")
const BLUE := Color("#4A8FD8")
const PURPLE := Color("#9B5DE5")
const GREEN := Color("#5DBB63")
const RARE := Color("#3FA7D6")
## art-a5 (STYLE_GUIDE 2b): this block is the single source of the UI palette. Every other
## script uses Art.* (or an alias of it); no hex values are re-declared elsewhere.
## Derived values allowed by the guide: alpha variants and lightened/darkened <= 0.3.
const OUTLINE := Color("#3F2631")          # Kenney sprite outline (popup text outline)
static var FLOOR_TINT := Color(BG.r / FLOOR_MAIN.r, BG.g / FLOOR_MAIN.g, BG.b / FLOOR_MAIN.b, 1.0)   # floor x tint = BG
static var RED_TEXT := RED.lightened(0.2)  # Enrage text: RED lifted for contrast on BG
static var HP_GHOST := RED.lightened(0.3)  # trailing HP-loss segment of the HP bars
const RARITY := {"common": BONE, "uncommon": GREEN, "rare": RARE, "legendary": GOLD}
const NODE_COLORS := {"battle": BONE, "elite": RED, "skill": PURPLE, "shop": GOLD, "rest": GREEN, "boss": RED}

## art-a5 (STYLE_GUIDE 5/6): phone minimums. The portrait canvas is 720 wide, so on a
## 390 CSS px phone 1 canvas px = 390/720 = 0.54 CSS px. A 44 CSS px tap target needs
## 82 canvas px; we use 88 (47.7 CSS px). Kenney Pixel's cap height is 448/1024 of the
## font size, so >= 12 CSS px caps need >= 51 canvas px; 56 gives 13.3 CSS px caps.
const PHONE_TAP := 88.0
const PHONE_MIN_FONT := 56

const HERO := 98
const FLOOR := 49

# enemy id -> sprite: a Kenney Tiny Dungeon tile number (res://art/tile_NNNN.png) or, since
# art-a5, a res:// path to a Tiny Creatures sprite (art/creatures/MAPPING.md, CC0). art-a5:
# every enemy is drawn untinted; the old multiply-tint stand-ins and their code path are gone.
const ENEMIES := {
	"enemy_rat": 123,
	"enemy_skeleton": "res://art/creatures/skeleton.png",
	"enemy_cultist": 111,
	"enemy_ghoul": 108,
	"enemy_bone_warden": 96,
	"enemy_drowned": "res://art/creatures/drowned.png",
	"enemy_bog_witch": "res://art/creatures/bog_witch.png",
	"enemy_gnoll": 112,
	"enemy_troll": "res://art/creatures/troll.png",
	"enemy_drowned_king": "res://art/creatures/drowned_king.png",
	"enemy_kobold": 124,
	"enemy_golem": "res://art/creatures/golem.png",
	"enemy_wraith": "res://art/creatures/wraith.png",
	"enemy_death_knight": "res://art/creatures/death_knight.png",
	"enemy_red_dragon": "res://art/creatures/red_dragon.png",
}
## Side-view sprites that face right as drawn: every Tiny Creatures sprite (pack convention)
## plus the Tiny Dungeon rat and kobold. The other Tiny Dungeon enemies face the viewer.
const FACING_RIGHT_TILES := [123, 124]

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
	# tiles 89 and 90 are treasure chests (89 plain, 90 with a lock plate); the pack has no coin
	# or crown, so the chests stand in for the coin trinkets and the Crown of Ages.
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

## art-a2: regular enemies and the hero at x5 (80px); the Dragon boss at x7 (112px, 1.4x,
## the nearest integer factor to 1.5x) so it reads as the boss. Integer factors only.
const ENEMY_SCALE := 5
const BIG := {"enemy_red_dragon": 7}

static var _cache := {}


## art-a2: Kenney Pixel draws ~0.6x the size of the default font at the same px size, so every
## UI size goes through here: x1.6, snapped to multiples of 8 so the pixel font stays crisp.
static func fs(size: int) -> int:
	if is_portrait():
		# art-a5: phones x2.6 with a 56 px floor (>= 12 CSS px cap height at 390 wide)
		return maxi(PHONE_MIN_FONT, int(round(size * 2.6 / 8.0)) * 8)
	return maxi(16, int(round(size * 1.6 / 8.0)) * 8)


static func is_portrait() -> bool:
	var loop = Engine.get_main_loop()
	return loop != null and loop.root.has_node("RunState") and loop.root.get_node("RunState").portrait


## art-a5: minimum tap height (canvas px) for buttons and map nodes; 0 = no extra floor.
static func tap_min() -> float:
	return PHONE_TAP if is_portrait() else 0.0


## art-a5: grow a button to the phone tap minimum (both axes) without shrinking it.
static func tap(b: Control) -> Control:
	var m := tap_min()
	if m > 0.0:
		b.custom_minimum_size = Vector2(maxf(b.custom_minimum_size.x, m), maxf(b.custom_minimum_size.y, m))
	return b


## Portrait phones have spare height, so sprites go up to x7 (Dragon x10, still ~1.4x).
static func enemy_scale(id: String) -> int:
	var portrait: bool = Engine.get_main_loop().root.get_node("RunState").portrait
	if portrait:
		return 12 if BIG.has(id) else 8   # art-a3: 128px / 192px on phones (1.5x)
	return int(BIG.get(id, ENEMY_SCALE))


static func hero_scale() -> int:
	return enemy_scale("hero")


## Tile scaled by an integer factor with nearest-neighbour (crisp pixels at any size).
## art-a5: `tile` is a Tiny Dungeon number or a res:// path; flip mirrors it horizontally.
static func tex(tile, scale: int = 4, flip: bool = false) -> Texture2D:
	var path: String = tile if tile is String else "res://art/tile_%04d.png" % int(tile)
	var key := "%s@%d%s" % [path, scale, "f" if flip else ""]
	if _cache.has(key):
		return _cache[key]
	var base: Texture2D = load(path)
	if base == null:
		return null
	var out: Texture2D = base
	if scale > 1 or flip:
		var img := base.get_image()
		if img.is_compressed():
			img.decompress()
		if scale > 1:
			img.resize(img.get_width() * scale, img.get_height() * scale, Image.INTERPOLATE_NEAREST)
		if flip:
			img.flip_x()
		out = ImageTexture.create_from_image(img)
	_cache[key] = out
	return out


## art-a5: every enemy faces the hero. The hero stands centred below the enemy row (both
## layouts), so a side-view sprite left of the centre keeps facing right and one at or right
## of the centre is mirrored to face left. Front-facing sprites are never mirrored.
static func faces_right(id: String) -> bool:
	var t = enemy_tile(id)
	return t is String or FACING_RIGHT_TILES.has(int(t))


static func enemy_flip(id: String, index: int, count: int) -> bool:
	return faces_right(id) and float(index) >= (count - 1) / 2.0


static func enemy_tile(id: String):
	return ENEMIES.get(id, 108)


static func enemy_tex(id: String, scale: int = 4, flip: bool = false) -> Texture2D:
	return tex(enemy_tile(id), scale, flip)


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


## Deep-stone backdrop: palette BG plus the tiled 16x16 floor at x4, tinted so its main colour is
## exactly BG (the tile's lighter / darker detail pixels keep the stone texture).
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
	floor_rect.modulate = FLOOR_TINT
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
	var font: FontFile = load("res://art/fonts/kenney_pixel.ttf")
	if font != null:
		font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		font.hinting = TextServer.HINTING_NONE
		font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		# art-a3: Kenney Pixel's space is only 2 of 16 pixel units (letters are 6 with a 1-unit
		# gap), so after canvas downscaling (e.g. 0.625 at 800x600) words ran together
		# ("CryptRat"). Widen the space glyph via a FontVariation.
		var fv := FontVariation.new()
		fv.base_font = font
		fv.set_spacing(TextServer.SPACING_SPACE, 6)
		t.default_font = fv
		t.default_font_size = fs(20)
	t.set_stylebox("normal", "Button", _box(PANEL, EDGE))
	t.set_stylebox("hover", "Button", _box(PANEL.lightened(0.08), BONE.darkened(0.25)))
	t.set_stylebox("pressed", "Button", _box(BG_DEEP, GOLD))
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
