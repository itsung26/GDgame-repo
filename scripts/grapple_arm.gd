class_name GrappleArm
extends Node3D

const IMPACT_PARTICLES_SCENE:PackedScene = preload("res://scenes/impact_particles.tscn")

@onready var player:Player = QuickRef.player
@onready var grapple_hook: RigidBody3D = %GrappleHook
@onready var camera_3d: PlayerCamera = %Camera3D
@onready var rope_origin: BoneAttachment3D = $grappleArm/whiplash_ARM/Skeleton3D/rope_origin

@export var logging_debug:bool = false
@export_category("Behavior")
@export var throw_velocity:float = 1.0

var hooked_target:Node3D:
	set =  setHookedTarget
## If true, the hook cannot detect any collision nor move.
var hook_active:bool = false:
	set = setHookActive
var hook_initial_transform:Transform3D

signal new_hooked_target_set(previous_hooked_target:Node3D, new_hooked_target:Node3D)


func _ready() -> void:
	# Cache the hook's initial transform
	hook_initial_transform = grapple_hook.transform
	setHookActive(false)


# If a target is hooked, go to it's position and stay there.
func _process(delta: float) -> void:
	pass


func setHookedTarget(hooked_targ:Node3D):
	var previous_hooked_target:Node3D = hooked_target
	var new_hooked_target:Node3D = hooked_targ
	new_hooked_target_set.emit(previous_hooked_target, new_hooked_target)
	
	hooked_target = new_hooked_target
	if previous_hooked_target == new_hooked_target:
		if logging_debug:
			Debug.log("Grappler hooked the same target again, was this intended?")


## Activates/deactivates the hook, preventing or enabling it from moving, monitoring
## contacts, etc. The hook should be disabled before it is teleported to prevent
## physical miscalculations and erroring.
func setHookActive(state:bool) -> void:
	hook_active = state
	
	if state == true:
		grapple_hook.freeze = false
		grapple_hook.sleeping = false
	elif state == false:
		grapple_hook.freeze = true
		grapple_hook.sleeping = true


## Reparents the hook to the player and moves the hook back to it's bone attatchment,
## re orienting it in the process.
func returnHookToHolder() -> void:
	if hook_active:
		hook_active = false
	
	grapple_hook.reparent(rope_origin)
	grapple_hook.transform = hook_initial_transform


## Does the actual release of the hook, in [param direction] with [param velocity].
func throwHook(direction:Vector3, velocity:float) -> void:
	if hook_active:
		if logging_debug:
			Debug.logerr("Attempted to throw the hook when it was still active.")
		return
	elif not isInHolder():
		if logging_debug:
			Debug.logerr("Attempted to throw the hook when it was not in the holder.")
		return
	
	grapple_hook.reparent(get_tree().current_scene)
	hook_active = true
	grapple_hook.linear_velocity = direction.normalized() * velocity


## Returns true if the hook is in the holder bone attatchment.
func isInHolder() -> bool:
	if grapple_hook.get_parent() == rope_origin:
		return true
	else:
		return false
