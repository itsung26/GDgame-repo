extends Node3D

@onready var bullet_ray_cast: RayCast3D = $"../../BulletRayCast"
@onready var camera_3d: Camera3D = %Camera3D
@onready var gun_animator: AnimationPlayer = $"../../../../GunAnimator"
var player:CharacterBody3D
var hud:Control
@onready var laser_generator:Node3D = get_tree().current_scene.find_child("LaserGenerator")
@onready var muzzle: Node3D = $VFX/muzzle

const DAMAGE_HITMARKER_SCENE = preload("res://scenes/damage_hitmarker.tscn")
const BULLET_DECAL_BLUE = preload("res://scenes/bullet_decal.tscn")
const BLUE_EMISSIVE_MATERIAL = preload("res://assets/materials/emissives/blue_emissive_material.tres")
const RED_EMISSIVE_MATERIAL = preload("res://assets/materials/emissives/red_emissive_material.tres")

var on_special = false
var isCharged = true

func _ready() -> void:
	player = $"../../../.."
	hud = get_tree().root.get_node("MapEnviroment/HUD")

# instantiate a body from the return of the get_collider() method
# this method is called every time the animation for firing runs and is essentially the bulk of the shoot code
# refer to the _process method for the animations, which are triggered by only input
func fire():
	var body = bullet_ray_cast.get_collider()
	var b = BULLET_DECAL_BLUE.instantiate()
	var b_mesh = b.get_node("MeshInstance3D")
	
	# duplicates the surface material and applies the duplicate to the new instance
	# conditional for if special is active
	if hud.animation_player.current_animation == "bar_charge_empty":
		b_mesh.set_surface_override_material(0, RED_EMISSIVE_MATERIAL.duplicate())
	else:
		b_mesh.set_surface_override_material(0, BLUE_EMISSIVE_MATERIAL.duplicate())
	
	# below occurs regardless of wether the bullets hit something or otherwise
	player.PISTOL_AMMO -= 1
	
	# pass if returns null to avoid null refrence errors
	# in other words, IF IT HITS SOMETHING DO THIS VVVVVV
	if body != null:
		var hit_target_point = bullet_ray_cast.get_collision_point()
		# adds the bullet decal to the object hit
		body.add_child(b)
		b.global_transform.origin = hit_target_point
		# orients bullet decal to aim away from surface normal and
		# adds a small offset to the target position to avoid collinearity
		var look_target = hit_target_point + bullet_ray_cast.get_collision_normal() + Vector3(0.001, 0, 0)
		b.look_at(look_target, Vector3.UP)
		
		# uses a mesh generator to generate a laser between the muzzle and the shot point
		laser_generator.generate_mesh_planes(muzzle.global_position, hit_target_point)

		if body.is_in_group("enemy"):
			# change the damage type that the hit enemy registers
			if getSpecialState() == false:
				body.last_hit_damage_type = body.damage_types.NORMAL
			elif getSpecialState():
				body.last_hit_damage_type = body.damage_types.OVERCLOCK
			
			# if pistol on normal state, subtract enemy health with normal damage range
			if not player.pistol_damage_increase:
				body.HEALTH -= randi_range(player.Pistol_Damage_Range_Min,player.Pistol_Damage_Range_Max)
			elif player.pistol_damage_increase:
				body.HEALTH -= randi_range(player.Pistol_Overclock_Damage_Range_Min,player.Pistol_OverClock_Damage_Range_Max)
			print("HEALTH of enemy: " + str(body.HEALTH))
		else: # if the raycast hits something that is not an enemy
			pass


func reload():
	player.PISTOL_AMMO = player.PISTOL_MAGSIZE
	
# called on right click from player
func special():
	if isCharged:
		isCharged = false
		hud.animation_player.play("bar_charge_empty")
		
func getSpecialState():
	if hud.pistol_on_overclock:
		return true
	else:
		return false
