extends Control
## Combat screen. v3.8 (COMBAT_FEEDBACK.md): turn banners, one-at-a-time enemy actions,
## lunges/shakes/flashes, damage popups (red HP loss, blue blocked), shield/puff/windup,
## trailing HP bars, intent highlight, a 2-line combat log and a 1x/2x speed toggle.
## Tweens, Labels and ColorRects only; pacing lives in CombatState (rules unchanged).

@onready var enemy_container = $VBox/EnemyArea/EnemyContainer
@onready var player_area = $VBox/PlayerArea
@onready var hp_label = $VBox/PlayerArea/PlayerStats/HPLabel
@onready var block_label = $VBox/PlayerArea/PlayerStats/BlockLabel
@onready var focus_label = $VBox/PlayerArea/PlayerStats/FocusLabel
@onready var actions_box = $VBox/PlayerArea/Actions
@onready var strike_button = $VBox/PlayerArea/Actions/StrikeButton
@onready var guard_button = $VBox/PlayerArea/Actions/GuardButton
@onready var skill_button = $VBox/PlayerArea/Actions/SkillButton

const CombatState = preload("res://scripts/combat_state.gd")
const Art = preload("res://scripts/art.gd")

const C_GOLD := Color("#E3B341")
const C_RED := Color("#C8433A")
const C_BLUE := Color("#4A8FD8")
const C_GREEN := Color("#5DBB63")
const C_PURPLE := Color("#9B5DE5")
const C_STRIP := Color("#1B1A24")
const C_TEXT := Color("#E8E2D0")
const ENEMY_W := 200.0
const HERO_W := 260.0

var combat_state: Node
var enemy_ui_nodes: Array = []
var enrage_toast: Label
var overlay: Control
var vignette: TextureRect
var hero_body: Control
var hero_bar: Dictionary
var log_labels: Array = []
var log_lines: Array = []
var speed_button: Button

func _ready():
	combat_state = CombatState.new()
	add_child(combat_state)
	
	combat_state.combat_ended.connect(_on_combat_ended)
	combat_state.player_turn_started.connect(_on_player_turn_started)
	combat_state.player_bled.connect(func(_amount): _update_ui())
	combat_state.enemy_turn_started.connect(_on_enemy_turn)
	combat_state.player_damaged.connect(_on_player_damaged)
	combat_state.enemy_damaged.connect(_on_enemy_damaged)
	combat_state.player_blocked.connect(func(_amount): _update_ui())
	combat_state.enemy_blocked.connect(func(_index, _amount): _update_ui())
	combat_state.focus_changed.connect(func(_focus): _update_ui())
	combat_state.intents_updated.connect(_update_enemy_intents)
	combat_state.enrage_started.connect(_on_enrage_started)
	combat_state.enemies_changed.connect(_create_enemy_ui)
	# v3.8 presentation
	combat_state.banner.connect(_on_banner)
	combat_state.phase_changed.connect(_on_phase_changed)
	combat_state.input_unlocked.connect(_on_input_unlocked)
	combat_state.actor_started.connect(_on_actor_started)
	combat_state.actor_ended.connect(_on_actor_ended)
	combat_state.lunge.connect(_on_lunge)
	combat_state.windup.connect(_on_windup)
	combat_state.hit.connect(_on_hit)
	combat_state.block_gained.connect(_on_block_gained)
	combat_state.healed.connect(_on_healed)
	combat_state.ticked.connect(_on_ticked)
	combat_state.status_popup.connect(func(t, text, color): _popup(t, text, color))
	combat_state.summoned.connect(_on_summoned)
	combat_state.killed.connect(_on_killed)
	combat_state.enrage_pulse.connect(_on_enrage_pulse)
	combat_state.log_line.connect(_on_log_line)
	
	$ColorRect.color = Art.BG
	Art.add_backdrop(self, 1)
	$VBox/Spacer.custom_minimum_size = Vector2(0, 6)
	_build_hero()
	_build_log()
	_create_enrage_toast()
	_build_overlay()
	
	var enemy_setup: Array = RunState.current_encounter
	
	combat_state.start_combat(enemy_setup)
	_create_enemy_ui()
	_update_ui()
	_on_phase_changed(true)   # locked until the first "Your Turn" banner fades
	
	var count = combat_state.enemies.size()
	DisplayServer.window_set_title("DL COMBAT: %d %s" % [count, "enemy" if count == 1 else "enemies"])

