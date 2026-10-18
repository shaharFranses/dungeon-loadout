extends Control

@onready var hp_label = $VBox/Header/Stats/HPLabel
@onready var gold_label = $VBox/Header/Stats/GoldLabel
@onready var node_battle = $VBox/Layer1/NodeBattle
@onready var node_shop_smith = $VBox/Layer2/HBox/NodeShopSmith
@onready var node_skill = $VBox/Layer2/HBox/NodeSkill
@onready var node_boss = $VBox/Layer3/NodeBoss

func _ready():
	DisplayServer.window_set_title("dungeon_loadout")
	_update_ui()

func _update_ui():
	hp_label.text = "HP: %d/%d" % [RunState.player_hp, RunState.player_max_hp]
	gold_label.text = "Gold: %d" % RunState.gold
	
	match RunState.map_progress:
		0:
			node_battle.disabled = false
			node_battle.text = "Crypt Rats"
			node_shop_smith.disabled = true
			node_shop_smith.text = "Blacksmith + Shop"
			node_shop_smith.modulate = Color(1, 1, 1)
			node_skill.disabled = true
			node_skill.text = "Skill Point"
			node_skill.modulate = Color(1, 1, 1)
			node_boss.disabled = true
			node_boss.text = "Bone Warden"
		1:
			node_battle.disabled = true
			node_battle.text = "Crypt Rats (done)"
			node_shop_smith.disabled = false
			node_shop_smith.text = "Blacksmith + Shop"
			node_skill.disabled = false
			node_skill.text = "Skill Point"
			node_boss.disabled = true
			node_boss.text = "Bone Warden"
		2:
			node_battle.disabled = true
			node_battle.text = "Crypt Rats (done)"
			
			if RunState.middle_node_choice == "node_shop_smith":
				node_shop_smith.disabled = true
				node_shop_smith.text = "Blacksmith + Shop (done)"
				node_skill.disabled = true
				node_skill.text = "Skill Point"
				node_skill.modulate = Color(0.5, 0.5, 0.5)
			elif RunState.middle_node_choice == "node_skill":
				node_skill.disabled = true
				node_skill.text = "Skill Point (done)"
				node_shop_smith.disabled = true
				node_shop_smith.text = "Blacksmith + Shop"
				node_shop_smith.modulate = Color(0.5, 0.5, 0.5)
			
			node_boss.disabled = false
			node_boss.text = "Bone Warden"
		_:
			pass

func _on_node_battle_pressed():
	get_tree().change_scene_to_file("res://scenes/combat.tscn")

func _on_node_shop_smith_pressed():
	RunState.choose_middle_node("node_shop_smith")
	get_tree().change_scene_to_file("res://scenes/shop_smith.tscn")

func _on_node_skill_pressed():
	RunState.choose_middle_node("node_skill")
	get_tree().change_scene_to_file("res://scenes/skill_pick.tscn")

func _on_node_boss_pressed():
	get_tree().change_scene_to_file("res://scenes/combat.tscn")
