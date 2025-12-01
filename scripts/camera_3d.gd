class_name PlayerCamera
extends Camera3D

@onready var player: Player = $"../.."
@onready var pivot: Node3D = $".."

@export_category("Roll")
@export var camera_roll_enabled:bool = true
@export var max_camera_roll: float = 3.25 # degrees, adjust as desired
@export var camera_roll_speed: float = 20.0 # how quickly the camera rolls
@export var camera_target_roll:float = 0.0

@export_category("Fov Lerp")
@export var camera_fov_lerp_enabled:bool = true
@export var camera_target_fov:float = 75.0
@export var camera_fov_lerp_speed:float = 0.5

# Camera Shake
@onready var cam_shaking:bool = false
@onready var remaining_time:float = 0
@onready var elapsed_time:float = 0
#strength controlls the overall magnitude of the shake
#while smoothness controlls how smooth motion is, kind of "anti-strength"
@onready var smoothness :float = 0.5 #0-1, higher values smooth out the shake motion more so that it's less jarring
@onready var current_strength :float = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if camera_roll_enabled and player.player_move_input_enabled:
		# Set target roll based on left/right input
		if player.input_dir.x > 0:
			camera_target_roll = -max_camera_roll # rolling right (negative z)
		elif player.input_dir.x < 0:
			camera_target_roll = max_camera_roll  # rolling left (positive z)
		else:
			camera_target_roll = 0.0
	else:
		camera_target_roll = 0.0
	
	# interpolate the z tilt
	rotation.z = lerp_angle(rotation.z, deg_to_rad(camera_target_roll), camera_roll_speed * delta)
	# interpolate the FOV
	fov = lerpf(fov, camera_target_fov, camera_fov_lerp_speed * delta)

## Additive camera shake. 
## If the camera is already shaking, then reset the elapsed time and remaining time of the shake and
## boost the strength of the shake, so that shakes have an additive effect.
func shakeCamera(duration:float, strength:float):
	pass
