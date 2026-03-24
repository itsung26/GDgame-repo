## Player-facing camera that adds movement/dash-based tilt, FOV easing, shake, and
## exposes pitch clamp helpers used by the player controller.
class_name PlayerCamera
extends Camera3D

## Reference to the owning player character.
@onready var player: Player = $"../.."
## Parent node used as the camera's yaw/pitch pivot.
@onready var pivot: Node3D = $".."

@export_category("Roll")
## Enables horizontal roll based on player strafing input.
@export var camera_roll_enabled:bool = true
## Maximum roll in degrees applied from left/right movement.
@export var max_camera_roll: float = 3.25
## How quickly the camera interpolates toward the target roll.
@export var camera_roll_speed: float = 20.0
## Target roll in degrees coming from strafing movement.
@export var camera_target_roll:float = 0.0

@export_category("Dash Roll")
## Enables extra roll while dashing, additive to movement roll.
@export var dash_roll_enabled: bool = true
## Maximum extra roll in degrees contributed by dash direction.
@export var dash_roll_amount: float = 5.0      # extra degrees of roll at full effect
## How quickly the dash roll reacts to changes in dash direction.
@export var dash_roll_lerp_speed: float = 12.0 # how fast dash roll reacts

## Smoothed, currently applied dash roll in degrees.
var dash_roll_current: float = 0.0  # current extra roll in degrees
## Immediate dash roll target before smoothing.
var dash_roll_target: float = 0.0   # desired extra roll in degrees

@export_category("Pitch Clamp")
## Base minimum pitch that the pivot can rotate to (before dash offsets).
@export var base_min_pitch_deg: float = -90.0
## Base maximum pitch that the pivot can rotate to (before dash offsets).
@export var base_max_pitch_deg: float = 90.0

@export_category("Dash Pitch")
## Enables pitch tilt while dashing forward/backward.
@export var dash_pitch_enabled: bool = true
## Maximum pitch offset in degrees contributed by dash direction.
@export var dash_pitch_amount: float = 4.0       # extra degrees of pitch at full effect
## How quickly the dash pitch reacts to changes in dash direction.
@export var dash_pitch_lerp_speed: float = 10.0  # how fast dash pitch reacts

## Smoothed, currently applied dash pitch in degrees.
var dash_pitch_current: float = 0.0  # current extra pitch in degrees
## Immediate dash pitch target before smoothing.
var dash_pitch_target: float = 0.0   # desired extra pitch in degrees

@export_category("Fov Lerp")
## Enables smooth interpolation of camera FOV toward a target.
@export var camera_fov_lerp_enabled:bool = true
## Target FOV in degrees.
@export var camera_target_fov:float = 75.0
## How quickly FOV interpolates toward the target.
@export var camera_fov_lerp_speed:float = 0.5

@export_category("Camera Shake")
## Controls smoothing of the 2D shake offset; 0 = raw jitter, 1 = very smooth.
@export var smoothness:float = 0.5 # 0..1

## True while a camera shake coroutine is active.
var cam_shaking:bool = false
## Remaining shake time in seconds.
var remaining_time:float = 0.0
## Elapsed shake time in seconds.
var elapsed_time:float = 0.0
## Current shake strength applied to pivot position.
var current_strength:float = 0.0
## True while the camera is in its sliding pose.
var camera_sliding:bool = false
## Last frame’s applied pivot offset used to keep base position stable during shake.
var _pivot_last_offset:Vector3 = Vector3.ZERO

## Per-frame camera update:
## - computes strafing roll and dash-based roll/pitch,
## - interpolates FOV toward its target.
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

	# Framerate-independent smoothing toward dash roll target
	var dash_roll_alpha: float = 1.0 - exp(-dash_roll_lerp_speed * delta)
	dash_roll_current = lerp(dash_roll_current, dash_roll_target, dash_roll_alpha)

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

	# Framerate-independent smoothing toward dash pitch target
	var dash_pitch_alpha: float = 1.0 - exp(-dash_pitch_lerp_speed * delta)
	dash_pitch_current = lerp(dash_pitch_current, dash_pitch_target, dash_pitch_alpha)

	# Apply total roll (movement + dash)
	var total_roll_deg: float = camera_target_roll + dash_roll_current
	rotation.z = lerp_angle(rotation.z, deg_to_rad(total_roll_deg), camera_roll_speed * delta)

	# Apply dash pitch tilt
	rotation.x = lerp_angle(rotation.x, deg_to_rad(dash_pitch_current), dash_pitch_lerp_speed * delta)

	# Apply FOV lerp
	fov = lerpf(fov, camera_target_fov, camera_fov_lerp_speed * delta)

## Returns the current minimum pitch in degrees, including dash pitch offset.
func get_min_pitch_deg() -> float:
	return base_min_pitch_deg + dash_pitch_current

## Returns the current maximum pitch in degrees, including dash pitch offset.
func get_max_pitch_deg() -> float:
	return base_max_pitch_deg + dash_pitch_current

## Moves the camera pivot to the sliding marker and reapplies pitch clamping.
func gotoSliding() -> void:
	camera_sliding = true
	# If shaking, remove current shake offset before changing position
	if cam_shaking:
		pivot.position -= _pivot_last_offset
		_pivot_last_offset = Vector3.ZERO
	pivot.position = player.sliding_marker.position
	# Clamp after moving
	pivot.rotation_degrees.x = clamp(pivot.rotation_degrees.x, get_min_pitch_deg(), get_max_pitch_deg())

## Returns the camera pivot to the head marker and reapplies pitch clamping.
func gotoNormal() -> void:
	camera_sliding = false
	# If shaking, remove current shake offset before changing position
	if cam_shaking:
		pivot.position -= _pivot_last_offset
		_pivot_last_offset = Vector3.ZERO
	pivot.position = player.head_marker.position
	# Clamp after moving
	pivot.rotation_degrees.x = clamp(pivot.rotation_degrees.x, get_min_pitch_deg(), get_max_pitch_deg())

## Kicks off a camera shake that jitters the pivot in local XY over time without changing rotation.
## Calling again while shaking extends the duration and increases strength.
func shakeCamera(duration: float = 0.66, strength: float = 1.0) -> void:
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


func _on_player_entered_player_state(new_player_state: Player.player_states, previous_player_state: Player.player_states) -> void:
	if new_player_state == Player.player_states.DEAD:
		if cam_shaking:
			pass
