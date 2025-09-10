extends CharacterBody3D

@onready var player: CharacterBody3D = $"."
@onready var camera_3d: Camera3D = %Camera3D
@onready var pivot: Node3D = $Pivot
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var camera_animator: AnimationPlayer = $CameraAnimator
@onready var special_light: OmniLight3D = $"Pivot/Camera3D/PistolSwayPivot/pistol/Skeleton3D/blaster-a/SpecialLight"
@onready var muzzle_flash: Sprite3D = $"Pivot/Camera3D/PistolSwayPivot/pistol/Skeleton3D/blaster-a/MuzzleFlashes/MuzzleFlash"
@onready var muzzle_flash_2: Sprite3D = $"Pivot/Camera3D/PistolSwayPivot/pistol/Skeleton3D/blaster-a/MuzzleFlashes/MuzzleFlash2"
@onready var pistol: Skeleton3D = $Pivot/Camera3D/PistolSwayPivot/pistol
@onready var shotgun: Node3D = $Pivot/Camera3D/Guns/shotgun
@onready var grapple_ray_cast: RayCast3D = $Pivot/Camera3D/GrappleRayCast
@onready var pistol_sway_pivot: Node3D = $Pivot/Camera3D/PistolSwayPivot
@onready var slam_timer: Timer = $SlamTimer
@onready var black_hole_launcher: Node3D = $Pivot/Camera3D/Guns/BlackHoleLauncher
@onready var bll_animator: AnimationPlayer = $BLLAnimator

@export_category("traits")
@export var HEALTH:float = 100.0

@export_category("movement")
@export var SPEED = 7.5
@export var JUMP_VELOCITY = 8.0
@export var look_sensitivity = 0.1
@export var gravity_enabled = true
@export var Stopwalk_slowdown:float = 7.5

@export_category("grappling hook")
@export var GRAPPLE_MAX_RANGE = 50
@export var GRAPPLE_SPEED_MAX = 20
@export var GRAPPLE_HOP = 8

@export_category("pistol")
@export var pistol_sway_enabled : bool = false
@export var pistol_sway_min : float = -5.0
@export var pistol_sway_max : float = 5.0
@export var pistol_sway_factor : float = 1.0

var grappling = false
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

func _ready() -> void:
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
	if event is InputEventMouseMotion and Global.player_look_input_enabled:
		mouse_delta2 = event.relative
		var mouse_delta = event.relative
		var yaw = -mouse_delta.x
		var pitch = -mouse_delta.y
		player.rotate_y(deg_to_rad(look_sensitivity * yaw))
		pivot.rotate_x(deg_to_rad(look_sensitivity * pitch))
		
# when overclock ends
func zoomIn():
	camera_animator.play("camera_overclock_zoom_in")
	SPEED = 5
	JUMP_VELOCITY = prev_jump_velocity
	animation_player.speed_scale = 1.5
	pistol_damage_increase = false
	muzzle_flash.modulate = Color.from_rgba8(60, 188, 235)
	muzzle_flash_2.modulate = Color.from_rgba8(60, 188, 235)
	special_light.visible = false

# when overclock begins
func zoomOut():
	camera_animator.play("camera_overclock_zoom_out")
	SPEED = SPEED * 2
	JUMP_VELOCITY = JUMP_VELOCITY * 1.5
	animation_player.speed_scale = 3
	pistol_damage_increase = true
	muzzle_flash.modulate = Color.RED
	muzzle_flash_2.modulate = Color.RED
	special_light.visible = true
	
func grapple():
	# if collision occurs between player and anything, stop the grapple and cancel out net velocity
	var collision_count = get_slide_collision_count()
	for i in range(collision_count):
		grappling = false
		
