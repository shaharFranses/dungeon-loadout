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
signal enrage_started(bonus: int)
signal player_bled(amount: int)

class Enemy:
	var enemy_id: String
	var display_name: String
	var max_hp: int
	var current_hp: int
	var block: int = 0
	var intent_pattern: Array
	var turn_count: int = 0
	var is_boss: bool = false
	var dmg_bonus: int = 0
	var burn: int = 0
	
	func _init(id: String, name: String, hp: int, pattern: Array, offset: int = 0, boss: bool = false):
		enemy_id = id
		display_name = name
		max_hp = hp
		current_hp = hp
		intent_pattern = pattern
		turn_count = offset
		is_boss = boss
	
	func attack_value(intent: Dictionary) -> int:
		return int(intent.value) + dmg_bonus
	
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
var player_bleed: int = 0
var player_bleed_turns: int = 0

var enemies: Array[Enemy] = []
var selected_enemy_index: int = 0

var is_player_turn: bool = true
var is_enemy_turn: bool = false
var combat_active: bool = false

const ENRAGE_START_TURN: int = 7
const ENRAGE_STEP: int = 2

var player_turn_number: int = 1

func start_combat(enemy_setup: Array):
	RunState.player_hp = clampi(RunState.player_hp, 0, RunState.player_max_hp)
	player_hp = RunState.player_hp
	player_max_hp = RunState.player_max_hp
	player_block = 0
	player_focus = 1
	player_focus_max = RunState.player_focus_max
	player_bleed = 0
	player_bleed_turns = 0
	
	enemies.clear()
	for setup in enemy_setup:
		var enemy = Enemy.new(setup.id, setup.name, setup.hp, setup.pattern,
				int(setup.get("offset", 0)), bool(setup.get("boss", false)))
		enemies.append(enemy)
	
	selected_enemy_index = 0
	player_turn_number = 1
	is_player_turn = true
	is_enemy_turn = false
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
	
	var target_index = selected_enemy_index
	var weapon: Dictionary = RunState.weapon
	var instakill: float = float(weapon.get("instakill", 0.0))
	if instakill > 0.0 and not target.is_boss and RunState.rng.randf() < instakill:
		_deal_damage_to_enemy(target_index, target.current_hp + target.block)
	else:
		_deal_damage_to_enemy(target_index, RunState.get_strike_damage())
	if int(weapon.get("burn", 0)) > 0 and target.is_alive():
		target.burn = int(weapon.burn)
	
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
	
	if not enemy.is_alive():
		_retarget_if_needed(enemy_index)

func _retarget_if_needed(dead_index: int):
	if dead_index != selected_enemy_index:
		return
	for i in range(enemies.size()):
		if enemies[i].is_alive():
			selected_enemy_index = i
			break

func _deal_damage_to_player(raw_damage: int):
	# Block is consumed hit by hit: Guard 5 vs two 4-damage hits absorbs 5 in total.
	var absorbed = mini(player_block, raw_damage)
	player_block -= absorbed
	var actual_damage = raw_damage - absorbed
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
		
		if enemy.burn > 0:
			enemy.current_hp -= enemy.burn
			emit_signal("enemy_damaged", i, enemy.burn)
			if not enemy.is_alive():
				_retarget_if_needed(i)
				await get_tree().create_timer(0.5).timeout
				continue
		
		var intent = enemy.get_current_intent()
		match intent.type:
			"strike", "heavy":
				_deal_damage_to_player(enemy.attack_value(intent) + get_enrage_bonus())
			"rend":
				_deal_damage_to_player(enemy.attack_value(intent) + get_enrage_bonus())
				player_bleed = int(intent.bleed)
				player_bleed_turns = int(intent.bleed_turns)
			"guard":
				enemy.block += intent.value
				emit_signal("enemy_blocked", i, intent.value)
			"buff":
				enemy.dmg_bonus += int(intent.value)
				emit_signal("enemy_blocked", i, 0)
		
		await get_tree().create_timer(0.5).timeout
		if player_hp <= 0:
			break
	
	for enemy in enemies:
		enemy.turn_count += 1
	
	is_enemy_turn = false
	
	if _check_combat_end():
		return
	
	_start_player_turn()

func _start_player_turn():
	player_block = 0
	player_focus = mini(player_focus + 1, player_focus_max)
	player_turn_number += 1
	
	if player_bleed_turns > 0:
		player_hp -= player_bleed
		player_bleed_turns -= 1
		RunState.player_hp = player_hp
		emit_signal("player_bled", player_bleed)
		if _check_combat_end():
			return
	
	is_player_turn = true
	emit_signal("focus_changed", player_focus)
	emit_signal("intents_updated")
	emit_signal("player_turn_started")
	if player_turn_number == ENRAGE_START_TURN:
		emit_signal("enrage_started", get_enrage_bonus())

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

func get_enrage_bonus() -> int:
	if player_turn_number < ENRAGE_START_TURN:
		return 0
	return (player_turn_number - ENRAGE_START_TURN + 1) * ENRAGE_STEP

func select_enemy(index: int):
	if index >= 0 and index < enemies.size():
		selected_enemy_index = index
