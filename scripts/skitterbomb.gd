class_name Skitterbomb
extends Enemy

@onready var bt_player: BTPlayer = $BTPlayer
@onready var animation_player: AnimationPlayer = $Skitterbomb2/AnimationPlayer
@onready var prepare_leap_delay: Timer = $"prepare leap delay"

@export var prepare_leap_delay_time:float
var player_inside_leap_trigger_area:bool = false

enum enemy_states {FOLLOWING, IDLE, PREPARELEAP, LEAPING}
var enemy_state:enemy_states = enemy_states.IDLE:
	set = setEnemyState

func setEnemyState(new_enemy_state:enemy_states):
	var previous_enemy_state:enemy_states = enemy_state
	enemy_state = new_enemy_state
	
	# prevent same state switching
	if previous_enemy_state == new_enemy_state:
		return
		
	if new_enemy_state == enemy_states.PREPARELEAP:
		lookAtYAxis(player.getPredictedPos(0.5))
		prepare_leap_delay.start(prepare_leap_delay_time)

func _ready() -> void:
	super._ready()

func _process(delta: float) -> void:
	if enemy_state == enemy_states.IDLE:
		animation_player.play("Idle")
	elif enemy_state == enemy_states.FOLLOWING:
		animation_player.play("forwards")
	if not is_on_floor():
		animation_player.play("Falling")
	

func _physics_process(delta: float) -> void:
	# update the debug state indicator
	setMeshText(getEnemyStateString())
	
	# update the blackboard variable with the player's position
	bt_player.blackboard.set_var(&"target_pos", player.global_position)
	
	if enemy_state == enemy_states.FOLLOWING:
		if velocity != Vector3.ZERO:
			lookAtYAxis(global_position + velocity)
	
	# Handle gravity.
	if not is_on_floor():
		if gravity_enabled:
			velocity += get_gravity() * delta
		velocity.x = lerpf(velocity.x, 0.0, slowInAirFactor * delta)
		velocity.z = lerpf(velocity.z, 0.0, slowInAirFactor * delta)
	
	move_and_slide()

func _killEnemy():
	Debug.log("Passthrough. HP: " + str(getHealth()))

func getPlayer() -> Player:
	if player:
		return player
	else:
		assert(false, "Failed to assert reference to player.")
		return null

func setMeshText(text:String) -> void:
	var text_mesh_instance:MeshInstance3D = find_child("text mesh")
	var text_mesh:TextMesh = text_mesh_instance.mesh
	text_mesh.text = text
	
func getEnemyStateString() -> String:
	return enemy_states.keys()[enemy_state]

func lookAtYAxis(point:Vector3) -> void:
		var prev_rot_x := rotation.x
		var prev_rot_z := rotation.z
		
		look_at( point)
		rotation.x = prev_rot_x
		rotation.z = prev_rot_z

## Leap sequence begins when player enters this area.
func _on_player_detector_body_entered(player: Player) -> void:
	player_inside_leap_trigger_area = true
	if is_on_floor():
		setEnemyState(enemy_states.PREPARELEAP)

func _on_player_detector_body_exited(player: Player) -> void:
	player_inside_leap_trigger_area = false

func _on_prepare_leap_delay_timeout() -> void:
	setEnemyState(enemy_states.FOLLOWING)
