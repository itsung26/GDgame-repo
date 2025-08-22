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



@export var SPEED = 5.0
@export var JUMP_VELOCITY = 4.5
@export var look_sensitivity = 0.1


func _ready() -> void:
	# set the mouse to be captured by the gamewindow
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
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
	SPEED = 10
	JUMP_VELOCITY = 6.5
	animation_player.speed_scale = 3
	Global.pistol_DAMAGE = 15
	muzzle_flash.modulate = Color.RED
	muzzle_flash_2.modulate = Color.RED
	special_light.visible = true

func _physics_process(delta: float) -> void:
	# clamp the camera pivot view
	var b = clamp(pivot.rotation_degrees.x, -90.0, 90.0)
	pivot.rotation_degrees.x = b
	
	# emit the current looking at direction of pitch for the player's look 
	
	
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

	move_and_slide()

func gunInputs(curr_weap): # run every frame in _process
	print(curr_weap)
	
	# save the current animation to a global transfer variable every frame
	Global.anim_playing = animation_player.current_animation
	
	# switch block======================================================================================
	if Input.is_action_just_pressed("slot1"):
		pass
	if Input.is_action_just_pressed("slot2"):
		Global.current_weapon = "pistol"
	if Input.is_action_just_pressed("slot3"):
		Global.current_weapon = "shotgun"
	
	# automatic fire block=====================================================================================
	if Input.is_action_pressed("fire"):
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

func _process(_delta) -> void:
	
	gunInputs(Global.current_weapon)
	
	# hide weapon on switch script
	if Global.current_weapon == "pistol":
		shotgun.visible = false
	elif Global.current_weapon == "shotgun":
		pistol.visible = false

# note: zoomOut and zoomIn are reversed. I screwed up.
func _on_hud_zoom_in_trigger() -> void:
	zoomOut()


func _on_hud_zoom_out_trigger() -> void:
	zoomIn()
