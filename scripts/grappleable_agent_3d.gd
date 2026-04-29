@tool
class_name GrappleableAgent3D
extends StaticBody3D
## Object allowing for to/from grapple interactions. Only functions as an initiator for the logic.
## The player's grapple system "detects" this object and intiates a push or pull grapple based on
## it's configuration.

@export var pull_behavior:pull_behaviors = pull_behaviors.PULL_PLAYER

## The "owner" of this grappleable box.
var agent:Node3D

enum pull_behaviors {PULL_AGENT, PULL_PLAYER}


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_READY:
			if not _parent_is_level():
				agent = get_parent()
		NOTIFICATION_PROCESS:
			if Engine.is_editor_hint():
				update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	var ret:PackedStringArray
	if _has_more_than_one_shape_child():
		ret.append("Can only have one child CollisionShape3D.")
	if _parent_is_level():
		ret.append("Parent cannot be the level itself.")
	return ret


## Returns true if this node has at least 1 collisionshape3d child.
func _has_collision_shape_child() -> bool:
	var children:Array[Node] = get_children()
	for child:Node in children:
		if child is CollisionShape3D:
			return true
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


## Returns true if the parent node is the root node.
func _parent_is_level() -> bool:
	var parent:Node = get_parent()
	if get_tree().current_scene == parent:
		return true
	else:
		return false
