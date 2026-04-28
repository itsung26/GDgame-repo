class_name GrappleArm
extends Node3D

## Public API notes:
## - This class owns hook launch, collision, and attachment state.
## - Hook pulling/reeling behavior is NOT processed here; it is processed in [code]Player[/code]
##   physics state machines (player/action states), and this class only exposes state/data for that flow.

#region @onready vars
@onready var player:Player = QuickRef.player
@onready var grapple_hook: RigidBody3D = %GrappleHook
@onready var camera_3d: PlayerCamera = %Camera3D
@onready var rope_origin: BoneAttachment3D = $grappleArm/whiplash_ARM/Skeleton3D/rope_origin
@onready var grapple_hook_sweeping_cast: ShapeCast3D = $grappleArm/whiplash_ARM/Skeleton3D/rope_origin/GrappleHook/GrappleHookSweepingCast
@onready var animator: AnimationPlayer = $grappleArm/grapple_arm_animator
@onready var grapple_rope_line: GrappleRopeLine = $"../../../GrappleRopeLine"
@onready var grapple_hook_smaller_collider: CollisionShape3D = $"grappleArm/whiplash_ARM/Skeleton3D/rope_origin/GrappleHook/grapple hook smaller collider"
#endregion

#region export vars
@export var logging_debug:bool = false
@export_category("Behavior")
## Base throw speed used by [code]throwHook()[/code].
@export var throw_velocity:float = 75.0
## Shared grapple movement speed consumed by player/hook logic.
@export var grapple_speed:float = 1.0
## This force is applied to the player when the grapple finds a target and calls setHookedTarget.
@export var force_applied_on_grapple:Vector3 = Vector3.UP
## This force is applied to the player when the grapple target goes back to null/the
## grapple finishes. Note that this force is only applied when either the player reaches
## the target, or the target reaches the player.
@export var force_applied_on_ungrapple:Vector3 = Vector3.UP
#endregion

#region regular vars
## Current target attached to the hook, or [code]null[/code] when unattached.
var hooked_target:Node3D:
	set =  setHookedTarget
## Enables/disables collision contact monitoring for the hook.
var hook_collision_monitoring_active:bool = false:
	set = setHookCollisionMonitoringActive
## Enables/disables movement simulation by toggling freeze/sleeping.
var hook_physics_simulation_active:bool = false:
	set = setHookPhysicsSimulationActive
var hook_initial_transform:Transform3D
## The global position of the hook last physics frame.
var last_hook_global_position:Vector3 = Vector3.ZERO
var _hook_global_position_cache:Vector3 = Vector3.ZERO
var _last_collision_normal_cache:Vector3 = Vector3.ZERO
var _last_collision_point_cache:Vector3 = Vector3.ZERO
## True if the hook is in the holder bone attachment.
var isInHolder:bool:
	get = getIsInHolder
## The normal of the last [code]grapple_hook[/code] collision.
var last_collision_normal:Vector3:
	get = getLastCollisionNormal
## The location of the last [code]grapple_hook[/code] collision, in global coordinates.
var last_collision_point:Vector3:
	get = getLastCollisionPoint
#endregion

signal new_hooked_target_set(previous_hooked_target:Node3D, new_hooked_target:Node3D)
## Emitted when the hook collides and collision data is available.
signal hook_collided(body:Node3D, collision_point:Vector3, collision_normal:Vector3)

const IMPACT_PARTICLES_SCENE:PackedScene = preload("res://scenes/impact_particles.tscn")


#region Setters and getters
func getIsInHolder() -> bool:
	if grapple_hook.get_parent() == rope_origin:
		return true
	else:
		return false


func getHookPhysicsState() -> PhysicsDirectBodyState3D:
	return PhysicsServer3D.body_get_direct_state(grapple_hook.get_rid())


## Returns the collision normal of the last registered collision of grapple_hook.
func getLastCollisionNormal() -> Vector3:
	var hook_physics_state:PhysicsDirectBodyState3D = getHookPhysicsState()
	if hook_physics_state != null and hook_physics_state.get_contact_count() > 0:
		_last_collision_normal_cache = hook_physics_state.get_contact_local_normal(0)
		return _last_collision_normal_cache
	else:
		return _last_collision_normal_cache


## Returns the collision point of the last registered collision of grapple_hook.
func getLastCollisionPoint() -> Vector3:
	var hook_physics_state:PhysicsDirectBodyState3D = getHookPhysicsState()
	if hook_physics_state != null and hook_physics_state.get_contact_count() > 0:
		_last_collision_point_cache = hook_physics_state.get_contact_collider_position(0)
		return _last_collision_point_cache
	else:
		return _last_collision_point_cache


