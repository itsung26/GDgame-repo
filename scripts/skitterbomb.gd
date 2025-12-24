class_name Skitterbomb
extends Enemy

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	pass
	
	# Handle gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

func _setBehaviorEnabled(new_behavior_enabled_state:bool):
	var previous_behavior_enabled_state:bool = behavior_enabled
	behavior_enabled = new_behavior_enabled_state

func _killEnemy():
	Debug.log("enemy is not able to die. Health: " + str(getHealth()))

## Leap sequence begins when player enters this area.
func _on_player_detector_body_entered(player: Player) -> void:
	pass # Replace with function body.
