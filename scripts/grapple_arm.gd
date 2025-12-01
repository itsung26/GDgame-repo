class_name GrappleArm
extends Node3D

const IMPACT_PARTICLES_SCENE:PackedScene = preload("res://scenes/impact_particles.tscn")

@onready var player:Player = $"../../.."
@onready var impact_spawn_ray_cast: RayCast3D = $grappleArm/whiplash_ARM/Skeleton3D/rope_origin/hook/ImpactSpawnRayCast
@onready var hook: RigidBody3D = $grappleArm/whiplash_ARM/Skeleton3D/rope_origin/hook
@onready var hooked_target:Node3D = null
@onready var camera_3d: PlayerCamera = %Camera3D

signal new_hooked_target_set(previous_hooked_target:Node3D, new_hooked_target:Node3D)

# If a target is hooked, go to it's position and stay
func _process(delta: float) -> void:
	if hooked_target:
		hook.freeze = true
		hook.global_position = hooked_target.global_position

# on hook hit world
func _on_world_collide_box_body_entered(body: StaticBody3D) -> void:
	# Add vfx for hook hitting the world
	var hit_point:Vector3 = impact_spawn_ray_cast.get_collision_point()
	var hit_surface_normal:Vector3 = impact_spawn_ray_cast.get_collision_normal()
	var impact_particles:GPUParticles3D = IMPACT_PARTICLES_SCENE.instantiate()
	get_tree().current_scene.add_child(impact_particles)
	impact_particles.setup(hit_point, hit_point + hit_surface_normal)
	
	player.action_state = player.action_states.IDLE

# Called when the hook enters the hook detection area of the grapple cube
func _on_grapple_cube_boost_collide_box_area_entered(grapple_cube_boost_detector: Area3D) -> void:
	camera_3d.camera_target_fov += 15.0
	var grapple_boost_cube:GrappleCubeBoost = grapple_cube_boost_detector.get_parent()
	setHookedTarget(grapple_boost_cube)
	
# Called when the hook exits the hook detection area of the grapple cube
func _on_grapple_cube_boost_collide_box_area_exited(grapple_cube_boost_detector: Area3D) -> void:
	camera_3d.camera_target_fov -= 15.0
	var grapple_boost_cube:GrappleCubeBoost = grapple_cube_boost_detector.get_parent()
	if hooked_target == grapple_boost_cube:
		setHookedTarget(null)

func setHookedTarget(hooked_targ:Node3D):
	var previous_hooked_target:Node3D = hooked_target
	var new_hooked_target:Node3D = hooked_targ
	new_hooked_target_set.emit(previous_hooked_target, new_hooked_target)
	
	hooked_target = new_hooked_target
