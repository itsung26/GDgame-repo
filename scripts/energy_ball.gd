class_name EnergyBall extends EnemyProjectile
@onready var deletion_animator: AnimationPlayer = $deletionAnimator
@export var despawn_timer:Timer
@onready var rigidbody_collider: CollisionShape3D = $rigidbody_collider

@export_group("Explosion Shockwave Settings")
@export var explosion_shockwave_curve:Curve
@export var explosion_shockwave_alpha_curve:Curve
@export var explosion_shockwave_color:Color
@export var explosion_shockwave_knockback:float = 16.0

@export_group("Explosion Damaging Settings")
@export var explosion_damaging_curve:Curve
@export var explosion_damaging_alpha_curve:Curve
@export var explosion_damaging_damage:float = 20.0
@export var explosion_damaging_color:Color

const explosion_3d_SCENE:PackedScene = preload("res://scenes/explosion_3d.tscn")

func _setup(pos:Vector3, dir:Vector3) -> void:
	super._setup(pos, dir)

func _ready() -> void:
	# start the clock for bullet despawn
	if can_despawn: # begin the countdown on load to despawning
		despawn_timer.start(despawn_time)
	else: # otherwise, timer is not needed
		despawn_timer.queue_free()

## Dismantles the projectile, freeing it when done.
func _destroySelf():
	linear_velocity = Vector3.ZERO
	axis_lock_linear_x = true
	axis_lock_linear_y = true
	axis_lock_linear_z = true
	deletion_animator.play("deletion")

func deleteBodyCollider() -> void:
	rigidbody_collider.queue_free()

func spawnExplosions() -> void:
	# instance the first part of the explosion (shockwave)
	var explosion_3d:Explosion3D = explosion_3d_SCENE.instantiate()
	get_tree().current_scene.add_child(explosion_3d)
	explosion_3d.setup(global_position, 0.0, explosion_shockwave_knockback, 0.66, 2.0,
	explosion_shockwave_color, 0.0, explosion_shockwave_curve, explosion_shockwave_alpha_curve, true)
	
	# instance the second part of the explosion (damage)
	explosion_3d = explosion_3d_SCENE.instantiate()
	get_tree().current_scene.add_child(explosion_3d)
	explosion_3d.setup(global_position, explosion_damaging_damage, 0.0,
	0.0, 0.0, explosion_damaging_color, 1.0, explosion_damaging_curve, explosion_damaging_alpha_curve,
	false)

func _on_hit_player(player: Player) -> void:
		player.damagePlayer(damage_to_player, "Melted by energy projectile")
		player.camera_3d.shakeCamera(cam_shake_duration, cam_shake_strength)
		if has_been_parried:
			spawnExplosions()
		_destroySelf()

func _on_hit_enemy(enemy: Enemy) -> void:
		enemy.damageEnemy(damage_to_enemies, enemy.damage_types.NORMAL)
		if has_been_parried:
			spawnExplosions()
		_destroySelf()
		
func _on_hit_other(body: Node3D) -> void:
	if has_been_parried:
		spawnExplosions()
	_destroySelf()

func _on_despawn_timer_timeout() -> void:
	_destroySelf()
