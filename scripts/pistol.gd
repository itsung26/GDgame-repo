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

@onready var pistol_ray_cast_target_pos: Marker3D = $pistolRayCast/pistolRayCastTargetPos
@onready var muzzle_charge_particles: GPUParticles3D = $"player pistol/barrel very end upper/muzzle charge particles"
@onready var muzzle_charge_light: OmniLight3D = $"player pistol/barrel very end upper/muzzle charge light"
@onready var barrel_end_cap_shader: MeshInstance3D = $"player pistol/barrel end cap SHADER"
@onready var barrel_heat_shader:ShaderMaterial = barrel_end_cap_shader.material_override
@onready var muzzle_charge_face_quad: MeshInstance3D = $"player pistol/barrel very end upper/muzzle charge face quad"
@onready var muzzle_charge_animator: AnimationPlayer = $"player pistol/barrel very end upper/muzzle charge animator"
@onready var muzzle_charge_animator_2: AnimationPlayer = $"player pistol/barrel very end upper/muzzle charge animator 2"
@onready var muzzle_charge_animator_3: AnimationPlayer = $"player pistol/barrel very end upper/muzzle charge animator 3"

@export var bullet_trail_color:Color = Color.GOLD
@export var muzzle_origin:Marker3D
@export var bullet_raycast:RayCast3D
var charge_visuals_enabled:bool = false:
	set = set_charge_visuals
var special_charge:float = 0.0
@export var special_charge_speed:float = 1.0
var barrel_tip_shader_value_min:float = 0.0
var barrel_tip_shader_value_max:float = 6.473

@export_group("debug")
@export var muzzle_charge_light_max_energy:float = 8.33
@export var muzzle_charge_light_increase_speed:float = 0.075
@export var muzzle_charge_light_decrease_speed:float = 12.0

enum charging_states{IDLE, CHARGING, CHARGED}
var charging_state:charging_states = charging_states.IDLE:
	set = set_charging_state

func set_charging_state(new_charging_state:charging_states):
	var previous_charging_state:charging_states = charging_state
	charging_state = new_charging_state
	
	# Prevent same-state switching.
	if previous_charging_state == new_charging_state:
		return
	
	# CHARGING to and from
	if new_charging_state == charging_states.CHARGING:
		set_charge_visuals(true)
		muzzle_charge_animator_2.play("fully charged")
	if previous_charging_state == charging_states.CHARGING:
		set_charge_visuals(false)
		muzzle_charge_animator_2.pause()
	
	# CHARGED to and from
	if new_charging_state == charging_states.CHARGED:
		muzzle_charge_face_quad.visible = true
	if previous_charging_state == charging_states.CHARGED:
		muzzle_charge_face_quad.visible = false
	
	# IDLE to and from
	if new_charging_state == charging_states.IDLE:
		pass
	if previous_charging_state == charging_states.IDLE:
		pass

func set_charge_visuals(new_charge_visuals_enabled_state:bool) -> void:
	var previous_charge_visuals_enabled_state:bool = charge_visuals_enabled
	charge_visuals_enabled = new_charge_visuals_enabled_state
	
	if new_charge_visuals_enabled_state == true:
		muzzle_charge_particles.emitting = true
	elif new_charge_visuals_enabled_state == false:
		muzzle_charge_particles.emitting = false

func _process(delta: float) -> void:
	Debug.log("charge: " + str(special_charge))
	Debug.log("state: " + str(charging_states.keys()[charging_state]))
	
	# Key the visual to the charage.
	barrel_heat_shader.set_shader_parameter("emission_strength", special_charge * .06473)
	
	# Check if the CHARGED state should be entered.
	if special_charge == 100.0:
		set_charging_state(charging_states.CHARGED)
	
	match charging_state:
		charging_states.CHARGING:
			special_charge = move_toward(special_charge, 100.0, special_charge_speed * delta)
			special_charge = clampf(special_charge, 0.0, 100.0)
		
		charging_states.IDLE:
			special_charge = 0.0
			muzzle_charge_animator_2.stop()
		
		charging_states.CHARGED:
			muzzle_charge_animator_2.play("fully charged")


func _onEquip():
	pass

func _fire():
	if charging_state == charging_states.IDLE:
		firePistol()
	
func _special():
	if charging_state == charging_states.IDLE:
		set_charging_state(charging_states.CHARGING)

func _specialRelease():
	if charging_state == charging_states.CHARGING:
		set_charging_state(charging_states.IDLE)
	elif charging_state == charging_states.CHARGED:
		fireSpecial()
		set_charging_state(charging_states.IDLE)

func _reload():
	pass

## Does the actual firing, including damage and vfx.
func firePistol() -> void:
	# get information about the thing that got hit (what it is and how the bullet hit it)
	var origin_pos:Vector3 = muzzle_origin.global_position
	var hit_pos:Vector3 = bullet_raycast.get_collision_point()
	var hit_body:Node3D = bullet_raycast.get_collider()
	var hit_surface_normal:Vector3 = bullet_raycast.get_collision_normal()
	
	# add a bullet trail and pass position data to it
	if hit_body == null:
		var bullet_trail:BulletTrail = BULLET_TRAIL_SCENE.instantiate()
		get_tree().current_scene.add_child(bullet_trail)
		bullet_trail.setup(origin_pos, pistol_ray_cast_target_pos.global_position, bullet_trail_color)
		return
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
		bullet_impact_particle_2.setup(hit_pos, hit_surface_normal)
		
## Does the special fire action (a charge shot)
func fireSpecial() -> void:
	Debug.log("ddd")
		
		
