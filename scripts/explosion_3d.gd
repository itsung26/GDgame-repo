@icon("res://explosionIcon.png")
class_name Explosion3D
extends Node3D

## Procedural explosion system. Requires [code]setup()[/code] to be called after being added to scene.
## 
## This object works largely the same way [code]BulletTrail[/code] does. It is first loaded, then
## instanced and added to the scene as a child of the root node, then activated with [code]setup[/code].

@onready var sphere: MeshInstance3D = $Sphere
@onready var sphere_material:StandardMaterial3D = sphere.get_active_material(0)
@onready var rocks_1: GPUParticles3D = $Rocks1
@onready var rocks_1_trails: GPUParticles3D = $Rocks1Trails
@onready var collision_shape_3d: CollisionShape3D = $BodyInfluencer/CollisionShape3D
@onready var deletion_timer: Timer = $"deletion timer"

@export var explosion_expand_speed:float = 0.25  # how fast to traverse the curve (0..1 per second)
@export var explosion_initial_radius:float = 1 # The initial radius of the explosion
@export var explosion_final_radius:float = 5 # The final radius of the explosion
var _exploding:bool = false
@export var explosion_scale_curve:Curve = preload("res://curves/explosion curves/scale.tres")
var _scale_float:float = scale.length()
@export var alpha_curve_speed:float = 0.25
@export var alpha_curve:Curve = preload("res://curves/explosion curves/alpha.tres")
var knockback_force:float
var damage:float
var screen_shake_duration:float
var screen_shake_strength:float
var _fading_alpha:bool = false
var _elapsed: float = 0.0  # normalized time along the curve [0..1]
var _alpha_elapsed: float = 0.0
var _can_apply_scale: bool = false
var _player:Player = Helper.getFirstInScene("Player")
@export var despawn_time:float = 7.5

## Camera shake exponential dropoff factor. 0.1 is medium dropoff
@export var cam_shake_exponential_dropoff:float = 0.1

func _init() -> void:
	_scale_float = 0.00001

func _process(delta: float) -> void:
	# queue for deletion if curves have stopped sampling. (corresponds to the explosion having fully ended.)
	if getCurvesStoppedSampling():
		collision_shape_3d.disabled = true
	
	if not Engine.is_editor_hint():
		# Apply current uniform scale
		scale = Vector3(_scale_float, _scale_float, _scale_float)
	
	if _exploding:
		# Scale over life
		if explosion_scale_curve != null and explosion_scale_curve.get_point_count() > 0:
			_elapsed = clamp(_elapsed + delta * explosion_expand_speed, 0.0, explosion_scale_curve.max_domain)
			_scale_float = explosion_scale_curve.sample_baked(_elapsed)
			if _elapsed >= explosion_scale_curve.max_domain:
				_exploding = false

	if _fading_alpha:
		# Alpha over life (independent curve)
		if alpha_curve != null and alpha_curve.get_point_count() > 0:
			_alpha_elapsed = clamp(_alpha_elapsed + delta * max(alpha_curve_speed, 0.0001), 0.0, alpha_curve.max_domain)
			var a: float = alpha_curve.sample_baked(_alpha_elapsed)
			if _alpha_elapsed >= alpha_curve.max_domain:
				_fading_alpha = false
			# Ensure material uses alpha blending
			sphere_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			# Update color alpha (keep current RGB)
			var c: Color = sphere_material.albedo_color
			c.a = a
			sphere_material.albedo_color = c
			# Optionally match emission alpha to albedo
			var e: Color = sphere_material.emission
			e.a = a
			sphere_material.emission = e

