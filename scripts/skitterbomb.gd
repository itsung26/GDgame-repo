class_name Skitterbomb
extends Enemy

@onready var bt_player: BTPlayer = $BTPlayer
@onready var blackboard: Blackboard = bt_player.blackboard

func _physics_process(delta: float) -> void:
	
	# Handle gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

func _setBehaviorEnabled(new_behavior_enabled_state:bool):
	var previous_behavior_enabled_state:bool = behavior_enabled
	behavior_enabled = new_behavior_enabled_state
