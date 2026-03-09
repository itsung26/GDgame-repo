class_name PlayerCamera
extends Camera3D

@onready var player: Player = $"../.."
@onready var pivot: Node3D = $".."

@export_category("Roll")
@export var camera_roll_enabled:bool = true
@export var max_camera_roll: float = 3.25
@export var camera_roll_speed: float = 20.0
@export var camera_target_roll:float = 0.0

@export_category("Dash Roll")
@export var dash_roll_enabled: bool = true
@export var dash_roll_amount: float = 5.0      # extra degrees of roll at full effect
@export var dash_roll_lerp_speed: float = 12.0 # how fast dash roll reacts

var dash_roll_current: float = 0.0  # current extra roll in degrees
var dash_roll_target: float = 0.0   # desired extra roll in degrees

@export_category("Pitch Clamp")
@export var base_min_pitch_deg: float = -90.0
@export var base_max_pitch_deg: float = 90.0

@export_category("Dash Pitch")
@export var dash_pitch_enabled: bool = true
@export var dash_pitch_amount: float = 4.0       # extra degrees of pitch at full effect
@export var dash_pitch_lerp_speed: float = 10.0  # how fast dash pitch reacts

var dash_pitch_current: float = 0.0  # current extra pitch in degrees
var dash_pitch_target: float = 0.0   # desired extra pitch in degrees

@export_category("Fov Lerp")
@export var camera_fov_lerp_enabled:bool = true
@export var camera_target_fov:float = 75.0
@export var camera_fov_lerp_speed:float = 0.5

@export_category("Camera Shake")
@export var smoothness:float = 0.5 # 0..1

# Shake state
var cam_shaking:bool = false
var remaining_time:float = 0.0
var elapsed_time:float = 0.0
var current_strength:float = 0.0
var camera_sliding:bool = false
# Last frame’s applied pivot offset
var _pivot_last_offset:Vector3 = Vector3.ZERO

func _process(delta: float) -> void:
	# Base roll from horizontal movement
	if camera_roll_enabled and player.player_move_input_enabled:
		if player.input_dir.x > 0.0:
			camera_target_roll = -max_camera_roll
		elif player.input_dir.x < 0.0:
			camera_target_roll = max_camera_roll
		else:
			camera_target_roll = 0.0
	else:
		camera_target_roll = 0.0

	# Additive roll from dashing direction
	if dash_roll_enabled and player.player_state == Player.player_states.DASHING:
		# Player's right direction in world space
		var right: Vector3 = player.global_transform.basis.x.normalized()
		# Sideways component of dash relative to the player (-1 = left, +1 = right)
		var sideways: float = player.dash_dir.dot(right)
		# Match existing convention: right (>0) leans camera to the right (negative roll)
		dash_roll_target = clamp(-sideways * dash_roll_amount, -dash_roll_amount, dash_roll_amount)
	else:
		dash_roll_target = 0.0

	dash_roll_current = lerp(dash_roll_current, dash_roll_target, dash_roll_lerp_speed * delta)

	# Additive pitch from dashing forward/back
	if dash_pitch_enabled and player.player_state == Player.player_states.DASHING:
		# Player's forward direction in world space
		var forward: Vector3 = -player.global_transform.basis.z.normalized()
		# Forward component of dash relative to the player (+1 = forward, -1 = backward)
		var forward_dot: float = player.dash_dir.dot(forward)
		# Positive forward_dot should tilt camera slightly down (negative pitch degrees)
		dash_pitch_target = clamp(-forward_dot * dash_pitch_amount, -dash_pitch_amount, dash_pitch_amount)
	else:
		dash_pitch_target = 0.0

	dash_pitch_current = lerp(dash_pitch_current, dash_pitch_target, dash_pitch_lerp_speed * delta)

	# Apply total roll (movement + dash)
	var total_roll_deg: float = camera_target_roll + dash_roll_current
	rotation.z = lerp_angle(rotation.z, deg_to_rad(total_roll_deg), camera_roll_speed * delta)

	# Apply dash pitch tilt
	rotation.x = lerp_angle(rotation.x, deg_to_rad(dash_pitch_current), dash_pitch_lerp_speed * delta)

	# Apply FOV lerp
	fov = lerpf(fov, camera_target_fov, camera_fov_lerp_speed * delta)

func get_min_pitch_deg() -> float:
	return base_min_pitch_deg + dash_pitch_current

func get_max_pitch_deg() -> float:
	return base_max_pitch_deg + dash_pitch_current

## Moves the camera to its slide position.
func gotoSliding() -> void:
	camera_sliding = true
	# If shaking, remove current shake offset before changing position
	if cam_shaking:
		pivot.position -= _pivot_last_offset
		_pivot_last_offset = Vector3.ZERO
	pivot.position = player.sliding_marker.position
	# Clamp after moving
	pivot.rotation_degrees.x = clamp(pivot.rotation_degrees.x, get_min_pitch_deg(), get_max_pitch_deg())

## Moves the camera back to its normal position from the sliding position.
func gotoNormal() -> void:
	camera_sliding = false
	# If shaking, remove current shake offset before changing position
	if cam_shaking:
		pivot.position -= _pivot_last_offset
		_pivot_last_offset = Vector3.ZERO
	pivot.position = player.head_marker.position
	# Clamp after moving
	pivot.rotation_degrees.x = clamp(pivot.rotation_degrees.x, get_min_pitch_deg(), get_max_pitch_deg())

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
