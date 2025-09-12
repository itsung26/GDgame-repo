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

@export_category("Settings")
@export var HEALTH: int = 100
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
@export var GRAPPLE_HOP = 8

@export_category("Pistol")
@export var Pistol_Damage_Range_Min := 12
@export var Pistol_Damage_Range_Max := 17
@export var Pistol_Overclock_Damage_Range_Min := 17
@export var Pistol_OverClock_Damage_Range_Max := 22

var player_state

var grapple_target_pos = Vector3.ZERO
var grapple_dir = Vector3.ZERO
var can_slam_jump = false
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

func _ready() -> void:
	# object reference definitions
	pistol = get_node("Pivot/Camera3D/Guns/Pistol")
	
	# disables the camera if you are not the current client in control of it
	camera_3d.current = is_multiplayer_authority()
	
	black_hole_cooldown_timer = get_node("../HUD/BlackHoleCooldownIcon/BlackHoleCooldownTimer")
	death_animator = get_node("../DeathScreen/DeathAnimator")
	cause_of_death_message = get_node("../DeathScreen/VBoxContainer/CauseOfDeathMessage")
	
	# set the mouse to be captured by the gamewindow
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# grapple ray target init + range
	grapple_ray_cast.target_position = Vector3(0, 0, -GRAPPLE_MAX_RANGE)
	
func _input(event) -> void:
	# handle mouselook
	if event is InputEventMouseMotion and player.player_look_input_enabled:
		mouse_delta2 = event.relative
		var mouse_delta = event.relative
		var yaw = -mouse_delta.x
		var pitch = -mouse_delta.y
		player.rotate_y(deg_to_rad(look_sensitivity * yaw))
		pivot.rotate_x(deg_to_rad(look_sensitivity * pitch))

func cameraRoll(delta):
	# Set target roll based on left/right input
	if input_dir.x > 0:
		camera_target_roll = -max_camera_roll # rolling right (negative z)
	elif input_dir.x < 0:
		camera_target_roll = max_camera_roll  # rolling left (positive z)
	else:
		camera_target_roll = 0.0

	# Smoothly interpolate the camera roll
	camera_3d.rotation.z = lerp_angle(camera_3d.rotation.z, deg_to_rad(camera_target_roll), camera_roll_speed * delta)

# when overclock ends
func zoomIn():
	camera_animator.play("camera_overclock_zoom_in")
	SPEED = SPEED / 2
	JUMP_VELOCITY = prev_jump_velocity
	gun_animator.speed_scale = 1.5
	pistol_damage_increase = false
	# muzzle_flash.modulate = Color.from_rgba8(60, 188, 235)
	# muzzle_flash_2.modulate = Color.from_rgba8(60, 188, 235)
	# special_light.visible = false

# when overclock begins
func zoomOut():
	camera_animator.play("camera_overclock_zoom_out")
	SPEED = SPEED * 2
	JUMP_VELOCITY = JUMP_VELOCITY * 1.5
	gun_animator.speed_scale = 3
	pistol_damage_increase = true
	# muzzle_flash.modulate = Color.RED
	# muzzle_flash_2.modulate = Color.RED
	# special_light.visible = true

func grapple():
	
	# if grapple and not grappling, grapple and set the positions
	if Input.is_action_just_pressed("grapple") and player_state != "grappling":
		if grapple_ray_cast.get_collider() != null:
			grapple_target_pos = grapple_ray_cast.get_collision_point()
			grapple_dir = (grapple_target_pos - grapple_ray_cast.global_position).normalized()
			# grapple_dir returns as a Vector3
			player_state = "grappling"
	
	# if grapple and grappling, stop grappling and initiate hop mechanic
	elif Input.is_action_just_pressed("grapple") and player_state == "grappling":
		player_state = "idle"
		velocity = Vector3.ZERO
		player.velocity.y = GRAPPLE_HOP
	
	
	# if collision occurs between player and anything, stop the grapple and cancel out net velocity
	var collision_count = get_slide_collision_count()
	for i in range(collision_count):
		player_state = "idle"
		

func _physics_process(delta: float) -> void:
	
	cameraRoll(delta)
	
	# grapple
	grapple()
	
	# clamp the camera pivot view
	var b = clamp(pivot.rotation_degrees.x, -90.0, 90.0)
	pivot.rotation_degrees.x = b
	
	# Add the gravity.
	if not is_on_floor():
		if gravity_enabled:
			velocity += get_gravity() * delta
			
	
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	input_dir = Input.get_vector("left", "right", "forward", "back")
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction and player_move_input_enabled:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	# Player will stop moving in the air when the movement is stopped
	elif direction == Vector3.ZERO and not is_on_floor():
		velocity.x = lerp(velocity.x, 0.0, Aerial_Slowdown * delta)
		velocity.z = lerp(velocity.z, 0.0, Aerial_Slowdown * delta)
	elif direction == Vector3.ZERO and is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, 10.0)
		velocity.z = move_toward(velocity.z, 0.0, 10.0)
		
	playerPhysicsStates()
	move_and_slide()

