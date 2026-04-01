class_name Player
extends CharacterBody3D

## The player. Creation of a new level that the player may be active in requires that a [code]Player[/code]
## scene, a [code]GrappleMeshGenerator[/code] scene, and a [code]LaserGenerator[/code] scene be present in the level.
##
## [u][b]Core Logic[/b][/u]
## [br]
## The player primarily works on the basis of a finite-state machine system. This involves a set
## of constants in the form of an enumeration, with a type-restricted variable "occupuying"
## one of the constants' state. [code]Player[/code] currently makes use of four seperate state machines:
## [br]
## [br] 
## [code]player_states[/code]: primarily handles changes to [code]velocity[/code] core attribute. (see enums and [code]set_player_state()[/code])
## [br]
## [code]weapon_states[/code]: handles what inputs are allowed based on which weapon the player has. This essentially functions as an inventory system. (see enums and [code]set_weapon_state()[/code])
## [br]
## [code]arm_states[/code]: handles which arm is currently equipped and which action occurs on pressing the arm action button. (see enums and [code]set_arm_state()[/code])
## [br]
## [code]action_states[/code]: Handles which action is currently occuring. (see enums) [color=lightblue]Note: this currently only handles grapple hook state logic and may be depreciated in the future.[/color]
## [br]
## [br]
## [u][b]Camera[/b][/u]
## [br]The camera movement logic is computed when [code]cameraFX()[/code] is called (excluding mouse look,
## as this needs to be computed on input in [code]_input()[/code]). It does not make use of a state
## machine, so any changes to it's position/rotation have to be procedural and account for
## the camera being in any given state.

#region @onready
@onready var player: CharacterBody3D = $"."
@onready var camera_3d: PlayerCamera = %Camera3D
@onready var pivot: Node3D = $Pivot
@onready var gun_animator: AnimationPlayer = $GunAnimator
@onready var camera_animator: AnimationPlayer = $CameraAnimator
@onready var shotgun: Node3D = $Pivot/Camera3D/Guns/shotgun
@onready var grapple_ray_cast: RayCast3D = $Pivot/Camera3D/GrappleRayCast
@onready var slam_timer: Timer = $SlamTimer
@onready var black_hole_launcher: Node3D = $Pivot/Camera3D/Guns/BlackHoleLauncher
@onready var bll_animator: AnimationPlayer = $BLLAnimator
@onready var arm_pivot_pistol: Node3D = $Pivot/Camera3D/ArmPivotPistol
@onready var arm_pivot_bll: Node3D = $Pivot/Camera3D/ArmPivotBLL
@onready var hud: HudGui = %HUD
@onready var grapple_target: Node3D = $"../GrappleTarget"
@onready var grapple_arm: GrappleArm = $Pivot/Camera3D/GrappleArm
@onready var grapple_direction_getter: RayCast3D = $Pivot/Camera3D/GrappleDirectionGetter
@onready var grapple_hook: RigidBody3D = $Pivot/Camera3D/GrappleArm/grappleArm/whiplash_ARM/Skeleton3D/rope_origin/hook
@onready var grapple_timer: Timer = $GrappleTimer
@onready var cam_shake_timer: Timer = $CamShakeTimer
@onready var sliding_marker: Marker3D = $CameraMarkerPositions/SlidingMarker
@onready var head_marker: Marker3D = $CameraMarkerPositions/HeadMarker
@onready var wind_rings: GPUParticles3D = $Pivot/Camera3D/WindRings
@onready var dash_length_timer: Timer = $DashLengthTimer
@onready var stamina_charge_delay_timer: Timer = $StaminaChargeDelayTimer
@onready var tail_marker: Marker3D = $Pivot/Camera3D/GrappleArm/grappleArm/whiplash_ARM/Skeleton3D/rope_origin/hook/TailMarker
@onready var world_collide_box: Area3D = $Pivot/Camera3D/GrappleArm/grappleArm/whiplash_ARM/Skeleton3D/rope_origin/hook/WorldCollideBox
@onready var parry_arm: Node3D = $Pivot/Camera3D/ParryArm
@onready var parry_arm_animator: AnimationPlayer = $"Pivot/Camera3D/ParryArm/parry arm/AnimationPlayer"
@onready var distant_marker: Marker3D = $Pivot/Camera3D/distantMarker
@onready var parry_flash: MeshInstance3D = $Pivot/Camera3D/ParryArm/ParryFlash
@onready var parry_flash_go_back_marker: Marker3D = $Pivot/Camera3D/parryFlashGoBackMarker
@onready var punch_raycast: RayCast3D = $Pivot/Camera3D/PunchRaycast
@onready var rope_origin: BoneAttachment3D = $Pivot/Camera3D/GrappleArm/grappleArm/whiplash_ARM/Skeleton3D/rope_origin
@onready var slide_particles: SlideParticles = $SlideParticles
@onready var slide_light:OmniLight3D = $SlideParticles/ImpactParticles/SlideLight
@onready var impact_sparks:GPUParticles3D = $SlideParticles/ImpactParticles/SparkTrailsSide/ImpactSparks
@onready var impact_sparks_2:GPUParticles3D = $SlideParticles/ImpactParticles/SparkTrailsSide/ImpactSparks2
@onready var impact_particles:GPUParticles3D = $SlideParticles/ImpactParticles
@onready var pause_menu: PauseMenu = %PauseMenu
#endregion

#region Enum FSMs
## Declared before [code]@export[/code] so properties such as [code]inital_arm[/code] can use these types.
## 4 seperate FSMs (finite state machines) to replace conditional trees.
##
## Player states. These states affect the player's kinematics.
## Associated state variable of type [code]player_states[/code]: [code]player_state[/code]
enum player_states {
	GROUNDED,
	DEAD,
	FALLING,
	WALL_SLIDING,
	REELINGTO,
	SLIDING,
	DASHING,
	SLAMMING
}

