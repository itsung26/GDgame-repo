extends BTAction

@export var nav_agent:NodePath
var has_reached_player:bool = false

func _tick(delta: float) -> Status:
	if has_reached_player:
		status = BT.SUCCESS
	else:
		status = BT.FAILURE
	return status
