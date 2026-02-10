class_name SkitterBomb
extends Enemy

# onreadies
@onready var animation_player: AnimationPlayer = $Skitterbomb2/AnimationPlayer
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D

# constants

# state machines
enum enemy_states {IDLE, STARTUP, FALLING, FOLLOWING, PREPARELEAP, LEAPING, DEAD}
var enemy_state:enemy_states:
	set = setEnemyState

# export vars
@export var initial_state:enemy_states

# regular vars

func setEnemyState(new_enemy_state:enemy_states):
	var previous_enemy_state:enemy_states = enemy_state
	enemy_state = new_enemy_state
	
	if previous_enemy_state == new_enemy_state:
		return
	
	if new_enemy_state == enemy_states.STARTUP:
		animation_player.play("rear action")

func _ready() -> void:
	setEnemyState(initial_state)
	
func _process(delta: float) -> void:
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
			pass # nav follow player here
	move_and_slide()
		
