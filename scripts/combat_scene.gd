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
	combat_state.player_turn_started.connect(_update_ui)
	combat_state.enemy_turn_started.connect(_on_enemy_turn)
	combat_state.player_damaged.connect(_on_player_damaged)
	combat_state.enemy_damaged.connect(_on_enemy_damaged)
	combat_state.player_blocked.connect(func(_amount): _update_ui())
	combat_state.enemy_blocked.connect(func(_index, _amount): _update_ui())
	combat_state.focus_changed.connect(func(_focus): _update_ui())
	combat_state.intents_updated.connect(_update_enemy_intents)
	combat_state.enrage_started.connect(_on_enrage_started)
	
	_create_enrage_toast()
	
	var enemy_setup = []
	if RunState.map_progress == 0:
		enemy_setup = [
			{"id": "enemy_rat", "name": "Rat", "hp": 8, "pattern": [
				{"type": "strike", "value": 4},
				{"type": "strike", "value": 4},
				{"type": "guard", "value": 3}
			]},
			{"id": "enemy_rat", "name": "Rat", "hp": 8, "pattern": [
				{"type": "strike", "value": 4},
				{"type": "strike", "value": 4},
				{"type": "guard", "value": 3}
			]}
		]
	elif RunState.map_progress == 2:
		enemy_setup = [
			{"id": "enemy_bone_warden", "name": "Bone Warden", "hp": 33, "pattern": [
				{"type": "strike", "value": 7},
				{"type": "strike", "value": 7},
				{"type": "heavy", "value": 11}
			]}
		]
	
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
	for i in range(combat_state.enemies.size()):
		var enemy = combat_state.enemies[i]
		var ui = enemy_ui_nodes[i]
		
		if enemy.is_alive():
			ui.button.text = "%s\nHP: %d/%d" % [enemy.display_name, enemy.current_hp, enemy.max_hp]
			if enemy.block > 0:
				ui.stats.text = "Block: %d" % enemy.block
			else:
				ui.stats.text = ""
			
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
	var bonus = combat_state.get_enrage_bonus()
	for i in range(combat_state.enemies.size()):
		var enemy = combat_state.enemies[i]
		var ui = enemy_ui_nodes[i]
		
		if enemy.is_alive():
			var intent = enemy.get_current_intent()
			match intent.type:
				"strike":
					ui.intent.text = "Strike %d" % (intent.value + bonus)
				"guard":
					ui.intent.text = "Guard +%d" % intent.value
				"heavy":
					ui.intent.text = "Heavy %d" % (intent.value + bonus)
			ui.enrage.text = "Enraged +%d" % bonus
			ui.enrage.visible = bonus > 0
		else:
			ui.intent.text = ""
			ui.enrage.visible = false

func _update_ui():
	hp_label.text = "HP: %d/%d" % [combat_state.player_hp, combat_state.player_max_hp]
	block_label.text = "Block: %d" % combat_state.player_block
	focus_label.text = "Focus: %d/%d" % [combat_state.player_focus, combat_state.player_focus_max]
	
	var can_act = combat_state.is_player_turn and combat_state.combat_active
	strike_button.disabled = not can_act
	guard_button.disabled = not can_act
	
	var has_skill = RunState.selected_talent != ""
	var can_use_skill = can_act and combat_state.player_focus >= 1 and has_skill
	skill_button.disabled = not can_use_skill
	skill_button.visible = has_skill
	
	if has_skill:
		var skill = RunState.get_skill_effect()
		if skill.type == "damage":
			skill_button.text = "Skill (Dmg %d)" % skill.value
		elif skill.type == "block":
			skill_button.text = "Skill (Blk +%d)" % skill.value
		elif skill.type == "strike_and_block":
			skill_button.text = "Skill (Atk %d + Blk %d)" % [skill.damage, skill.block]
	
	strike_button.text = "Strike (%d)" % RunState.strike_damage
	guard_button.text = "Guard (5)"
	
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
	await get_tree().create_timer(1.0).timeout
	
	if won:
		if RunState.map_progress == 0:
			RunState.add_gold(55)
			RunState.advance_map()
			get_tree().change_scene_to_file("res://scenes/map.tscn")
		elif RunState.map_progress == 2:
			get_tree().change_scene_to_file("res://scenes/result.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/result.tscn")
