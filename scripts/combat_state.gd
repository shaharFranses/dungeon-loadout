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
# v3.8 presentation signals (COMBAT_FEEDBACK.md). index -1 = the hero.
signal banner(side: String)                   # "player" / "enemy"
signal phase_changed(enemy_phase: bool)       # true for the whole enemy phase
signal input_unlocked()
signal actor_started(index: int, intent: Dictionary)
signal actor_ended(index: int)
signal lunge(index: int, heavy: bool)
signal windup(index: int)
signal hit(target: int, hp_loss: int, blocked: int, heavy: bool)
signal block_gained(target: int, amount: int)
signal healed(target: int, amount: int)
signal ticked(target: int, kind: String, amount: int)
signal status_popup(target: int, text: String, color: Color)
signal summoned(index: int)
signal killed(index: int)
signal enrage_pulse(bonus: int)
signal log_line(text: String)

const Encounters = preload("res://scripts/encounters.gd")
const TalentData = preload("res://scripts/talent_data.gd")

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

var is_player_turn: bool = false
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
	is_player_turn = false
	is_enemy_turn = false
	combat_active = true
	
	emit_signal("intents_updated")
	_player_turn_intro()

# ---- v3.8 pacing ----
# Every beat goes through _wait(), scaled by RunState.anim_scale() (1x / 2x speed toggle,
# and the QA anim=fast / anim=off flags). Rules never depend on the timing.

func _wait(seconds: float):
	var scale := RunState.anim_scale()
	if scale <= 0.0 or seconds <= 0.0:
		await _sleep(0.0)
		return
	await _sleep(seconds * scale)

## art-a3: one-shot Timer owned by this node. If the combat scene leaves the tree mid-wait
## (scene swap), the Timer stops with it and the coroutine never resumes, so nothing touches
## the tree from a node that has left it. 0 seconds = wait one process frame.
func _sleep(seconds: float):
	if not is_inside_tree():
		await tree_entered   # never fires: this node is being freed with its scene
		return
	if seconds <= 0.0:
		var frame_timer := Timer.new()
		frame_timer.one_shot = true
		frame_timer.wait_time = 0.001
		add_child(frame_timer)
		frame_timer.start()
		await frame_timer.timeout
		frame_timer.queue_free()
		return
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = seconds
	add_child(timer)
	timer.start()
	await timer.timeout
	timer.queue_free()

## Banner beats: fade in 0.15 + hold (min 0.2s at 2x) before the fade-out starts.
func _banner_until_fade(hold: float):
	var scale := RunState.anim_scale()
	if scale <= 0.0:
		await _sleep(0.0)
		return
	var t := 0.15 * scale + maxf(hold * scale, 0.2 if scale < 1.0 and not RunState.qa_anim_override() else 0.0)
	await _sleep(t)

func _phase_log(what: String, extra: Dictionary = {}):
	var data := {"what": what, "ms": Time.get_ticks_msec(), "turn": player_turn_number}
	data.merge(extra)
	RunState.qa_log("PHASE", data)

func _player_turn_intro():
	# Start-of-turn ticks have already resolved; show "Your Turn", unlock when it starts fading.
	emit_signal("banner", "player")
	_phase_log("player_banner")
	await _banner_until_fade(0.4)
	if not combat_active:
		return
	is_player_turn = true
	_phase_log("input_unlocked")
	emit_signal("input_unlocked")
	emit_signal("player_turn_started")
	if player_turn_number == ENRAGE_START_TURN:
		emit_signal("enrage_started", get_enrage_bonus())

func _make_enemy(setup: Dictionary) -> Enemy:
	# Stage D Ascension: +10% enemy HP per level (summons included).
	return Enemy.new(setup.id, setup.name, RunState.enemy_hp(int(setup.hp)), setup.pattern,
			int(setup.get("offset", 0)), bool(setup.get("boss", false)))

## What the next Strike will deal, plus the one-off modifiers behind it
## (first-Strike trinket bonus, Hex). Used by both the button label and the Strike itself.
func strike_preview() -> Dictionary:
	var damage: int = RunState.get_strike_damage()
	var notes: Array = []
	var first_bonus := RunState.get_first_strike_bonus()
	if not first_strike_used and first_bonus > 0:
		damage += first_bonus
		notes.append("%s +%d" % [String(RunState.gear.trinket.get("name", "First Strike")), first_bonus])
	if player_hex > 0:
		damage = maxi(0, damage - player_hex)
		notes.append("Hexed -%d" % player_hex)
	return {"damage": damage, "notes": notes}

