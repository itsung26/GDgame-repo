class_name Skitterbomb
extends Enemy

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var nav_target_point:Vector3
@onready var nav_next_point:Vector3

func _ready() -> void:
	navigation_agent_3d.target_position = player.global_position
	nav_target_point = navigation_agent_3d.target_position

func _physics_process(delta: float) -> void:
	
	# Handle gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		velocity.x = lerpf(velocity.x, 0.0, slowInAirFactor)
		velocity.z = lerpf(velocity.z, 0.0, slowInAirFactor)

func _killEnemy():
	Debug.log("enemy is not able to die. Health: " + str(getHealth()))

## Leap sequence begins when player enters this area.
func _on_player_detector_body_entered(player: Player) -> void:
	pass # Replace with function body.
