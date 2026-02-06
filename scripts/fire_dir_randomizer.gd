@tool
extends Node

@export var random_rot_min_x: float = -360 # degrees
@export var random_rot_max_x: float = 360 # degrees
@export var random_rot_min_z: float = -360 # degrees
@export var random_rot_max_z: float = 360 # degrees
@export var delay:float = 0.1 # seconds
@export var shuffling:bool = false
@export_tool_button("Reset rotations (Editor)") var a = euggggh

@onready var fire_dir_l: RayCast3D = $"../bullet turret/Armature/Skeleton3D/GunLAttatchment/FireDirL"
@onready var fire_dir_r: RayCast3D = $"../bullet turret/Armature/Skeleton3D/GunRAttatchment/FireDirR"

var _elapsed_time: float = 0.0

func _ready() -> void:
	if shuffling:
		set_process(true)

func _process(delta: float) -> void:
	if shuffling:
		_elapsed_time += delta
		if _elapsed_time >= delay:
			_elapsed_time = 0.0
			# Shuffle the fire direction(s) after the delay
			fire_dir_l.rotation.x = randf_range(deg_to_rad(random_rot_min_x), deg_to_rad(random_rot_max_x))
			fire_dir_l.rotation.z = randf_range(deg_to_rad(random_rot_min_z), deg_to_rad(random_rot_max_z))
			fire_dir_r.rotation.x = randf_range(deg_to_rad(random_rot_min_x), deg_to_rad(random_rot_max_x))
			fire_dir_r.rotation.z = randf_range(deg_to_rad(random_rot_min_z), deg_to_rad(random_rot_max_z))

## Don't use this.
func euggggh():
	fire_dir_l.rotation = Vector3.ZERO
	fire_dir_r.rotation = Vector3.ZERO

func getDirectionLeftGun() -> Vector3:
	return Vector3.ZERO
	
func getDirectionRightGun() -> Vector3:
	return Vector3.ZERO
