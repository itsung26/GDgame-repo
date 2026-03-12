class_name PlayerFloorCast
extends RayCast3D


func getBodyBelow() -> Node:
	return get_collider()


## Returns the player's displacement from the world or body below them.
func getPlayerDisplacement() -> float:
	if getBodyBelow() != null:
		var collision_point:Vector3 = get_collision_point()
		var ret:float = global_position.y - collision_point.y
		return ret
	return -1