# ---------- building ----------

func _make_bar(width: float) -> Dictionary:
	var back := ColorRect.new()
	back.color = Color(0.12, 0.1, 0.12)
	back.size = Vector2(width, 10)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ghost := ColorRect.new()
	ghost.color = Color(0.95, 0.75, 0.7)
	ghost.size = Vector2(width, 10)
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := ColorRect.new()
	fill.color = C_RED
	fill.size = Vector2(width, 10)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.add_child(ghost)
	back.add_child(fill)
	return {"root": back, "ghost": ghost, "fill": fill, "width": width, "ratio": -1.0}

func _set_bar(bar: Dictionary, value: int, max_value: int):
	if bar.is_empty() or not is_instance_valid(bar.fill):
		return
	var ratio := clampf(float(value) / maxf(1.0, float(max_value)), 0.0, 1.0)
	if is_equal_approx(ratio, float(bar.ratio)):
		return
	var target_w: float = float(bar.width) * ratio
	if bar.ratio < 0.0:
		bar.fill.size.x = target_w
		bar.ghost.size.x = target_w
	elif ratio < bar.ratio:
		var tw: Tween = bar.fill.create_tween()
		tw.tween_property(bar.fill, "size:x", target_w, _t(0.25))
		var tg: Tween = bar.ghost.create_tween()
		tg.tween_interval(_t(0.3))
		tg.tween_property(bar.ghost, "size:x", target_w, _t(0.25))
	else:
		bar.ghost.size.x = target_w
		var tw: Tween = bar.fill.create_tween()
		tw.tween_property(bar.fill, "size:x", target_w, _t(0.25))
	bar.ratio = ratio

func _build_hero():
	var holder := Control.new()
	var px := 16 * Art.hero_scale()
	var hero_h := px + 48.0
	holder.custom_minimum_size = Vector2(HERO_W, hero_h)
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	# hero_body is what lunge / shake / flash tween, so the sprite lives inside it.
	hero_body = Control.new()
	hero_body.size = Vector2(HERO_W, hero_h)
	holder.add_child(hero_body)
	var hero_sprite := TextureRect.new()
	hero_sprite.texture = Art.tex(Art.HERO, Art.hero_scale())
	hero_sprite.position = Vector2((HERO_W - px) / 2.0, 0)
	hero_sprite.size = Vector2(px, px)
	hero_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_body.add_child(hero_sprite)
	var panel := Panel.new()
	panel.position = Vector2(0, px + 4)
	panel.size = Vector2(HERO_W, 30)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_body.add_child(panel)
	var name_label := Label.new()
	name_label.text = "You"
	name_label.position = panel.position
	name_label.size = panel.size
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", Art.fs(18))
	hero_body.add_child(name_label)
	hero_bar = _make_bar(HERO_W)
	hero_bar.root.position = Vector2(0, px + 38)
	hero_body.add_child(hero_bar.root)
	player_area.add_child(holder)
	player_area.move_child(holder, 1)

func _build_log():
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	for k in range(2):
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", Art.fs(15))
		label.add_theme_color_override("font_color", C_TEXT)
		label.modulate = Color(1, 1, 1, 0.5 if k == 0 else 1.0)
		box.add_child(label)
		log_labels.append(label)
	player_area.add_child(box)
	player_area.move_child(box, actions_box.get_index())

