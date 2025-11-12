class_name EnergyBall extends RigidBody3D

@export var damage_to_player:float
@export var damage_to_enemies:float
@export var travel_speed:float = 16
@export var initial_direction:Vector3
@export var initial_spawn_position:Vector3

func _ready() -> void:
	global_position = initial_spawn_position
	if initial_direction != Vector3.ZERO:
		linear_velocity = initial_direction.normalized() * travel_speed
	else:
		linear_velocity = -global_transform.basis.z * travel_speed

## Dismantles the projectile, freeing it when done.
# WIP: replace with particle destruction effect
func destroySelf():
	queue_free()

# continually look in the direction of linear velocity travel
func _process(delta: float) -> void:
	if linear_velocity.length() > 0.01:
		var dir := linear_velocity.normalized()
		var up := Vector3.UP
		if abs(dir.dot(up)) > 0.98:
			up = Vector3.FORWARD
		look_at(global_position + dir, up)

func _on_body_entered(body: Node) -> void:
	
	if body is Player:
		#print("enemy projectile collided with player")
		var player:Player = body
		player.damagePlayer(damage_to_player, "Melted by energy projectile")
		destroySelf()
	
	elif body is Enemy:
		#print("enemy projectile collided with enemy")
		var enemy:Enemy = body
		enemy.damageEnemy(damage_to_enemies, enemy.damage_types.NORMAL)
		destroySelf()
	
	else:
		#print("enemy projectile collided with world")
		destroySelf()