## Called after being instanced and added to the scene.
func setup(spawn_pos:Vector3 = Vector3.ZERO, damage:float = 0.0, knockback_force:float = 5.0,
screen_shake_duration:float = 0.66, screen_shake_strength:float = 2.0,
color:Color = Color.GRAY, emission_strength:float = 0.0, unshaded:bool = false) -> void:
		_exploding = true
		_fading_alpha = true
		_elapsed = 0.0
		_alpha_elapsed = 0.0
		self.knockback_force = knockback_force
		self.damage = damage
		self.screen_shake_duration = screen_shake_duration
		self.screen_shake_strength = screen_shake_strength
		global_position = spawn_pos
		# Enable alpha blending so alpha_curve affects visibility
		# set a bunch of material parameters
		sphere_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sphere_material.albedo_color = color
		sphere_material.emission = color
		sphere_material.emission_energy_multiplier = emission_strength
		rocks_1.emitting = true
		if unshaded:
			sphere_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		else:
			sphere_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		if explosion_scale_curve != null:
			self.explosion_scale_curve = explosion_scale_curve
		if alpha_curve != null:
			self.alpha_curve = alpha_curve
		deletion_timer.start(despawn_time)
			
		# Shake screen by amount based on distance from explosion
		# Create an exponential relationship for camera shake dropoff
		var distance_to_player:float = (_player.camera_3d.global_position - global_position).length()
		var strength := screen_shake_strength * exp(-cam_shake_exponential_dropoff * distance_to_player)
		# Optional clamp to avoid ultra-small shakes:
		strength = clamp(strength, 0.0, screen_shake_strength)
		if strength > 0.001:
			_player.camera_3d.shakeCamera(screen_shake_duration, strength)

## Returns false if at least one curve is actively sampling and true if they both are not.
func getCurvesStoppedSampling() -> bool:
	# Scale sampling active?
	var scale_active := false
	if _exploding:
		if explosion_scale_curve != null and explosion_scale_curve.get_point_count() > 0:
			scale_active = _elapsed < explosion_scale_curve.max_domain
		else:
			# No usable curve, treat as not active
			scale_active = false

	# Alpha sampling active?
	var alpha_active := false
	if _fading_alpha:
		if alpha_curve != null and alpha_curve.get_point_count() > 0:
			alpha_active = _alpha_elapsed < alpha_curve.max_domain
		else:
			alpha_active = false

	# Return true only if both are NOT active
	return (not scale_active) and (not alpha_active)
	
## When player hit by explosion
func _on_body_influencer_player_entered(player: Player) -> void:
	var center_point:Vector3 = global_position # get the center of the sphere
	var dir_to_player_head:Vector3 = (player.camera_3d.global_position - center_point).normalized()
	
	# apply a force to the player
	if knockback_force > 0:
		player.velocity = Vector3.ZERO # kill player velocity. (may be removed in the future)
		player.global_position.y += 0.1
		player.velocity += dir_to_player_head * knockback_force # apply a force to the player
		
	player.damagePlayer(damage, "explosion", screen_shake_duration, screen_shake_strength)

## When projectile hit by explosion
func _on_body_influencer_projectile_entered(projectile: EnemyProjectile) -> void:
	var center_point:Vector3 = global_position # get the center of the sphere
	var dir_out:Vector3 = (projectile.global_position - center_point).normalized() # get vector to projectile away from center
	
	# apply a force to the projectile
	if knockback_force > 0:
		projectile.linear_velocity = Vector3.ZERO
		projectile.linear_velocity = dir_out * knockback_force 


func _on_body_influencer_enemy_entered(enemy: Enemy) -> void:
	var center_point:Vector3 = global_position # get the center of the sphere
	var vertical_offset:float = 1.0 # so the force isnt applied to the feet of the enemy
	var dir_to_enemy:Vector3 = ((enemy.global_position + Vector3(0, vertical_offset, 0)) - center_point).normalized()
	
	# apply a force to the enemy
	if knockback_force > 0:
		enemy.velocity = Vector3.ZERO
		enemy.global_position.y += 0.1
		enemy.velocity += dir_to_enemy * knockback_force
		
	enemy.damageEnemy(damage, Enemy.damage_types.EXPLOSIVE)

# Delete after timer runs out.
func _on_deletion_timer_timeout() -> void:
	queue_free()
