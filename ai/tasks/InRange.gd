@tool
extends BTCondition

@export var target_var:StringName
@export var distance:float = 0.0

# Display a customized name (requires @tool).
func _generate_name() -> String:
	return "InRange of: " + LimboUtility.decorate_var(target_var) + " by distance: " + str(distance)


# Called once during initialization.
func _setup() -> void:
	pass


# Called each time this task is entered.
func _enter() -> void:
	pass


# Called each time this task is exited.
func _exit() -> void:
	pass


# Called each time this task is ticked (aka executed).
func _tick(delta: float) -> Status:
	var target_var_vector3:Vector3 = blackboard.get_var(target_var)
	var distance_from:float = (target_var_vector3 - agent.global_position).length()
	if distance_from <= distance:
		return SUCCESS
	
	return FAILURE


# Strings returned from this method are displayed as warnings in the behavior tree editor (requires @tool).
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	return warnings
