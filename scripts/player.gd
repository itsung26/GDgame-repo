extends CharacterBody3D

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
@onready var hud: Control = $"../HUD"
@onready var grapple_target: Node3D = $"../GrappleTarget"
@onready var grapple_rope_mesh_gen: Node3D = $"../grapple_rope_meshGen"
@onready var grapple_arm: Node3D = $Pivot/Camera3D/GrappleArm
@onready var grapple_direction_getter: RayCast3D = $Pivot/Camera3D/GrappleDirectionGetter
@onready var grapple_hook: RigidBody3D = $Pivot/Camera3D/GrappleArm/grappleArm/whiplash_ARM/Skeleton3D/rope_origin/hook
@onready var grapple_timer: Timer = $GrappleTimer
@onready var cam_shake_timer: Timer = $CamShakeTimer
@onready var slide_particles: Node3D = $SlideParticles
@onready var sliding_marker: Marker3D = $CameraMarkerPositions/SlidingMarker
@onready var head_marker: Marker3D = $CameraMarkerPositions/HeadMarker

@export_category("Settings")
@export var HEALTH: int = 100

@export_category("Camera")
@export var max_camera_roll: float = 7.5 # degrees, adjust as desired
@export var camera_roll_speed: float = 6.5 # how quickly the camera rolls

@export_category("Movement")
@export var SPEED = 12.0
@export var JUMP_VELOCITY = 8.0
@export var look_sensitivity = 0.1
@export var gravity_enabled = true
@export var Aerial_Slowdown := 0.0

@export_category("Grappling Hook")
@export var Grapple_Enabled:= true
@export var GRAPPLE_MAX_RANGE = 50
@export var GRAPPLE_SPEED_MAX = 20

@export_category("Pistol")
@export var PISTOL_MAGSIZE:= 35
var PISTOL_AMMO := PISTOL_MAGSIZE
@export var Pistol_Damage_Range_Min := 12
@export var Pistol_Damage_Range_Max := 17
@export var Pistol_Overclock_Damage_Range_Min := 17
@export var Pistol_OverClock_Damage_Range_Max := 22

@export_category("Black Hole Launcher")
@export var BLL_MAGSIZE := 3
var BLL_AMMO := BLL_MAGSIZE
@export var black_hole_damage_per_frame := 1.0
@export var BLL_projectile_travel_speed := 300.0
@export var BLL_pull_speed := 10

# 3 seperate FSMs (finite state machines) to replace conditional trees
enum player_states{GROUNDED, DEAD, FALLING, REELINGTO, SLIDING}
enum weapon_states{MELEE, PISTOL, SHOTGUN, BLL}
enum action_states{IDLE, GRAPPLING, DASHING}

var player_state:player_states = player_states.GROUNDED:
	set = set_player_state
var weapon_state:weapon_states = weapon_states.PISTOL:
	set = set_weapon_state
var action_state:action_states = action_states.IDLE:
	set = set_action_state

var storagevar = JUMP_VELOCITY
var mouse_delta2 : Vector2
var pistol_damage_increase:bool = false
var death_animator
var cause_of_death
var cause_of_death_message
var black_hole_time_remaining
var black_hole_cooldown_timer
var prev_jump_velocity = JUMP_VELOCITY
var pistol
var weapon_anim_playing
var player_move_input_enabled = true
var player_look_input_enabled = true
var player_fire_input_enabled = true
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
var reel_vector
var impact_particles:GPUParticles3D
var impact_sparks:GPUParticles3D
var impact_sparks_2:GPUParticles3D
var slide_light:OmniLight3D

func _ready() -> void:
	# object reference definitions
	slide_light = slide_particles.get_node("ImpactParticles/OmniLight3D")
	impact_particles = slide_particles.get_node("ImpactParticles")
	impact_sparks = slide_particles.get_node("ImpactParticles/SparkTrailsSide/ImpactSparks")
	impact_sparks_2 = slide_particles.get_node("ImpactParticles/SparkTrailsSide/ImpactSparks2")
	pistol = get_node("Pivot/Camera3D/Guns/Pistol")
	skeleton = grapple_arm.get_node("grappleArm/whiplash_ARM/Skeleton3D")
	rope_origin = skeleton.get_node("rope_origin")
	black_hole_cooldown_timer = get_node("../HUD/BlackHoleCooldownIcon/BlackHoleCooldownTimer")
	death_animator = get_node("../DeathScreen/DeathAnimator")
	cause_of_death_message = get_node("../DeathScreen/VBoxContainer/CauseOfDeathMessage")

	# set the mouse to be captured by the gamewindow
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# set the grapple hook's physics process to static so it doesn't fall to the depths of hell
	grapple_hook.freeze = true
	