func _build_overlay():
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	# Enrage edge vignette: radial gradient, clear centre -> red edges.
	var grad := Gradient.new()
	grad.set_color(0, Color(0.78, 0.26, 0.23, 0.0))
	grad.set_color(1, Color(0.78, 0.26, 0.23, 0.85))
	grad.add_point(0.55, Color(0.78, 0.26, 0.23, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.05, 1.05)
	tex.width = 128
	tex.height = 128
	vignette = TextureRect.new()
	vignette.texture = tex
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.modulate.a = 0.0
	overlay.add_child(vignette)
	speed_button = Button.new()
	speed_button.text = "Speed %dx" % RunState.combat_speed()
	speed_button.custom_minimum_size = Vector2(110, 36)
	# Anchored to the top-right of the (stretch-aware) viewport: offsets only, no absolute
	# position, so it stays on screen at any window size / aspect / DPR.
	speed_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	speed_button.offset_left = -124.0
	speed_button.offset_right = -14.0
	speed_button.offset_top = 10.0
	speed_button.offset_bottom = 46.0
	speed_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	speed_button.add_theme_font_size_override("font_size", Art.fs(16))
	speed_button.pressed.connect(_on_speed_pressed)
	add_child(speed_button)

func _create_enemy_ui():
	var max_px := 0
	for e in combat_state.enemies:
		max_px = maxi(max_px, 16 * Art.enemy_scale(e.enemy_id))
	var btn_h := float(max_px) + 64.0   # sprite + 2 lines of Kenney Pixel
	var body_h := btn_h + 16.0
	for child in enemy_container.get_children():
		enemy_container.remove_child(child)
		child.queue_free()
	
	enemy_ui_nodes.clear()
	
	for i in range(combat_state.enemies.size()):
		var enemy = combat_state.enemies[i]
		var vbox = VBoxContainer.new()
		vbox.custom_minimum_size = Vector2(ENEMY_W, 0)
		
		# holder keeps the layout slot; body moves freely for lunges and shakes.
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(ENEMY_W, body_h)
		var body := Control.new()
		body.size = Vector2(ENEMY_W, body_h)
		holder.add_child(body)
		
		var button = Button.new()
		button.size = Vector2(ENEMY_W, btn_h)
		button.text = enemy.display_name
		# Art pass A: 16x16 sprite at x4 (integer, nearest) as the button icon, so every
		# body tween (lunge, shake, flash, highlight modulate) moves the sprite too.
		button.icon = Art.enemy_tex(enemy.enemy_id, Art.enemy_scale(enemy.enemy_id))
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.add_theme_font_size_override("font_size", Art.fs(15))
		var tint := Art.enemy_tint(enemy.enemy_id)
		for c in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color", "icon_hover_pressed_color"]:
			button.add_theme_color_override(c, tint)
		button.add_theme_color_override("icon_disabled_color", tint * Color(1, 1, 1, 0.6))
		button.pressed.connect(func(): _on_enemy_selected(i))
		body.add_child(button)
		var bar := _make_bar(ENEMY_W)
		bar.root.position = Vector2(0, btn_h + 4.0)
		body.add_child(bar.root)
		
		var stats_label = Label.new()
		stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_label.add_theme_font_size_override("font_size", Art.fs(16))
		
		var intent_label = Label.new()
		intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		intent_label.add_theme_font_size_override("font_size", Art.fs(18))
		intent_label.custom_minimum_size = Vector2(ENEMY_W, 26)
		intent_label.pivot_offset = Vector2(ENEMY_W / 2.0, 13)
		
		var enrage_label = Label.new()
		enrage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		enrage_label.add_theme_font_size_override("font_size", Art.fs(16))
		enrage_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
		enrage_label.visible = false
		
		vbox.add_child(holder)
		vbox.add_child(stats_label)
		vbox.add_child(intent_label)
		vbox.add_child(enrage_label)
		
		enemy_container.add_child(vbox)
		if not enemy.is_alive():
			body.modulate.a = 0.35
			body.position.y = 10
		enemy_ui_nodes.append({
			"button": button,
			"body": body,
			"bar": bar,
			"stats": stats_label,
			"intent": intent_label,
			"enrage": enrage_label
		})
	
	_update_enemy_ui()
	_update_enemy_intents()

func _update_enemy_ui():
	if enemy_ui_nodes.size() != combat_state.enemies.size():
		return
	for i in range(combat_state.enemies.size()):
		var enemy = combat_state.enemies[i]
		var ui = enemy_ui_nodes[i]
		
		_set_bar(ui.bar, maxi(0, enemy.current_hp), enemy.max_hp)
		if enemy.is_alive():
			ui.button.text = "%s\nHP: %d/%d" % [enemy.display_name, enemy.current_hp, enemy.max_hp]
			var notes: Array = []
			if enemy.block > 0:
				notes.append("Block: %d" % enemy.block)
			if enemy.dmg_bonus > 0:
				notes.append("Power +%d" % enemy.dmg_bonus)
			if enemy.burn > 0:
				notes.append("Burn %d" % enemy.burn)
			ui.stats.text = "  ".join(notes)
			
			if i == combat_state.selected_enemy_index:
				ui.button.modulate = Color(1.2, 1.2, 0.8)
			else:
				ui.button.modulate = Color(1, 1, 1)
		else:
			ui.button.text = "%s\nDEAD" % enemy.display_name
			ui.stats.text = ""
			ui.intent.text = ""
			ui.enrage.visible = false
			ui.button.modulate = Color(0.5, 0.5, 0.5)

func _update_enemy_intents():
	if enemy_ui_nodes.size() != combat_state.enemies.size():
		return
	var bonus = combat_state.get_enrage_bonus()
	for i in range(combat_state.enemies.size()):
		var enemy = combat_state.enemies[i]
		var ui = enemy_ui_nodes[i]
		
		if enemy.is_alive():
			var intent = enemy.get_current_intent()
			ui.intent.text = _intent_text(enemy, intent, bonus)
			ui.enrage.text = "Enraged +%d" % bonus
			ui.enrage.visible = bonus > 0
		else:
			ui.intent.text = ""
			ui.enrage.visible = false

func _intent_text(enemy, intent: Dictionary, bonus: int) -> String:
	var attack: int = enemy.attack_value(intent) + bonus
	match intent.type:
		"strike":
			var hits := int(intent.get("hits", 1))
			return "Strike %d x%d" % [attack, hits] if hits > 1 else "Strike %d" % attack
		"heavy":
			return "%s %d" % [intent.get("label", "Heavy"), attack]
		"guard":
			return "Guard +%d" % intent.value
		"rend":
			return "Rend %d (+%d x%d)" % [attack, intent.bleed, intent.bleed_turns]
		"buff":
			return "Buff +%d dmg" % intent.value
		"hex":
			return "Hex (next Strike -%d)" % intent.value
		"regen":
			return "Regenerate %d" % intent.value
		"summon":
			return "Summon Drowned"
		"tidal":
			return "Tidal %d (ignores half Block)" % attack
		"drain":
			return "Drain %d (heals %d)" % [attack, intent.value]
	return String(intent.type).capitalize()

func _update_ui():
	hp_label.text = "HP: %d/%d" % [combat_state.player_hp, combat_state.player_max_hp]
	if combat_state.player_bleed_turns > 0:
		hp_label.text += "  Bleed %d x%d" % [combat_state.player_bleed, combat_state.player_bleed_turns]
	if combat_state.player_hex > 0:
		hp_label.text += "  Hexed -%d" % combat_state.player_hex
	block_label.text = "Block: %d" % combat_state.player_block
	focus_label.text = "Focus: %d/%d" % [combat_state.player_focus, combat_state.player_focus_max]
	
	var can_act = combat_state.is_player_turn and combat_state.combat_active
	_set_bar(hero_bar, combat_state.player_hp, combat_state.player_max_hp)
	strike_button.disabled = not can_act
	guard_button.disabled = not can_act
	
	var has_skill = RunState.skill_id != ""
	var can_use_skill = can_act and combat_state.player_focus >= combat_state.skill_cost() and has_skill
	skill_button.disabled = not can_use_skill
	skill_button.visible = has_skill
	
	if has_skill:
		var skill = RunState.get_skill_effect()
		if skill.type == "damage":
			skill_button.text = "Skill (Dmg %d)" % skill.value
		elif skill.type == "damage_all":
			skill_button.text = "Skill (Dmg %d all)" % skill.value
		elif skill.type == "block":
			skill_button.text = "Skill (Blk +%d)" % skill.value
		elif skill.type == "strike_and_block":
			skill_button.text = "Skill (Atk %d + Blk %d)" % [skill.damage, skill.block]
	
	var preview: Dictionary = combat_state.strike_preview()
	strike_button.text = "Strike (%d)" % preview.damage
	if not preview.notes.is_empty():
		strike_button.text += "\n" + ", ".join(preview.notes)
	guard_button.text = "Guard (%d)" % RunState.get_guard_amount()
	if has_skill and combat_state.skill_is_free():
		skill_button.text += " FREE"
	
	_update_enemy_ui()

func _create_enrage_toast():
	enrage_toast = Label.new()
	enrage_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enrage_toast.add_theme_font_size_override("font_size", Art.fs(22))
	enrage_toast.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	enrage_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	enrage_toast.offset_left = -300.0
	enrage_toast.offset_right = 300.0
	enrage_toast.offset_top = 8.0
	enrage_toast.offset_bottom = 40.0
	enrage_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enrage_toast.visible = false
	add_child(enrage_toast)

func _on_enrage_started(bonus: int):
	enrage_toast.text = "Enemies are enraged! +%d damage each turn from now on" % bonus
	enrage_toast.visible = true
	await get_tree().create_timer(2.5).timeout
	if is_instance_valid(enrage_toast):
		enrage_toast.visible = false


# ---------- v3.8 feedback ----------

func _t(seconds: float) -> float:
	return maxf(seconds * RunState.anim_scale(), 0.001)

func _body(index: int) -> Control:
	if index < 0:
		return hero_body
	if index < enemy_ui_nodes.size():
		return enemy_ui_nodes[index].body
	return null

func _anchor_point(index: int) -> Vector2:
	var b := _body(index)
	if b == null or not is_instance_valid(b):
		return get_viewport_rect().size / 2.0
	var r := b.get_global_rect()
	return Vector2(r.position.x + r.size.x / 2.0, r.position.y + 8.0)

## Floating text: up 30px and fade over 0.6s. Never waited on.
func _popup(index: int, text: String, color: Color, size: int = 26, offset: Vector2 = Vector2.ZERO):
	RunState.qa_log("POP", {"target": index, "text": text, "ms": Time.get_ticks_msec()})
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", Art.fs(size))
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(label)
	var p := _anchor_point(index) + offset
	label.position = p - Vector2(label.get_minimum_size().x / 2.0, 0)
	var tw := label.create_tween().set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y - 30.0, _t(0.6))
	tw.tween_property(label, "modulate:a", 0.0, _t(0.6)).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(label.queue_free)