func gunInputs(curr_weap): # run every frame in _process
	
	# switch weapon block==================================================================================
	if Input.is_action_just_pressed("slot1"): #and not gun_animator.is_playing():
		Global.current_weapon = "melee"
		
	if Input.is_action_just_pressed("slot2"): #and not gun_animator.is_playing():
		if Global.current_weapon != "pistol":
			if gun_animator.current_animation == "reload_pistol":
				pass
			else:
				gun_animator.play("equip_pistol")
		Global.current_weapon = "pistol"
		
	if Input.is_action_just_pressed("slot3"): #and not gun_animator.is_playing():
		Global.current_weapon = "shotgun"
		
	if Input.is_action_just_pressed("slot4"):
		Global.current_weapon = "BLL"
	
	# automatic fire block===================================================================================
	if Input.is_action_pressed("fire") and player_fire_input_enabled:
		# use seperate animation players for each weapon
		
		if curr_weap == "pistol":
			if gun_animator.current_animation == "inspect" or gun_animator.current_animation == "equip_pistol":
				gun_animator.stop()
			elif gun_animator.current_animation == "reload_pistol":
				pass
			else:
				if Global.blaster_ammo > 0:
					gun_animator.play("fire")
				elif Global.blaster_ammo == 0: gun_animator.play("reload_pistol")

	# semi-automatic fire block========================================================================
	if Input.is_action_just_pressed("fire") and player_fire_input_enabled:
		
		if curr_weap == "shotgun":
			print("shotgun fire")
		
		elif curr_weap == "BLL":
			if bll_animator.current_animation == "Black Hole Launcher/BLL_cooldown":
				pass
			else:
				if Global.BLL_ammo > 0:
					black_hole_launcher.bll_animator.play("Black Hole Launcher/BLL_cooldown")

	
	# inspect block=======================================================================================
	if Input.is_action_just_pressed("inspect weapon"):
		if curr_weap == "pistol":
			if gun_animator.current_animation == "reload_pistol":
				pass
			elif gun_animator.current_animation == "equip_pistol":
					gun_animator.stop()
					gun_animator.play("inspect")
			else:
				gun_animator.play("inspect")

		elif curr_weap == "shotgun":
			print("shotgun inspect")
		
		elif curr_weap == "BLL":
			print("black hole inspect")
		
	# reload block=========================================================================================
	if Input.is_action_just_pressed("reload"):
		if curr_weap == "pistol":
			if Global.blaster_ammo != 50:
				gun_animator.play("reload_pistol")
		
		elif curr_weap == "shotgun":
			print("shotgun reload")
	
		elif curr_weap == "BLL":
			pass
			
			
	# special block=========================================================================================
	if Input.is_action_just_pressed("right click action") and player_fire_input_enabled:
		if curr_weap == "pistol":
			pistol.special(Global.current_weapon)
		
		elif curr_weap == "shotgun":
			print("shotgun special")
			
		elif curr_weap == "BLL":
			pass
	# ======================================================================================================
	
func hideGuns():
	 # hide weapon on switch
	if Global.current_weapon == "pistol":
		arm_pivot_bll.visible = false
		arm_pivot_pistol.visible = true
		pistol.visible = true
		black_hole_launcher.visible = false
		shotgun.visible = false
	elif Global.current_weapon == "shotgun":
		arm_pivot_bll.visible = false
		arm_pivot_pistol.visible = false
		shotgun.visible = true
		black_hole_launcher.visible = false
		pistol.visible = false
	elif Global.current_weapon == "melee":
		arm_pivot_bll.visible = false
		arm_pivot_pistol.visible = false
		black_hole_launcher.visible = false
		shotgun.visible = false
		pistol.visible = false
	elif Global.current_weapon == "BLL":
		arm_pivot_bll.visible = true
		arm_pivot_pistol.visible = false
		black_hole_launcher.visible = true
		pistol.visible = false
		shotgun.visible = false

var a = true
func _process(_delta) -> void:
	
	playerStates()
	
	if Input.is_action_just_pressed("forcequit"):
		get_tree().quit()
	
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
	
	
	gunInputs(Global.current_weapon)
	hideGuns()

# note: zoomOut and zoomIn are reversed. I screwed up.
func _on_hud_zoom_in_trigger() -> void:
	zoomOut()


func _on_hud_zoom_out_trigger() -> void:
	zoomIn()


func _on_slam_timer_timeout() -> void:
	can_slam_jump = false
	JUMP_VELOCITY = storagevar

func playerDie():
	player_state = "dead"
	cause_of_death_message.text = cause_of_death
	Engine.time_scale = 0.3
	death_animator.play("death")

# valid states: grappling, dead, idle, 
func playerStates():
		if player_state == "dead":
			player_fire_input_enabled = false
			player_look_input_enabled = false
			player_move_input_enabled = false

func playerPhysicsStates():
	if player_state == "grappling":
		velocity = grapple_dir * GRAPPLE_SPEED_MAX
