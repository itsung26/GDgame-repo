class_name DeathCamera
extends Node3D
## A scene that is instanced upon the player death. Serves as a kind of "outro cinematic"
## should the death of the player occur.

@onready var rigid_body_3d: RigidBody3D = $RigidBody3D
@onready var camera_3d: Camera3D = $RigidBody3D/Camera3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func setup(
torque_applied:float = 10.0,
velocity_applied:float = 10.0,
initial_rotation:Vector3 = Vector3.ZERO,
initial_position:Vector3 = Vector3.ZERO,
initial_velocity:Vector3 = Vector3.ZERO
) -> void:
	name = "DeathCamera"
	var angular_vector:Vector3
	var fling_dir:Vector3
	
	global_position = initial_position
	global_rotation = initial_rotation
	
	fling_dir = getRandomVector(-1.0, 1.0).normalized()
	angular_vector = getRandomVector(-1.0, 1.0).normalized()
	angular_vector = angular_vector * torque_applied
	
	rigid_body_3d.linear_velocity = initial_velocity + (fling_dir * velocity_applied)
	rigid_body_3d.angular_velocity = angular_vector
	
	camera_3d.make_current()
	animation_player.play("fade_to_death")


## Returns a random vector with each component independently in [range_min, range_max].
func getRandomVector(range_min: float, range_max: float) -> Vector3:
	return Vector3(
		randf_range(range_min, range_max),
		randf_range(range_min, range_max),
		randf_range(range_min, range_max),
	)
