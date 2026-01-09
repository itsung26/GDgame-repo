@tool
extends BTAction

@export var target_position_var := &"target_pos"

func _generate_name() -> String:
	return "Arrive pos: %s" % LimboUtility.decorate_var(target_position_var)

func _tick(delta: float) -> Status:
	var target_pos: Vector3 = blackboard.get_var(target_position_var, Vector3.ZERO)
	if target_pos - agent.global_position == Vector3.ZERO:
		return SUCCESS
	
	
	return RUNNING
