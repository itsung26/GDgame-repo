class_name SkitterBomb
extends Enemy

# signals
signal leap_landed

# onreadies
@onready var animation_player: AnimationPlayer = $Skitterbomb2/AnimationPlayer
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var state_debug_text: StateDebugText = $StateDebugText
@onready var leap_delay_timer: Timer = $"leap delay timer"
@onready var player_detector_collider: CollisionShape3D = $"player detector/player detector collider"
@onready var explosion_timer: Timer = $ExplosionTimer

# constants
const explosion_SCENE:PackedScene = preload("res://scenes/explosion_3d.tscn")

# state machines
enum enemy_states {IDLE, STARTUP, FALLING, FOLLOWING, PREPARELEAP, LEAPING, RETURNTOSENDER, DEAD}
var enemy_state:enemy_states:
	set = setEnemyState

# navigation tuning
@export var lerp_angle_factor:float = 8.0
## Minimum distance the player must move before updating navigation path (reduces pathfinding calls)
@export var path_update_threshold:float = 2.0
## How often to update the navigation path (in seconds). Lower = more frequent updates but more expensive
@export var path_update_interval:float = 0.2
@export var initial_state:enemy_states
@export var prepare_leap_duration:float = 1.0
## Time (seconds) the leap should take from launch to landing (end of leap).
## Note: If the target is above the enemy, this will be overridden to make the apex hit the target.
@export var leap_travel_time:float = 0.75
## The enemy will leap to the player's predicted position + this offset.
@export var leap_to_player_offset:Vector3 = Vector3.ZERO
## The enemy's speed is multiplied by this amount upon being parried while leaping.
@export var return_to_sender_multiplier:float = 2.0

# regular vars
var last_player_position:Vector3 = Vector3.ZERO
var path_update_timer:float = 0.0
var cached_next_path_position:Vector3 = Vector3.ZERO
var leap_target_position:Vector3 = Vector3.ZERO
var leap_has_left_ground:bool = false
var leap_time_in_state:float = 0.0
var leap_current_travel_time:float = 0.0

func setEnemyState(new_enemy_state:enemy_states):
	var previous_enemy_state:enemy_states = enemy_state
	enemy_state = new_enemy_state
	
	if previous_enemy_state == new_enemy_state:
		return
	
	# update the debug state text
	state_debug_text.updateStateReadout(enemy_state, enemy_states)
	
	# STARTUP state
	if new_enemy_state == enemy_states.STARTUP:
		animation_player.play("rear action")
	
	# PREPARELEAP state
	if new_enemy_state == enemy_states.PREPARELEAP:
		velocity.x = 0.0
		velocity.z = 0.0
		var distance_to_player:float = global_position.distance_to(player.global_position)
		# Predict player position accounting for both prepare delay AND leap travel time
		# Total time from now until landing = prepare_leap_duration + leap_travel_time
		var total_time_until_landing:float = prepare_leap_duration + leap_travel_time
		leap_target_position = player.getPredictedPos(total_time_until_landing) + leap_to_player_offset
		var rotation_looking_at_targ:Vector3 = getVec3LookingAtTarget(leap_target_position)
		rotation.y = rotation_looking_at_targ.y
		player_detector_collider.disabled = true # change to true on final implementation
		leap_delay_timer.start(prepare_leap_duration)

	# LEAPING state
	if new_enemy_state == enemy_states.LEAPING:
		leap_has_left_ground = false
		leap_time_in_state = 0.0
		parriable = true
		# Launch with a ballistic velocity so that, when possible, the apex of the jump is at the target.
		# If the target is above us, choose time so vertical velocity is ~0 at the target (apex there).
		# Otherwise, fall back to the configured leap_travel_time.
		var gravity:Vector3 = get_gravity()
		var displacement:Vector3 = leap_target_position - global_position
		var travel_time:float = leap_travel_time
		var g_y:float = gravity.y
		var dy:float = displacement.y
		
		if g_y < -0.001 and dy > 0.01:
			# Make the target the apex: dy = -0.5 * g_y * T^2  ->  T = sqrt(2*dy / -g_y)
			travel_time = sqrt(2.0 * dy / -g_y)
		
		leap_current_travel_time = max(travel_time, 0.01)
		
		# Solve p(t) = p0 + v*t + 0.5*g*t^2  => v = (p(t) - p0 - 0.5*g*t^2) / t
		var initial_velocity:Vector3 = (displacement - 0.5 * gravity * leap_current_travel_time * leap_current_travel_time) / leap_current_travel_time
		velocity = initial_velocity
		
		# Use the actual calculated travel time (which may differ from leap_travel_time if apex adjustment occurred)
		explosion_timer.start(leap_current_travel_time)
	if previous_enemy_state == enemy_states.LEAPING:
		parriable = false
		
	# RETURNTOSENDER state
	if new_enemy_state == enemy_states.RETURNTOSENDER:
		# enemy should travel towards the point returned by player.getFacingPoint()
		var target_point:Vector3 = player.getFacingPoint()
		var dir:Vector3 = (target_point - global_position).normalized()
		velocity = dir * SPEED * return_to_sender_multiplier

