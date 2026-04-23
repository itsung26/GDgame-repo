class_name GrappleArm
extends Node3D

const IMPACT_PARTICLES_SCENE:PackedScene = preload("res://scenes/impact_particles.tscn")

@onready var player:Player = $"../../.."
@onready var hook: RigidBody3D = $grappleArm/whiplash_ARM/Skeleton3D/rope_origin/hook
@onready var hooked_target:Node3D = null
@onready var camera_3d: PlayerCamera = %Camera3D

signal new_hooked_target_set(previous_hooked_target:Node3D, new_hooked_target:Node3D)

# If a target is hooked, go to it's position and stay there.
func _process(delta: float) -> void:
	if hooked_target:
		hook.freeze = true
		
		if hooked_target is Enemy:
			hook.global_position = hooked_target.global_position + hooked_target.chest_offset


func setHookedTarget(hooked_targ:Node3D):
	var previous_hooked_target:Node3D = hooked_target
	var new_hooked_target:Node3D = hooked_targ
	new_hooked_target_set.emit(previous_hooked_target, new_hooked_target)
	
	hooked_target = new_hooked_target
	if previous_hooked_target == new_hooked_target:
		Debug.log("Grappler hooked the same target again, was this intended?")
