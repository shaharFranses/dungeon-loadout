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
const FLOOR_MAIN := Color("#EAA56C")
## art-a6 readability (Shahar: "the writing with the pixel art is hard to read"), per DL Art's
## STYLE_GUIDE section 10 (art/style-guide @ 54e2d42). Outlines and shadows are BG_DEEP only
## (never OUTLINE #3F2631, 1.11:1 on BG); static text over sprites, floor or map lines sits on a
## PLATE; text uses only the TXT_* roles below (RED, RED_TEXT, PURPLE, BLUE and EDGE are fill and
## bar colours, never text) and is never dimmed with modulate.
const TEXT_OUTLINE := BG_DEEP
const PLATE := Color(0x1B1A24EB)            # Color("#1B1A24", 0.92)
const TXT := Color("#E8E2D0")               # primary (BONE) 11.80:1 on BG
const TXT_DIM := Color("#AAB7CC")           # dim / secondary, replaces EDGE text (7.53)
const TXT_DISABLED := Color("#8B9BB4")      # disabled, always with a lock / x glyph (5.41)
const TXT_POS := Color("#5DBB63")           # positive / heal / Uncommon (GREEN, 6.37)
const TXT_NEG := Color("#FF706D")           # negative / damage / Enrage (5.67)
const TXT_GOLD := Color("#E3B341")          # gold / Legendary (7.85)
const TXT_BLOCK := Color("#75E3FF")         # block (10.32)
const TXT_FOCUS := Color("#D176D0")         # focus / arcane (5.25)
const TXT_RARE := Color("#3FA7D6")          # rare (5.61)
const LOCK := "\u00D7 "                     # Kenney Pixel has no lock glyph; the guide allows "x"
const MUTED := TXT_DIM
## Font tiers [desktop, phone] canvas px; Kenney Pixel is native 16, so every size is 16*s.
const TIER := {"title": [64, 96], "heading": [48, 64], "body": [32, 48], "small": [32, 48],
		"popup": [48, 64], "crit": [64, 96]}
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
static var RED_TEXT := TXT_NEG             # art-a6: Enrage text uses the Negative text role
static var HP_GHOST := RED.lightened(0.3)  # trailing HP-loss segment of the HP bars
const RARITY := {"common": BONE, "uncommon": GREEN, "rare": RARE, "legendary": GOLD}
const NODE_COLORS := {"battle": BONE, "elite": RED, "skill": PURPLE, "shop": GOLD, "rest": GREEN, "boss": RED}
## art-a6: map node label colours (text roles; NODE_COLORS stays for fills and icons)
const NODE_TEXT := {"battle": TXT, "elite": TXT_NEG, "skill": TXT_FOCUS, "shop": TXT_GOLD, "rest": TXT_POS, "boss": TXT_NEG}

## art-a5 (STYLE_GUIDE 5/6): phone minimums. The portrait canvas is 720 wide, so on a
## 390 CSS px phone 1 canvas px = 390/720 = 0.54 CSS px. A 44 CSS px tap target needs
## 82 canvas px; we use 88 (47.7 CSS px). Kenney Pixel's cap height is 448/1024 of the
## font size, so >= 12 CSS px caps need >= 51 canvas px; 56 gives 13.3 CSS px caps.
const PHONE_TAP := 88.0
const PHONE_MIN_FONT := 48   # art-a6: phone body tier (3x native, 26 CSS px font / 11.4 CSS px cap)

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


## art-a6 (STYLE_GUIDE 10): every UI size is a tier from TIER, a whole multiple of Kenney
## Pixel's native 16 (no 24/40/56, no fractional scale). Callers still pass the old logical
## sizes: <= 20 is body, 21-26 heading, >= 27 title.
static func tier(name: String) -> int:
	return int(TIER[name][1 if is_portrait() else 0])


static func fs(size: int) -> int:
	if size >= 27:
		return tier("title")
	if size >= 21:
		return tier("heading")
	return tier("body")


## art-a6: .tscn font sizes (authored in landscape px) mapped onto the tiers.
static func scene_fs(px: int) -> int:
	if px >= 64:
		return tier("title")
	if px >= 40:
		return tier("heading")
	return tier("body")


## art-a6: number pop-ups 48/64, crit or boss 64/96.
static func popup_fs(crit: bool) -> int:
	return tier("crit" if crit else "popup")


