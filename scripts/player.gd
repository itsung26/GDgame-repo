@icon("res://assets/2d assets/ui/icons generic/plr.png")
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

@onready var player: CharacterBody3D = $"."
@onready var camera_3d: Camera3D = %Camera3D
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
@onready var hud: HudGui = $"../HUD"
@onready var grapple_target: Node3D = $"../GrappleTarget"
@onready var grapple_arm: Node3D = $Pivot/Camera3D/GrappleArm
@onready var grapple_direction_getter: RayCast3D = $Pivot/Camera3D/GrappleDirectionGetter
@onready var grapple_hook: RigidBody3D = $Pivot/Camera3D/GrappleArm/grappleArm/whiplash_ARM/Skeleton3D/rope_origin/hook
@onready var grapple_timer: Timer = $GrappleTimer
@onready var cam_shake_timer: Timer = $CamShakeTimer
@onready var slide_particles: Node3D = $SlideParticles
@onready var sliding_marker: Marker3D = $CameraMarkerPositions/SlidingMarker
@onready var head_marker: Marker3D = $CameraMarkerPositions/HeadMarker
@onready var wind_rings: GPUParticles3D = $Pivot/Camera3D/WindRings
@onready var dash_length_timer: Timer = $DashLengthTimer
@onready var stamina_charge_delay_timer: Timer = $StaminaChargeDelayTimer
@onready var tail_marker: Marker3D = $Pivot/Camera3D/GrappleArm/grappleArm/whiplash_ARM/Skeleton3D/rope_origin/hook/TailMarker
@onready var grapple_hook_smaller_collider: CollisionShape3D = %"grapple hook smaller collider"
@onready var parry_arm: Node3D = $Pivot/Camera3D/ParryArm
@onready var parry_arm_animator: AnimationPlayer = $"Pivot/Camera3D/ParryArm/parry arm/AnimationPlayer"
@onready var hitstop_timer: Timer = $HitstopTimer
@onready var parry_target_get_ray_cast: RayCast3D = $Pivot/Camera3D/ParryArm/ParryTargetGetRayCast
@onready var distant_marker: Marker3D = $Pivot/Camera3D/distantMarker

const grapple_rope_mesh_gen_SCENE = preload("res://scenes/grapple_rope_meshGen.tscn")
var grapple_rope_mesh_gen:ropeMeshGenerator
const LaserGenerator_SCENE = preload("res://scenes/laser_generator.tscn")


@export_category("Input Allowments")
@export var player_move_input_enabled:bool = true
@export var player_look_input_enabled:bool = true
@export var player_fire_input_enabled:bool = true
@export var player_dash_input_enabled:bool = true
@export var player_arm_action_enabled:bool = true
@export var weapon_switch_enabled:bool = true
@export var player_slide_slam_input_enabled:bool = true
var stamina_recharging:bool = true

@export_category("Physics Compute")
## If [code]true[/code], compute physics for velocity on the XZ plane.
## This can be used to prevent the player from moving, but still alowing the player to fall.
@export var player_kinematics_enabled_xz:bool = true
## If [code]true[/code], compute physics for velocity on the Y axis (up and down).
## This can be useful for freezing the player in the air.
@export var player_kinematics_enabled_y:bool = true

@export_category("Main Attributes")
@export var Godmode:bool = false
@export var HEALTH:float = 100
@export var STAMINA:float = 300
## Delay after dash before stamina before stamina begins to recharge in seconds.
@export var stamina_charge_delay:float = 1.0 # seconds
## Speed at which the stamina charges.
@export var stamina_charge_speed:float = 100.0
@export var inital_arm:arm_states = arm_states.GRAPPLEARM

@export_category("Camera")
@export var camera_roll_enabled:bool = true
@export var max_camera_roll: float = 3.25 # degrees, adjust as desired
@export var camera_roll_speed: float = 20.0 # how quickly the camera rolls

