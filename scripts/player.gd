extends CharacterBody3D

@onready var player: CharacterBody3D = $"."
@onready var camera_3d: Camera3D = %Camera3D
@onready var pivot: Node3D = $Pivot
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var camera_animator: AnimationPlayer = $CameraAnimator
@onready var muzzle_flash: Sprite3D = $"Pivot/Camera3D/pistol/Skeleton3D/blaster-a/MuzzleFlashes/MuzzleFlash"
@onready var muzzle_flash_2: Sprite3D = $"Pivot/Camera3D/pistol/Skeleton3D/blaster-a/MuzzleFlashes/MuzzleFlash2"


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

# when overclock begins
func zoomOut():
	camera_animator.play("camera_overclock_zoom_out")
	SPEED = 10
	JUMP_VELOCITY = 6.5
	animation_player.speed_scale = 3
	Global.pistol_DAMAGE = 15
	muzzle_flash.modulate = Color.RED
	muzzle_flash_2.modulate = Color.RED

func _physics_process(delta: float) -> void:
	# clamp the camera pivot view
	var b = clamp(pivot.rotation_degrees.x, -90.0, 90.0)
	pivot.rotation_degrees.x = b
	
	# emit the current looking at direction of pitch for the player's look 
	Global.camera_look_dir = pivot.rotation_degrees
	
	
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

# note: zoomOut and zoomIn are reversed. I screwed up.
func _on_hud_zoom_in_trigger() -> void:
	zoomOut()


func _on_hud_zoom_out_trigger() -> void:
	zoomIn()