func any_enemy_alive() -> bool:
	for enemy in enemies:
		if enemy.is_alive():
			return true
	return false

## Name used in QA logs: the intent's own label when it has one (Breath), else its type.
static func intent_name(intent: Dictionary) -> String:
	return String(intent.get("label", intent.type)).to_lower()

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
	emit_signal("actor_started", -1, {"type": "strike"})
	emit_signal("lunge", -1, false)
	await _wait(0.1)
	var weapon: Dictionary = RunState.weapon
	var damage: int = strike_preview().damage
	first_strike_used = true
	player_hex = 0
	var instakill: float = float(weapon.get("instakill", 0.0))
	if instakill > 0.0 and not target.is_boss and RunState.rng.randf() < instakill:
		_deal_damage_to_enemy(target_index, target.current_hp + target.block)
		emit_signal("log_line", "You Strike: instakill!")
	else:
		var dealt := _deal_damage_to_enemy(target_index, damage)
		emit_signal("log_line", "You Strike %s for %d%s" % [target.display_name, dealt.hp_lost,
				" (%d blocked)" % dealt.blocked if dealt.blocked > 0 else ""])
	if int(weapon.get("burn", 0)) > 0 and target.is_alive():
		target.burn = int(weapon.burn)
	
	var cleave_pct := RunState.get_cleave_pct()
	if cleave_pct > 0:
		for i in range(enemies.size()):
			if i != target_index and enemies[i].is_alive():
				_deal_damage_to_enemy(i, floori(damage * cleave_pct / 100.0))
				break
	await _finish_player_action()

func player_action_guard():
	if not is_player_turn or not combat_active:
		return
	is_player_turn = false
	emit_signal("actor_started", -1, {"type": "guard"})
	var amount := RunState.get_guard_amount()
	player_block += amount
	emit_signal("player_blocked", amount)
	emit_signal("block_gained", -1, amount)
	emit_signal("log_line", "You Guard: +%d Block" % amount)
	await _finish_player_action(0.4)

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
	emit_signal("actor_started", -1, {"type": "skill"})
	var skill_name := String(TalentData.get_def(RunState.skill_id).get("name", "Skill"))
	var lunged: bool = skill.type in ["damage", "damage_all", "strike_and_block"]
	if lunged:
		emit_signal("lunge", -1, false)
		await _wait(0.1)
	if skill.type == "damage":
		var target = enemies[selected_enemy_index]
		if target.is_alive():
			var dealt := _deal_damage_to_enemy(selected_enemy_index, skill.value)
			emit_signal("log_line", "%s hits %s for %d" % [skill_name, target.display_name, dealt.hp_lost])
	elif skill.type == "damage_all":
		for i in range(enemies.size()):
			if enemies[i].is_alive():
				_deal_damage_to_enemy(i, skill.value)
		emit_signal("log_line", "%s hits every enemy for %d" % [skill_name, skill.value])
	elif skill.type == "block":
		player_block += skill.value
		emit_signal("player_blocked", skill.value)
		emit_signal("block_gained", -1, skill.value)
	elif skill.type == "strike_and_block":
		var target = enemies[selected_enemy_index]
		if target.is_alive():
			var dealt := _deal_damage_to_enemy(selected_enemy_index, skill.damage)
			emit_signal("log_line", "%s hits %s for %d, +%d Block" % [skill_name, target.display_name, dealt.hp_lost, skill.block])
		player_block += skill.block
		emit_signal("player_blocked", skill.block)
		emit_signal("block_gained", -1, skill.block)
	await _finish_player_action(0.3 if lunged else 0.4)

func _finish_player_action(remaining: float = 0.3):
	# Player feedback ~0.4s in total (a lunge's contact already took 0.1), then a 0.2s gap.
	await _wait(remaining)
	emit_signal("actor_ended", -1)
	await _wait(0.2)
	_end_player_turn()