func _flash(node: CanvasItem, color: Color, seconds: float):
	if node == null or not is_instance_valid(node):
		return
	var keep_a := node.modulate.a
	var tw := node.create_tween()
	tw.tween_property(node, "modulate", Color(color.r, color.g, color.b, keep_a), _t(seconds * 0.4))
	tw.tween_property(node, "modulate", Color(1, 1, 1, keep_a), _t(seconds * 0.6))

func _shake(node: Control, amount: float, seconds: float):
	if node == null or not is_instance_valid(node):
		return
	var base_x := 0.0
	var tw := node.create_tween()
	var step := _t(seconds / 4.0)
	tw.tween_property(node, "position:x", base_x + amount, step)
	tw.tween_property(node, "position:x", base_x - amount, step)
	tw.tween_property(node, "position:x", base_x + amount * 0.5, step)
	tw.tween_property(node, "position:x", base_x, step)

func _shape_flash(index: int, color: Color, circle: bool, from_scale: float, peak: float, end_scale: float, seconds: float, fade: bool):
	var panel := Panel.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(color.r, color.g, color.b, 0.55)
	box.border_color = color
	box.set_border_width_all(3)
	box.set_corner_radius_all(40 if circle else 10)
	panel.add_theme_stylebox_override("panel", box)
	panel.size = Vector2(80, 80)
	panel.pivot_offset = Vector2(40, 40)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(panel)
	var b := _body(index)
	var centre := get_viewport_rect().size / 2.0
	if b != null and is_instance_valid(b):
		var r := b.get_global_rect()
		centre = r.position + Vector2(r.size.x / 2.0, minf(r.size.y, 120.0) / 2.0)
	panel.position = centre - Vector2(40, 40)
	panel.scale = Vector2.ONE * from_scale
	var tw := panel.create_tween()
	tw.tween_property(panel, "scale", Vector2.ONE * peak, _t(seconds * 0.6))
	tw.tween_property(panel, "scale", Vector2.ONE * end_scale, _t(seconds * 0.4))
	if fade:
		tw.parallel().tween_property(panel, "modulate:a", 0.0, _t(seconds * 0.4))
	else:
		tw.tween_property(panel, "modulate:a", 0.0, _t(0.15))
	tw.tween_callback(panel.queue_free)

