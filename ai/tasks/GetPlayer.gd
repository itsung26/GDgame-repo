@tool
extends BTAction

@export var target_var_position:StringName = &"target_var_position"

func _generate_name() -> String:
	return "Store pos: " + LimboUtility.decorate_var(target_var_position)

func _tick(delta: float) -> Status:
	var player:Player = agent.get_tree().get_first_node_in_group("players")
	if player != null:
		blackboard.set_var(target_var_position, player.global_position)
		return SUCCESS
	
	return FAILURE
