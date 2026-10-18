extends Node

signal combat_ended(won: bool)
signal player_turn_started()
signal enemy_turn_started()
signal player_damaged(amount: int)
signal enemy_damaged(enemy_index: int, amount: int)
signal player_blocked(amount: int)
signal enemy_blocked(enemy_index: int, amount: int)
signal focus_changed(new_focus: int)
signal intents_updated()

class Enemy:
	var enemy_id: String
	var display_name: String
	var max_hp: int
	var current_hp: int
	var block: int = 0
	var intent_pattern: Array
	var turn_count: int = 0
	
	func _init(id: String, name: String, hp: int, pattern: Array):
		enemy_id = id
		display_name = name
		max_hp = hp
		current_hp = hp
		intent_pattern = pattern
	
	func get_current_intent() -> Dictionary:
		if intent_pattern.is_empty():
			return {"type": "strike", "value": 5}
		var index = turn_count % intent_pattern.size()
		return intent_pattern[index]
	
	func is_alive() -> bool:
		return current_hp > 0

var player_hp: int
var player_max_hp: int
var player_block: int = 0
var player_focus: int = 1
var player_focus_max: int = 2

var enemies: Array[Enemy] = []
var selected_enemy_index: int = 0

var is_player_turn: bool = true
var is_enemy_turn: bool = false
var combat_active: bool = false

func start_combat(enemy_setup: Array):
	RunState.player_hp = clampi(RunState.player_hp, 0, RunState.player_max_hp)
	player_hp = RunState.player_hp
	player_max_hp = RunState.player_max_hp
	player_block = 0
	player_focus = 1
	player_focus_max = RunState.player_focus_max
	
	enemies.clear()
	for setup in enemy_setup:
		var enemy = Enemy.new(setup.id, setup.name, setup.hp, setup.pattern)
		enemies.append(enemy)
	
	selected_enemy_index = 0
	is_player_turn = true
	combat_active = true
	
	emit_signal("intents_updated")
	emit_signal("player_turn_started")

func player_action_strike():
	if not is_player_turn or not combat_active:
		return
	
	var target = enemies[selected_enemy_index]
	if not target.is_alive():
		return
	
	is_player_turn = false
	
	var damage = RunState.strike_damage
	_deal_damage_to_enemy(selected_enemy_index, damage)
	
	await get_tree().create_timer(0.3).timeout
	_end_player_turn()

func player_action_guard():
	if not is_player_turn or not combat_active:
		return
	
	is_player_turn = false
	
	player_block += 5
	emit_signal("player_blocked", 5)
	
	await get_tree().create_timer(0.3).timeout
	_end_player_turn()

func player_action_skill():
	if not is_player_turn or not combat_active or player_focus < 1:
		return
	
	var skill = RunState.get_skill_effect()
	if skill.type == "none":
		return
	
	is_player_turn = false
	
	player_focus -= 1
	emit_signal("focus_changed", player_focus)
	
	if skill.type == "damage":
		var target = enemies[selected_enemy_index]
		if target.is_alive():
			_deal_damage_to_enemy(selected_enemy_index, skill.value)
	elif skill.type == "block":
		player_block += skill.value
		emit_signal("player_blocked", skill.value)
	elif skill.type == "strike_and_block":
		var target = enemies[selected_enemy_index]
		if target.is_alive():
			_deal_damage_to_enemy(selected_enemy_index, skill.damage)
		player_block += skill.block
		emit_signal("player_blocked", skill.block)
	
	await get_tree().create_timer(0.3).timeout
	_end_player_turn()

func _deal_damage_to_enemy(enemy_index: int, raw_damage: int):
	var enemy = enemies[enemy_index]
	var actual_damage = maxi(0, raw_damage - enemy.block)
	enemy.current_hp -= actual_damage
	emit_signal("enemy_damaged", enemy_index, actual_damage)
	
	if not enemy.is_alive() and enemy_index == selected_enemy_index:
		for i in range(enemies.size()):
			if enemies[i].is_alive():
				selected_enemy_index = i
				break

func _deal_damage_to_player(raw_damage: int):
	var actual_damage = maxi(0, raw_damage - player_block)
	player_hp -= actual_damage
	RunState.player_hp = player_hp
	emit_signal("player_damaged", actual_damage)

func _end_player_turn():
	is_player_turn = false
	
	if _check_combat_end():
		return
	
	await get_tree().create_timer(0.5).timeout
	_start_enemy_turn()

func _start_enemy_turn():
	if is_enemy_turn:
		return
	
	is_enemy_turn = true
	emit_signal("enemy_turn_started")
	
	for i in range(enemies.size()):
		var enemy = enemies[i]
		if not enemy.is_alive():
			continue
		
		enemy.block = 0
		
		var intent = enemy.get_current_intent()
		match intent.type:
			"strike":
				_deal_damage_to_player(intent.value)
			"guard":
				enemy.block += intent.value
				emit_signal("enemy_blocked", i, intent.value)
			"heavy":
				_deal_damage_to_player(intent.value)
		
		await get_tree().create_timer(0.5).timeout
	
	for enemy in enemies:
		enemy.turn_count += 1
	
	is_enemy_turn = false
	
	if _check_combat_end():
		return
	
	_start_player_turn()

func _start_player_turn():
	player_block = 0
	player_focus = mini(player_focus + 1, player_focus_max)
	
	is_player_turn = true
	emit_signal("focus_changed", player_focus)
	emit_signal("intents_updated")
	emit_signal("player_turn_started")

func _check_combat_end() -> bool:
	if player_hp <= 0:
		combat_active = false
		RunState.player_hp = 0
		emit_signal("combat_ended", false)
		return true
	
	var any_alive = false
	for enemy in enemies:
		if enemy.is_alive():
			any_alive = true
			break
	
	if not any_alive:
		combat_active = false
		emit_signal("combat_ended", true)
		return true
	
	return false

func select_enemy(index: int):
	if index >= 0 and index < enemies.size():
		selected_enemy_index = index
