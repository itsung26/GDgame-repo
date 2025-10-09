@tool
extends Node3D
@onready var cube_head: MeshInstance3D = $Cube_head
@onready var target: Marker3D = $Screen/target
@onready var cube_head_ears: MeshInstance3D = $Cube_head/Cube_head_ears
@onready var screen: MeshInstance3D = $Screen

@export var look_at_target:Vector3 = Vector3.ZERO
@export var player_in_collider:bool = false
var cube_ears_inactive_rotation = Vector3.ZERO
var cube_ears_active_rotation = Vector3(0.0,0.0,60.0)

func _process(delta: float) -> void:
	# if in editor, set the look target to the target node's position
	if Engine.is_editor_hint():
		look_at_target = target.global_position
	
	# cube head to look at target pos
	cube_head.look_at(look_at_target, Vector3.UP)
	cube_head.rotation.z = 0
	cube_head.rotation.x = 0
	cube_head.rotation.y = cube_head.rotation.y + deg_to_rad(90)
	

	
