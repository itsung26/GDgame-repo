class_name SkitterBomb
extends Enemy

# onreadies
@onready var animation_player: AnimationPlayer = $Skitterbomb2/AnimationPlayer
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var state_debug_text: StateDebugText = $StateDebugText

# constants

# navigation tuning
@export var lerp_angle_factor:float = 8.0
## Minimum distance the player must move before updating navigation path (reduces pathfinding calls)
@export var path_update_threshold:float = 2.0
## How often to update the navigation path (in seconds). Lower = more frequent updates but more expensive
@export var path_update_interval:float = 0.2

# state machines
enum enemy_states {IDLE, STARTUP, FALLING, FOLLOWING, PREPARELEAP, LEAPING, DEAD}
var enemy_state:enemy_states:
	set = setEnemyState

# export vars
@export var initial_state:enemy_states

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
	
	if new_enemy_state == enemy_states.STARTUP:
		animation_player.play("rear action")

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
		if enemy_state == enemy_states.FOLLOWING:
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
		
