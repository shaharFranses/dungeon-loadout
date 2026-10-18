extends Control

@onready var gold_label = $VBox/Header/GoldLabel
@onready var buy_button = $VBox/Panels/ShopPanel/VBox/BuyButton
@onready var item_name = $VBox/Panels/ShopPanel/VBox/ItemName
@onready var item_effect = $VBox/Panels/ShopPanel/VBox/ItemEffect
@onready var item_price = $VBox/Panels/ShopPanel/VBox/ItemPrice
@onready var hone_button = $VBox/Panels/SmithPanel/VBox/HoneButton
@onready var service_effect = $VBox/Panels/SmithPanel/VBox/ServiceEffect

func _ready():
	DisplayServer.window_set_title("dungeon_loadout")
	_update_ui()

func _update_ui():
	gold_label.text = "Gold: %d" % RunState.gold
	
	if RunState.equipped_gear == "gear_iron_longsword":
		buy_button.disabled = true
		buy_button.text = "Sold Out"
		item_name.text = "Iron Longsword (owned)"
	else:
		if RunState.gold >= 35:
			buy_button.disabled = false
			buy_button.text = "Buy (35g)"
		else:
			buy_button.disabled = true
			buy_button.text = "Need more gold"
	
	var has_weapon = RunState.equipped_gear != ""
	var can_afford_hone = RunState.gold >= 20
	var already_honed = RunState.hone_edge_used
	
	if already_honed:
		hone_button.disabled = true
		hone_button.text = "Already Used"
	elif not has_weapon:
		hone_button.disabled = true
		hone_button.text = "Need weapon"
	elif not can_afford_hone:
		hone_button.disabled = true
		hone_button.text = "Need more gold"
	else:
		hone_button.disabled = false
		hone_button.text = "Hone Edge (20g)"
	
	if RunState.equipped_gear == "gear_iron_longsword":
		if RunState.hone_edge_used:
			service_effect.text = "Strike: 11 (9+2)"
		else:
			service_effect.text = "Strike: 9 to 11"
	else:
		service_effect.text = "Strike: +2 damage"

func _on_buy_pressed():
	if RunState.spend_gold(35):
		RunState.equip_gear_iron_longsword()
		_update_ui()

func _on_hone_pressed():
	if RunState.spend_gold(20):
		RunState.hone_edge()
		_update_ui()

func _on_continue_pressed():
	RunState.advance_map()
	get_tree().change_scene_to_file("res://scenes/map.tscn")
