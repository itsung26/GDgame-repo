class_name EnemyFilth extends Enemy


@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var filth_animator:AnimationPlayer = $FilthAnimator
@onready var body_collider: CollisionShape3D = $bodyCollider
@onready var body_collider_2: CollisionShape3D = $bodyCollider2
@onready var time_untill_process_disable_timer:Timer = $timeUntillDisable

@export_category("General Properties")
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

enum enemy_states {STUNNED, FALLING, RUNNING, PREPARINGBITE, BITING, ENDINGBITE, DYING, DEAD, NULL}
var enemy_state:enemy_states = enemy_states.RUNNING:
	set = set_enemy_state

enum enemy_box_states {RUNNING, ATTACKING, DYING}
var enemy_box_state:enemy_box_states = enemy_box_states.RUNNING:
	set = set_enemy_box_state

var player_in_bite_box:bool = false

func _ready() -> void:
	super._ready() # ensure Enemy._ready runs (physics_frame hookup)
	if filth_animator == null:
		print("ERROR: filth animation player not found")
	if player == null:
		print("ERROR: initial call to PLAYER returned null ensure that the player is loaded before the given object")

func set_enemy_state(new_enemy_state:enemy_states):
	var previous_enemy_state = enemy_state
	enemy_state = new_enemy_state
	
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
	
	# end of bite to and from
	if new_enemy_state == enemy_states.ENDINGBITE:
		velocity = Vector3.ZERO
		
	# DYING to and from
	if new_enemy_state == enemy_states.DYING:
		set_enemy_box_state(enemy_box_states.DYING)
		damage_enabled = false
		filth_animator.play("ChestExplosion")
		
	# DEAD to and from
	if new_enemy_state == enemy_states.DEAD:
		velocity = Vector3.ZERO
		set_collision_layer_value(2, false)
		if time_untill_process_disable != 0:
			time_untill_process_disable_timer.start(time_untill_process_disable)
		else: pass
		

func _killEnemy():
	set_enemy_state(enemy_states.DYING)

func set_enemy_box_state(new_enemy_box_state:enemy_box_states):
	var previous_enemy_box_state = enemy_box_state
	enemy_box_state = new_enemy_box_state
	
	if new_enemy_box_state == enemy_box_states.ATTACKING:
		set_collision_mask_value(1, false)  # disable collision with player
		#body_collider_2.disabled = false
		#body_collider.disabled = true
	if previous_enemy_box_state == enemy_box_states.ATTACKING:
		set_collision_mask_value(1, true)  # enable collision with player
	
	# death box state to and from
	if new_enemy_box_state == enemy_box_states.DYING:
		$deadbodyCollider3.disabled = false
		$bodyCollider.disabled = true
		$biteHurtBox/CollisionShape3D.disabled = true
		$readyBiteBox/CollisionShape3D.disabled = true
	if previous_enemy_box_state == enemy_box_states.DYING:
		print("ERROR: enemy left death box state")
	

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
			
		enemy_states.DYING:
			velocity.x = lerp(velocity.x, 0.0, slowInAirFactor * delta)
			velocity.z = lerp(velocity.z, 0.0, slowInAirFactor * delta)

func disableProcess():
	print("disabled process")
	# set the process thread to disabled
	process_mode = Node.PROCESS_MODE_DISABLED # disables all interactions with node
	

## checks to see if the enemy is in the air or on the ground and sets the state once accordingly if it is not already in another state
func checkForStates():
	if (is_on_floor() and enemy_state == enemy_states.FALLING):
		set_enemy_state(enemy_states.RUNNING)
	elif not is_on_floor() and enemy_state == enemy_states.RUNNING:
		set_enemy_state(enemy_states.FALLING)

## Begins the method stack for the bite attack
func beginBiteChain():
	set_enemy_state(enemy_states.PREPARINGBITE)



func _process(_delta: float) -> void:
	$"debug state text".mesh.text = str(enemy_states.keys()[enemy_state])

func _physics_process(delta: float) -> void:
	
	if not is_on_floor() and gravity_enabled:
		# handle gravity
		velocity += get_gravity() * delta

	# handle allowed physics
	statePhysicsLogic()
	checkForStates()
	move_and_slide()




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
