@tool
class_name GrappleableAgent3D
extends StaticBody3D

@export var pull_behavior:pull_behaviors = pull_behaviors.PULL_PLAYER

#var agent:CharacterBody3D

enum pull_behaviors {PULL_AGENT, PULL_PLAYER}


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY:
			#set_collision_layer_value(1, false)
			#set_collision_layer_value(10, true)
			#set_collision_mask_value(1, false)
			pass
		NOTIFICATION_PROCESS:
			if Engine.is_editor_hint():
				update_configuration_warnings()
		NOTIFICATION_PHYSICS_PROCESS:
			pass


func _get_configuration_warnings() -> PackedStringArray:
	var ret:PackedStringArray
	#if !_has_collision_shape_child():
		#ret.append("Needs at least 1 child collision shape.")
	if !_has_characterbody_parent():
		if pull_behavior == pull_behaviors.PULL_AGENT:
			ret.append("A CharacterBody3D parent is required in PULL_AGENT mode.")
	if _has_more_than_one_shape_child():
		ret.append("Can only have one child CollisionShape3D.")
	return ret


## Returns true if this node has at least 1 collisionshape3d child.
func _has_collision_shape_child() -> bool:
	var children:Array[Node] = get_children()
	for child:Node in children:
		if child is CollisionShape3D:
			return true
	
	return false


## Returns true if this node's parent is is a characterbody3D.
func _has_characterbody_parent() -> bool:
	var current_parent:Node = get_parent()
	while current_parent != null:
		if current_parent is CharacterBody3D:
			return true
		current_parent = current_parent.get_parent()
	
	return false


## Returns true if this node has more than 1 collisionShape3D child.
func _has_more_than_one_shape_child() -> bool:
	var shape_child_count:int = 0
	for child:Node in get_children():
		if child is CollisionShape3D:
			shape_child_count += 1
			if shape_child_count > 1:
				return true
	
	return false
