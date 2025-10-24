class_name EnemyFilth extends Enemy


@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@export var animation_player: AnimationPlayer
var pulldir:Vector3

enum enemy_states {STUNNED, GROUNDED, FALLING, RUNNING}
@export var enemy_state:enemy_states = enemy_states.GROUNDED:
	set = set_enemy_state


func set_enemy_state(new_enemy_state:enemy_states):
	var previous_enemy_state = enemy_state
	enemy_state = new_enemy_state
	
	# falling to and from
	if new_enemy_state == enemy_states.FALLING:
		animation_player.play("Falling_4")
	
	# Grounded to and from
	if new_enemy_state == enemy_states.GROUNDED:
		animation_player.play("Idle_8")
		
	# running to and from
	if new_enemy_state == enemy_states.RUNNING:
		animation_player.play("Run_11")
		
func _ready() -> void:
	pass

func statePhysicsLogic(delta = get_process_delta_time()):
	match enemy_state:
		
		enemy_states.STUNNED:
			if is_on_floor():
				velocity = lerp(velocity, Vector3.ZERO, 5 * delta) # prevent sliding on floor
				
		enemy_states.FALLING:
			# slow travel on xz plane in air to zero
			velocity.x = lerp(velocity.x, 0.0, slowInAirFactor * delta)
			velocity.z = lerp(velocity.z, 0.0, slowInAirFactor * delta)
		
		enemy_states.GROUNDED:
			velocity = lerp(velocity, Vector3.ZERO, 5 * delta)
		
		enemy_states.RUNNING:
			# get the vector going to the next path position
			var dir = (navigation_agent_3d.get_next_path_position() - global_position).normalized()
			velocity = dir * SPEED
			
func _process(delta: float) -> void:
	navigation_agent_3d.target_position = player.global_position
	
	if (is_on_floor() and
	enemy_state != enemy_states.STUNNED and 
	enemy_state != enemy_states.GROUNDED):
		enemy_state = enemy_states.GROUNDED
	elif not (is_on_floor() and
	enemy_state != enemy_states.STUNNED and 
	enemy_state != enemy_states.FALLING):
		enemy_state = enemy_states.FALLING

func _physics_process(delta: float) -> void:
	if not is_on_floor() and gravity_enabled:
		# handle gravity
		velocity += get_gravity() * delta

	# handle allowed physics
	statePhysicsLogic()
	move_and_slide()