## Arm states. These states affect which arm is currently active. Associated state variable of type [code]arm_states[/code]: [code]arm_state[/code]
enum arm_states{GRAPPLEARM, PARRYARM}

## WIP. Currently only represents the grapple hook's state.
enum action_states{IDLE, GRAPPLING}
#endregion

@export_group("Input Allowments")
@export var player_move_input_enabled:bool = true
@export var player_jump_input_enabled:bool = true
@export var player_look_input_enabled:bool = true
@export var player_fire_input_enabled:bool = true
@export var player_dash_input_enabled:bool = true
@export var player_arm_action_input_enabled:bool = true
@export var weapon_switch_input_enabled:bool = true
@export var player_slide_slam_input_enabled:bool = true
@export var player_arm_switch_input_enabled:bool = true

@export_category("Main Attributes")
@export var Godmode:bool = false
@export var HEALTH:float = 100:
	set = setHealth
@export var can_be_healed:bool = true
@export var can_be_damaged:bool = true
@export var in_combat:bool = false: set = setInCombat
@export var STAMINA:float = 300
## Delay after dash before stamina before stamina begins to recharge in seconds.
@export var stamina_charge_delay:float = 0.1 # seconds
## Speed at which the stamina charges.
@export var stamina_charge_speed:float = 100.0
@export var inital_arm:arm_states = arm_states.GRAPPLEARM

@export_group("Physics Compute")
## If [code]true[/code], compute physics for velocity on the XZ plane.
## This can be used to prevent the player from moving, but still alowing the player to fall.
@export var player_kinematics_enabled_xz:bool = true
## If [code]true[/code], compute physics for velocity on the Y axis (up and down).
## This can be useful for freezing the player in the air.
@export var player_kinematics_enabled_y:bool = true

@export_group("Movement")
@export var SPEED = 12.0
@export var JUMP_VELOCITY = 7.0
@export var look_sensitivity = 0.1
@export var gravity_enabled = true
## How much the player is slowed down passively in the air when not moving.
@export var Aerial_Slowdown := 0.0
## How quickly the player is able to accelerate/deccelerate in the air.
@export var AIR_ACCELERATION := 6.0
## The amount that base speed is multiplied with for the slide speed.
@export var slide_speed_multiplier := 1.5
## How much velocity the dash applies.
@export var dash_velocity_increase := 37.5
## Amount of time that the dash velocity is applied for
@export var dash_time_length := 0.1
## The velocity applied in the negative y direction. Should remain constant.
@export var slam_velocity := 35.0
## Multiplier for gravity strength while wall sliding.
@export var wall_slide_gravity_scale:float = 0.3
## Horizontal velocity applied away from the wall when performing a wall jump.
@export var wall_jump_applied_velocity:float = 12.0
## Maximum number of times the player can jump off walls before touching the ground again.
@export var max_wall_jumps:int = 3

@export_group("Grappling Hook")
@export var Grapple_Enabled:= true
@export var GRAPPLE_SPEED_MAX = 90
@export var grapple_pull_speed:float = 25.0
## The amount of upward velocity that is added to the player after beginning to pull the grapple on an enemy
@export var grapple_hop:float = 1.0
@export var grapple_hook_damage:float = 1.0

@export_group("Parrying")
## The amount of time that time stops for when parrying something.
@export var hitstop_duration:float = 0.21
## The factor that projectile's speed is multiplied with after being parried.
@export var parry_projectile_speed_boost:float = 2.0
## Wether the parry arm action in specific is allowed to occur.
@export var parry_input_allowed:bool = true
## How much health is regained on a successful parry.
@export var parry_heal_amount:float = 25.0

@export_group("Respawning and Death")
@export var death_camera_fling_magnitude:float = 1.0
@export var death_camera_spin_magnitude:float = 1.0
@export var death_time_slow_speed:float = 1.0
@export var can_lerp_time_in_death:bool = true
## When [code]true[/code], any button input will cause a respawn. Only intended to
## be used in the [code]DEAD[/code] state.
@export var awaiting_death_input:bool = false

@export_group("Extras")
## This enables the ability to freely control the slide direction. Largley overpowered and intended as a cheat/extra feature.
@export var free_slide_enabled := false

@export_category("Weapons")
## The initial weapon. If none is set, the initial weapon defaults to the first in the
## weapon_states order.
@export var initial_weapon:PlayerWeapon
## Weapon states. These states serve as the weapons that the player is allowed to use.
## Associated state variable of type [code]PlayerWeapon[/code]: [code]weapon_state[/code]
## Important Note: This state machine differs from the others in the way that it is an array,
## not an enumeration. The array directly contains refrences to the PlayerWeapon objects
## and the weapon_state directly holds the object itself.
## For example, checking if the player has the pistol would include: weapon_state == pistol.
@export var weapon_states:Array[PlayerWeapon]

#region Variables
var player_state:player_states = player_states.GROUNDED:
	set = set_player_state
var arm_state:arm_states = arm_states.GRAPPLEARM:
	set = set_arm_state
var action_state:action_states = action_states.IDLE:
	set = set_action_state
var weapon_state:PlayerWeapon:
	set = set_weapon_state
## Remaining wall jumps available before needing to touch the ground.
var wall_jumps_left:int = 0
## True while the player is touching a wall based on slide collisions, even without input.
var touching_wall:bool = false
## Approximate normal of the wall the player is currently touching, derived from test_move checks.
var wall_normal:Vector3 = Vector3.ZERO
var parry_target:Node3D
var cause_of_death:String = ""
var direction:Vector3
var input_dir := Vector2.ZERO
var dash_dir:Vector3
var initial_player_rotation:Vector3
var initial_camera_rotation:Vector3
var los_query:LineOfSightQuery
var grapple_rope_mesh_gen:ropeMeshGenerator
var stamina_recharging:bool = true
#endregion

