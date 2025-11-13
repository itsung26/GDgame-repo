class_name EnergyBall extends EnemyProjectile
@onready var deletion_animator: AnimationPlayer = $deletionAnimator
@onready var despawn_timer: Timer = $DespawnTimer
@onready var rigidbody_collider: CollisionShape3D = $rigidbody_collider


func _ready() -> void:
	# go to set position
	global_position = initial_spawn_position
	# if initial direction is set, go towards that dir, if not, go direction facing
	if initial_direction != Vector3.ZERO:
		linear_velocity = initial_direction.normalized() * travel_speed
	else:
		linear_velocity = -global_transform.basis.z * travel_speed
	# start the clock for bullet despawn
	if can_despawn: # begin the countdown on load to despawning
		despawn_timer.start(despawn_time)
	else: # otherwise, timer is not needed
		despawn_timer.queue_free()

## Dismantles the projectile, freeing it when done.
func destroySelf():
	linear_velocity = Vector3.ZERO
	axis_lock_linear_x = true
	axis_lock_linear_y = true
	axis_lock_linear_z = true
	deletion_animator.play("deletion")

func deleteBodyCollider():
	rigidbody_collider.queue_free()

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


func _on_despawn_timer_timeout() -> void:
	destroySelf()