func set_player_state(new_player_state:int):
	# init vars
	var previous_player_state := player_state
	player_state = new_player_state
	
	# death to and from
	if new_player_state == player_states.DEAD:
		player_fire_input_enabled = false
		player_look_input_enabled = false
		player_move_input_enabled = false
		
	# REELINGTO to and from
	if new_player_state == player_states.REELINGTO:
		camera_animator.play("camera_overclock_zoom_out")
	if previous_player_state == player_states.REELINGTO:
		camera_animator.play("camera_overclock_zoom_in")
		
	# SLIDING to and from
	if new_player_state == player_states.SLIDING:
		pivot.global_position = sliding_marker.global_position
		impact_particles.emitting = true
		impact_sparks.emitting = true
		impact_sparks_2.emitting = true
		slide_light.visible = true
	if previous_player_state == player_states.SLIDING:
		pivot.global_position = head_marker.global_position
		impact_particles.emitting = false
		impact_sparks.emitting = false
		impact_sparks_2.emitting = false
		slide_light.visible = false
	
func set_weapon_state(new_weapon_state:int):
	# init vars
	var previous_weapon_state := weapon_state
	weapon_state = new_weapon_state
	
	# pistol to and from
	if new_weapon_state == weapon_states.PISTOL:
		# make visible
		arm_pivot_pistol.visible = true
		pistol.visible = true
		# if gun is not reloading, play equip anim
		if gun_animator.current_animation == "reload_pistol":
			pass
		else:
			gun_animator.stop()
			gun_animator.play("equip_pistol")
	if  previous_weapon_state == weapon_states.PISTOL:
		arm_pivot_pistol.visible = false
		pistol.visible = false
	
	# black hole launcher to and from
	if new_weapon_state == weapon_states.BLL:
		# make visible
		arm_pivot_bll.visible = true
		black_hole_launcher.visible = true
		# if gun is not on cooldown anim, play equip anim
		if bll_animator.current_animation == "Black Hole Launcher/BLL_cooldown":
			pass
		else:
			bll_animator.stop()
			bll_animator.play("Black Hole Launcher/BLL_equip")
	if previous_weapon_state == weapon_states.BLL:
		arm_pivot_bll.visible = false
		black_hole_launcher.visible = false
	
func set_action_state(new_action_state:int):
	# init vars
	var previous_action_state := action_state
	action_state = new_action_state
	
	# grapple to and from
	if new_action_state == action_states.GRAPPLING and Grapple_Enabled:
		print("state set to grapple")
		grapple_rope_mesh_gen.visible = true
		grapple_hook.reparent(get_tree().root) # reparent and face direction raycast is looking
		grapple_hook.rotation = Vector3.ZERO
		var grapple_dir = grapple_direction_getter.global_rotation
		grapple_hook.rotation = grapple_dir
		grapple_hook.freeze = false
		# Use basis to get the forward direction
		var forward = grapple_hook.global_transform.basis.z.normalized()
		grapple_hook.linear_velocity = -forward * GRAPPLE_SPEED_MAX
		grapple_timer.start()
		$Pivot/Camera3D/GrappleArm/grappleArm/grapple_arm_animator.play("grapple_out")
	if previous_action_state == action_states.GRAPPLING:
		print("state left grapple")
		grapple_rope_mesh_gen.visible = false
		grapple_hook.freeze = true
		grapple_hook.reparent(rope_origin) # reparent and set it to face how it did before
		grapple_hook.position = Vector3(-0.069, 0.252, 0.043)
		grapple_hook.rotation = Vector3(deg_to_rad(81.1), deg_to_rad(86.5), deg_to_rad(83.3))
		grapple_hook.scale = Vector3(1.0, 1.0, 1.0)
		$Pivot/Camera3D/GrappleArm/grappleArm/grapple_arm_animator.play("grapple_rebound")

# camera control by mouse input relative to last frame
func _input(event) -> void:
	# handle force-quitting
	if Input.is_action_just_pressed("forcequit"):
		get_tree().quit()
	
	# handle grapple activation
	if Input.is_action_just_pressed("grapple"):
		if action_state != action_states.GRAPPLING:
			action_state = action_states.GRAPPLING
			
	# get the slide action input for a state change
	if Input.is_action_just_pressed("slide") and is_on_floor():
		if velocity == Vector3.ZERO:
			var forward_dir = -transform.basis.z.normalized()
			velocity = forward_dir * SPEED
		player_state = player_states.SLIDING

	# on slide released do state check
	if Input.is_action_just_released("slide") and player_state == player_states.SLIDING:
		if player_state == player_states.REELINGTO:
			pass
		else:
			player_state = player_states.GROUNDED
	else:
		push_error("ERROR: expected the state to be sliding in order to go back to GROUNDED")
	
	# handle mouselook
	if event is InputEventMouseMotion and player.player_look_input_enabled:
		mouse_delta2 = event.relative
		var mouse_delta = event.relative
		var yaw = -mouse_delta.x
		var pitch = -mouse_delta.y
		player.rotate_y(deg_to_rad(look_sensitivity * yaw))
		pivot.rotate_x(deg_to_rad(look_sensitivity * pitch))
		


