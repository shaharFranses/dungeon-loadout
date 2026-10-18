extends Resource
class_name EnemyData

@export var enemy_id: String = ""
@export var display_name: String = ""
@export var max_hp: int = 10
@export var intent_pattern: Array[Dictionary] = []

func get_intent_at_turn(turn: int) -> Dictionary:
	if intent_pattern.is_empty():
		return {"type": "strike", "value": 5}
	var index = turn % intent_pattern.size()
	return intent_pattern[index]
