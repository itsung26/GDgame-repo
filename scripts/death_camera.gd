class_name DeathCamera
extends Node3D
## A scene that is instanced upon the player death. Serves as a kind of "outro cinematic"
## should the death of the player occur.

@onready var rigid_body_3d: RigidBody3D = $RigidBody3D
@onready var camera_3d: Camera3D = $RigidBody3D/Camera3D


func setup(torque_applied:float = 10.0, velocity_applied:float = 10.0) -> void:
	name = "DeathCamera"
	var angular_vector:Vector3
	var fling_dir:Vector3
	
	fling_dir = getRandomVector(-1.0, 1.0).normalized()
	angular_vector = getRandomVector(-1.0, 1.0).normalized()
	angular_vector = angular_vector * torque_applied
	
	rigid_body_3d.linear_velocity = fling_dir * velocity_applied
	rigid_body_3d.angular_velocity = angular_vector
	
	camera_3d.make_current()


## Returns a random vector with each component independently in [range_min, range_max].
func getRandomVector(range_min: float, range_max: float) -> Vector3:
	return Vector3(
		randf_range(range_min, range_max),
		randf_range(range_min, range_max),
		randf_range(range_min, range_max),
	)
