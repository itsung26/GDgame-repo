class_name EnemyProjectile extends RigidBody3D

@export var damage_to_player:float
@export var damage_to_enemies:float
@export var travel_speed:float = 16
@export var parriable:bool = true
@export var can_despawn:bool = true
@export var despawn_time:float = 10.0
@export var has_been_parried:bool = false: set = _set_has_been_parried

## Goes to [code]global_position[/code] at pos, and travels in the direction of dir at travel_speed
func _setup(_pos:Vector3, _dir:Vector3) -> void:
	if not _dir.is_normalized():
		_dir = _dir.normalized()
	global_position = _pos
	# if initial direction is set, go towards that dir, if not, go direction facing
	if _dir != Vector3.ZERO:
		linear_velocity = _dir * travel_speed
	else:
		linear_velocity = -global_transform.basis.z * travel_speed

func _set_has_been_parried(new_has_been_parried:bool):
	has_been_parried = new_has_been_parried
	
	parriable = false

func _destroySelf():
	queue_free()

# continually look in the direction of linear velocity travel
func _process(delta: float) -> void:
	if linear_velocity.length() > 0.01:
		var dir := linear_velocity.normalized()
		var up := Vector3.UP
		if abs(dir.dot(up)) > 0.98:
			up = Vector3.FORWARD
		look_at(global_position + dir, up)