func _bounce(node: Control):
	if node == null or not is_instance_valid(node):
		return
	node.pivot_offset = node.size / 2.0
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector2.ONE * 1.25, _t(0.08))
	tw.tween_property(node, "scale", Vector2.ONE, _t(0.12))

func _on_banner(side: String):
	var strip := ColorRect.new()
	strip.color = Color(C_STRIP.r, C_STRIP.g, C_STRIP.b, 0.92)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vp := get_viewport_rect().size
	strip.size = Vector2(vp.x, 64)
	strip.position = Vector2(-40, vp.y * 0.42)
	var label := Label.new()
	label.text = "Your Turn" if side == "player" else "Enemy Turn"
	label.size = strip.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", Art.fs(34))
	label.add_theme_color_override("font_color", C_GOLD if side == "player" else C_RED)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.add_child(label)
	strip.modulate.a = 0.0
	overlay.add_child(strip)
	var hold := 0.4 if side == "player" else 0.25
	var scale := RunState.anim_scale()
	var hold_t := maxf(hold * scale, 0.2 if scale < 1.0 and not RunState.qa_anim_override() else 0.001)
	var tw := strip.create_tween()
	tw.tween_property(strip, "modulate:a", 1.0, _t(0.15))
	tw.parallel().tween_property(strip, "position:x", 0.0, _t(0.15))
	tw.tween_interval(hold_t)
	tw.tween_property(strip, "modulate:a", 0.0, _t(0.15))
	tw.tween_callback(strip.queue_free)