## art-a6: the text role for a palette colour that used to be drawn as text.
static func text_color(c: Color) -> Color:
	if c == RED or c == RED.lightened(0.2):
		return TXT_NEG
	if c == BLUE:
		return TXT_BLOCK
	if c == PURPLE:
		return TXT_FOCUS
	if c == EDGE:
		return TXT_DIM
	return c


static func px_scale(size: int) -> int:
	return maxi(1, int(size / 16))


## Text drawn straight over sprites / floor (no plate possible) and pop-ups:
## outline BG_DEEP 4*s and a crisp BG_DEEP shadow offset (s, s).
static func outline_text(c: Control, size: int) -> void:
	var s := px_scale(size)
	c.add_theme_color_override("font_outline_color", TEXT_OUTLINE)
	c.add_theme_constant_override("outline_size", 4 * s)
	shadow_text(c, size)


## Titles and headings: BG_DEEP shadow at (s, s), shadow_size 0, no outline.
static func shadow_text(c: Control, size: int) -> void:
	var s := px_scale(size)
	c.add_theme_color_override("font_shadow_color", BG_DEEP)
	c.add_theme_constant_override("shadow_offset_x", s)
	c.add_theme_constant_override("shadow_offset_y", s)
	c.add_theme_constant_override("shadow_outline_size", 0)


static var _plates := {}

## Label plate: #1B1A24 at 0.92, border s in #3F2631, square, no AA, margins 3s / s.
static func plate_box(size: int) -> StyleBoxFlat:
	var s := px_scale(size)
	if _plates.has(s):
		return _plates[s]
	var p := StyleBoxFlat.new()
	p.bg_color = PLATE
	p.set_border_width_all(s)
	p.border_color = OUTLINE
	p.set_corner_radius_all(0)
	p.anti_aliasing = false
	p.content_margin_left = 3 * s
	p.content_margin_right = 3 * s
	p.content_margin_top = s
	p.content_margin_bottom = s
	_plates[s] = p
	return p


## art-a6: put a label on a plate (PlateLabel variation; RunState sizes the box to the font).
static func plate(label: Label) -> Label:
	label.theme_type_variation = &"PlateLabel"
	return label


## art-a6: give a plated label its per-size plate now (also done by RunState after setup).
static func size_plate(label: Label) -> void:
	if label.theme_type_variation == &"PlateLabel":
		label.add_theme_stylebox_override("normal", plate_box(label.get_theme_font_size("font_size")))


## art-a6: hide an empty plated label's plate so no dark bar shows (the label has no text, so
## nothing readable is dimmed).
static func sync_plate(label: Label) -> void:
	if label != null:
		label.self_modulate.a = 0.0 if String(label.text).strip_edges() == "" else 1.0


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
		t.default_font_size = tier("body")
	t.set_stylebox("normal", "Button", _box(PANEL, EDGE))
	t.set_stylebox("hover", "Button", _box(PANEL.lightened(0.08), BONE.darkened(0.25)))
	t.set_stylebox("pressed", "Button", _box(BG_DEEP, GOLD))
	t.set_stylebox("disabled", "Button", _box(PANEL.darkened(0.25), EDGE.darkened(0.3)))
	t.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), GOLD.darkened(0.2)))
	t.set_color("font_color", "Button", BONE)
	t.set_color("font_hover_color", "Button", BONE)
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_focus_color", "Button", BONE)
	t.set_color("font_disabled_color", "Button", TXT_DISABLED)   # art-a6: was EDGE (2.27:1)
	t.set_color("icon_disabled_color", "Button", Color(1, 1, 1, 0.45))
	t.set_constant("h_separation", "Button", 8)
	t.set_stylebox("panel", "Panel", _box(PANEL, EDGE))
	t.set_stylebox("panel", "PanelContainer", _box(PANEL, EDGE))
	t.set_color("font_color", "Label", BONE)
	# art-a6: body text on BG / PANEL / plate has no outline and no shadow
	for type in ["Label", "Button"]:
		t.set_color("font_outline_color", type, TEXT_OUTLINE)
		t.set_constant("outline_size", type, 0)
	t.set_type_variation(&"PlateLabel", &"Label")
	t.set_stylebox("normal", &"PlateLabel", plate_box(tier("body")))
	return t
