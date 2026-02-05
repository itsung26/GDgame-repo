class_name EnergyBall extends EnemyProjectile

@onready var deletion_animator: AnimationPlayer = $deletionAnimator
@onready var despawn_timer: Timer = $DespawnTimer
@onready var rigidbody_collider: CollisionShape3D = $rigidbody_collider
@onready var damage_collider: Area3D = $DamageCollider
@onready var owner_collision_timer: Timer = $OwnerCollisionTimer
@onready var ball_outline: MeshInstance3D = $ball_outline

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

## Wether collision with the owner enemy is enabled.
var collision_with_owner_enabled:bool = false
## The enemy that fired this bullet.
var owner_enemy:Enemy = null

const explosion_3d_SCENE:PackedScene = preload("res://scenes/explosion_3d.tscn")

func _setup(pos:Vector3, dir:Vector3, owner:Enemy, time_before_owner_collide_re_enabled:float = 0.25) -> void:
	super._setup(pos, dir, owner)
	# Set the owner enemy and temporarily disable collision with them.
	owner_enemy = owner
	add_collision_exception_with(owner)
	collision_with_owner_enabled = false
	owner_collision_timer.start(time_before_owner_collide_re_enabled)

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
	ball_outline.queue_free()
	deletion_animator.play("deletion")

func deleteBodyCollider() -> void:
	rigidbody_collider.queue_free()

func spawnExplosions() -> void:
	# instance the first part of the explosion (shockwave)
	var shockwave_explosion:Explosion3D = explosion_3d_SCENE.instantiate()
	get_tree().current_scene.add_child(shockwave_explosion)
	shockwave_explosion.setup_preset(global_position, shockwave_explosion.explosion_presets.SHOCKWAVE_SMALL)
	
	# instance the second part of the explosion (damage)
	var explosion_yellow:Explosion3D = explosion_3d_SCENE.instantiate()
	get_tree().current_scene.add_child(explosion_yellow)
	explosion_yellow.setup_preset(global_position, explosion_yellow.explosion_presets.YELLOW_SMALL)

func _on_hit_player(player: Player) -> void:
		player.damagePlayer(damage_to_player, "Melted by energy projectile")
		player.camera_3d.shakeCamera(cam_shake_duration, cam_shake_strength)
		if has_been_parried:
			spawnExplosions()
		_destroySelf()

func _on_hit_enemy(enemy: Enemy) -> void:
	#Debug.log(owner_enemy)
	#Debug.log(enemy)
	#Debug.log(collision_with_owner_enabled)
	if enemy == owner_enemy:
		if collision_with_owner_enabled:
			enemy.damageEnemy(damage_to_enemies, enemy.damage_types.NORMAL)
			if has_been_parried:
				spawnExplosions()
			_destroySelf()
	else:
		enemy.damageEnemy(damage_to_enemies, enemy.damage_types.NORMAL)
		if has_been_parried:
			spawnExplosions()
		_destroySelf()

## When a world wall is hit. (Not an enemy)
func _on_hit_other(body: Node3D) -> void:
	if not body is Enemy:
		if has_been_parried:
			spawnExplosions()
		_destroySelf()

func _on_despawn_timer_timeout() -> void:
	_destroySelf()

## When this timer runs out, collision will be re-enabled with the enemy that shot
## the bullet.
func _on_owner_collision_timer_timeout() -> void:
	collision_with_owner_enabled = true
	remove_collision_exception_with(owner_enemy)