func _on_phase_changed(enemy_phase: bool):
	# Buttons greyed for the whole enemy phase (and until the Your Turn banner fades).
	if enemy_phase:
		actions_box.modulate = Color(1, 1, 1, 0.5)
	_update_ui()

func _on_input_unlocked():
	actions_box.modulate = Color(1, 1, 1, 1)
	for b in [strike_button, guard_button, skill_button]:
		if b.visible:
			b.pivot_offset = b.size / 2.0
			var tw: Tween = b.create_tween()
			tw.tween_property(b, "scale", Vector2.ONE * 1.05, _t(0.1))
			tw.tween_property(b, "scale", Vector2.ONE, _t(0.1))

func _on_actor_started(index: int, _intent: Dictionary):
	if index < 0:
		actions_box.modulate = Color(1, 1, 1, 0.5)
		_update_ui()
		return
	for k in range(enemy_ui_nodes.size()):
		var ui = enemy_ui_nodes[k]
		if k == index:
			var tw: Tween = ui.intent.create_tween().set_parallel(true)
			tw.tween_property(ui.intent, "scale", Vector2.ONE * 1.3, _t(0.12))
			tw.tween_property(ui.intent, "modulate", Color(1.6, 1.6, 1.6, 1), _t(0.12))
			tw.tween_property(ui.body, "modulate", Color(1.3, 1.3, 1.3, ui.body.modulate.a), _t(0.12))
		else:
			ui.intent.modulate = Color(1, 1, 1, 0.6)

func _on_actor_ended(index: int):
	for k in range(enemy_ui_nodes.size()):
		var ui = enemy_ui_nodes[k]
		ui.intent.modulate = Color(1, 1, 1, 1)
		if k == index:
			var tw: Tween = ui.intent.create_tween()
			tw.tween_property(ui.intent, "scale", Vector2.ONE, _t(0.1))
			ui.body.modulate = Color(1, 1, 1, ui.body.modulate.a)