#region Constants
const hurt_rect_SCENE:PackedScene = preload("res://scenes/hurt_rect.tscn")
const grapple_rope_mesh_gen_SCENE = preload("res://scenes/grapple_rope_meshGen.tscn")
const bullet_trail_SCENE:PackedScene = preload("res://scenes/bullet_trail.tscn")
const los_query_SCENE:PackedScene = preload("res://scenes/line_of_sight_query.tscn")
const death_camera_SCENE:PackedScene = preload("res://scenes/death_camera.tscn")
#endregion

#region Signals
## Emitted when the [code]player_state[/code] changes.
signal entered_player_state(new_player_state:player_states, previous_player_state:player_states)
signal entered_arm_state(new_arm_state:arm_states, previous_arm_state:arm_states)
signal entered_action_state(new_action_state:action_states, previous_action_state:action_states)
## Emitted when the equipped [code]weapon_state[/code] ([code]PlayerWeapon[/code]) changes.
signal entered_weapon_state(new_weapon_state:PlayerWeapon, previous_weapon_state:PlayerWeapon)
## Emitted when [code]in_combat[/code] changes (e.g. combat area enter/exit).
signal in_combat_changed(new_in_combat:bool, previous_in_combat:bool)
#endregion


func set_player_state(new_player_state:player_states):
	# init vars
	var previous_player_state := player_state
	player_state = new_player_state
	
	# prevent switching to the same state
	if previous_player_state == new_player_state:
		# exception is the DASHING state
		if new_player_state != player_states.DASHING:
			return
	
	# Emit signal
	entered_player_state.emit(new_player_state, previous_player_state)
		
	# death to and from
	if new_player_state == player_states.DEAD:
		# disable inputs
		player_move_input_enabled = false
		player_dash_input_enabled = false
		player_jump_input_enabled = false
		player_fire_input_enabled = false
		player_arm_action_input_enabled = false
		weapon_switch_input_enabled = false
		player_arm_switch_input_enabled = false
		player_look_input_enabled = false
		# prevent healing the player
		can_be_healed = false
		player_kinematics_enabled_xz = false
		player_kinematics_enabled_y = false
		grapple_arm.visible = false
		parry_arm.visible = false
		# prevent damaging the player
		can_be_damaged = false
		player_look_input_enabled = false
		player_slide_slam_input_enabled = false
		
		var velocity_cache:Vector3 = killVelocity()
		weapon_state.visible = false
		
		var death_camera:DeathCamera = death_camera_SCENE.instantiate()
		get_tree().current_scene.add_child(death_camera)
		death_camera.setup(
			self,
			death_camera_spin_magnitude,
			death_camera_fling_magnitude,
			camera_3d.global_rotation,
			camera_3d.global_position,
			velocity_cache
			)
	if previous_player_state == player_states.DEAD:
		# re enable inputs
		player_move_input_enabled = true
		player_dash_input_enabled = true
		player_jump_input_enabled = true
		player_fire_input_enabled = true
		player_arm_action_input_enabled = true
		weapon_switch_input_enabled = true
		player_look_input_enabled = true
		can_be_healed = true
		player_kinematics_enabled_xz = true
		player_kinematics_enabled_y = true
		grapple_arm.visible = true
		parry_arm.visible = true
		can_be_damaged = true
		player_look_input_enabled = true
		player_slide_slam_input_enabled = true
		player_arm_switch_input_enabled = true
		
		weapon_state.visible = true

	# GROUNDED to and from
	if new_player_state == player_states.GROUNDED:
		# Reset available wall jumps whenever the player lands.
		wall_jumps_left = max_wall_jumps
		
	# SLIDING to and from
	if new_player_state == player_states.SLIDING:
		camera_3d.gotoSliding()
		impact_particles.emitting = true
		impact_sparks.emitting = true
		impact_sparks_2.emitting = true
		slide_light.visible = true
	if previous_player_state == player_states.SLIDING:
		camera_3d.gotoNormal()
		impact_particles.emitting = false
		impact_sparks.emitting = false
		impact_sparks_2.emitting = false
		slide_light.visible = false
		
	# DASHING to and from
	if new_player_state == player_states.DASHING:
		Godmode = true
		stamina_recharging = false
		stamina_charge_delay_timer.start(stamina_charge_delay)
		STAMINA -= 100
		# cancels grapple if it is active
		if action_state == action_states.GRAPPLING:
			set_action_state(action_states.IDLE)
		# starts the timer and zeroes velocity
		dash_length_timer.start(dash_time_length)
		velocity = Vector3.ZERO
		# gets foward direction relative to players BASIS.Z
		var forward_dir = -transform.basis.z
		# if no input, dash fowards
		if input_dir == Vector2.ZERO:
			velocity = forward_dir * dash_velocity_increase
		# else, dash in the direction of horizontal travel
		else:
			velocity = direction * dash_velocity_increase
	if previous_player_state == player_states.DASHING:
		Godmode = false
		var prev_velocity = velocity
		velocity = Vector3.ZERO
		velocity = prev_velocity / 2
	
	# SLAMMING to and from
	if new_player_state == player_states.SLAMMING:
		player_move_input_enabled = false
		set_action_state(action_states.IDLE)
		gravity_enabled = false
		velocity = Vector3.ZERO # kill velocity
		velocity.y = -slam_velocity # slam down
	if previous_player_state == player_states.SLAMMING:
		player_move_input_enabled = true
		gravity_enabled = true


