@tool
class_name Explosion3D
extends Node3D

## Procedural explosion system. Requires [code]setup()[/code] to be called after being added to scene.
## 
## This object works largely the same way [code]BulletTrail[/code] does. It is first loaded, then
## instanced and added to the scene as a child of the root node, then activated with [code]setup[/code].

@onready var collision_shape_3d: CollisionShape3D = $Area3D/CollisionShape3D
@onready var sphere: MeshInstance3D = $Sphere
@onready var sphere_material:StandardMaterial3D = sphere.get_active_material(0)

@export var explosion_expand_speed:float = 0.25  # how fast to traverse the curve (0..1 per second)
var exploding:bool = false
@export var explosion_scale_curve:Curve
var scale_float:float = scale.length()
@export var alpha_curve_speed:float = 0.25
@export var alpha_curve:Curve

var _elapsed: float = 0.0  # normalized time along the curve [0..1]
var _alpha_elapsed: float = 0.0
var _can_apply_scale: bool = false

# Neccessary to prevent editor error spamming
func _init() -> void:
	_can_apply_scale = true
	scale_float = 0.00001

func _process(delta: float) -> void:
	Debug.log(exploding)
	if _can_apply_scale:
		# Apply current uniform scale
		scale = Vector3(scale_float, scale_float, scale_float)
	
	if exploding:
		# Scale over life
		if explosion_scale_curve != null and explosion_scale_curve.get_point_count() > 0:
			_elapsed = clamp(_elapsed + delta * explosion_expand_speed, 0.0, 1.0)
			scale_float = explosion_scale_curve.sample_baked(_elapsed)
			if _elapsed >= 1.0:
				exploding = false
		else:
			scale_float += explosion_expand_speed * delta
		
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
func setup(spawn_pos:Vector3 = Vector3.ZERO, damage:float = 0.0, knockback_force:float = 5.0, color:Color = Color.GRAY, explosion_scale_curve:Curve = self.explosion_scale_curve, alpha_curve:Curve = self.alpha_curve) -> void:
	exploding = true
	_elapsed = 0.0
	_alpha_elapsed = 0.0
	global_position = spawn_pos
	# Enable alpha blending so alpha_curve affects visibility
	sphere_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sphere_material.albedo_color = color
	sphere_material.emission = color
	if explosion_scale_curve != null:
		self.explosion_scale_curve = explosion_scale_curve
	if alpha_curve != null:
		self.alpha_curve = alpha_curve