@export_category("Movement")
@export var SPEED = 12.0
@export var JUMP_VELOCITY = 8.0
@export var look_sensitivity = 0.1
@export var gravity_enabled = true
## How much the player is slowed down passively in the air when not moving.
@export var Aerial_Slowdown := 0.0
## How quickly the player is able to accelerate/deccelerate in the air.
@export var AIR_ACCELERATION := 6.0
## The amount that base speed is multiplied with for the slide speed.
@export var slide_speed_multiplier := 2.0
## How much velocity the dash applies.
@export var dash_velocity_increase := 5.0
## Amount of time that the dash velocity is applied for
@export var dash_time_length := 0.5
## The velocity applied in the negative y direction. Should remain constant.
@export var slam_velocity := 35.0

@export_category("Grappling Hook")
@export var Grapple_Enabled:= true
@export var GRAPPLE_SPEED_MAX = 20
@export var grapple_pull_speed:float = 10
## The amount of upward velocity that is added to the player after beginning to pull the grapple on an enemy
@export var grapple_hop:float = 1.0

@export_category("Black Hole Launcher")
@export var BLL_MAGSIZE := 3
var BLL_AMMO := BLL_MAGSIZE
@export var black_hole_damage_per_frame := 1
@export var BLL_projectile_travel_speed := 300.0
## How violently entities are pulled to the center of the black hole in m/s.
@export var BLL_pull_speed := 10

@export_category("Parrying")
@export var parry_target:Node3D
@export var hitstop_duration:float = 0.25
## The factor that projectile's speed is multiplied with after being parried.
@export var parry_projectile_speed_boost:float = 1.0

@export_category("Extras")
## This enables the ability to freely control the slide direction. Largley overpowered and intended as a cheat/extra feature.
@export var free_slide_enabled := false

#region State Machine initializers
## 4 seperate FSMs (finite state machines) to replace conditional trees.
##
## Player states. These states affect the player's kinematics. 
## Associated state variable of type [code]player_states[/code]: [code]player_state[/code]
enum player_states{GROUNDED, DEAD, FALLING, REELINGTO, SLIDING, DASHING, SLAMMING}
var player_state:player_states = player_states.GROUNDED:
	set = set_player_state

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
@onready var weapon_state:PlayerWeapon:
	set = set_weapon_state

## Arm states. These states affect which arm is currently active. Associated state variable of type [code]arm_states[/code]: [code]arm_state[/code]
enum arm_states{GRAPPLEARM, PARRYARM}
var arm_state:arm_states = arm_states.GRAPPLEARM:
	set = set_arm_state

## WIP. Currently only represents the grapple hook's state.
enum action_states{IDLE, GRAPPLING, PARRYING, REELINGFROM}
var action_state:action_states = action_states.IDLE:
	set = set_action_state
#endregion


# Signals for corresponding FSMs.
## Emitted when the [code]player_state[/code] changes.
signal entered_player_state(new_player_state:player_states, previous_player_state:player_states)
signal entered_arm_state(new_arm_state:arm_states, previous_arm_state:arm_states)
signal entered_action_state(new_action_state:action_states, previous_action_state:action_states)



# Weapon refrences
@onready var pistol: PlayerPistol = $Pivot/Camera3D/Guns/Pistol
@onready var melee: Melee = $Pivot/Camera3D/Guns/Melee

var storagevar = JUMP_VELOCITY
var mouse_delta2 : Vector2
var pistol_damage_increase:bool = false
var death_animator
var cause_of_death
var black_hole_time_remaining
var black_hole_cooldown_timer
var prev_jump_velocity = JUMP_VELOCITY
var weapon_anim_playing
var direction
var input_dir := Vector2.ZERO
var camera_target_roll: float = 0.0
var current_weapon_string_name:String = "null state"
var current_player_string_name:String = "null state"
var current_action_string_name:String = "null state"
var rope_origin
var skeleton
var impact_particles_scene = preload("res://scenes/impact_particles.tscn")
var doing_shake = false
var reel_vector:Vector3
var impact_particles:GPUParticles3D
var impact_sparks:GPUParticles3D
var impact_sparks_2:GPUParticles3D
var slide_light:OmniLight3D
var pause:Control
var dash_dir:Vector3
var hooked_target:Object = null
var hooked_target_pull_origin:Object = null

