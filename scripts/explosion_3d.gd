@tool
class_name Explosion3D
extends Node3D

## Procedural explosion system. Requires [code]setup()[/code] to be called after being added to scene.
## 
## This object works largely the same way [code]BulletTrail[/code] does. It is first loaded, then
## instanced and added to the scene as a child of the root node, then activated with [code]setup[/code].

@onready var sphere: MeshInstance3D = $Sphere
@onready var sphere_material:StandardMaterial3D = sphere.get_active_material(0)

@export var explosion_expand_speed:float = 0.25  # how fast to traverse the curve (0..1 per second)
var _exploding:bool = false
@export var explosion_scale_curve:Curve
var _scale_float:float = scale.length()
@export var alpha_curve_speed:float = 0.25
@export var alpha_curve:Curve
var knockback_force:float
var damage:float
var screen_shake_duration:float
var screen_shake_strength:float

var _elapsed: float = 0.0  # normalized time along the curve [0..1]
var _alpha_elapsed: float = 0.0
var _can_apply_scale: bool = false
var _player:Player = Helper.getFirstInScene("Player")

@export var camera_shake_distance_factor:float

func _init() -> void:
	_scale_float = 0.00001

func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		# Apply current uniform scale
		scale = Vector3(_scale_float, _scale_float, _scale_float)
	
	if _exploding:
		# Scale over life
		if explosion_scale_curve != null and explosion_scale_curve.get_point_count() > 0:
			_elapsed = clamp(_elapsed + delta * explosion_expand_speed, 0.0, 1.0)
			_scale_float = explosion_scale_curve.sample_baked(_elapsed)
			if _elapsed >= 1.0:
				_exploding = false
		else:
			_scale_float += explosion_expand_speed * delta
		
		# Alpha over life (independent curve)
		if alpha_curve != null and alpha_curve.get_point_count() > 0:
			_alpha_elapsed = clamp(_alpha_elapsed + delta * max(alpha_curve_speed, 0.0001), 0.0, 1.0)
			var a: float = alpha_curve.sample_baked(_alpha_elapsed)
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
func setup(
	spawn_pos:Vector3 = Vector3.ZERO,
	damage:float = 0.0,
	knockback_force:float = 5.0,
	screen_shake_duration:float = 0.66,
	screen_shake_strength:float = 2.0,
	color:Color = Color.GRAY,
	emission_strength:float = 0.0,
	explosion_scale_curve:Curve = self.explosion_scale_curve,
	alpha_curve:Curve = self.alpha_curve) -> void:
		_exploding = true
		_elapsed = 0.0
		_alpha_elapsed = 0.0
		self.knockback_force = knockback_force
		self.damage = damage
		self.screen_shake_duration = screen_shake_duration
		self.screen_shake_strength = screen_shake_strength
		global_position = spawn_pos
		# Enable alpha blending so alpha_curve affects visibility
		sphere_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sphere_material.albedo_color = color
		sphere_material.emission = color
		sphere_material.emission_energy_multiplier = emission_strength
		if explosion_scale_curve != null:
			self.explosion_scale_curve = explosion_scale_curve
		if alpha_curve != null:
			self.alpha_curve = alpha_curve
		# Shake screen by amount based on distance from explosion
		var distance_to_player:float = Vector3(_player.camera_3d.global_position - global_position).length()
		Debug.log("distance to player: " + str(distance_to_player))
		var shake_strength = 1 / distance_to_player * camera_shake_distance_factor
		Debug.log(shake_strength)
		_player.camera_3d.shakeCamera(0.50, shake_strength)

func _on_body_influencer_player_entered(player: Player) -> void:
	var center_point:Vector3 = global_position
	var dir_to_player_head:Vector3 = (player.camera_3d.global_position - center_point).normalized()
	
	player.velocity += dir_to_player_head * knockback_force # apply a force to the player
	player.damagePlayer(damage, "explosion", screen_shake_duration, screen_shake_strength)