func _deal_damage_to_enemy(enemy_index: int, raw_damage: int) -> Dictionary:
	var enemy = enemies[enemy_index]
	if not enemy.is_alive():
		return {"hp_loss": 0, "blocked": 0, "hp_lost": 0}
	var absorbed = mini(enemy.block, raw_damage)
	enemy.block -= absorbed
	var actual_damage = raw_damage - absorbed
	var hp_before: int = enemy.current_hp
	enemy.current_hp -= actual_damage
	emit_signal("enemy_damaged", enemy_index, actual_damage)
	# Popup shows real HP lost (overkill clamped at 0), matching the clamped HP bar.
	emit_signal("hit", enemy_index, mini(actual_damage, maxi(0, hp_before)), absorbed, false)
	
	if not enemy.is_alive():
		_on_enemy_killed(enemy_index)
	# hp_lost: HP actually removed (overkill clamped) - what popups and the log show.
	return {"hp_loss": actual_damage, "blocked": absorbed, "hp_lost": mini(actual_damage, maxi(0, hp_before))}

func _on_enemy_killed(enemy_index: int):
	emit_signal("killed", enemy_index)
	emit_signal("log_line", "%s is defeated" % enemies[enemy_index].display_name)
	var heal := RunState.get_kill_heal()
	if heal > 0:
		var before := player_hp
		player_hp = mini(player_hp + heal, player_max_hp)
		RunState.player_hp = player_hp
		emit_signal("player_damaged", 0)
		if player_hp > before:
			emit_signal("healed", -1, player_hp - before)
	_retarget_if_needed(enemy_index)

func _retarget_if_needed(dead_index: int):
	if dead_index != selected_enemy_index:
		return
	for i in range(enemies.size()):
		if enemies[i].is_alive():
			selected_enemy_index = i
			break

var _attack_heavy: bool = false

func _deal_damage_to_player(raw_damage: int, attacker: Enemy = null, block_factor: float = 1.0) -> Dictionary:
	# Block is consumed hit by hit: Guard 5 vs two 4-damage hits absorbs 5 in total.
	# block_factor < 1 lets an attack ignore part of your Block (Tidal ignores half).
	var usable_block = floori(player_block * block_factor)
	var absorbed = mini(usable_block, raw_damage)
	player_block -= absorbed
	var actual_damage = raw_damage - absorbed
	var php_before := player_hp
	player_hp = maxi(0, player_hp - actual_damage)   # v3.8: never below 0 (HUD, DLEND, end screen)
	RunState.player_hp = player_hp
	emit_signal("player_damaged", actual_damage)
	emit_signal("hit", -1, mini(actual_damage, maxi(0, php_before)), absorbed, _attack_heavy)
	var thorns := RunState.get_thorns()
	if thorns > 0 and attacker != null and attacker.is_alive():
		var ai := enemies.find(attacker)
		var thorns_loss: int = mini(thorns, attacker.current_hp)
		attacker.current_hp -= thorns
		emit_signal("enemy_damaged", ai, thorns)
		emit_signal("ticked", ai, "thorns", thorns_loss)
		if not attacker.is_alive():
			_on_enemy_killed(ai)
	return {"hp_loss": actual_damage, "blocked": absorbed, "hp_lost": mini(actual_damage, maxi(0, php_before))}

func _end_player_turn():
	is_player_turn = false
	
	if _check_combat_end():
		return
	
	_start_enemy_turn()

