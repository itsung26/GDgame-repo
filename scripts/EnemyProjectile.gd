class_name EnemyProjectile extends RigidBody3D

@export var damage_to_player:float
@export var damage_to_enemies:float
@export var travel_speed:float = 16
@export var parriable:bool = true
@export var can_despawn:bool = true
@export var despawn_time:float = 10.0
@export var has_been_parried:bool = false: set = _set_has_been_parried

## Goes to [code]global_position[/code] at pos, and travels in the direction of dir at travel_speed
func _setup(pos:Vector3, dir:Vector3) -> void:
	if not dir.is_normalized():
		dir = dir.normalized()
	global_position = pos
	# if initial direction is set, go towards that dir, if not, go direction facing
	if dir != Vector3.ZERO:
		linear_velocity = dir.normalized() * travel_speed
	else:
		linear_velocity = -global_transform.basis.z * travel_speed

func _set_has_been_parried(new_has_been_parried:bool):
	has_been_parried = new_has_been_parried

func _destroySelf():
	axis_lock_linear_x = true
	axis_lock_linear_y = true
	axis_lock_linear_z = true
	queue_free()
