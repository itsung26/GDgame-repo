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

@export var explosion_expand_speed:float = 1  # how fast to traverse the curve (0..1 per second)
var exploding:bool = false
@export var explosion_scale_curve:Curve
var scale_float:float = scale.length()
@export var alpha_curve_speed:float
@export var alpha_curve:Curve

var _elapsed: float = 0.0  # normalized time along the curve [0..1]

func _process(delta: float) -> void:
	scale = Vector3(scale_float, scale_float, scale_float)
	
	if exploding:
		# Advance normalized time along the curve
		if explosion_scale_curve != null and explosion_scale_curve.get_point_count() > 0:
			_elapsed = clamp(_elapsed + delta * explosion_expand_speed, 0.0, 1.0)
			# Sample the curve (0..1) to drive the visual/collider scale
			scale_float = explosion_scale_curve.sample_baked(_elapsed)
			# Stop when finished
			if _elapsed >= 1.0:
				exploding = false
		else:
			# Fallback: linear growth if no curve assigned
			scale_float += explosion_expand_speed * delta

## Called after being instanced and added to the scene.
func setup(spawn_pos:Vector3 = Vector3.ZERO, damage:float = 0.0, knockback_force:float = 5.0, color:Color = Color.GRAY, explosion_scale_curve:Curve = self.explosion_scale_curve) -> void:
	exploding = true
	_elapsed = 0.0
	global_position = spawn_pos
	sphere_material.albedo_color = color
	sphere_material.emission = color
	if explosion_scale_curve != null:
		self.explosion_scale_curve = explosion_scale_curve
