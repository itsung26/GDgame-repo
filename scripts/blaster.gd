class_name PlayerPistol
extends PlayerWeapon

## [b]Weapon[/b]: Pistol
## [b]Fire type[/b]: Semi-auto

@onready var bullet_ray_cast: RayCast3D = $"../../BulletRayCast"
@onready var camera_3d: Camera3D = %Camera3D
@onready var muzzle: Node3D = $VFX/muzzle

const DAMAGE_HITMARKER_SCENE = preload("res://scenes/damage_hitmarker.tscn")
const BULLET_DECAL_BLUE = preload("res://scenes/bullet_decal.tscn")
const BLUE_EMISSIVE_MATERIAL = preload("res://assets/materials/emissives/blue_emissive_material.tres")
const RED_EMISSIVE_MATERIAL = preload("res://assets/materials/emissives/red_emissive_material.tres")
const BULLET_TRAIL_SCENE:PackedScene = preload("res://scenes/bullet_trail.tscn")

@export var bullet_trail_color:Color = Color.GOLD

func _onEquip():
	pass

func _fire():
	var origin_pos:Vector3 = muzzle.global_position
	var target_pos:Vector3
	
	var bullet_trail:BulletTrail = BULLET_TRAIL_SCENE.instantiate()
	get_tree().current_scene.add_child(bullet_trail)
	bullet_trail.setup(origin_pos, target_pos, bullet_trail_color)
	
func _special():
	pass

func _reload():
	pass

func hurtTarget():
	pass