# called when the player is loaded into the scene.
# Player should be loaded after main enviroment and global lighting, but before 
# map and everything else.
func _ready() -> void:
	
	# object reference definitions (needs to be moved)
	pause = get_tree().current_scene.find_child("Pause")
	slide_light = slide_particles.get_node("ImpactParticles/OmniLight3D")
	impact_particles = slide_particles.get_node("ImpactParticles")
	impact_sparks = slide_particles.get_node("ImpactParticles/SparkTrailsSide/ImpactSparks")
	impact_sparks_2 = slide_particles.get_node("ImpactParticles/SparkTrailsSide/ImpactSparks2")
	skeleton = grapple_arm.get_node("grappleArm/whiplash_ARM/Skeleton3D")
	rope_origin = skeleton.get_node("rope_origin")
	black_hole_cooldown_timer = get_tree().current_scene.find_child("BlackHoleCooldownTimer")
	death_animator = get_node("../DeathScreen/DeathAnimator")

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
		
	weapon_state = initial_weapon

func set_player_state(new_player_state:int):
	# init vars
	var previous_player_state := player_state
	player_state = new_player_state
	
	# Emit signal
	entered_player_state.emit(new_player_state, previous_player_state)
	
	if previous_player_state == new_player_state:
		print("WARNING: Player entered a new state matching it's own. This is allowed, but may cause state machine override problems.")
	
	# death to and from
	if new_player_state == player_states.DEAD:
		pass
		
	# REELINGTO to and from
	if new_player_state == player_states.REELINGTO:
		camera_animator.play("camera_overclock_zoom_out")
	if previous_player_state == player_states.REELINGTO:
		camera_animator.play("camera_overclock_zoom_in")
		
	# SLIDING to and from
	if new_player_state == player_states.SLIDING:
		pivot.position = sliding_marker.position
		# Clamp after moving
		pivot.rotation_degrees.x = clamp(pivot.rotation_degrees.x, -90.0, 90.0)
		impact_particles.emitting = true
		impact_sparks.emitting = true
		impact_sparks_2.emitting = true
		slide_light.visible = true
	if previous_player_state == player_states.SLIDING:
		pivot.position = head_marker.position
		# Clamp after moving
		pivot.rotation_degrees.x = clamp(pivot.rotation_degrees.x, -90.0, 90.0)
		impact_particles.emitting = false
		impact_sparks.emitting = false
		impact_sparks_2.emitting = false
		slide_light.visible = false
		
	# DASHING to and from
	if new_player_state == player_states.DASHING:
		stamina_recharging = false
		stamina_charge_delay_timer.start(stamina_charge_delay)
		STAMINA -= 100
		# cancels grapple if it is active
		if action_state == action_states.GRAPPLING:
			action_state = action_states.IDLE
		# disables gravity
		gravity_enabled = false
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
		velocity = Vector3.ZERO
		gravity_enabled = true
	
	# SLAMMING to and from
	if new_player_state == player_states.SLAMMING:
		action_state = action_states.IDLE
		gravity_enabled = false
		velocity = Vector3.ZERO # kill velocity
		velocity.y = -slam_velocity # slam down
		camera_roll_enabled = false
	if previous_player_state == player_states.SLAMMING:
		gravity_enabled = true
		camera_roll_enabled = true
	
func set_weapon_state(new_weapon_state:PlayerWeapon):
	var previous_weapon_state:PlayerWeapon = weapon_state
	weapon_state = new_weapon_state
	
	# makes the previous weapon invisible and the new weapon visible
	if previous_weapon_state != null:
		previous_weapon_state.visible = false
	new_weapon_state.visible = true
	
	# calls the equip logic on the weapon that is being equipped
	new_weapon_state._onEquip()
		
func set_action_state(new_action_state:int):
	# init vars
	var previous_action_state := action_state
	action_state = new_action_state
	
	# Emit signal
	entered_action_state.emit(new_action_state, previous_action_state)
	
	# grappling to and from
	if new_action_state == action_states.GRAPPLING and Grapple_Enabled:
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
		grapple_rope_mesh_gen.visible = false
		grapple_hook.freeze = true
		grapple_hook.reparent(rope_origin) # reparent and set it to face how it did before
		grapple_hook.position = Vector3(-0.069, 0.252, 0.043)
		grapple_hook.rotation = Vector3(deg_to_rad(81.1), deg_to_rad(86.5), deg_to_rad(83.3))
		grapple_hook.scale = Vector3(1.0, 1.0, 1.0)
		$Pivot/Camera3D/GrappleArm/grappleArm/grapple_arm_animator.play("grapple_rebound")
		
	# IDLE to and from
	if new_action_state == action_states.IDLE:
		grapple_hook_smaller_collider.disabled = true
	if previous_action_state == action_states.IDLE:
		grapple_hook_smaller_collider.disabled = false

		
	# reelingfrom (pulling) to and from
	if new_action_state == action_states.REELINGFROM:
		print("reeling to player")