func swayPistol(delta):
	if pistol_sway_enabled:
		mouse_delta2 = clamp(mouse_delta2, Vector2(pistol_sway_min,-5), Vector2(pistol_sway_max,5))
		pistol_sway_pivot.rotation.y = lerpf(0.0,5.0,mouse_delta2.x/5) * pistol_sway_factor * delta

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		
		swayPistol(delta)
		
			# if grapple and not grappling, grapple and set the positions
		if Input.is_action_just_pressed("grapple") and grappling == false:
			if grapple_ray_cast.get_collider() != null:
				grapple_target_pos = grapple_ray_cast.get_collision_point()
				grapple_dir = (grapple_target_pos - grapple_ray_cast.global_position).normalized()
				# grapple_dir returns as a Vector3
				grappling = true
		
		# if grapple and grappling, stop grappling and initiate hop mechanic
		elif Input.is_action_just_pressed("grapple") and grappling == true:
			grappling = false
			velocity = Vector3.ZERO
			player.velocity.y = GRAPPLE_HOP
		
		
		# clamp the camera pivot view
		var b = clamp(pivot.rotation_degrees.x, -90.0, 90.0)
		pivot.rotation_degrees.x = b
		
		# grapple
		grapple()
		
		# Add the gravity.
		if not is_on_floor():
			if gravity_enabled:
				velocity += get_gravity() * delta
				
		
		
		# Handle jump.
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
			
		
			
		# handle slam jumping
		#if Input.is_action_just_pressed("slam") and is_on_floor():
			#pass
		#elif Input.is_action_just_pressed("slam") and not is_on_floor():
			#player.velocity.y = -25
			#can_slam_jump = true
		#if is_on_floor() and can_slam_jump:
			#JUMP_VELOCITY = 12
			#slam_timer.start()
		
		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var input_dir := Input.get_vector("left", "right", "forward", "back")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
		if direction and Global.player_move_input_enabled:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		
		# Player will stop moving in the air when the movement is stopped
		else:
			velocity.x = move_toward(velocity.x, 0, Stopwalk_slowdown)
			velocity.z = move_toward(velocity.z, 0, Stopwalk_slowdown)

		if grappling:
			velocity = grapple_dir * GRAPPLE_SPEED_MAX
			
		move_and_slide()

func gunInputs(curr_weap): # run every frame in _process
	
	# save the current animation to a global transfer variable every frame
	Global.anim_playing = animation_player.current_animation
	
	# switch weapon block==================================================================================
	if Input.is_action_just_pressed("slot1"): #and not animation_player.is_playing():
		Global.current_weapon = "melee"
		
	if Input.is_action_just_pressed("slot2"): #and not animation_player.is_playing():
		if Global.current_weapon != "pistol":
			if animation_player.current_animation == "reload_pistol":
				pass
			else:
				animation_player.play("equip_pistol")
		Global.current_weapon = "pistol"
		
	if Input.is_action_just_pressed("slot3"): #and not animation_player.is_playing():
		Global.current_weapon = "shotgun"
		
	if Input.is_action_just_pressed("slot4"):
		Global.current_weapon = "BLL"
	
	# automatic fire block===================================================================================
	if Input.is_action_pressed("fire") and Global.player_fire_input_enabled:
		# use seperate animation players for each weapon
		
		if curr_weap == "pistol":
			if animation_player.current_animation == "inspect" or animation_player.current_animation == "equip_pistol":
				animation_player.stop()
			elif animation_player.current_animation == "reload_pistol":
				pass
			else:
				if Global.blaster_ammo > 0:
					animation_player.play("fire")
				elif Global.blaster_ammo == 0: animation_player.play("reload_pistol")

	# semi-automatic fire block========================================================================
	if Input.is_action_just_pressed("fire") and Global.player_fire_input_enabled:
		
		if curr_weap == "shotgun":
			print("shotgun fire")
		
		elif curr_weap == "BLL":
			if bll_animator.current_animation == "Black Hole Launcher/BLL_cooldown":
				pass
			else:
				if Global.BLL_ammo > 0:
					black_hole_launcher.BLLFire()
	
	# inspect block=======================================================================================
	if Input.is_action_just_pressed("inspect weapon"):
		if curr_weap == "pistol":
			if animation_player.current_animation == "reload_pistol":
				pass
			elif animation_player.current_animation == "equip_pistol":
					animation_player.stop()
					animation_player.play("inspect")
			else:
				animation_player.play("inspect")

		elif curr_weap == "shotgun":
			print("shotgun inspect")
		
		elif curr_weap == "BLL":
			print("black hole inspect")
		
	# reload block=========================================================================================
	if Input.is_action_just_pressed("reload"):
		if curr_weap == "pistol":
			if Global.blaster_ammo != 50:
				animation_player.play("reload_pistol")
		
		elif curr_weap == "shotgun":
			print("shotgun reload")
	
		elif curr_weap == "BLL":
			pass
			
			
	# special block=========================================================================================
	if Input.is_action_just_pressed("right click action") and Global.player_fire_input_enabled:
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
		pistol.visible = true
		black_hole_launcher.visible = false
		shotgun.visible = false
	elif Global.current_weapon == "shotgun":
		shotgun.visible = true
		black_hole_launcher.visible = false
		pistol.visible = false
	elif Global.current_weapon == "melee":
		black_hole_launcher.visible = false
		shotgun.visible = false
		pistol.visible = false
	elif Global.current_weapon == "BLL":
		black_hole_launcher.visible = true
		pistol.visible = false
		shotgun.visible = false

var a = true
func _process(_delta) -> void:
	# exits the server and quits the game
	if Input.is_action_just_pressed("forcequit"):
		$"../".exit_game(name.to_int())
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
	cause_of_death_message.text = cause_of_death
	Engine.time_scale = 0.3
	death_animator.play("death")
	
func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())
