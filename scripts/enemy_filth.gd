class_name EnemyFilth extends Enemy


@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var filth_animator:AnimationPlayer = $FilthAnimator
@onready var body_collider: CollisionShape3D = $bodyCollider
@onready var time_untill_process_disable_timer:Timer = $timeUntillDisable
@onready var state_debug_text: StateDebugText = $StateDebugText

## The weight that the enemy rotates exponentially with to look at it's target
@export var lerp_angle_factor:float = 8.0
## The velocity that the enemy launches forwards with when it does the attack.
@export var bite_velocity:float = 1500.0
## bite damage
@export var bite_damage:float = 8.0
## attack player cause of death
@export var player_cause_of_death_message:String = "Bitten to death"
## time after death untill the process_mode disables. When set to 0, the process will never disable.
@export var time_untill_process_disable:float = 4.0
## Minimum distance the player must move before updating navigation path (reduces pathfinding calls)
@export var path_update_threshold:float = 2.0
## How often to update the navigation path (in seconds). Lower = more frequent updates but more expensive
@export var path_update_interval:float = 0.2

## Main physics states.
enum enemy_states {STUNNED, FALLING, RUNNING, PREPARINGBITE, BITING, ENDINGBITE, DYING, DEAD, NULL}
var enemy_state:enemy_states = enemy_states.RUNNING:
	set = set_enemy_state

var player_in_bite_box:bool = false
var last_player_position:Vector3 = Vector3.ZERO
var path_update_timer:float = 0.0
var cached_next_path_position:Vector3 = Vector3.ZERO

func set_enemy_state(new_enemy_state:enemy_states):
	var previous_enemy_state = enemy_state
	enemy_state = new_enemy_state
	
	# prevent same-state setting
	if previous_enemy_state == new_enemy_state:
		return
	# prevent switching out of death states
	elif previous_enemy_state == enemy_states.DYING or previous_enemy_state == enemy_states.DEAD:
		return
	
	# falling to and from
	if new_enemy_state == enemy_states.FALLING:
		filth_animator.play("Falling_4")
	
	# STUNNED to and from
	if new_enemy_state == enemy_states.STUNNED:
		filth_animator.play("Idle_8")
		
	# running to and from
	if new_enemy_state == enemy_states.RUNNING:
		filth_animator.play("Run_11")
	
	# preparing bite to and from
	if new_enemy_state == enemy_states.PREPARINGBITE:
		velocity = Vector3.ZERO
		filth_animator.play("Bite_0")
	if previous_enemy_state == enemy_states.ENDINGBITE:
		# on ending the bite, check if the player is still in the bite box and and begin another attack chain
		if player_in_bite_box:
			beginBiteChain()
	
	# Biting to and from
	if new_enemy_state == enemy_states.BITING:
		# initiate velocity change
		var dir:Vector3 = -transform.basis.z
		velocity = dir * bite_velocity * get_physics_process_delta_time()
		disableCollider()
	if previous_enemy_state == enemy_states.BITING:
		enableCollider()
	
	# end of bite to and from
	if new_enemy_state == enemy_states.ENDINGBITE:
		velocity = Vector3.ZERO
		
	# DYING to and from
	if new_enemy_state == enemy_states.DYING:
		damage_enabled = false
		filth_animator.play("ChestExplosion")
		
	# DEAD to and from
	if new_enemy_state == enemy_states.DEAD:
		velocity = Vector3.ZERO
		set_collision_layer_value(2, false)
		if time_untill_process_disable != 0:
			time_untill_process_disable_timer.start(time_untill_process_disable)
		else: pass

func _ready() -> void:
	super._ready() # ensure Enemy._ready runs (physics_frame hookup)
	if filth_animator == null:
		assert(false, "Enemy found no animation player.")
	if player == null:
		set_enemy_state(enemy_states.STUNNED)
	else:
		last_player_position = player.global_position
		# Initialize navigation agent settings for better performance
		navigation_agent_3d.path_desired_distance = 0.5
		navigation_agent_3d.target_desired_distance = 0.5

func _process(_delta: float) -> void:
	# Debug.log(velocity) # Commented out for performance - enable only when debugging
	state_debug_text.updateStateReadout(enemy_state, enemy_states)
	if stunned and enemy_state != enemy_states.DYING and enemy_state != enemy_states.DEAD and enemy_state != enemy_states.FALLING:
		set_enemy_state(enemy_states.STUNNED)

func _physics_process(delta: float) -> void:
	
	if not is_on_floor() and gravity_enabled:
		# handle gravity
		velocity += get_gravity() * delta

	# handle allowed physics
	statePhysicsLogic()
	move_and_slide()


	
		

func _killEnemy():
	set_enemy_state(enemy_states.DYING)

func statePhysicsLogic(delta = get_physics_process_delta_time()): # run every physics frame
	# checks to see if the enemy is in the air or on the ground and sets the state once accordingly if it is not already in another state
	if (is_on_floor() and enemy_state == enemy_states.FALLING and enemy_state != enemy_states.STUNNED and player):
		set_enemy_state(enemy_states.RUNNING)
	elif not is_on_floor() and enemy_state == enemy_states.RUNNING:
		set_enemy_state(enemy_states.FALLING)
	
	match enemy_state:
		
		enemy_states.STUNNED:
			if is_on_floor():
				velocity = lerp(velocity, Vector3.ZERO, 5 * delta) # prevent sliding on floor
				
		enemy_states.FALLING: # slow on xz do nothing else
			velocity.x = lerp(velocity.x, 0.0, slowInAirFactor * delta)
			velocity.z = lerp(velocity.z, 0.0, slowInAirFactor * delta)
		
		enemy_states.RUNNING: # get the path to the player and move towards and look at it's path points
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
			
			# rotation - optimized: calculate direction directly instead of using expensive look_at
			var direction_to_target:Vector3 = cached_next_path_position - global_position
			if direction_to_target.length_squared() > 0.001: # Avoid division by zero
				var target_angle:float = atan2(direction_to_target.x, direction_to_target.z) + PI
				rotation.y = lerp_angle(rotation.y, target_angle, lerp_angle_factor * delta)
			
		enemy_states.DYING:
			velocity.x = lerp(velocity.x, 0.0, slowInAirFactor * delta)
			velocity.z = lerp(velocity.z, 0.0, slowInAirFactor * delta)


func disableProcess():
	print("disabled process")
	# set the process thread to disabled
	process_mode = Node.PROCESS_MODE_DISABLED # disables all interactions with node

## Begins the method stack for the bite attack
func beginBiteChain():
	set_enemy_state(enemy_states.PREPARINGBITE)

func disableCollider() -> void:
	add_collision_exception_with(player)

func enableCollider() -> void:
	remove_collision_exception_with(player)

func _on_ready_bite_box_body_entered(_body: Player) -> void:
	if enemy_state != enemy_states.FALLING:
		player_in_bite_box = true
		beginBiteChain()


func _on_ready_bite_box_body_exited(_body: Player) -> void:
	player_in_bite_box = false




func _on_bite_hurt_box_body_entered(body: Player) -> void:
	if enemy_state == enemy_states.BITING:
		var plr:Player = body
		plr.damagePlayer(bite_damage, player_cause_of_death_message)


func _on_time_untill_disable_timeout() -> void:
	print("timeout. disabling enemy process.")
	disableProcess()