func set_arm_state(new_arm_state:int):
	# init vars
	var previous_arm_state := arm_state
	arm_state = new_arm_state
	
	entered_arm_state.emit(new_arm_state, previous_arm_state)
	
	# GRAPPLEARM to and from
	if new_arm_state == arm_states.GRAPPLEARM:
		grapple_arm.visible = true
	if previous_arm_state == arm_states.GRAPPLEARM:
		grapple_arm.visible = false
		# on leaving the grapple arm state, grapple go back to idle if currently busy
		if action_state == action_states.GRAPPLING:
			set_action_state(action_states.IDLE)
		elif action_state == action_states.REELINGFROM:
			set_action_state(action_states.IDLE)
	
	# PARRYARM to and from
	if new_arm_state == arm_states.PARRYARM:
		parry_arm.visible = true
	if previous_arm_state == arm_states.PARRYARM:
		parry_arm.visible = false
	
			

# camera control by mouse input relative to last frame
func _input(event) -> void:
	
	if Input.is_action_just_pressed("switch arm"):
		if arm_state == arm_states.GRAPPLEARM:
			set_arm_state(arm_states.PARRYARM)
		elif arm_state == arm_states.PARRYARM:
			set_arm_state(arm_states.GRAPPLEARM)
	
	# handle grapple activation
	if Input.is_action_just_pressed("arm action") and player_arm_action_enabled:
		
		if arm_state == arm_states.GRAPPLEARM:
			if not grapple_rope_mesh_gen == null:
				if action_state != action_states.GRAPPLING:
					action_state = action_states.GRAPPLING
				elif action_state == action_states.GRAPPLING and player_state != player_states.REELINGTO:
					action_state = action_states.IDLE
			else:
				print("Grapple disabled due to lack of mesh generator. Be sure to add one to the scene to enable grapple hook rope generation.")
		elif arm_state == arm_states.PARRYARM:
			parry_arm_animator.play("swing arm initial")
			
	# on slide | slam pressed
	if Input.is_action_just_pressed("Slide | Slam") and is_on_floor() and player_slide_slam_input_enabled:
		player_state = player_states.SLIDING
	elif Input.is_action_just_pressed("Slide | Slam") and not is_on_floor() and player_slide_slam_input_enabled:
		player_state = player_states.SLAMMING

	# on slide | slam released do state check
	if Input.is_action_just_released("Slide | Slam") and player_state == player_states.SLIDING:
		if player_state == player_states.REELINGTO:
			pass
		else:
			player_state = player_states.GROUNDED
	
	if Input.is_action_just_pressed("dash") and player_dash_input_enabled and STAMINA >= 100:
		dash_dir = Vector3(velocity.x, 0, velocity.z).normalized()
		if not player_state == player_states.DASHING: # if player is not already dashing
			player_state = player_states.DASHING
	
	
	# handle mouselook
	if event is InputEventMouseMotion and player_look_input_enabled:
		mouse_delta2 = event.relative
		var mouse_delta = event.relative
		var yaw = -mouse_delta.x
		var pitch = -mouse_delta.y
		player.rotate_y(deg_to_rad(look_sensitivity * yaw))
		pivot.rotate_x(deg_to_rad(look_sensitivity * pitch))
		
func damagePlayer(damage:float, death_cause:String = "Unknown"):
	var previous_health:float = HEALTH
	var new_health:float = HEALTH - damage
	
	cause_of_death = death_cause
	
	if not Godmode:
		HEALTH = new_health