func set_weapon_state(new_weapon_state:PlayerWeapon):
	# prevent the weapon state from being set to null
	if new_weapon_state == null:
		return

	var previous_weapon_state:PlayerWeapon = weapon_state
	weapon_state = new_weapon_state
	
	# prevent switching to the same state
	if previous_weapon_state == new_weapon_state:
		return
	
	entered_weapon_state.emit(new_weapon_state, previous_weapon_state)
	
	# makes the previous weapon invisible and the new weapon visible
	if previous_weapon_state != null:
		previous_weapon_state.visible = false
	new_weapon_state.visible = true
	
	# calls the equip logic on the weapon that is being equipped
	new_weapon_state._onEquip()


func set_action_state(new_action_state:action_states):
	# init vars
	var previous_action_state := action_state
	action_state = new_action_state
	
	if previous_action_state == new_action_state:
		return
	
	# Emit signal
	entered_action_state.emit(new_action_state, previous_action_state)
	
	# grappling to and from
	if new_action_state == action_states.GRAPPLING and Grapple_Enabled:
		world_collide_box.monitoring = true
		grapple_rope_mesh_gen.visible = true
		grapple_hook.reparent(get_tree().current_scene) # reparent and face direction raycast is looking
		grapple_hook.rotation = Vector3.ZERO
		var grapple_dir = grapple_direction_getter.global_rotation
		grapple_hook.rotation = grapple_dir
		grapple_hook.freeze = false
		# Use basis to get the forward direction
		var forward = grapple_hook.global_transform.basis.z.normalized()
		grapple_hook.linear_velocity = -forward * GRAPPLE_SPEED_MAX # move forwards with a set linear velocity
		$Pivot/Camera3D/GrappleArm/grappleArm/grapple_arm_animator.play("grapple_out")
	if previous_action_state == action_states.GRAPPLING: # run these actions upon moving out of grappling state unless going into reelingfrom state
		print(world_collide_box.monitoring)
		world_collide_box.set_deferred("monitoring", false)
		print(world_collide_box.monitoring)
		grapple_rope_mesh_gen.visible = false
		grapple_hook.freeze = true
		grapple_hook.reparent(rope_origin) # reparent and set it to face how it did before
		grapple_hook.position = Vector3(-0.069, 0.252, 0.043)
		grapple_hook.rotation = Vector3(deg_to_rad(81.1), deg_to_rad(86.5), deg_to_rad(83.3))
		grapple_hook.scale = Vector3(1.0, 1.0, 1.0)
		$Pivot/Camera3D/GrappleArm/grappleArm/grapple_arm_animator.play("grapple_rebound")
		
	# IDLE to and from
	if new_action_state == action_states.IDLE:
		pass
	if previous_action_state == action_states.IDLE:
		pass


func set_arm_state(new_arm_state:arm_states):
	# init vars
	var previous_arm_state := arm_state
	arm_state = new_arm_state
	
	# prevent switching to the same state
	if previous_arm_state == new_arm_state:
		return
	
	entered_arm_state.emit(new_arm_state, previous_arm_state)
	
	# GRAPPLEARM to and from
	if new_arm_state == arm_states.GRAPPLEARM:
		grapple_arm.visible = true
	if previous_arm_state == arm_states.GRAPPLEARM:
		grapple_arm.visible = false
		# on leaving the grapple arm state, grapple go back to idle if currently busy
		if action_state == action_states.GRAPPLING:
			set_action_state(action_states.IDLE)
	
	# PARRYARM to and from
	if new_arm_state == arm_states.PARRYARM:
		parry_arm.visible = true
	if previous_arm_state == arm_states.PARRYARM:
		parry_arm.visible = false


# called when the player is loaded into the scene.
# Player should be loaded after main enviroment and global lighting, but before 
# map and everything else.
func _ready() -> void:
	# initializers for variables and state machines
	initial_player_rotation = player.rotation
	initial_camera_rotation = camera_3d.rotation
	los_query = los_query_SCENE.instantiate()
	get_tree().current_scene.add_child.call_deferred(los_query)
	
	var contains_weapon:bool = false
	for weapon in weapon_states:
		if weapon != null:
			contains_weapon = true
	
	if weapon_states.is_empty() or not contains_weapon:
		assert(false, "No weapons! Player should at least have weapon melee equipped.")
	
	# hide all weapons except the one the player is using
	for weapon in weapon_states:
		# if the active weapon is not the iterated weapon, hide it
		if weapon_state != weapon:
			if weapon:
				weapon.visible = false
		else:
			if weapon:
				weapon.visible = true

	# set the mouse to be captured by the gamewindow
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# set the grapple hook's physics process to static so it doesn't fall to the depths of hell
	grapple_hook.freeze = true
	
	# Switch to the initial arm
	if arm_state != inital_arm:
		set_arm_state(inital_arm)
	
	# Switch to initial weapon
	if initial_weapon == null:
		initial_weapon = weapon_states.front()
		set_weapon_state(initial_weapon)
	else:
		set_weapon_state(initial_weapon)
	
	# initialize the stamina and stamina bar
	_initializeStamina()