func cameraFX(delta):
	# Set target roll based on left/right input
	if input_dir.x > 0:
		camera_target_roll = -max_camera_roll # rolling right (negative z)
	elif input_dir.x < 0:
		camera_target_roll = max_camera_roll  # rolling left (positive z)
	else:
		camera_target_roll = 0.0

	# Smoothly interpolate the camera roll
	camera_3d.rotation.z = lerp_angle(camera_3d.rotation.z, deg_to_rad(camera_target_roll), camera_roll_speed * delta)
	
	# clamp the camera view to prevent back breaking
	var b = clamp(pivot.rotation_degrees.x, -90.0, 90.0)
	pivot.rotation_degrees.x = b

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





func _physics_process(delta: float) -> void:
	# runs main grapple logic every physics frame.
	grappleFrameLogic()
	
	cameraFX(delta) # roll, tilt, clamp
	
	# state control
	if is_on_floor() and player_state != player_states.REELINGTO and player_state != player_states.SLIDING:
		player_state = player_states.GROUNDED
	elif not is_on_floor() and player_state != player_states.REELINGTO:
		player_state = player_states.FALLING
	
	# Add the gravity 
	if not is_on_floor() and gravity_enabled:
		velocity += get_gravity() * delta
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y += JUMP_VELOCITY
	
	# Get the input direction and handle the movement/deceleration.
	input_dir = Input.get_vector("left", "right", "forward", "back")
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# movement state logic
	if player_state == player_states.GROUNDED:
		if direction and player_move_input_enabled:
			var ground_dir = direction.normalized()
			velocity.x = ground_dir.x * SPEED
			velocity.z = ground_dir.z * SPEED
		elif direction == Vector3.ZERO:
			velocity.x = move_toward(velocity.x, 0.0, 10.0)
			velocity.z = move_toward(velocity.z, 0.0, 10.0)
	
	elif player_state == player_states.FALLING:
		if direction and player_move_input_enabled:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		# Player will stop moving in the air when the movement is stopped
		elif direction == Vector3.ZERO and not is_on_floor():
			velocity.x = lerp(velocity.x, 0.0, Aerial_Slowdown * delta)
			velocity.z = lerp(velocity.z, 0.0, Aerial_Slowdown * delta)

	# reeling state logic
	elif player_state == player_states.REELINGTO:
		velocity = reel_vector

	# sliding state logic
	elif player_state == player_states.SLIDING:
		var direction = velocity.normalized()
		velocity.x = direction.x * 24
		velocity.z = direction.z * 24
		
	move_and_slide()

func gunInputs(): # run every frame in _process
	
	# switch weapon block==================================================================================
	if Input.is_action_just_pressed("slot1") and weapon_state != weapon_states.MELEE:
		weapon_state = weapon_states.MELEE
		
	if Input.is_action_just_pressed("slot2") and weapon_state != weapon_states.PISTOL:
		weapon_state = weapon_states.PISTOL
		
	if Input.is_action_just_pressed("slot3") and weapon_state != weapon_states.SHOTGUN:
		weapon_state = weapon_states.SHOTGUN
		
	if Input.is_action_just_pressed("slot4") and weapon_state != weapon_states.BLL:
		weapon_state = weapon_states.BLL
	
	# automatic fire block===================================================================================
	if Input.is_action_pressed("fire") and player_fire_input_enabled:
		# use seperate animation players for each weapon
		
		if weapon_state == weapon_states.PISTOL:
			if gun_animator.current_animation == "inspect" or gun_animator.current_animation == "equip_pistol":
				gun_animator.stop()
			elif gun_animator.current_animation == "reload_pistol":
				pass
			else:
				if PISTOL_AMMO > 0:
					gun_animator.play("fire")
				elif PISTOL_AMMO == 0: gun_animator.play("reload_pistol")

	# semi-automatic fire block========================================================================
	if Input.is_action_just_pressed("fire") and player_fire_input_enabled:
		
		if weapon_state == weapon_states.SHOTGUN:
			print("shotgun fire")
		
		elif weapon_state == weapon_states.BLL:
			if bll_animator.current_animation == "Black Hole Launcher/BLL_cooldown":
				pass
			else:
				if Global.BLL_ammo > 0:
					black_hole_launcher.bll_animator.play("Black Hole Launcher/BLL_cooldown")

	
	# inspect block=======================================================================================
	if Input.is_action_just_pressed("inspect weapon"):
		if weapon_state == weapon_states.PISTOL:
			if gun_animator.current_animation == "reload_pistol":
				pass
			elif gun_animator.current_animation == "equip_pistol":
					gun_animator.stop()
					gun_animator.play("inspect")
			else:
				gun_animator.play("inspect")

		elif weapon_state == weapon_states.SHOTGUN:
			print("shotgun inspect")
		
		elif weapon_state == weapon_states.BLL:
			print("black hole inspect")
		
	# reload block=========================================================================================
	if Input.is_action_just_pressed("reload"):
		if weapon_state == weapon_states.PISTOL:
			if PISTOL_AMMO != PISTOL_MAGSIZE:
				gun_animator.play("reload_pistol")
		
		elif weapon_state == weapon_states.SHOTGUN:
			print("shotgun reload")
	
		elif weapon_state == weapon_states.BLL:
			pass
			
			
	# special block=========================================================================================
	if Input.is_action_just_pressed("right click action") and player_fire_input_enabled:
		if weapon_state == weapon_states.PISTOL:
			pistol.special()
		
		elif weapon_state == weapon_states.SHOTGUN:
			print("shotgun special")
			
		elif weapon_state == weapon_states.BLL:
			print("no special attack available")
	# ======================================================================================================