func cameraFX(delta):
	if camera_roll_enabled:
		# Set target roll based on left/right input
		if input_dir.x > 0:
			camera_target_roll = -max_camera_roll # rolling right (negative z)
		elif input_dir.x < 0:
			camera_target_roll = max_camera_roll  # rolling left (positive z)
		else:
			camera_target_roll = 0.0
	else:
		camera_target_roll = 0.0

	# Smoothly interpolate the camera roll
	camera_3d.rotation.z = lerp_angle(camera_3d.rotation.z, deg_to_rad(camera_target_roll), camera_roll_speed * delta)

	# clamp the camera view to prevent back breaking
	pivot.rotation_degrees.x = clamp(pivot.rotation_degrees.x, -90.0, 90.0)

# called when overclock ends
func zoomIn():
	camera_animator.play("camera_overclock_zoom_in")
	SPEED = SPEED / 2
	JUMP_VELOCITY = prev_jump_velocity
	gun_animator.speed_scale = 1.5
	pistol_damage_increase = false

# called when overclock begins
func zoomOut():
	camera_animator.play("camera_overclock_zoom_out")
	SPEED = SPEED * 2
	JUMP_VELOCITY = JUMP_VELOCITY * 1.5
	gun_animator.speed_scale = 3
	pistol_damage_increase = true


## This method performs the primary computations for kinematics based on which state player_state is in.
func physicsStateLogic(delta=get_physics_process_delta_time()):
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
			var desired = direction * SPEED
			var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
			var new_horizontal = horizontal_velocity.lerp(Vector3(desired.x, 0, desired.z), AIR_ACCELERATION * delta)
			velocity.x = new_horizontal.x
			velocity.z = new_horizontal.z
		elif direction == Vector3.ZERO:
			velocity.x = lerp(velocity.x, 0.0, Aerial_Slowdown * delta)
			velocity.z = lerp(velocity.z, 0.0, Aerial_Slowdown * delta)
	# reeling state logic
	elif player_state == player_states.REELINGTO:
		velocity = reel_vector
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
		pass # see set_player_state()
	# slamming state logic
	elif player_state == player_states.SLAMMING:
		# velocity was set from beginning, so no changes are made
		pass # see set_player_state()