func _start_enemy_turn():
	if is_enemy_turn:
		return
	
	is_enemy_turn = true
	emit_signal("phase_changed", true)
	emit_signal("enemy_turn_started")
	emit_signal("banner", "enemy")
	_phase_log("enemy_banner")
	var banner_left := 0.4   # until the Enemy Turn banner starts fading (0.15 in + 0.25 hold)
	
	# Start-of-turn ticks resolve inside the banner: Block clears, then Burn (0.25s each).
	var acting: Array = enemies.duplicate()
	for enemy in acting:
		if enemy.is_alive():
			enemy.block = 0
	emit_signal("enemy_blocked", -1, 0)
	for enemy in acting:
		var i := enemies.find(enemy)
		if not enemy.is_alive() or enemy.burn <= 0:
			continue
		var burn_loss: int = mini(enemy.burn, enemy.current_hp)
		enemy.current_hp -= enemy.burn
		emit_signal("enemy_damaged", i, enemy.burn)
		emit_signal("ticked", i, "burn", burn_loss)
		emit_signal("log_line", "Burn: %s takes %d" % [enemy.display_name, enemy.burn])
		if not enemy.is_alive():
			_on_enemy_killed(i)
		await _wait(0.25)
		banner_left -= 0.25
	if banner_left > 0.0:
		await _wait(banner_left)
	
	var bonus := get_enrage_bonus()
	if bonus > 0 and any_enemy_alive():
		emit_signal("enrage_pulse", bonus)
		await _wait(0.3)
	
	var first := true
	for enemy in acting:
		var i := enemies.find(enemy)
		if i < 0 or not enemy.is_alive() or not combat_active:
			continue
		if not first:
			await _wait(0.15)
		first = false
		await _enemy_action(enemy, i)
		if player_hp <= 0 or not any_enemy_alive():
			break
	
	for enemy in acting:
		enemy.turn_count += 1
	
	is_enemy_turn = false
	_phase_log("enemy_phase_end")
	emit_signal("intents_updated")   # next intents appear at the end of the enemy phase
	emit_signal("phase_changed", false)
	
	if _check_combat_end():
		return
	
	_start_player_turn()

## One enemy's action, ~0.6-0.7s (Heavy/Breath/Tidal ~0.9s with the windup).
func _enemy_action(enemy: Enemy, i: int):
	var intent: Dictionary = enemy.get_current_intent()
	emit_signal("actor_started", i, intent)
	_phase_log("enemy_action", {"index": i, "enemy": enemy.display_name, "intent": intent_name(intent)})
	await _wait(0.08)   # intent highlight
	var kind := String(intent.type)
	var attack := kind in ["strike", "heavy", "rend", "tidal", "drain"]
	_attack_heavy = kind in ["heavy", "tidal"]
	if _attack_heavy:
		emit_signal("windup", i)
		await _wait(0.25)
	if attack:
		emit_signal("lunge", i, _attack_heavy)
		await _wait(0.1)   # contact
	_run_intent(enemy, i)
	_attack_heavy = false
	await _wait(0.36 if attack else 0.42)
	emit_signal("actor_ended", i)

func _run_intent(enemy: Enemy, i: int):
	# A dead enemy never acts (QA Stage C: a dead Ghoul still struck).
	if not enemy.is_alive() or not combat_active:
		return
	var intent = enemy.get_current_intent()
	var bonus := get_enrage_bonus()
	var hp_before := player_hp
	var block_before := player_block
	var enemy_hp_before := enemy.current_hp
	_run_intent_effect(enemy, i, intent, bonus)
	RunState.qa_log("ACTION", {"turn": player_turn_number, "enemy": enemy.display_name, "intent": intent_name(intent),
			"kind": intent.type, "value": intent.get("value", 0), "block_before": block_before,
			"hp": [hp_before, player_hp], "enemy_hp_before": enemy_hp_before, "enemy_hp": maxi(0, enemy.current_hp),
			"died": not enemy.is_alive(), "enemies": enemies.size()})