## Called every frame. Main thread frames fluctuate around a target fps of 60.
## Kinematic-related operations should only be run in _physics_process, while logic and other operations
## should be run in the main [color=455aff]process[/color] loop.
func _process(delta) -> void:
	if Input.is_action_just_pressed("debug func"):
		setHealth(HEALTH - 100.0)
	# print what canvasitem was clicked on when something is clicked here
	
	grapple_rope_mesh_gen = get_tree().current_scene.get_node("grapple_rope_meshGen")
	# I hate this
	chargeStamina(delta)
	
	#region Gun Inputs
	if weapon_state and weapon_switch_input_enabled:
		# switch weapon block==================================================================================
		if Input.is_action_just_pressed("slot1"):
			if weapon_states[0]:
				set_weapon_state(weapon_states[0]) # slot 1
			
		if Input.is_action_just_pressed("slot2"):
			if weapon_states[1]:
				set_weapon_state(weapon_states[1]) # slot 2
		
		if Input.is_action_just_pressed("slot3"):
			if weapon_states[2]:
				set_weapon_state(weapon_states[2])
		
		
		# automatic fire block===================================================================================
		if Input.is_action_pressed("fire") and player_fire_input_enabled and weapon_state.automatic and weapon_state.can_fire:
			# use seperate animation players for each weapon
			weapon_state._fire()
		# semi-automatic fire block========================================================================
		if Input.is_action_just_pressed("fire") and player_fire_input_enabled and not weapon_state.automatic and weapon_state.can_fire:
			weapon_state._fire()
		# inspect block=======================================================================================
		if Input.is_action_just_pressed("inspect weapon"):
			print("weapon inspect currently disabled")
		# reload block=========================================================================================
		if Input.is_action_just_pressed("reload"):
			weapon_state._reload()
				
		# special block=========================================================================================
		if Input.is_action_just_pressed("right click action") and player_fire_input_enabled:
			weapon_state._special()
		elif Input.is_action_just_released("right click action"):
			weapon_state._specialRelease()
		# ======================================================================================================
	#endregion

	# keeps the rope attatched to the grapple bit.
	# DEPRECATED - replace with self contained behavior in the form of an object
	if grapple_rope_mesh_gen:
		grapple_rope_mesh_gen.generate_mesh_planes(rope_origin.global_position, grapple_hook.global_position)
	
	process_player_state(delta)


func process_player_state(delta:float) -> void:
	if player_state == player_states.DEAD and can_lerp_time_in_death:
		TimeFlowSystem.setTimeScale(lerpf(
			TimeFlowSystem.getTimeScale(),
			0.0,
			death_time_slow_speed * delta
		))