func _on_lunge(index: int, heavy: bool):
	var b := _body(index)
	if b == null or not is_instance_valid(b):
		return
	# art-a2: big lunge toward the target side so enemy actions read at a glance.
	var dist := -36.0 if index < 0 else (72.0 if heavy else 56.0)
	var base_y := b.position.y
	if index >= 0 and heavy:
		base_y = 0.0
	var tw := b.create_tween()
	tw.tween_property(b, "position:y", base_y + dist, _t(0.1))
	tw.tween_property(b, "position:y", 0.0, _t(0.15))
	if index >= 0 and heavy:
		tw.parallel().tween_property(b, "modulate", Color(1, 1, 1, b.modulate.a), _t(0.15))

func _on_windup(index: int):
	var b := _body(index)
	if b == null or not is_instance_valid(b):
		return
	var tw := b.create_tween().set_parallel(true)
	tw.tween_property(b, "position:y", -12.0, _t(0.25))
	tw.tween_property(b, "modulate", Color(1.6, 0.55, 0.5, b.modulate.a), _t(0.25))

func _on_hit(target: int, hp_loss: int, blocked: int, heavy: bool):
	var size := 34 if heavy else 26
	if target < 0:
		size = 64 if heavy else 52   # art-a2: large number over the hero
	if hp_loss > 0:
		_popup(target, "-%d" % hp_loss, C_RED, size, Vector2(0, 10) if target < 0 else Vector2.ZERO)
		if blocked > 0:
			_popup(target, "(%d blocked)" % blocked, C_BLUE, 18, Vector2(-46, 30))
	elif blocked > 0:
		_popup(target, "Blocked %d" % blocked, C_BLUE, 22)
	else:
		_popup(target, "0", C_TEXT, 20)
	var b := _body(target)
	if target < 0:
		_shake(b, 10.0 if heavy else 6.0, 0.2)
		if hp_loss > 0:
			_flash(b, C_RED, 0.25)
	else:
		_shake(b, 4.0, 0.16)
		_flash(b, Color(2, 2, 2), 0.12)
	_update_ui()

func _on_block_gained(target: int, amount: int):
	_shape_flash(target, C_BLUE, false, 0.6, 1.2, 1.0, 0.25, false)
	_shield_pop(target)
	_popup(target, "+%d Block" % amount, C_BLUE, 22)
	_update_ui()
	_bounce(block_label if target < 0 else (enemy_ui_nodes[target].stats if target < enemy_ui_nodes.size() else null))

