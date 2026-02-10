class_name SkitterBomb
extends Enemy

# onreadies
@onready var animation_player: AnimationPlayer = $Skitterbomb2/AnimationPlayer
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var state_debug_text: StateDebugText = $StateDebugText
@onready var leap_delay_timer: Timer = $"leap delay timer"
@onready var player_detector_collider: CollisionShape3D = $"player detector/player detector collider"

# constants


# state machines
enum enemy_states {IDLE, STARTUP, FALLING, FOLLOWING, PREPARELEAP, LEAPING, DEAD}
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

# regular vars
var last_player_position:Vector3 = Vector3.ZERO
var path_update_timer:float = 0.0
var cached_next_path_position:Vector3 = Vector3.ZERO

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
		var look_at_point:Vector3 = player.getPredictedPos(prepare_leap_duration)
		var rotation_looking_at_targ:Vector3 = getVec3LookingAtTarget(look_at_point)
		rotation.y = rotation_looking_at_targ.y
		player_detector_collider.disabled = false # change to true on final implementation
		leap_delay_timer.start(prepare_leap_duration)
	

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
		if not is_on_floor() and gravity_enabled:
			velocity += get_gravity() * delta
		
		# handle FALLING state transitions relative to FOLLOWING
		if is_on_floor() and enemy_state == enemy_states.FALLING and enemy_state != enemy_states.DEAD:
			setEnemyState(enemy_states.FOLLOWING)
		elif not is_on_floor() and enemy_state == enemy_states.FOLLOWING:
			setEnemyState(enemy_states.FALLING)
		
		# state-specific physics
		if enemy_state == enemy_states.FALLING:
			# In the air: don't follow, just damp XZ velocity
			velocity.x = lerp(velocity.x, 0.0, slowInAirFactor * delta)
			velocity.z = lerp(velocity.z, 0.0, slowInAirFactor * delta)
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


func _on_player_detector_body_entered(player:Player) -> void:
	setEnemyState(enemy_states.PREPARELEAP)

func _on_prepare_leap_delay_timeout() -> void:
	setEnemyState(enemy_states.LEAPING)
