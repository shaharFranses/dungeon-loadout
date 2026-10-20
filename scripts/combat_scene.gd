extends Control

@onready var enemy_container = $VBox/EnemyArea/EnemyContainer
@onready var hp_label = $VBox/PlayerArea/PlayerStats/HPLabel
@onready var block_label = $VBox/PlayerArea/PlayerStats/BlockLabel
@onready var focus_label = $VBox/PlayerArea/PlayerStats/FocusLabel
@onready var strike_button = $VBox/PlayerArea/Actions/StrikeButton
@onready var guard_button = $VBox/PlayerArea/Actions/GuardButton
@onready var skill_button = $VBox/PlayerArea/Actions/SkillButton

const CombatState = preload("res://scripts/combat_state.gd")

var combat_state: Node
var enemy_ui_nodes: Array = []
var enrage_toast: Label

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
	
	_create_enrage_toast()
	
	var enemy_setup: Array = RunState.current_encounter
	
	combat_state.start_combat(enemy_setup)
	_create_enemy_ui()
	_update_ui()
	
	var count = combat_state.enemies.size()
	DisplayServer.window_set_title("DL COMBAT: %d %s" % [count, "enemy" if count == 1 else "enemies"])

func _create_enemy_ui():
	for child in enemy_container.get_children():
		child.queue_free()
	
	enemy_ui_nodes.clear()
	
	for i in range(combat_state.enemies.size()):
		var enemy = combat_state.enemies[i]
		var vbox = VBoxContainer.new()
		vbox.custom_minimum_size = Vector2(200, 0)
		
		var button = Button.new()
		button.custom_minimum_size = Vector2(200, 120)
		button.text = enemy.display_name
		button.pressed.connect(func(): _on_enemy_selected(i))
		
		var panel = PanelContainer.new()
		panel.add_child(button)
		
		var stats_label = Label.new()
		stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_label.add_theme_font_size_override("font_size", 16)
		
		var intent_label = Label.new()
		intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		intent_label.add_theme_font_size_override("font_size", 18)
		
		var enrage_label = Label.new()
		enrage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		enrage_label.add_theme_font_size_override("font_size", 16)
		enrage_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
		enrage_label.visible = false
		
		vbox.add_child(panel)
		vbox.add_child(stats_label)
		vbox.add_child(intent_label)
		vbox.add_child(enrage_label)
		
		enemy_container.add_child(vbox)
		enemy_ui_nodes.append({
			"button": button,
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
	
	strike_button.text = "Strike (%d)" % RunState.get_strike_damage()
	guard_button.text = "Guard (%d)" % RunState.get_guard_amount()
	if has_skill and combat_state.skill_is_free():
		skill_button.text += " FREE"
	
	_update_enemy_ui()

func _create_enrage_toast():
	enrage_toast = Label.new()
	enrage_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enrage_toast.add_theme_font_size_override("font_size", 22)
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

func _on_enemy_turn():
	_update_ui()

func _on_player_turn_started():
	_update_ui()
	_qa_dump()

func _qa_dump():
	var foes: Array = []
	for enemy in combat_state.enemies:
		foes.append({"name": enemy.display_name, "hp": enemy.current_hp, "max_hp": enemy.max_hp,
				"intent": enemy.get_current_intent().type, "block": enemy.block})
	RunState.qa_dump_ui(self, "combat", {"turn": combat_state.player_turn_number,
			"focus": combat_state.player_focus, "enemies": foes,
			"enrage": combat_state.get_enrage_bonus(), "node": RunState.current_node_type,
			"block": combat_state.player_block, "skill_cost": combat_state.skill_cost()})

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
	await get_tree().create_timer(1.0).timeout
	
	if not won:
		get_tree().change_scene_to_file("res://scenes/result.tscn")
		return
	RunState.on_combat_won()
	get_tree().change_scene_to_file(RunState.after_combat_scene())