# Called every physics frame. FPS: 120
func _physics_process(delta: float) -> void:

	# Update touching_wall using test_move so it does not depend on current velocity/input.
	touching_wall = false
	wall_normal = Vector3.ZERO
	var wall_check_distance := 0.1
	var local_dirs := [
		Vector3.LEFT,
		Vector3.RIGHT,
		Vector3.FORWARD,
		Vector3.BACK
	]
	for local_dir in local_dirs:
		var world_dir: Vector3 = (transform.basis * local_dir).normalized()
		if test_move(global_transform, world_dir * wall_check_distance):
			touching_wall = true
			# The surface normal points away from the wall; approximate it as the opposite
			# of the direction we are testing into.
			wall_normal = -world_dir
			break

	# state control
	if (is_on_floor() and 
	player_state != player_states.REELINGTO and 
	player_state != player_states.SLIDING and 
	player_state != player_states.DASHING and
	player_state != player_states.GROUNDED and
	player_state != player_states.DEAD):
		set_player_state(player_states.GROUNDED)

	elif (not is_on_floor() and 
	player_state != player_states.REELINGTO and 
	player_state != player_states.DASHING and 
	player_state != player_states.SLAMMING and 
	player_state != player_states.FALLING and
	player_state != player_states.WALL_SLIDING and
	player_state != player_states.DEAD):
		set_player_state(player_states.FALLING)
	
	# Add the gravity 
	if not is_on_floor() and gravity_enabled:
		var gravity: Vector3 = get_gravity()
		if player_state == player_states.WALL_SLIDING:
			gravity *= wall_slide_gravity_scale
		velocity += gravity * delta

	# Enter wall sliding when airborne and touching a wall, primarily while falling.
	if (not is_on_floor()
		and touching_wall
		and player_state == player_states.FALLING
		and velocity.y < 0.0):
		set_player_state(player_states.WALL_SLIDING)
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") and player_jump_input_enabled:
		# Normal ground jump
		if is_on_floor() and not (player_state == player_states.REELINGTO):
			velocity.y = JUMP_VELOCITY
			wall_jumps_left = max_wall_jumps
		# Wall jump while airborne (limited by wall_jumps_left)
		elif not is_on_floor() and touching_wall and wall_jumps_left > 0:
			var push_dir: Vector3 = wall_normal
			# If we don't have a valid wall normal, do not apply a wall jump.
			if push_dir != Vector3.ZERO:
				push_dir = push_dir.normalized()
				velocity.x = push_dir.x * wall_jump_applied_velocity
				velocity.z = push_dir.z * wall_jump_applied_velocity
				velocity.y = JUMP_VELOCITY
				wall_jumps_left -= 1
				set_player_state(player_states.FALLING)
		# Jump-cancel out of reeling grapple while airborne
		elif not is_on_floor() and player_state == player_states.REELINGTO:
			set_action_state(action_states.IDLE)
			velocity = Vector3.ZERO
			velocity.y = JUMP_VELOCITY
	
	# Get the input direction and handle the movement/deceleration.
	input_dir = Input.get_vector("left", "right", "forward", "back")
	direction = Vector3(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	physics_process_player_state(delta)

	# if kinematics are not enabled, kill all velocity before computing physics
	if not player_kinematics_enabled_xz:
		velocity.x = 0.0
		velocity.z = 0.0
	if not player_kinematics_enabled_y:
		velocity.y = 0.0
	move_and_slide()


func physics_process_player_state(delta:float) -> void:
	# run all state machine related physics logic every physics frame
	# grounded movement state logic
	if player_state == player_states.GROUNDED:
		if direction and player_move_input_enabled:
			var ground_dir = direction.normalized()
			velocity.x = ground_dir.x * SPEED
			velocity.z = ground_dir.z * SPEED
		elif direction == Vector3.ZERO:
			velocity.x = move_toward(velocity.x, 0.0, 10.0)
			velocity.z = move_toward(velocity.z, 0.0, 10.0)
	# falling movement state logic
	elif player_state == player_states.FALLING:
		if player_move_input_enabled and direction != Vector3.ZERO:
			var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
			var current_speed = horizontal_velocity.length()
			var desired_dir = Vector3(direction.x, 0, direction.z).normalized()
			var desired_horizontal: Vector3 = desired_dir * SPEED
			# If already moving at or above SPEED in the input direction, preserve speed instead of clamping down
			if current_speed >= SPEED and horizontal_velocity.dot(desired_horizontal) > 0.0:
				desired_horizontal = desired_dir * current_speed
			# Constant horizontal acceleration toward desired_horizontal
			var accel_step: float = AIR_ACCELERATION * delta
			var new_horizontal = horizontal_velocity.move_toward(desired_horizontal, accel_step)
			velocity.x = new_horizontal.x
			velocity.z = new_horizontal.z
		elif direction == Vector3.ZERO:
			# Constant horizontal deceleration toward zero
			var decel_step: float = Aerial_Slowdown * delta
			velocity.x = move_toward(velocity.x, 0.0, decel_step)
			velocity.z = move_toward(velocity.z, 0.0, decel_step)
	# wall sliding state logic
	elif player_state == player_states.WALL_SLIDING:
		# Horizontal control while wall sliding can reuse falling logic via input,
		# but the slower gravity (applied above) keeps vertical speed in check.
		if player_move_input_enabled and direction != Vector3.ZERO:
			var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
			var current_speed = horizontal_velocity.length()
			var desired_dir = Vector3(direction.x, 0, direction.z).normalized()
			var desired_horizontal: Vector3 = desired_dir * SPEED
			if current_speed >= SPEED and horizontal_velocity.dot(desired_horizontal) > 0.0:
				desired_horizontal = desired_dir * current_speed
			# Constant horizontal acceleration toward desired_horizontal while wall sliding
			var wall_accel_step: float = AIR_ACCELERATION * delta
			var new_horizontal = horizontal_velocity.move_toward(desired_horizontal, wall_accel_step)
			velocity.x = new_horizontal.x
			velocity.z = new_horizontal.z
		elif direction == Vector3.ZERO:
			# Constant horizontal deceleration toward zero while wall sliding
			var wall_decel_step: float = Aerial_Slowdown * delta
			velocity.x = move_toward(velocity.x, 0.0, wall_decel_step)
			velocity.z = move_toward(velocity.z, 0.0, wall_decel_step)
	# reeling state logic
	elif player_state == player_states.REELINGTO:
		# Continually set the player's velocity to move towards the grapple target
		var dir:Vector3 = (grapple_arm.hooked_target.global_position - camera_3d.global_position).normalized()
		velocity = dir * grapple_pull_speed
	# sliding state logic
	elif player_state == player_states.SLIDING:
		# allows free control of slide direction
		if free_slide_enabled:
			var input_dir = Input.get_vector("left", "right", "forward", "back")
			if input_dir == Vector2.ZERO:
				# No movement keys pressed: slide forward relative to camera
				var forward = -global_transform.basis.z.normalized()
				velocity.x = forward.x * SPEED * slide_speed_multiplier
				velocity.z = forward.z * SPEED * slide_speed_multiplier
			else:
				# Movement keys pressed: slide in input direction relative to player
				var slide_dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
				velocity.x = slide_dir.x * SPEED * slide_speed_multiplier
				velocity.z = slide_dir.z * SPEED * slide_speed_multiplier
		# only allows direction of slide to be set on activation
		elif not free_slide_enabled:
			var forward_direction = -transform.basis.z
			var horizontal_direction = Vector3(velocity.x, 0, velocity.z)
			# if player is not moving, slide forwards
			if horizontal_direction.length() == 0:
				velocity = forward_direction * SPEED * slide_speed_multiplier
			else:
				var direction = velocity.normalized()
				velocity = direction * SPEED * slide_speed_multiplier
	# dashing state logic
	elif player_state == player_states.DASHING:
		# keeps the player from falling or rising mid dash
		global_position.y = global_position.y
	# slamming state logic
	elif player_state == player_states.SLAMMING:
		# velocity was set from beginning, so no changes are made
		pass # see set_player_state()


# camera control by mouse input relative to last frame
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and player_look_input_enabled:
		var mouse_delta: Vector2 = event.relative
		var yaw: float = -mouse_delta.x
		var pitch: float = -mouse_delta.y
		player.rotate_y(deg_to_rad(look_sensitivity * yaw))
		pivot.rotate_x(deg_to_rad(look_sensitivity * pitch))
		pivot.rotation_degrees.x = clamp(
			pivot.rotation_degrees.x,
			camera_3d.get_min_pitch_deg(),
			camera_3d.get_max_pitch_deg()
		)

	# Input map actions: physical events (key, joypad, mouse) or InputEventAction from Input.parse_input_event().
	# Godot does not emit InputEventAction for normal keypresses; those arrive as InputEventKey etc.
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion or event is InputEventMouseButton or event is InputEventAction:
		if awaiting_death_input:
			pass
		
		if event.is_action_pressed("switch arm") and not event.is_echo() and player_arm_switch_input_enabled:
			if arm_state == arm_states.GRAPPLEARM:
				set_arm_state(arm_states.PARRYARM)
			elif arm_state == arm_states.PARRYARM:
				set_arm_state(arm_states.GRAPPLEARM)

		# handle grapple activation
		if event.is_action_pressed("arm action") and not event.is_echo() and player_arm_action_input_enabled:
			if arm_state == arm_states.GRAPPLEARM:
				if not grapple_rope_mesh_gen == null:
					if action_state != action_states.GRAPPLING:
						set_action_state(action_states.GRAPPLING)
					elif action_state == action_states.GRAPPLING and player_state != player_states.REELINGTO:
						set_action_state(action_states.IDLE)
				else:
					assert(false, "Grapple disabled due to lack of mesh generator. Be sure to add one to the scene to enable grapple hook rope generation.")

			elif arm_state == arm_states.PARRYARM:
				if parry_input_allowed:
					parry_arm_animator.play("swing arm initial")

		# on slide | slam pressed
		if event.is_action_pressed("Slide | Slam") and not event.is_echo() and is_on_floor() and player_slide_slam_input_enabled:
			set_player_state(player_states.SLIDING)
		elif event.is_action_pressed("Slide | Slam") and not event.is_echo() and not is_on_floor() and player_slide_slam_input_enabled:
			#set_player_state(player_states.SLAMMING)
			Debug.log("Slamming is currently disabled due to being terrible. Replacement is WIP.")

		# on slide | slam released do state check
		if event.is_action_released("Slide | Slam") and player_state == player_states.SLIDING:
			if player_state == player_states.REELINGTO:
				pass
			else:
				set_player_state(player_states.GROUNDED)

		if event.is_action_pressed("dash") and not event.is_echo() and player_dash_input_enabled and STAMINA >= 100:
			# Determine dash direction for camera effects based on input:
			# - If there is no movement input, use forward direction (default forward dash)
			# - Otherwise, use the current input direction relative to the player
			var dash_input: Vector2 = Input.get_vector("left", "right", "forward", "back")
			if dash_input == Vector2.ZERO:
				var forward_dir: Vector3 = -transform.basis.z
				dash_dir = forward_dir.normalized()
			else:
				var local_dash: Vector3 = Vector3(dash_input.x, 0.0, dash_input.y)
				dash_dir = (transform.basis * local_dash).normalized()

			set_player_state(player_states.DASHING)


func setHealth(new_health:float = HEALTH) -> void:
	new_health = clampf(new_health, 0.0, 100.0)
	var previous_health:float = HEALTH
	HEALTH = new_health
	var health_increased:bool = new_health > previous_health
	var health_decreased:bool = new_health < previous_health
	
	if health_increased:
		if not can_be_healed:
			return
	elif health_decreased:
		if not can_be_damaged:
			return
		# make screen flash red by instancing a VFX scene. It will be automatically freed when done.
		var hurt_rect:Control = hurt_rect_SCENE.instantiate()
		get_tree().current_scene.add_child(hurt_rect)
		hurt_rect.name = "HurtRect"
		assert(get_tree().current_scene.has_node("HurtRect"))
	elif previous_health == new_health:
		pass # health unchanged

	if new_health <= 0.0 and player_state != player_states.DEAD:
		set_player_state(player_states.DEAD)


func setInCombat(new_state:bool) -> void:
	if in_combat == new_state:
		return
	var previous_in_combat:bool = in_combat
	in_combat = new_state
	in_combat_changed.emit(in_combat, previous_in_combat)


## Returns true if [param targ] is in the line of sight from the player's camera.
## Note that this does not account for the target being in the player's field of view.
func losQuery(targ:Vector3, stop_on_enemies:bool, stop_on_world:bool) -> bool:
	var line_of_sight_clear:bool = false
	line_of_sight_clear = los_query.queryHasLineOfSight(camera_3d.global_position, targ, false, stop_on_enemies, stop_on_world)
	return line_of_sight_clear


## Disables firing for all weapons possesed by the player.
func deactivateWeapons() -> void:
	for weapon_state:PlayerWeapon in weapon_states:
		if weapon_state:
			weapon_state.can_fire = false


## Enables firing for all weapons possesed by the player.
func activateWeapons() -> void:
	for weapon_state:PlayerWeapon in weapon_states:
		if weapon_state:
			weapon_state.can_fire = true


func chargeStamina(delta=get_process_delta_time()):
	if stamina_recharging:
		STAMINA = move_toward(STAMINA, 300.0, stamina_charge_speed * delta)


## Will check if there is a valid parry target and parry it if so.
func parryTargetInBox():
	# If it hits something in the box and it is parriable
	if parry_target != null and parry_target.parriable == true:
		parry_arm_animator.play("swing arm parry")
		var raycast_target_body:Node = punch_raycast.get_collider()
		var raycast_target_location:Vector3 = punch_raycast.get_collision_point()
		var parry_visuals:Array[Node] = get_tree().get_nodes_in_group("parry visuals")
		for node:Node in parry_visuals:
			if node == parry_flash:
				parry_flash.visible = true
				parry_flash.top_level = true
			else:
				node.visible = true
		# If the raycast does not detect a body, set the target location to the distant camera marker
		# This ensures any parried projectiles will fly away from the player and not in a
		# random direction.
		if raycast_target_body == null:
			raycast_target_location = distant_marker.global_position
		# Hitstop regardless of what body was parried.
		hitStop(hitstop_duration)
		# Prevent the player from beginning another parry while hitstopped
		parry_input_allowed = false
		
		# Special cases in for different parriable things.
		if parry_target is EnemyProjectile:
			setHealth(HEALTH + parry_heal_amount)
			parry_target.has_been_parried = true
			if parry_target is EnergyBall:
				parry_target.linear_velocity = Vector3.ZERO
				parry_target.linear_velocity = (raycast_target_location - parry_target.global_position).normalized() * (parry_target.travel_speed * parry_projectile_speed_boost)
		
		elif parry_target is PistolBomb:
			parry_target.parried.emit()
			# If it hits something
			if punch_raycast.get_collider() != null:
				var pistolbomb_trail:BulletTrail = bullet_trail_SCENE.instantiate()
				get_tree().current_scene.add_child(pistolbomb_trail)
				var point:Vector3 = punch_raycast.get_collision_point() # the point to stick to
				pistolbomb_trail.setup(parry_target.global_position, point, Color.RED)
				var hit_body = punch_raycast.get_collider() # the body the raycast hit
				
				# If that something is an enemy
				if hit_body is Enemy:
					parry_target.stickTo(hit_body, point)
				elif not hit_body is Enemy:
					parry_target.stickTo(hit_body, point)
			# if it misses (the ray cast body returns null)
			else:
				parry_target.queue_free()
		
		elif parry_target is Enemy:
			parry_target.parried.emit()
		
	# If no valid target was found in the box
	elif parry_target == null:
		parry_arm_animator.play("swing arm miss")

	elif parry_target != null and parry_target.parriable == false:
		parry_arm_animator.play("swing arm miss")


## Returns the combined rotation of the player's camera and the player's body. This
## corresponds to the combined vector of where they are looking.
func getFacingRot() -> Vector2:
	var cam_global_rot_x:float = camera_3d.global_rotation.x
	var player_global_rot_y:float = global_rotation.y
	var combined_global_rot = Vector2(cam_global_rot_x, player_global_rot_y)
	return combined_global_rot


## Returns the point that a 5000 meter long raycast originating from the player's
## central camera zone collides with. Raycast only collides with the world.
func getFacingPoint() -> Vector3:
	var long_point_getter: RayCast3D = $Pivot/Camera3D/LongPointGetter
	if long_point_getter.get_collider() != null:
		var ret:Vector3 = long_point_getter.get_collision_point()
		return ret
	return Vector3.ZERO


## Disables the firing of all weapons and sets the timescale to zero for [param hitstop_duration_time]
func hitStop(hitstop_duration_time:float):
	TimeFlowSystem.interruptTimeflow(hitstop_duration_time, Callable(self, &"_on_hitstop_end"))
	deactivateWeapons()


## This callback is called after the hitstop ends.
func _on_hitstop_end() -> void:
	activateWeapons()
	parry_input_allowed = true
	var parry_visuals:Array[Node] = get_tree().get_nodes_in_group("parry visuals")
	for node:Node in parry_visuals:
		if node == parry_flash:
			parry_flash.visible = false
			parry_flash.top_level = false
			parry_flash.global_position = parry_flash_go_back_marker.global_position
		else:
			node.visible = false


## Get's the player's predicted position at [code]time[/code] seconds, assuming velocity
## will remain constant. Cane be used for enemy aim prediction. Returns in the global
## coordinate system.
func getPredictedPos(time:float) -> Vector3:
	var a:Vector3 = velocity * time
	var r:Vector3 = a + global_position
	return r


## Get's the player camera's predicted position at [code]time[/code] seconds, assuming velocity
## will remain constant. Cane be used for enemy aim prediction. Returns in the global
## coordinate system.
func getCameraPredictedPos(time:float) -> Vector3:
	var a:Vector3 = velocity * time
	var r:Vector3 = a + camera_3d.global_position
	return r


func getHookedTarget() -> Node3D:
	return grapple_arm.hooked_target


## Applies a single force to the player in a direction.
func applyForceImpulse(force:float, dir:Vector3) -> void:
	if not dir.is_normalized():
		dir = dir.normalized()
	velocity += force * dir


## Zeros the player's velocity and returns what it was before it was killed.
func killVelocity() -> Vector3:
	var ret:Vector3 = velocity
	velocity = Vector3.ZERO
	return ret


func _initializeStamina() -> void:
	hud.stamina_bar.max_value = 300.0
	hud.stamina_bar.progress = 300.0


func _on_dash_length_timer_timeout() -> void:
	if player_state != player_states.REELINGTO:
		if is_on_floor():
			set_player_state(player_states.GROUNDED)
		elif not is_on_floor():
			set_player_state(player_states.FALLING)


func _on_stamina_charge_delay_timer_timeout() -> void:
	stamina_recharging = true


# when enemy touches player on grapple, kill player velocity and apply hop if on floor
func _on_grapple_enemy_cease_area_body_entered(body:Enemy) -> void:
	if body == grapple_target:
		pass # set the grapple state to idle


#region Parry Hitbox entry and exit
func _on_parry_hitbox_body_entered(body: Node3D) -> void:
	if body is EnemyProjectile and body.parriable and parry_target == null:
		parry_target = body
	elif body is Enemy and parry_target == null:
		parry_target = body
	elif body is PistolBomb and body.parriable and parry_target == null and not body.has_been_parried:
		parry_target = body


func _on_parry_hitbox_body_exited(body: Node3D) -> void:
	if body == parry_target:
		parry_target = null


#endregion


## Primary logic for beginning grapple interactions goes here. State machines handle maintaining grapple connection and physics.
func _on_grapple_arm_new_hooked_target_set(previous_hooked_target: Node3D, new_hooked_target: Node3D) -> void:
	if new_hooked_target is GrappleCubeBoost:
		set_player_state(player_states.REELINGTO)

	elif new_hooked_target is Enemy:
		# Cause the enemy to emit the grappled signal.
		new_hooked_target.emit_signal("on_grappled")
		if new_hooked_target.weight == Enemy.weight_class.HEAVY:
			set_player_state(player_states.REELINGTO)
		elif new_hooked_target.weight == Enemy.weight_class.LIGHT:
			Debug.log("Placeholder: Light enemy hooked")

	elif new_hooked_target == null:
		if is_on_floor():
			set_player_state(player_states.GROUNDED)
		elif not is_on_floor():
			set_player_state(player_states.FALLING)
