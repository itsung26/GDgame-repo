class_name EnemyFilth extends Enemy


@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var filth_animator:AnimationPlayer = $FilthAnimator
@export var air_navigation_accel: float = 2.5
@export var lerp_angle_factor:float

const spawn_intro_particles_SCENE:PackedScene = preload("res://scenes/spawn_intro_particles.tscn")

enum enemy_states {STUNNED, FALLING, RUNNING, PREPARINGBITE, BITING, NULL}
var enemy_state:enemy_states = enemy_states.RUNNING:
	set = set_enemy_state


func _ready() -> void:
	if filth_animator == null:
		print("ERROR: filth animation player not found")
		print(get_tree().current_scene.get_children())
	if player == null:
		print("ERROR: initial call to PLAYER returned null ensure that the player is loaded before the given object")
	var b := spawn_intro_particles_SCENE.instantiate()
	add_child(b)

func set_enemy_state(new_enemy_state:enemy_states):
	var previous_enemy_state = enemy_state
	enemy_state = new_enemy_state
	
	# falling to and from
	if new_enemy_state == enemy_states.FALLING:
		filth_animator.play("Falling_4")
	
	# STUNNED to and from
	elif new_enemy_state == enemy_states.STUNNED:
		filth_animator.play("Idle_8")
		
	# running to and from
	elif new_enemy_state == enemy_states.RUNNING:
		filth_animator.play("Run_11")
	
	elif new_enemy_state == enemy_states.PREPARINGBITE:
		filth_animator.play("Bite_0")
		

func statePhysicsLogic(delta = get_physics_process_delta_time()): # run every physics frame
	match enemy_state:
		
		enemy_states.STUNNED:
			if is_on_floor():
				velocity = lerp(velocity, Vector3.ZERO, 5 * delta) # prevent sliding on floor
				
		enemy_states.FALLING: # slow on xz do nothing else
			velocity.x = lerp(velocity.x, 0.0, slowInAirFactor * delta)
			velocity.z = lerp(velocity.z, 0.0, slowInAirFactor * delta)
		
		enemy_states.RUNNING: # get the path to the player and move towards and look at it's path points
			# movement
			navigation_agent_3d.target_position = player.global_position # update the navigation target
			var dir = navigation_agent_3d.get_next_path_position() - global_position # get the direction to go
			dir = dir.normalized() # normalize it
			var target_vector:Vector3 = dir * SPEED * delta
			velocity.x = target_vector.x
			velocity.z = target_vector.z
			
			# rotation
			rotation.y = lerp_angle(rotation.y, getVec3LookingAtTarget(navigation_agent_3d.get_next_path_position()).y, lerp_angle_factor * delta)
		
		enemy_states.BITING:
			pass
			

## checks to see if the enemy is in the air or on the ground and sets the state once accordingly if it is not already in another state
func checkForStates():
	if (is_on_floor() and enemy_state != enemy_states.RUNNING and enemy_state == enemy_states.FALLING):
		set_enemy_state(enemy_states.RUNNING)
	elif not (is_on_floor() and enemy_state == enemy_states.RUNNING):
		set_enemy_state(enemy_states.FALLING)


func _process(delta: float) -> void:
	$MeshInstance3D.mesh.text = str(enemy_states.keys()[enemy_state])
	print(is_on_floor())

func _physics_process(delta: float) -> void:
	
	if not is_on_floor() and gravity_enabled:
		# handle gravity
		velocity += get_gravity() * delta

	# handle allowed physics
	statePhysicsLogic()
	checkForStates()
	move_and_slide()


func _on_visibility_body_entered(body: Player) -> void:
	print(body)


func _on_visibility_body_exited(body: Player) -> void:
	print(body)


func _on_ready_bite_box_body_entered(body: Player) -> void:
	set_enemy_state(enemy_states.PREPARINGBITE)
	
