class_name PlayerCamera
extends Camera3D

@onready var player: Player = $"../.."
@onready var pivot: Node3D = $".."

@export_category("Roll")
@export var camera_roll_enabled:bool = true
@export var max_camera_roll: float = 3.25
@export var camera_roll_speed: float = 20.0
@export var camera_target_roll:float = 0.0

@export_category("Fov Lerp")
@export var camera_fov_lerp_enabled:bool = true
@export var camera_target_fov:float = 75.0
@export var camera_fov_lerp_speed:float = 0.5

# Shake state
var cam_shaking:bool = false
var remaining_time:float = 0.0
var elapsed_time:float = 0.0
var current_strength:float = 0.0
@export var smoothness:float = 0.5 # 0..1

# Last frame’s applied pivot offset
var _pivot_last_offset:Vector3 = Vector3.ZERO

func _process(delta: float) -> void:
	if camera_roll_enabled and player.player_move_input_enabled:
		if player.input_dir.x > 0:
			camera_target_roll = -max_camera_roll
		elif player.input_dir.x < 0:
			camera_target_roll = max_camera_roll
		else:
			camera_target_roll = 0.0
	else:
		camera_target_roll = 0.0
	
	rotation.z = lerp_angle(rotation.z, deg_to_rad(camera_target_roll), camera_roll_speed * delta)
	fov = lerpf(fov, camera_target_fov, camera_fov_lerp_speed * delta)

## Translate pivot in local XY for a screen shake (no camera rotation). One call starts full shake.
func shakeCamera(duration: float, strength: float) -> void:
	if cam_shaking:
		remaining_time = max(remaining_time, duration)
		current_strength += strength
		return
	
	cam_shaking = true
	current_strength = strength
	remaining_time = duration
	elapsed_time = 0.0
	_pivot_last_offset = Vector3.ZERO
	
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	
	while elapsed_time < duration:
		await get_tree().process_frame
		var dt: float = get_process_delta_time()
		elapsed_time += dt
		remaining_time = max(0.0, duration - elapsed_time)
		
		# Remove previous frame offset (keep base pivot position stable)
		pivot.position -= _pivot_last_offset
		
		var fade: float = 1.0 - (elapsed_time / duration) # ease out
		var raw2D: Vector2 = Vector2(
			rng.randf_range(-1.0, 1.0),
			rng.randf_range(-1.0, 1.0)
		) * current_strength * fade
		
		var alpha: float = 1.0 - clamp(smoothness, 0.0, 1.0)
		var smoothed2D: Vector2 = Vector2(_pivot_last_offset.x, _pivot_last_offset.y).lerp(raw2D, alpha)
		
		var new_offset: Vector3 = Vector3(smoothed2D.x, smoothed2D.y, 0.0)
		pivot.position += new_offset
		_pivot_last_offset = new_offset
	
	# Final cleanup: remove residual offset
	pivot.position -= _pivot_last_offset
	_pivot_last_offset = Vector3.ZERO
	
	cam_shaking = false
	current_strength = 0.0
	remaining_time = 0.0
	elapsed_time = 0.0
