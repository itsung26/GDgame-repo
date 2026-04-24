class_name GrappleArm
extends Node3D

const IMPACT_PARTICLES_SCENE:PackedScene = preload("res://scenes/impact_particles.tscn")

@onready var player:Player = QuickRef.player
@onready var grapple_hook: RigidBody3D = %GrappleHook
@onready var camera_3d: PlayerCamera = %Camera3D
@onready var rope_origin: BoneAttachment3D = $grappleArm/whiplash_ARM/Skeleton3D/rope_origin
@onready var grapple_hook_sweeping_cast: ShapeCast3D = $grappleArm/whiplash_ARM/Skeleton3D/rope_origin/GrappleHook/GrappleHookSweepingCast
@onready var animator: AnimationPlayer = $grappleArm/grapple_arm_animator

@export var logging_debug:bool = false
@export_category("Behavior")
@export var throw_velocity:float = 1.0

var hooked_target:Node3D:
	set =  setHookedTarget
## If true, the hook is in flight and can move/collide.
var hook_active:bool = false:
	set = setHookActive
var hook_initial_transform:Transform3D
## The global position of the hook last physics frame.
var last_hook_global_position:Vector3 = Vector3.ZERO
var _hook_global_position_cache:Vector3 = Vector3.ZERO
## True if the hook is in the holder bone attachment.
var isInHolder:bool:
	get = getIsInHolder

signal new_hooked_target_set(previous_hooked_target:Node3D, new_hooked_target:Node3D)


func getIsInHolder() -> bool:
	if grapple_hook.get_parent() == rope_origin:
		return true
	else:
		return false


func _ready() -> void:
	# Cache the hook's initial transform
	hook_initial_transform = grapple_hook.transform
	_hook_global_position_cache = grapple_hook.global_position
	last_hook_global_position = _hook_global_position_cache
	setHookActive(false)


func _physics_process(_delta: float) -> void:
	if hook_active:
		last_hook_global_position = _hook_global_position_cache
		_hook_global_position_cache = grapple_hook.global_position
		updateShapeCastState(last_hook_global_position, grapple_hook.global_position)
		
		var cast_collider_body:Node3D = grapple_hook_sweeping_cast.get_collider(0)
		if cast_collider_body:
			if logging_debug:
				Debug.log("Hook shapecast registered collision, handling.")
			handleHookCollision(cast_collider_body)


func setHookedTarget(hooked_targ:Node3D):
	var previous_hooked_target:Node3D = hooked_target
	var new_hooked_target:Node3D = hooked_targ
	hooked_target = new_hooked_target
	new_hooked_target_set.emit(previous_hooked_target, new_hooked_target)
	
	if new_hooked_target == null:
		breakpoint


## Activates/deactivates the hook, preventing or enabling it from moving, monitoring
## contacts, etc. The hook should be disabled before it is teleported to prevent
## physical miscalculations and erroring.
func setHookActive(is_active:bool) -> void:
	hook_active = is_active
	
	if is_active == true:
		grapple_hook.freeze = false
		grapple_hook.sleeping = false
		grapple_hook.contact_monitor = true
	elif is_active == false:
		grapple_hook.freeze = true
		grapple_hook.sleeping = true
		grapple_hook.contact_monitor = false


## Reparents the hook to the player and moves the hook back to it's bone attatchment,
## re orienting it in the process.
func returnHookToHolder() -> void:
	if hook_active:
		setHookActive(false)
	
	grapple_hook.reparent(rope_origin)
	grapple_hook.transform = hook_initial_transform
	_hook_global_position_cache = grapple_hook.global_position
	last_hook_global_position = _hook_global_position_cache


## Does the actual release of the hook, in [param direction] with [param velocity].
func throwHook(direction:Vector3, velocity:float) -> void:
	if hook_active:
		if logging_debug:
			Debug.logerr("Attempted to throw the hook when it was still active.")
		return
	elif not isInHolder:
		if logging_debug:
			Debug.logerr("Attempted to throw the hook when it was not in the holder.")
		return
	
	grapple_hook.reparent(get_tree().current_scene)
	_hook_global_position_cache = grapple_hook.global_position
	last_hook_global_position = _hook_global_position_cache
	setHookActive(true)
	grapple_hook.linear_velocity = direction.normalized() * velocity


func handleHookCollision(body:Node3D) -> void:
	if logging_debug:
		Debug.log("Handling hook collision for: " + str(body))
	
	if body is WorldBody:
		player.set_action_state(Player.action_states.IDLE)


## Moves the shapecast to pos, looking at pos_2. Expects global coordinates.
func updateShapeCastState(pos:Vector3, pos_2:Vector3) -> void:
	grapple_hook_sweeping_cast.global_position = pos
	grapple_hook_sweeping_cast.target_position = grapple_hook_sweeping_cast.to_local(pos_2)
	grapple_hook_sweeping_cast.force_shapecast_update()


## Called when the hook collides with something.
func _on_grapple_hook_body_entered(body: Node) -> void:
	if logging_debug:
		Debug.log("Hook body registered collision.")
	last_hook_global_position = _hook_global_position_cache
	_hook_global_position_cache = grapple_hook.global_position
	handleHookCollision(body)