## Sets [code]hooked_target[/code], emits [code]new_hooked_target_set[/code], and disables free-flight simulation.
func setHookedTarget(hooked_targ:Node3D):
	var previous_hooked_target:Node3D = hooked_target
	var new_hooked_target:Node3D = hooked_targ
	hooked_target = new_hooked_target
	new_hooked_target_set.emit(previous_hooked_target, new_hooked_target)
	
	if new_hooked_target != null:
		player.killVelocity()
		player.applyForceImpulse(force_applied_on_grapple.length(), force_applied_on_grapple.normalized())
		setHookCollisionMonitoringActive(false)
		setHookPhysicsSimulationActive(false)


## Enables/disables collision monitoring and sweeping cast updates for the hook.
func setHookCollisionMonitoringActive(is_active:bool) -> void:
	hook_collision_monitoring_active = is_active
	grapple_hook.contact_monitor = is_active
	grapple_hook_smaller_collider.disabled = !is_active
	grapple_hook_sweeping_cast.enabled = is_active


## Enables/disables hook rigid-body simulation by toggling freeze/sleeping.
func setHookPhysicsSimulationActive(is_active:bool) -> void:
	hook_physics_simulation_active = is_active
	grapple_hook.freeze = not is_active
	grapple_hook.sleeping = not is_active
#endregion


func _ready() -> void:
	# Cache the hook's initial transform
	hook_initial_transform = grapple_hook.transform
	_hook_global_position_cache = grapple_hook.global_position
	last_hook_global_position = _hook_global_position_cache
	setHookCollisionMonitoringActive(false)
	setHookPhysicsSimulationActive(false)


func _physics_process(_delta: float) -> void:
	
	if hook_physics_simulation_active:
		last_hook_global_position = _hook_global_position_cache
		_hook_global_position_cache = grapple_hook.global_position
		updateShapeCastState(last_hook_global_position, grapple_hook.global_position)
		
		var cast_collider_body:Node3D = grapple_hook_sweeping_cast.get_collider(0)
		if cast_collider_body:
			if logging_debug:
				Debug.log("Hook shapecast registered collision, handling.")
			handleHookCollision(cast_collider_body)
	
	if hooked_target:
		# snap hook to the target
		if hooked_target is Enemy:
			grapple_hook.global_position = hooked_target.global_position + hooked_target.chest_offset
		else:
			grapple_hook.global_position = hooked_target.global_position


## Reparents the hook to the player and moves the hook back to it's bone attatchment,
## re orienting it in the process.
## This is an immediate reset and does not run pull/reel behavior.
func returnHookToHolderInstant() -> void:
	if hook_physics_simulation_active:
		setHookCollisionMonitoringActive(false)
		setHookPhysicsSimulationActive(false)
	if hooked_target:
		hooked_target = null
	
	grapple_hook.reparent(rope_origin)
	grapple_hook.transform = hook_initial_transform
	_hook_global_position_cache = grapple_hook.global_position
	last_hook_global_position = _hook_global_position_cache


## Does the actual release of the hook, in [param direction] with [param velocity].
## This only starts hook flight; any pull/reel behavior is processed by [code]Player[/code] state machines.
func throwHook(direction:Vector3, velocity:float) -> void:
	if hook_physics_simulation_active:
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
	setHookCollisionMonitoringActive(true)
	setHookPhysicsSimulationActive(true)
	grapple_hook.linear_velocity = direction.normalized() * velocity


## Handles a registered hook collision and emits [code]hook_collided[/code].
## This is the most important method in the grapple hook system as every reaction
## to the hook runs through here.
func handleHookCollision(body:Node3D) -> void:
	if logging_debug:
		Debug.log("Handling hook collision for: " + str(body))

	hook_collided.emit(body, last_collision_point, last_collision_normal)
	
	if body is WorldBody:
		var impact_particles:GPUParticles3D = IMPACT_PARTICLES_SCENE.instantiate()
		get_tree().current_scene.add_child(impact_particles)
		impact_particles.setup(last_collision_point, last_collision_point + last_collision_normal.normalized())
		player.set_action_state(Player.action_states.IDLE)
	
	elif body is GrappleableAgent3D:
		hooked_target = body.agent
		if body.pull_behavior == GrappleableAgent3D.pull_behaviors.PULL_PLAYER:
			player.set_player_state(Player.player_states.GRAPPLING_TO)
		elif body.pull_behavior == GrappleableAgent3D.pull_behaviors.PULL_AGENT:
			player.set_action_state(Player.action_states.REELING_IN)


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


## Call this instead of hooked_target.global_position to account for enemy chest offset.
func getHookedTargetPosition() -> Vector3:
	if hooked_target == null:
		if logging_debug:
			Debug.logerr("Hooked target is null! Returning Vector3.ZERO")
		return Vector3.ZERO
	elif hooked_target is Enemy:
		return hooked_target.global_position + hooked_target.chest_offset
	else:
		return hooked_target.global_position


## Returns the true global_position, ignoring any offsets.
func getTrueHookedTargetPosition() -> Vector3:
	return hooked_target.global_position