var a = true
func _process(_delta) -> void:
	
	# updates string variables with the current state for debug purposes
	updateStateStrings()
	
	# keeps the rope attatched to the grapple bit
	grapple_rope_mesh_gen.generate_mesh_planes(rope_origin.global_position, grapple_hook.global_position)
	
	# retrn the time remaining on the current black hole cooldown animation and save as a time
	if bll_animator.current_animation == "Black Hole Launcher/BLL_cooldown":
		black_hole_time_remaining = bll_animator.current_animation_length - bll_animator.current_animation_position
		black_hole_time_remaining = black_hole_time_remaining
		if black_hole_time_remaining < 0.50:
			black_hole_time_remaining = 0.00
		var time_left = str(snappedf(black_hole_time_remaining, 0.01)) + "s"
		black_hole_cooldown_timer.text = time_left
	
	# kill the player
	if HEALTH <= 0:
		playerDie()
	
	
	gunInputs()
	
# updates the string variables that contain the names of the state based on the active state
func updateStateStrings():
	# update the string name of the weapon state every frame
	if weapon_state == weapon_states.PISTOL:
		current_weapon_string_name = "pistol"
	elif weapon_state == weapon_states.BLL:
		current_weapon_string_name = "black hole launcher"
	elif weapon_state == weapon_states.SHOTGUN:
		current_weapon_string_name = "shotgun"
	elif weapon_state == weapon_states.MELEE:
		current_weapon_string_name = "MELEE"
		
	# update the string name of the player state every frame
	if player_state == player_states.GROUNDED:
		current_player_string_name = "GROUNDED"
	elif player_state == player_states.DEAD:
		current_player_string_name = "DEAD"
	elif player_state == player_states.FALLING:
		current_player_string_name = "FALLING"
	elif player_state == player_states.REELINGTO:
		current_player_string_name = "REELINGTO"
	elif player_state == player_states.SLIDING:
		current_player_string_name = "SLIDING"

	# update the string name of the action every frame
	if action_state == action_states.GRAPPLING:
		current_action_string_name = "GRAPPLING"
	elif action_state == action_states.IDLE:
		current_action_string_name = "IDLE"

func grappleFrameLogic():
	pass

# note: zoomOut and zoomIn are reversed. I screwed up.
func _on_hud_zoom_in_trigger() -> void:
	zoomOut()


func _on_hud_zoom_out_trigger() -> void:
	zoomIn()

func playerDie():
	player_state = player_states.DEAD
	cause_of_death_message.text = cause_of_death
	Engine.time_scale = 0.3
	death_animator.play("death")


func _on_grapple_timer_timeout() -> void:
	pass

# signals the first body the hook collides with
# if hook collides with something that is not the grapple cube, retract
func _on_hook_collide(body) -> void:
	if not body.is_in_group("grapple_cubes"):
		var impact_particles = impact_particles_scene.instantiate()
		var impact_pos = grapple_hook.global_position
		var particle_look_marker = impact_particles.get_node("Marker")
		get_tree().root.add_child(impact_particles)
		impact_particles.global_position = impact_pos
		particle_look_marker.global_position = camera_3d.global_position
		action_state = action_states.IDLE


func _on_cam_shake_timer_timeout() -> void:
	doing_shake = false
