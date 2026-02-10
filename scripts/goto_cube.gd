class_name GotoCube
extends Node3D

## The node that the vector3 variable will be searched for in.
@export var owner_node3d:Node3D
## This debug object will continuously go to [code]position_variable[/code].
@export var position_variable:StringName

func _process(delta: float) -> void:
	var x = owner_node3d.get(position_variable)
	if x is Vector3:
		global_position = x
