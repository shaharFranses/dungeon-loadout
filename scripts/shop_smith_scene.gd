extends Control
## Shop + Smith: one item per gear slot (rarity 50/35/15), heal 10 HP for 20g (max 2 per
## visit, shows the real amount, disabled at full HP), Hone +2 (once per weapon) 20g,
## Reinforce armor +2 Block (once per armor) 25g.

const GearData = preload("res://scripts/gear_data.gd")
const UiUtil = preload("res://scripts/ui_util.gd")

var stock: Array = []
var sold: Array = []
var heals_bought: int = 0
var status_label: Label
var gear_label: Label
var stock_buttons: Array = []
var heal_button: Button
var hone_button: Button
var reinforce_button: Button


func _ready():
	DisplayServer.window_set_title("dungeon_loadout")
	for slot in GearData.SLOTS:
		var rarity := GearData.roll_rarity(RunState.rng, GearData.SHOP_RARITY)
		var owned: Dictionary = RunState.gear[slot]
		var item := GearData.pick_item(RunState.rng, slot, rarity, [] if owned.is_empty() else [owned.id])
		stock.append(item)
		sold.append(false)
	RunState.qa_log("SHOP", {"stock": stock})

	var box := UiUtil.make_screen(self, "Blacksmith + Shop")
	box.add_theme_constant_override("separation", 8)
	status_label = UiUtil.make_label("", 18, UiUtil.GOLD)
	box.add_child(status_label)
	gear_label = UiUtil.make_label("", 15, UiUtil.DIM)
	box.add_child(gear_label)
	for i in range(stock.size()):
		var item: Dictionary = stock[i]
		box.add_child(UiUtil.make_label(GearData.describe(item), 16, GearData.RARITY_COLORS[item.rarity]))
		var button := UiUtil.make_button("", _on_buy_pressed.bind(i), 420.0)
		box.add_child(button)
		stock_buttons.append(button)
	heal_button = UiUtil.make_button("", _on_heal_pressed, 420.0)
	box.add_child(heal_button)
	hone_button = UiUtil.make_button("", _on_hone_pressed, 420.0)
	box.add_child(hone_button)
	reinforce_button = UiUtil.make_button("", _on_reinforce_pressed, 420.0)
	box.add_child(reinforce_button)
	box.add_child(UiUtil.make_button("Continue", _on_continue_pressed, 420.0))
	_update_ui()


func _price(item: Dictionary) -> int:
	return int(GearData.SHOP_PRICES[item.rarity])


func heal_amount() -> int:
	return mini(RunState.SHOP_HEAL_AMOUNT, RunState.player_max_hp - RunState.player_hp)


func _update_ui():
	status_label.text = UiUtil.status_line()
	gear_label.text = UiUtil.gear_line()
	for i in range(stock.size()):
		var button: Button = stock_buttons[i]
		var price := _price(stock[i])
		if sold[i]:
			button.text = "Sold"
			button.disabled = true
		else:
			button.text = "Buy %s (%dg)" % [stock[i].name, price]
			button.disabled = RunState.gold < price

	var heals_left: int = RunState.SHOP_HEAL_MAX_BUYS - heals_bought
	if heals_left <= 0:
		heal_button.text = "Heal: sold out this visit"
		heal_button.disabled = true
	elif heal_amount() <= 0:
		heal_button.text = "Heal: HP is full"
		heal_button.disabled = true
	else:
		heal_button.text = "Heal +%d (%dg, %d left)" % [heal_amount(), RunState.SHOP_HEAL_PRICE, heals_left]
		heal_button.disabled = RunState.gold < RunState.SHOP_HEAL_PRICE

	if RunState.gear.weapon.is_empty():
		hone_button.text = "Hone Edge: need a weapon"
		hone_button.disabled = true
	elif RunState.weapon_honed:
		hone_button.text = "Hone Edge: already honed"
		hone_button.disabled = true
	else:
		hone_button.text = "Hone Edge +2 (%dg)" % RunState.HONE_PRICE
		hone_button.disabled = RunState.gold < RunState.HONE_PRICE

	if RunState.gear.armor.is_empty():
		reinforce_button.text = "Reinforce Armor: need armor"
		reinforce_button.disabled = true
	elif RunState.armor_reinforced:
		reinforce_button.text = "Reinforce Armor: already done"
		reinforce_button.disabled = true
	else:
		reinforce_button.text = "Reinforce Armor +2 Block (%dg)" % RunState.REINFORCE_PRICE
		reinforce_button.disabled = RunState.gold < RunState.REINFORCE_PRICE
	RunState.qa_dump_ui(self, "shop", {"stock": stock, "sold": sold, "heals_bought": heals_bought})


func _on_buy_pressed(index: int):
	if sold[index] or not RunState.spend_gold(_price(stock[index])):
		return
	sold[index] = true
	RunState.equip(stock[index])
	_update_ui()


func _on_heal_pressed():
	if heals_bought >= RunState.SHOP_HEAL_MAX_BUYS or heal_amount() <= 0:
		return
	if RunState.spend_gold(RunState.SHOP_HEAL_PRICE):
		heals_bought += 1
		RunState.heal(RunState.SHOP_HEAL_AMOUNT)
		_update_ui()


func _on_hone_pressed():
	if RunState.can_hone() and RunState.spend_gold(RunState.HONE_PRICE):
		RunState.hone_edge()
		_update_ui()


func _on_reinforce_pressed():
	if RunState.can_reinforce() and RunState.spend_gold(RunState.REINFORCE_PRICE):
		RunState.reinforce_armor()
		_update_ui()


func _on_continue_pressed():
	get_tree().change_scene_to_file("res://scenes/map.tscn")
