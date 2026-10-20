extends Node
## Turn-based combat rules. One action per player turn (Strike, Guard or Skill).

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
signal enemies_changed()

const Encounters = preload("res://scripts/encounters.gd")

class Enemy:
	var enemy_id: String
	var display_name: String
	var max_hp: int
	var current_hp: int
	var block: int = 0
	var intent_pattern: Array
	var turn_count: int = 0
	var is_boss: bool = false
	var is_summon: bool = false
	var has_summoned: bool = false  # v3.6: Summon happens once per fight
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
	
	func get_current_intent() -> Dictionary:
		if intent_pattern.is_empty():
			return {"type": "strike", "value": 5}
		var index = turn_count % intent_pattern.size()
		var intent: Dictionary = intent_pattern[index]
		if intent.type == "summon" and has_summoned:
			return {"type": "strike", "value": int(intent.get("after_strike", 8))}
		return intent
	
	func attack_value(intent: Dictionary) -> int:
		return int(intent.value) + dmg_bonus
	
	func is_alive() -> bool:
		return current_hp > 0

var player_hp: int
var player_max_hp: int
var player_block: int = 0
var player_focus: int = 1
var player_focus_max: int = 2
var player_bleed: int = 0
var player_bleed_turns: int = 0
var player_hex: int = 0
var first_strike_used: bool = false

var enemies: Array[Enemy] = []
var selected_enemy_index: int = 0

var is_player_turn: bool = true
var is_enemy_turn: bool = false
var combat_active: bool = false

const ENRAGE_START_TURN: int = 7
const ENRAGE_STEP: int = 2
const MAX_SUMMONS: int = 1

var player_turn_number: int = 1

func start_combat(enemy_setup: Array):
	RunState.player_hp = clampi(RunState.player_hp, 0, RunState.player_max_hp)
	player_hp = RunState.player_hp
	player_max_hp = RunState.player_max_hp
	player_focus_max = RunState.get_max_focus()
	player_focus = RunState.get_start_focus()
	player_block = RunState.get_start_block()
	player_bleed = 0
	player_bleed_turns = 0
	player_hex = 0
	first_strike_used = false
	
	enemies.clear()
	for setup in enemy_setup:
		enemies.append(_make_enemy(setup))
	
	selected_enemy_index = 0
	player_turn_number = 1
	is_player_turn = true
	is_enemy_turn = false
	combat_active = true
	
	emit_signal("intents_updated")
	emit_signal("player_turn_started")

func _make_enemy(setup: Dictionary) -> Enemy:
	return Enemy.new(setup.id, setup.name, setup.hp, setup.pattern,
			int(setup.get("offset", 0)), bool(setup.get("boss", false)))

func skill_is_free() -> bool:
	var every := RunState.get_free_skill_every()
	return every > 0 and player_turn_number % every == 0

func skill_cost() -> int:
	return 0 if skill_is_free() else 1

func player_action_strike():
	if not is_player_turn or not combat_active:
		return
	
	var target = enemies[selected_enemy_index]
	if not target.is_alive():
		return
	
	is_player_turn = false
	
	var target_index = selected_enemy_index
	var weapon: Dictionary = RunState.weapon
	var damage: int = RunState.get_strike_damage()
	if not first_strike_used:
		damage += RunState.get_first_strike_bonus()
		first_strike_used = true
	if player_hex > 0:
		damage = maxi(0, damage - player_hex)
		player_hex = 0
	var instakill: float = float(weapon.get("instakill", 0.0))
	if instakill > 0.0 and not target.is_boss and RunState.rng.randf() < instakill:
		_deal_damage_to_enemy(target_index, target.current_hp + target.block)
	else:
		_deal_damage_to_enemy(target_index, damage)
	if int(weapon.get("burn", 0)) > 0 and target.is_alive():
		target.burn = int(weapon.burn)
	
	var cleave_pct := RunState.get_cleave_pct()
	if cleave_pct > 0:
		for i in range(enemies.size()):
			if i != target_index and enemies[i].is_alive():
				_deal_damage_to_enemy(i, floori(damage * cleave_pct / 100.0))
				break
	
	await get_tree().create_timer(0.3).timeout
	_end_player_turn()

func player_action_guard():
	if not is_player_turn or not combat_active:
		return
	
	is_player_turn = false
	
	var amount := RunState.get_guard_amount()
	player_block += amount
	emit_signal("player_blocked", amount)
	
	await get_tree().create_timer(0.3).timeout
	_end_player_turn()

func player_action_skill():
	var cost := skill_cost()
	if not is_player_turn or not combat_active or player_focus < cost:
		return
	
	var skill = RunState.get_skill_effect()
	if skill.type == "none":
		return
	
	is_player_turn = false
	
	player_focus -= cost
	emit_signal("focus_changed", player_focus)
	
	if skill.type == "damage":
		var target = enemies[selected_enemy_index]
		if target.is_alive():
			_deal_damage_to_enemy(selected_enemy_index, skill.value)
	elif skill.type == "damage_all":
		for i in range(enemies.size()):
			if enemies[i].is_alive():
				_deal_damage_to_enemy(i, skill.value)
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
	if not enemy.is_alive():
		return
	var absorbed = mini(enemy.block, raw_damage)
	enemy.block -= absorbed
	var actual_damage = raw_damage - absorbed
	enemy.current_hp -= actual_damage
	emit_signal("enemy_damaged", enemy_index, actual_damage)
	
	if not enemy.is_alive():
		_on_enemy_killed(enemy_index)

