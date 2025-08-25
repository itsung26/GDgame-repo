extends CharacterBody3D

@onready var player: CharacterBody3D = $"."
@onready var camera_3d: Camera3D = %Camera3D
@onready var pivot: Node3D = $Pivot
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var camera_animator: AnimationPlayer = $CameraAnimator
@onready var special_light: OmniLight3D = $"Pivot/Camera3D/pistol/Skeleton3D/blaster-a/SpecialLight"
@onready var muzzle_flash: Sprite3D = $"Pivot/Camera3D/pistol/Skeleton3D/blaster-a/MuzzleFlashes/MuzzleFlash"
@onready var muzzle_flash_2: Sprite3D = $"Pivot/Camera3D/pistol/Skeleton3D/blaster-a/MuzzleFlashes/MuzzleFlash2"
@onready var pistol: Skeleton3D = $Pivot/Camera3D/pistol
@onready var shotgun: Node3D = $Pivot/Camera3D/Guns/shotgun
@onready var grapple_ray_cast: RayCast3D = $Pivot/Camera3D/GrappleRayCast


@export_category("movement")
@export var SPEED = 5.0
@export var JUMP_VELOCITY = 4.5
@export var look_sensitivity = 0.1

@export_category("grappling hook")
@export var GRAPPLE_MAX_RANGE = 0
@export var GRAPPLE_SPEED_MAX = 0
@export var GRAPPLE_HOP = 0

var grappling = false
var grapple_target_pos = Vector3.ZERO
var grapple_dir = Vector3.ZERO

func _ready() -> void:
	# set the mouse to be captured by the gamewindow
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# grapple ray target init + range
	grapple_ray_cast.target_position = Vector3(0, 0, -GRAPPLE_MAX_RANGE)
	
func _input(event) -> void:
	# handle mouselook
	if event is InputEventMouseMotion:
		var mouse_delta = event.relative
		var yaw = -mouse_delta.x
		var pitch = -mouse_delta.y
		player.rotate_y(deg_to_rad(look_sensitivity * yaw))
		pivot.rotate_x(deg_to_rad(look_sensitivity * pitch))
	
# when overclock ends
func zoomIn():
	camera_animator.play("camera_overclock_zoom_in")
	SPEED = 5
	JUMP_VELOCITY = 4.5
	animation_player.speed_scale = 1.5
	Global.pistol_DAMAGE = 3
	muzzle_flash.modulate = Color.from_rgba8(60, 188, 235)
	muzzle_flash_2.modulate = Color.from_rgba8(60, 188, 235)
	special_light.visible = false

# when overclock begins
func zoomOut():
	camera_animator.play("camera_overclock_zoom_out")
	SPEED = SPEED * 2
	JUMP_VELOCITY = JUMP_VELOCITY * 1.5
	animation_player.speed_scale = 3
	Global.pistol_DAMAGE = 15
	muzzle_flash.modulate = Color.RED
	muzzle_flash_2.modulate = Color.RED
	special_light.visible = true
	
func grapple():
	# if collision occurs between player and anything, stop the grapple and cancel out net velocity
	var collision_count = get_slide_collision_count()
	for i in range(collision_count):
		var collision = get_slide_collision(i)
		grappling = false
		velocity = Vector3.ZERO
		# print("stopped grapple")
	
	# if grapple and not grappling, grapple and set the positions
	if Input.is_action_just_pressed("grapple") and grappling == false:
		if grapple_ray_cast.get_collider() != null:
			grapple_target_pos = grapple_ray_cast.get_collision_point()
			grapple_dir = (grapple_target_pos - grapple_ray_cast.global_position).normalized()
			grappling = true
			print("started grapple")
	
	# if grapple and grappling, stop grappling and initiate hop mechanic
	elif Input.is_action_just_pressed("grapple") and grappling == true:
		grappling = false
		velocity = Vector3.ZERO
		player.velocity.y = GRAPPLE_HOP
		print("stopped grapple")

func _physics_process(delta: float) -> void:
	# print(grapple_target_pos)
	
	# clamp the camera pivot view
	var b = clamp(pivot.rotation_degrees.x, -90.0, 90.0)
	pivot.rotation_degrees.x = b
	
	# grapple
	grapple()
	
	
	# gun bobbing on walk animation
	'''
	if velocity.x != 0 or velocity.z != 0:
		animation_player.play("gunBob")
	else:
		animation_player.stop()
	'''
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	if grappling:
		velocity = grapple_dir * GRAPPLE_SPEED_MAX
	move_and_slide()

func gunInputs(curr_weap): # run every frame in _process
	
	# save the current animation to a global transfer variable every frame
	Global.anim_playing = animation_player.current_animation
	
	# switch weapon block======================================================================================
	if Input.is_action_just_pressed("slot1"): #and not animation_player.is_playing():
		Global.current_weapon = "melee"
	if Input.is_action_just_pressed("slot2"): #and not animation_player.is_playing():
		Global.current_weapon = "pistol"
	if Input.is_action_just_pressed("slot3"): #and not animation_player.is_playing():
		Global.current_weapon = "shotgun"
	
	# automatic fire block=====================================================================================
	if Input.is_action_pressed("fire"):
		# use AnimationPlayer for all animations
		
		if curr_weap == "pistol":
			if animation_player.current_animation == "inspect":
				animation_player.stop()
			elif animation_player.current_animation == "reload_pistol":
				pass
			else:
				if Global.blaster_ammo > 0:
					animation_player.play("fire")
				elif Global.blaster_ammo == 0: animation_player.play("reload_pistol")
	# semi-automatic fire block========================================================================
	if Input.is_action_just_pressed("fire"):
		if curr_weap == "shotgun":
			print("shotgun fire")
	
	# inspect block=======================================================================================
	if Input.is_action_just_pressed("inspect weapon"):
		if curr_weap == "pistol":
			if animation_player.current_animation == "reload_pistol":
				pass
			else:
				animation_player.play("inspect")
		elif curr_weap == "shotgun":
			print("shotgun inspect")
		
	# reload block=============================================================================================
	if Input.is_action_just_pressed("reload"):
		if curr_weap == "pistol":
			if Global.blaster_ammo != 50:
				animation_player.play("reload_pistol")
		elif curr_weap == "shotgun":
			print("shotgun reload")
			
	# special block=============================================================================================
	if Input.is_action_just_pressed("right click action"):
		if curr_weap == "pistol":
			pistol.special(Global.current_weapon)
		elif curr_weap == "shotgun":
			print("shotgun special")

func hideGuns(curr_weap):
	# hide weapon on switch
	if Global.current_weapon == "pistol":
		pistol.visible = true
		shotgun.visible = false
	elif Global.current_weapon == "shotgun":
		shotgun.visible = true
		pistol.visible = false
	elif Global.current_weapon == "melee":
		shotgun.visible = false
		pistol.visible = false

var a = true
func _process(_delta) -> void:
	
	gunInputs(Global.current_weapon)
	hideGuns(Global.current_weapon)

# note: zoomOut and zoomIn are reversed. I screwed up.
func _on_hud_zoom_in_trigger() -> void:
	zoomOut()


func _on_hud_zoom_out_trigger() -> void:
	zoomIn()