# Called every physics frame. FPS: 120
func _physics_process(delta: float) -> void:
	
	cameraFX(delta) # roll, tilt, clamp
	
	# state control
	if (is_on_floor() and 
	player_state != player_states.REELINGTO and 
	player_state != player_states.SLIDING and 
	player_state != player_states.DASHING and
	player_state != player_states.GROUNDED):
		player_state = player_states.GROUNDED

	elif (not is_on_floor() and 
	player_state != player_states.REELINGTO and 
	player_state != player_states.DASHING and 
	player_state != player_states.SLAMMING and 
	player_state != player_states.FALLING):
		player_state = player_states.FALLING
	
	# Add the gravity 
	if not is_on_floor() and gravity_enabled:
		velocity += get_gravity() * delta
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y += JUMP_VELOCITY
	
	# Get the input direction and handle the movement/deceleration.
	input_dir = Input.get_vector("left", "right", "forward", "back")
	direction = Vector3(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# run all state machine related physics logic every physics frame
	physicsStateLogic()

	# if kinematics are not enabled, kill all velocity before computing physics
	if not player_kinematics_enabled_xz:
		velocity.x = 0.0
		velocity.z = 0.0
	if not player_kinematics_enabled_y:
		velocity.y = 0.0
	move_and_slide()

func gunInputs(): # to be called in a method that can "hear" inputs
	# switch weapon block==================================================================================
	if Input.is_action_just_pressed("slot1") and weapon_state != weapon_states[0] and weapon_switch_enabled:
		set_weapon_state(weapon_states[0])
		
	if Input.is_action_just_pressed("slot2") and weapon_state != weapon_states[1] and weapon_switch_enabled:
		set_weapon_state(weapon_states[1])
	
	
	# automatic fire block===================================================================================
	if Input.is_action_pressed("fire") and player_fire_input_enabled and weapon_state.automatic:
		# use seperate animation players for each weapon
		weapon_state._fire()
	# semi-automatic fire block========================================================================
	if Input.is_action_just_pressed("fire") and player_fire_input_enabled and not weapon_state.automatic:
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
	# ======================================================================================================

func charge_stamina(delta=get_process_delta_time()):
	if stamina_recharging:
		STAMINA = move_toward(STAMINA, 300.0, stamina_charge_speed * delta)

func processTargetPull(delta=get_process_delta_time()):
	if hooked_target:
		# Get the vector from the hooked target to the player
		var target_to_player_dir: Vector3 = global_position - hooked_target.global_position
		grapple_hook.global_position = hooked_target_pull_origin.global_position
		hooked_target.velocity = target_to_player_dir.normalized() * grapple_pull_speed * delta
	else:
		pass

## Will check if there is a valid parry target and parry it if so.
func parryTargetInBox():
	if parry_target != null and parry_target.parriable == true:
		parry_arm_animator.play("swing arm parry")
		var raycast_target_body:Node = parry_target_get_ray_cast.get_collider()
		var raycast_target_location:Vector3 = parry_target_get_ray_cast.get_collision_point()
		var parry_visuals:Array[Node] = get_tree().get_nodes_in_group("parry visuals")
		for node:Node in parry_visuals:
			node.visible = true
		# If the raycast does not detect a body, set the target location to the distant camera marker
		if raycast_target_body == null:
			raycast_target_location = distant_marker.global_position
		hitStop()
		if parry_target is EnemyProjectile:
			parry_target.has_been_parried = true
			if parry_target is EnergyBall:
				parry_target.linear_velocity = Vector3.ZERO
				parry_target.linear_velocity = (raycast_target_location - parry_target.global_position).normalized() * (parry_target.travel_speed * parry_projectile_speed_boost)
	elif parry_target == null:
		parry_arm_animator.play("swing arm miss")

func hitStop():
	Engine.time_scale = 0.0
	hitstop_timer.start(hitstop_duration)

var a = true
# Called every frame. Main thread frames fluctuate around a target fps of 60.
# Kinematic-related operations should only be run in _physics_process, while logic and other operations
# should be run in _process
func _process(delta) -> void:
	print(weapon_state)
	
	grapple_rope_mesh_gen = get_tree().current_scene.get_node("grapple_rope_meshGen")
	charge_stamina()
	
	# the main process where the enemy gets drawn to the player on the hook
	if action_state != action_states.IDLE:
		processTargetPull()
	# if the hook is idle and in the holder, set it to look right and face right direction
	elif action_state == action_states.IDLE and grapple_hook.get_parent() == rope_origin:
		if grapple_rope_mesh_gen:
			grapple_rope_mesh_gen.visible = false
		grapple_hook.freeze = true
		grapple_hook.position = Vector3(-0.069, 0.252, 0.043)
		grapple_hook.rotation = Vector3(deg_to_rad(81.1), deg_to_rad(86.5), deg_to_rad(83.3))
		grapple_hook.scale = Vector3(1.0, 1.0, 1.0)
	
	# keeps the rope attatched to the grapple bit
	if grapple_rope_mesh_gen:
		grapple_rope_mesh_gen.generate_mesh_planes(rope_origin.global_position, grapple_hook.global_position)
	
	# retrn the time remaining on the current black hole cooldown animation and save as a time
	if bll_animator.current_animation == "Black Hole Launcher/BLL_cooldown":
		black_hole_time_remaining = bll_animator.current_animation_length - bll_animator.current_animation_position
		black_hole_time_remaining = black_hole_time_remaining
		if black_hole_time_remaining < 0.50:
			black_hole_time_remaining = 0.00
		var time_left = str(snappedf(black_hole_time_remaining, 0.01)) + "s"
		if black_hole_cooldown_timer:
			black_hole_cooldown_timer.text = time_left
	
	# kill the player
	if HEALTH <= 0:
		playerDie()
	
	# handle all weapon inputs, if the weapon is not null (it should never be)
	if weapon_state:
		gunInputs()
	# updates string variables with the current state for debug purposes
	updateStateStrings()

	
	
	
# updates the string variables that contain the names of the state based on the active state
func updateStateStrings():
	# update the string name of the weapon state every frame
	match weapon_state:
		pass
		
	# update the string name of the player state every frame
	match player_state:
		player_states.GROUNDED: current_player_string_name = "GROUNDED"
		player_states.DEAD: current_player_string_name = "DEAD"
		player_states.FALLING: current_player_string_name = "FALLING"
		player_states.REELINGTO: current_player_string_name = "REELINGTO"
		player_states.SLIDING: current_player_string_name = "SLIDING"
		player_states.DASHING: current_player_string_name = "DASHING"
		player_states.SLAMMING: current_player_string_name = "SLAMMING"

	# update the string name of the action every frame
	match action_state:
		action_states.IDLE: current_action_string_name = "IDLE"
		action_states.GRAPPLING: current_action_string_name = "GRAPPLING"
		action_states.PARRYING: current_action_string_name = "PARRYING"
		action_states.REELINGFROM: current_action_string_name = "REELINGFROM"

func playerDie():
	player_state = player_states.DEAD
	Engine.time_scale = 0.3

#region Grapple Hook collision detections
# when the grapple hook's smaller collider hits the world, go back to idle
# when it hits enemies, pull them towards player
func _on_world_collide_box_body_entered(body: Enemy) -> void:
	hooked_target = body
	if hooked_target:
		if hooked_target.is_in_group("enemy"):
			var enemy_hooked:Enemy = hooked_target
			hooked_target_pull_origin = enemy_hooked.grapple_origin
			
			if not is_on_floor():
				player.velocity.y = 0 + grapple_hop
			enemy_hooked.last_hit_damage_type = enemy_hooked.damage_types.NORMAL
			enemy_hooked.damageEnemy(2.0, enemy_hooked.damage_types.NORMAL)
			if enemy_hooked.weight == enemy_hooked.weight_class.LIGHT:
				grapple_hook.freeze = true
				grapple_hook.global_position = hooked_target_pull_origin.global_position
				grapple_hook.look_at(tail_marker.global_position, Vector3.UP)

## When it hits an area 3d that is not an enemy, it was world so go back to idle
func _on_world_collide_box_world_entered(body:Node):
	if not body is Enemy:
		print("hook hit world, going back to idle")
		var impact_particles = impact_particles_scene.instantiate()
		var impact_pos = grapple_hook.global_position
		var particle_look_marker = impact_particles.get_node("Marker")
		get_tree().root.add_child(impact_particles)
		impact_particles.global_position = impact_pos
		particle_look_marker.global_position = camera_3d.global_position
		action_state = action_states.IDLE

# when the hook's actual collider stops colliding with whatever it is colliding with
func _on_world_collide_box_body_exited(body: Node3D) -> void:
#endregion
	hooked_target = null

# when the unstuck button is pressed, reset the player states and go to origin
func _on_unstuck_pressed() -> void:
	player_state = player_states.GROUNDED
	action_state = action_states.IDLE
	global_position = Vector3.ZERO
	velocity = Vector3.ZERO
	player.rotation = Vector3.ZERO
	pause.pause_state = pause.pause_states.UNPAUSED


func _on_dash_length_timer_timeout() -> void:
	if player_state != player_states.REELINGTO:
		if is_on_floor():
			player_state = player_states.GROUNDED
		elif not is_on_floor():
			player_state = player_states.FALLING

func _on_stamina_charge_delay_timer_timeout() -> void:
	stamina_recharging = true

# when enemy touches player on grapple, kill player velocity and apply hop if on floor
func _on_grapple_enemy_cease_area_body_entered(hooked_target) -> void:
	if hooked_target.is_in_group("enemy"):
		if hooked_target.weight == hooked_target.weight_class.LIGHT and not is_on_floor():
			# applies the same hop affect to the hooked body
			hooked_target.velocity.x = 0
			hooked_target.velocity.z = 0
			hooked_target.velocity.y = 0 + grapple_hop
			action_state = action_states.IDLE
			player.velocity.x = 0
			player.velocity.z = 0
			player.velocity.y = 0 + grapple_hop

#region Parry Hitbox entry and exit
func _on_parry_hitbox_body_entered(body: Node3D) -> void:
	if body is EnemyProjectile and body.parriable and parry_target == null:
		parry_target = body
	elif body is Enemy and parry_target == null:
		parry_target = body


func _on_parry_hitbox_body_exited(body: Node3D) -> void:
	if body == parry_target:
		parry_target = null
#endregion


func _on_hitstop_timer_timeout() -> void:
	for node:Node in get_tree().get_nodes_in_group("parry visuals"):
		node.visible = false
	Engine.time_scale = 1.0