## art-a2: big 16x16 shield sprite (x6, 96px) pops over whoever Guards, then fades.
func _shield_pop(target: int):
	var b := _body(target)
	if b == null or not is_instance_valid(b):
		return
	var icon := TextureRect.new()
	icon.texture = Art.tex(102, 6)
	icon.size = Vector2(96, 96)
	icon.pivot_offset = Vector2(48, 48)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.modulate = Color(0.75, 0.9, 1.4, 1.0)
	overlay.add_child(icon)
	var rect := b.get_global_rect()
	icon.position = rect.position + Vector2(rect.size.x / 2.0 - 48.0, 0.0)
	icon.scale = Vector2(0.4, 0.4)
	var tw := icon.create_tween()
	tw.tween_property(icon, "scale", Vector2(1.15, 1.15), _t(0.14)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(icon, "scale", Vector2.ONE, _t(0.08))
	tw.tween_interval(_t(0.2))
	tw.tween_property(icon, "modulate:a", 0.0, _t(0.25))
	tw.tween_callback(icon.queue_free)

func _on_healed(target: int, amount: int):
	if amount > 0:
		_popup(target, "+%d" % amount, C_GREEN, 24)
	_update_ui()

func _on_ticked(target: int, kind: String, amount: int):
	match kind:
		"burn":
			_popup(target, "Burn %d" % amount, C_GOLD, 22)
			_flash(_body(target), Color(1.6, 1.2, 0.4), 0.1)
		"bleed":
			_popup(target, "Bleed %d" % amount, C_RED, 22)
			_flash(_body(target), C_RED, 0.1)
		"thorns":
			_popup(target, "Thorns -%d" % amount, C_RED, 22, Vector2(0, -18))
			_flash(_body(target), Color(2, 2, 2), 0.1)
	_update_ui()

func _on_summoned(index: int):
	await get_tree().process_frame   # let the rebuilt row lay out first
	if not is_instance_valid(self) or index >= enemy_ui_nodes.size():
		return
	_shape_flash(index, Color(1, 1, 1), true, 0.01, 1.5, 1.5, 0.25, true)
	var b: Control = enemy_ui_nodes[index].body
	b.modulate.a = 0.0
	var tw := b.create_tween()
	tw.tween_property(b, "modulate:a", 1.0, _t(0.2))
	_popup(index, "Summon!", C_PURPLE, 24)

func _on_killed(index: int):
	var b := _body(index)
	if b == null or not is_instance_valid(b):
		return
	var tw := b.create_tween().set_parallel(true)
	tw.tween_property(b, "modulate:a", 0.35, _t(0.3))
	tw.tween_property(b, "position:y", 10.0, _t(0.3))

func _on_enrage_pulse(bonus: int):
	var tw := vignette.create_tween()
	tw.tween_property(vignette, "modulate:a", 1.0, _t(0.12))
	tw.tween_property(vignette, "modulate:a", 0.0, _t(0.18))
	var r: Rect2 = enemy_container.get_global_rect()
	var label := Label.new()
	label.text = "Enrage +%d" % bonus
	label.add_theme_font_size_override("font_size", Art.fs(30))
	label.add_theme_color_override("font_color", C_RED)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(label)
	label.position = Vector2(r.position.x + r.size.x / 2.0 - label.get_minimum_size().x / 2.0, r.position.y - 6)
	var tl := label.create_tween()
	tl.tween_property(label, "position:y", label.position.y - 30.0, _t(0.6))
	tl.parallel().tween_property(label, "modulate:a", 0.0, _t(0.6))
	tl.tween_callback(label.queue_free)
	_update_enemy_intents()
	for ui in enemy_ui_nodes:
		_bounce(ui.intent)

func _on_log_line(text: String):
	log_lines.append(text)
	while log_lines.size() > 2:
		log_lines.pop_front()
	for k in range(2):
		var idx := log_lines.size() - 2 + k
		log_labels[k].text = log_lines[idx] if idx >= 0 else ""
	RunState.qa_log("LOG", {"text": text})

func _on_speed_pressed():
	var speed := RunState.toggle_combat_speed()
	speed_button.text = "Speed %dx" % speed

func _on_enemy_turn():
	_update_ui()

func _on_player_turn_started():
	_update_ui()
	_qa_dump()

func _qa_dump():
	var foes: Array = []
	for enemy in combat_state.enemies:
		foes.append({"name": enemy.display_name, "hp": maxi(0, enemy.current_hp), "max_hp": enemy.max_hp,
				"intent": combat_state.intent_name(enemy.get_current_intent()), "block": enemy.block})
	RunState.qa_dump_ui(self, "combat", {"turn": combat_state.player_turn_number,
			"focus": combat_state.player_focus, "enemies": foes,
			"enrage": combat_state.get_enrage_bonus(), "node": RunState.current_node_type,
			"block": combat_state.player_block, "skill_cost": combat_state.skill_cost(),
			"speed": RunState.combat_speed(), "log": log_lines.duplicate()})

func _on_enemy_selected(index: int):
	combat_state.select_enemy(index)
	_update_enemy_ui()

func _on_strike_pressed():
	combat_state.player_action_strike()

func _on_guard_pressed():
	combat_state.player_action_guard()

func _on_skill_pressed():
	combat_state.player_action_skill()

func _on_player_damaged(_amount: int):
	_update_ui()

func _on_enemy_damaged(_index: int, _amount: int):
	_update_ui()

func _on_combat_ended(won: bool):
	_update_ui()
	RunState.qa_log("END", {"won": won, "hp": combat_state.player_hp, "turn": combat_state.player_turn_number,
			"node": RunState.current_node_type})
	await get_tree().create_timer(_t(1.0)).timeout
	
	if not won:
		get_tree().change_scene_to_file("res://scenes/result.tscn")
		return
	RunState.on_combat_won()
	get_tree().change_scene_to_file(RunState.after_combat_scene())