func _run_intent_effect(enemy: Enemy, i: int, intent: Dictionary, bonus: int):
	match intent.type:
		"strike", "heavy":
			var hits := int(intent.get("hits", 1))
			var lost := 0
			var blocked := 0
			for _hit in range(hits):
				if player_hp <= 0 or not enemy.is_alive():
					break
				var r := _deal_damage_to_player(enemy.attack_value(intent) + bonus, enemy)
				lost += r.hp_lost
				blocked += r.blocked
			var verb: String = String(intent.get("label", "Heavy")) if intent.type == "heavy" else "strikes"
			emit_signal("log_line", "%s %s for %d%s" % [enemy.display_name, verb, lost,
					" (%d blocked)" % blocked if blocked > 0 else ""])
		"rend":
			var r := _deal_damage_to_player(enemy.attack_value(intent) + bonus, enemy)
			emit_signal("log_line", "%s rends for %d%s" % [enemy.display_name, r.hp_lost,
					" (%d blocked)" % r.blocked if r.blocked > 0 else ""])
			# If Thorns killed the attacker on this hit, its Rend bleed does not follow.
			if enemy.is_alive():
				player_bleed = int(intent.bleed)
				player_bleed_turns = int(intent.bleed_turns)
				emit_signal("status_popup", -1, "Bleed %d x%d" % [player_bleed, player_bleed_turns], Color("#C8433A"))
		"tidal":
			var r := _deal_damage_to_player(enemy.attack_value(intent) + bonus, enemy, 0.5)
			emit_signal("log_line", "%s Tidal for %d%s" % [enemy.display_name, r.hp_lost,
					" (%d blocked)" % r.blocked if r.blocked > 0 else ""])
		"drain":
			var r := _deal_damage_to_player(enemy.attack_value(intent) + bonus, enemy)
			emit_signal("log_line", "%s drains for %d" % [enemy.display_name, r.hp_lost])
			if enemy.is_alive():
				var before := enemy.current_hp
				enemy.current_hp = mini(enemy.current_hp + int(intent.value), enemy.max_hp)
				emit_signal("enemy_blocked", i, 0)
				if enemy.current_hp > before:
					emit_signal("healed", i, enemy.current_hp - before)
		"guard":
			enemy.block += intent.value
			emit_signal("enemy_blocked", i, intent.value)
			emit_signal("block_gained", i, int(intent.value))
			emit_signal("log_line", "%s Guards: +%d Block" % [enemy.display_name, intent.value])
		"buff":
			enemy.dmg_bonus += int(intent.value)
			emit_signal("enemy_blocked", i, 0)
			emit_signal("status_popup", i, "Power +%d" % int(intent.value), Color("#E3B341"))
			emit_signal("log_line", "%s grows stronger: +%d damage" % [enemy.display_name, intent.value])
		"hex":
			player_hex = int(intent.value)
			emit_signal("enemy_blocked", i, 0)
			emit_signal("status_popup", -1, "Hexed -%d" % player_hex, Color("#9B5DE5"))
			emit_signal("log_line", "%s hexes you: next Strike -%d" % [enemy.display_name, player_hex])
		"regen":
			var before := enemy.current_hp
			enemy.current_hp = mini(enemy.current_hp + int(intent.value), enemy.max_hp)
			emit_signal("enemy_blocked", i, 0)
			emit_signal("healed", i, enemy.current_hp - before)
			emit_signal("log_line", "%s regenerates %d" % [enemy.display_name, enemy.current_hp - before])
		"summon":
			var slot := _summon_drowned()
			enemy.has_summoned = true
			if slot >= 0:
				emit_signal("summoned", slot)
				emit_signal("log_line", "%s summons a Drowned" % enemy.display_name)

func _summon_drowned() -> int:
	var alive_summons := 0
	for e in enemies:
		if e.is_summon and e.is_alive():
			alive_summons += 1
	if alive_summons >= MAX_SUMMONS:
		return -1
	var setup := Encounters.make_enemy(RunState.rng, Encounters.DROWNED_SUMMON)
	var summoned := _make_enemy(setup)
	summoned.is_summon = true
	# Reuse a dead summon's slot so the enemy row does not keep growing.
	for k in range(enemies.size()):
		if enemies[k].is_summon and not enemies[k].is_alive():
			enemies[k] = summoned
			emit_signal("enemies_changed")
			return k
	enemies.append(summoned)
	emit_signal("enemies_changed")
	return enemies.size() - 1

func _start_player_turn():
	var keep_pct := RunState.get_keep_block_pct()
	player_block = floori(player_block * keep_pct / 100.0) if keep_pct > 0 else 0
	player_focus = mini(player_focus + 1, player_focus_max)
	player_turn_number += 1
	emit_signal("focus_changed", player_focus)
	emit_signal("player_blocked", 0)
	
	if player_bleed_turns > 0:
		var bleed_loss: int = mini(player_bleed, maxi(0, player_hp))
		player_hp = maxi(0, player_hp - player_bleed)
		player_bleed_turns -= 1
		RunState.player_hp = player_hp
		emit_signal("player_bled", player_bleed)
		emit_signal("ticked", -1, "bleed", bleed_loss)
		emit_signal("log_line", "Bleed: you take %d" % player_bleed)
		if _check_combat_end():
			return
	
	_player_turn_intro()

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
	# Targeting is input too: ignored outside your turn (v3.8 input lock).
	if not is_player_turn or not combat_active:
		return
	if index >= 0 and index < enemies.size():
		selected_enemy_index = index