func _on_enemy_killed(enemy_index: int):
	var heal := RunState.get_kill_heal()
	if heal > 0:
		player_hp = mini(player_hp + heal, player_max_hp)
		RunState.player_hp = player_hp
		emit_signal("player_damaged", 0)
	_retarget_if_needed(enemy_index)

func _retarget_if_needed(dead_index: int):
	if dead_index != selected_enemy_index:
		return
	for i in range(enemies.size()):
		if enemies[i].is_alive():
			selected_enemy_index = i
			break

func _deal_damage_to_player(raw_damage: int, attacker: Enemy = null, block_factor: float = 1.0):
	# Block is consumed hit by hit: Guard 5 vs two 4-damage hits absorbs 5 in total.
	# block_factor < 1 lets an attack ignore part of your Block (Tidal ignores half).
	var usable_block = floori(player_block * block_factor)
	var absorbed = mini(usable_block, raw_damage)
	player_block -= absorbed
	var actual_damage = raw_damage - absorbed
	player_hp -= actual_damage
	RunState.player_hp = player_hp
	emit_signal("player_damaged", actual_damage)
	var thorns := RunState.get_thorns()
	if thorns > 0 and attacker != null and attacker.is_alive():
		attacker.current_hp -= thorns
		emit_signal("enemy_damaged", enemies.find(attacker), thorns)
		if not attacker.is_alive():
			_on_enemy_killed(enemies.find(attacker))

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
	
	var acting: Array = enemies.duplicate()
	for enemy in acting:
		var i := enemies.find(enemy)
		if not enemy.is_alive():
			continue
		
		enemy.block = 0
		
		if enemy.burn > 0:
			enemy.current_hp -= enemy.burn
			emit_signal("enemy_damaged", i, enemy.burn)
			if not enemy.is_alive():
				_on_enemy_killed(i)
				await get_tree().create_timer(0.5).timeout
				continue
		
		_run_intent(enemy, i)
		
		await get_tree().create_timer(0.5).timeout
		if player_hp <= 0:
			break
	
	for enemy in acting:
		enemy.turn_count += 1
	
	is_enemy_turn = false
	
	if _check_combat_end():
		return
	
	_start_player_turn()

func _run_intent(enemy: Enemy, i: int):
	var intent = enemy.get_current_intent()
	var bonus := get_enrage_bonus()
	var hp_before := player_hp
	var block_before := player_block
	_run_intent_effect(enemy, i, intent, bonus)
	RunState.qa_log("ACTION", {"turn": player_turn_number, "enemy": enemy.display_name, "intent": intent.type,
			"value": intent.get("value", 0), "block_before": block_before, "hp": [hp_before, player_hp],
			"enemy_hp": enemy.current_hp, "enemies": enemies.size()})

func _run_intent_effect(enemy: Enemy, i: int, intent: Dictionary, bonus: int):
	match intent.type:
		"strike", "heavy":
			for _hit in range(int(intent.get("hits", 1))):
				if player_hp <= 0 or not enemy.is_alive():
					break
				_deal_damage_to_player(enemy.attack_value(intent) + bonus, enemy)
		"rend":
			_deal_damage_to_player(enemy.attack_value(intent) + bonus, enemy)
			player_bleed = int(intent.bleed)
			player_bleed_turns = int(intent.bleed_turns)
		"tidal":
			_deal_damage_to_player(enemy.attack_value(intent) + bonus, enemy, 0.5)
		"drain":
			_deal_damage_to_player(enemy.attack_value(intent) + bonus, enemy)
			if enemy.is_alive():
				enemy.current_hp = mini(enemy.current_hp + int(intent.value), enemy.max_hp)
				emit_signal("enemy_blocked", i, 0)
		"guard":
			enemy.block += intent.value
			emit_signal("enemy_blocked", i, intent.value)
		"buff":
			enemy.dmg_bonus += int(intent.value)
			emit_signal("enemy_blocked", i, 0)
		"hex":
			player_hex = int(intent.value)
			emit_signal("enemy_blocked", i, 0)
		"regen":
			enemy.current_hp = mini(enemy.current_hp + int(intent.value), enemy.max_hp)
			emit_signal("enemy_blocked", i, 0)
		"summon":
			_summon_drowned()
			enemy.has_summoned = true

func _summon_drowned():
	var alive_summons := 0
	for e in enemies:
		if e.is_summon and e.is_alive():
			alive_summons += 1
	if alive_summons >= MAX_SUMMONS:
		return
	var setup := Encounters.make_enemy(RunState.rng, Encounters.DROWNED_SUMMON)
	var summoned := _make_enemy(setup)
	summoned.is_summon = true
	# Reuse a dead summon's slot so the enemy row does not keep growing.
	for k in range(enemies.size()):
		if enemies[k].is_summon and not enemies[k].is_alive():
			enemies[k] = summoned
			emit_signal("enemies_changed")
			return
	enemies.append(summoned)
	emit_signal("enemies_changed")

func _start_player_turn():
	var keep_pct := RunState.get_keep_block_pct()
	player_block = floori(player_block * keep_pct / 100.0) if keep_pct > 0 else 0
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
