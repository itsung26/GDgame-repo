class_name EnemyFilth extends Enemy


@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var filth_animator:AnimationPlayer = $FilthAnimator
@onready var body_collider: CollisionShape3D = $bodyCollider
@onready var state_debug_text: StateDebugText = $StateDebugText

## The weight that the enemy rotates exponentially with to look at it's target
@export var lerp_angle_factor:float = 8.0
## The velocity that the enemy launches forwards with when it does the attack.
@export var bite_velocity:float = 1500.0
## bite damage
@export var bite_damage:float = 8.0
## attack player cause of death
@export var player_cause_of_death_message:String = "Bitten to death"
## Minimum distance the player must move before updating navigation path (reduces pathfinding calls)
@export var path_update_threshold:float = 2.0
## How often to update the navigation path (in seconds). Lower = more frequent updates but more expensive
@export var path_update_interval:float = 0.2

## Main physics states.
enum enemy_states {IDLE, FALLING, RUNNING, PREPARINGBITE, BITING, ENDINGBITE, DEAD}
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
	elif previous_enemy_state == enemy_states.DEAD:
		enemy_state = previous_enemy_state
		return
	
	# falling to and from
	if new_enemy_state == enemy_states.FALLING:
		filth_animator.play("Falling_4")
	
	# IDLE to and from
	if new_enemy_state == enemy_states.IDLE:
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
		disablePhysicalCollider(false)
	if previous_enemy_state == enemy_states.BITING:
		enablePhysicalCollider(true)
	
	# end of bite to and from
	if new_enemy_state == enemy_states.ENDINGBITE:
		velocity = Vector3.ZERO
		
	# DEAD to and from
	if new_enemy_state == enemy_states.DEAD:
		velocity = Vector3.ZERO
		$readyBiteBox/CollisionShape3D.disabled = true
		body_collider.disabled = true
		queue_free()
		

func _ready() -> void:
	super._ready() # ensure Enemy._ready runs (physics_frame hookup)
	if filth_animator == null:
		assert(false, "Enemy found no animation player.")
	if player == null:
		set_enemy_state(enemy_states.IDLE)
	else:
		last_player_position = player.global_position
		# Initialize navigation agent settings for better performance
		navigation_agent_3d.path_desired_distance = 0.5
		navigation_agent_3d.target_desired_distance = 0.5

func _process(_delta: float) -> void:
	state_debug_text.updateStateReadout(enemy_state, enemy_states)
	
	if not behavior_enabled:
		set_enemy_state(enemy_states.IDLE)

func _physics_process(delta: float) -> void:
	
	if not is_on_floor() and gravity_enabled:
		# handle gravity
		velocity += get_gravity() * delta

	# handle allowed physics
	# checks to see if the enemy is in the air or on the ground and sets the state once accordingly if it is not already in another state
	if (is_on_floor() and enemy_state == enemy_states.FALLING and enemy_state != enemy_states.IDLE and player):
		set_enemy_state(enemy_states.RUNNING)
	elif not is_on_floor() and enemy_state == enemy_states.RUNNING:
		set_enemy_state(enemy_states.FALLING)
	
	match enemy_state:
		
		enemy_states.IDLE:
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
	
	# if the enemy is dead, skip physics calculations
	if enemy_state != enemy_states.DEAD:
		move_and_slide()


	
		

func _killEnemy():
	set_enemy_state(enemy_states.DEAD)

func disableProcess():
	print("disabled process")
	# set the process thread to disabled
	process_mode = Node.PROCESS_MODE_DISABLED # disables all interactions with node

## Begins the method stack for the bite attack
func beginBiteChain():
	set_enemy_state(enemy_states.PREPARINGBITE)


func _disableCollisionAllEnemies():
	var enemies:Array[Node] = get_tree().get_nodes_in_group("enemy")
	for enemy:Enemy in enemies:
		add_collision_exception_with(enemy)


func _enableCollisionAllEnemies():
	var enemies:Array[Node] = get_tree().get_nodes_in_group("enemy")
	for enemy:Enemy in enemies:
		remove_collision_exception_with(enemy)


func disablePhysicalCollider(with_all:bool) -> void:
	add_collision_exception_with(player)
	if with_all:
		_disableCollisionAllEnemies()


func enablePhysicalCollider(with_all:bool) -> void:
	remove_collision_exception_with(player)
	if with_all:
		_enableCollisionAllEnemies()


func _on_ready_bite_box_body_entered(_body: Player) -> void:
	if enemy_state != enemy_states.FALLING:
		player_in_bite_box = true
		beginBiteChain()


func _on_ready_bite_box_body_exited(_body: Player) -> void:
	player_in_bite_box = false




func _on_bite_hurt_box_body_entered(body: Player) -> void:
	if enemy_state == enemy_states.BITING:
		var plr:Player = body
		plr.setHealth(plr.HEALTH - bite_damage)
		plr.cause_of_death = player_cause_of_death_message
		plr.camera_3d.shakeCamera()
