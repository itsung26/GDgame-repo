class_name PlayerPistol
extends PlayerWeapon

## [b]Weapon[/b]: Pistol
## [b]Fire type[/b]: Automatic

const DAMAGE_HITMARKER_SCENE:PackedScene = preload("res://scenes/damage_hitmarker.tscn")
const BULLET_DECAL_BLUE:PackedScene = preload("res://scenes/bullet_decal.tscn")
const BLUE_EMISSIVE_MATERIAL:StandardMaterial3D = preload("res://assets/materials/emissives/blue_emissive_material.tres")
const RED_EMISSIVE_MATERIAL:StandardMaterial3D = preload("res://assets/materials/emissives/red_emissive_material.tres")
const BULLET_TRAIL_SCENE:PackedScene = preload("res://scenes/bullet_trail.tscn")
const BULLET_IMPACT_PARTICLE_SCENE_1:PackedScene = null
const BULLET_IMPACT_PARTICLE_SCENE_2:PackedScene = preload("res://scenes/bullet_impact_particles_2.tscn")

@onready var gunplaceholderanimator: AnimationPlayer = $gunplaceholderanimator
@onready var pistol_ray_cast_target_pos: Marker3D = $pistolRayCast/pistolRayCastTargetPos

@export var bullet_trail_color:Color = Color.GOLD
@export var muzzle_origin:Marker3D
@export var bullet_raycast:RayCast3D

func _onEquip():
	gunplaceholderanimator.play("onequip")

func _fire():
	gunplaceholderanimator.play("fire")
	
	
func _special():
	pass

func _reload():
	if gunplaceholderanimator.current_animation == "fire":
		gunplaceholderanimator.play("reload")

## Does the actual firing, including damage and vfx.
func firePistol() -> void:
	# get information about the thing that got hit (what it is and how the bullet hit it)
	var origin_pos:Vector3 = muzzle_origin.global_position
	var hit_pos:Vector3 = bullet_raycast.get_collision_point()
	var hit_body:Node3D = bullet_raycast.get_collider()
	var hit_surface_normal:Vector3 = bullet_raycast.get_collision_normal()
	
	# add a bullet trail and pass position data into it
	if hit_body == null:
		var bullet_trail:BulletTrail = BULLET_TRAIL_SCENE.instantiate()
		get_tree().current_scene.add_child(bullet_trail)
		bullet_trail.setup(origin_pos, pistol_ray_cast_target_pos.global_position, bullet_trail_color)
	else:
		var bullet_trail:BulletTrail = BULLET_TRAIL_SCENE.instantiate()
		get_tree().current_scene.add_child(bullet_trail)
		bullet_trail.setup(origin_pos, hit_pos, bullet_trail_color)
	
	# Register the actual damage part of the gun
	# cases for each thing that could be hit
	if hit_body is Enemy:
		hit_body.damageEnemy(randf_range(damage_max, damage_max), Enemy.damage_types.NORMAL)
	else:
		# add an impact particle to the scene where the bullet hit
		# go to hit point and look at surface normal
		var bullet_impact_particle_2 = BULLET_IMPACT_PARTICLE_SCENE_2.instantiate()
		get_tree().current_scene.add_child(bullet_impact_particle_2)
		bullet_impact_particle_2.setup(hit_pos, hit_surface_normal, 1.5)