func _ready() -> void:
	# Initialize navigation data if we have a player
	if player != null:
		last_player_position = player.global_position
		# Match EnemyFilth's navigation agent tuning
		navigation_agent_3d.path_desired_distance = 0.5
		navigation_agent_3d.target_desired_distance = 0.5
	setEnemyState(initial_state)
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("debug func"):
		global_position.y += 10.0
	if behavior_enabled:
		if enemy_state == enemy_states.FALLING:
			animation_player.play("Falling")
		elif enemy_state == enemy_states.IDLE:
			animation_player.play("Idle")
		elif enemy_state == enemy_states.FOLLOWING:
			animation_player.play("forwards")
	else:
		setEnemyState(enemy_states.IDLE)

func _physics_process(delta: float) -> void:
	if behavior_enabled:
		# apply gravity when in the air
		if not is_on_floor() and gravity_enabled and enemy_state != enemy_states.RETURNTOSENDER:
			velocity += get_gravity() * delta
		
		# handle air/ground state transitions
		# Only FOLLOWING can enter FALLING. LEAPING is handled separately below.
		if is_on_floor():
			if enemy_state == enemy_states.FALLING and enemy_state != enemy_states.DEAD and enemy_state != enemy_states.RETURNTOSENDER:
				setEnemyState(enemy_states.FOLLOWING)
		elif not is_on_floor() and enemy_state == enemy_states.FOLLOWING:
			setEnemyState(enemy_states.FALLING)
		
		# state-specific physics
		if enemy_state == enemy_states.FALLING:
			# In the air: don't follow, just damp XZ velocity
			velocity.x = lerp(velocity.x, 0.0, slowInAirFactor * delta)
			velocity.z = lerp(velocity.z, 0.0, slowInAirFactor * delta)
		elif enemy_state == enemy_states.LEAPING:
			# Let the initial launch velocity + gravity handle the arc.
			# Track when we've actually left the ground so we only end the leap after a real airborne phase,
			# and only after roughly the intended travel time has elapsed.
			leap_time_in_state += delta
			if not is_on_floor():
				leap_has_left_ground = true
			elif leap_has_left_ground and is_on_floor() and leap_time_in_state >= leap_current_travel_time:
				# Land from leap -> emit signal and resume following (or chain into another state later)
				leap_landed.emit()
				leap_has_left_ground = false
				leap_time_in_state = 0.0
				setEnemyState(enemy_states.FOLLOWING)
		elif enemy_state == enemy_states.FOLLOWING:
			# Navigation behavior mirroring EnemyFilth.RUNNING
			if player == null:
				return
			
			# Throttled pathfinding updates - only update if player moved significantly or timer expired
			path_update_timer += delta
			var player_moved_distance:float = player.global_position.distance_to(last_player_position)
			
			if path_update_timer >= path_update_interval or player_moved_distance >= path_update_threshold:
				# Only update target if it's been a while or player moved significantly
				navigation_agent_3d.target_position = player.global_position
				last_player_position = player.global_position
				path_update_timer = 0.0
			
			# Cache the next path position to avoid calling it twice
			if navigation_agent_3d.is_navigation_finished():
				# If pathfinding is finished, move directly toward player
				cached_next_path_position = player.global_position
			else:
				cached_next_path_position = navigation_agent_3d.get_next_path_position()
			
			# movement
			var dir = cached_next_path_position - global_position # get the direction to go
			dir = dir.normalized() # normalize it
			var target_vector:Vector3 = dir * SPEED * delta
			velocity.x = target_vector.x
			velocity.z = target_vector.z
			
			# rotation - calculate direction directly instead of using look_at
			var direction_to_target:Vector3 = cached_next_path_position - global_position
			if direction_to_target.length_squared() > 0.001: # Avoid division by zero
				var target_angle:float = atan2(direction_to_target.x, direction_to_target.z) + PI
				rotation.y = lerp_angle(rotation.y, target_angle, lerp_angle_factor * delta)
	move_and_slide()

## Returns the location in global coordinates that the enemy is currently leaping at.
## If the enemy is not leaping at anything, the function will return the last location
## that it was leaping at.
func getJumpingAtTargetPos() -> Vector3:
	return leap_target_position

func _on_player_detector_body_entered(player:Player) -> void:
	setEnemyState(enemy_states.PREPARELEAP)

func _on_prepare_leap_delay_timeout() -> void:
	setEnemyState(enemy_states.LEAPING)


func _on_leap_landed() -> void:
	player_detector_collider.disabled = false

func _on_explosion_timer_timeout() -> void:
	var explosion:Explosion3D = explosion_SCENE.instantiate()
	get_tree().current_scene.add_child(explosion)
	explosion.setup_preset(global_position, Explosion3D.explosion_presets.YELLOW_SMALL)
	
	var explosion_2:Explosion3D = explosion_SCENE.instantiate()
	get_tree().current_scene.add_child(explosion_2)
	explosion_2.setup_preset(global_position, Explosion3D.explosion_presets.SHOCKWAVE_SMALL)

func _on_parried() -> void:
	explosion_timer.stop()
	setEnemyState(enemy_states.RETURNTOSENDER)
