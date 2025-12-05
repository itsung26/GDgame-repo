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

@export var explosion_scale:float = 1.0
@export var explosion_expand_speed:float = 0.25
var exploding:bool = false
@export var explosion_scale_curve:Curve
@export var knockback_force:float


func _process(delta: float) -> void:
	# stick the collider's scale to the visual's scale by setting an attribute
	collision_shape_3d.scale = Vector3(explosion_scale, explosion_scale, explosion_scale)
	sphere.scale = Vector3(explosion_scale, explosion_scale, explosion_scale)
	
	if exploding:
		pass # change explosion_scale based on the curve

func setup(spawn_pos:Vector3, explosion_scale_curve:Curve, damage:float, knockback_force:float, color:Color) -> void:
		exploding = true
		global_position = spawn_pos
		self.explosion_scale_curve = explosion_scale_curve
		self.knockback_force = knockback_force
		sphere_material.albedo_color = color
		sphere_material.emission = color
		
		
