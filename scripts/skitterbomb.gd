class_name Skitterbomb
extends Enemy

func _ready() -> void:
	super._ready()

func _physics_process(delta: float) -> void:
	Debug.log(is_on_floor())
	
	# Handle gravity.
	if not is_on_floor():
		if gravity_enabled:
			velocity += get_gravity() * delta
		velocity.x = lerpf(velocity.x, 0.0, slowInAirFactor * delta)
		velocity.z = lerpf(velocity.z, 0.0, slowInAirFactor * delta)
	
	move_and_slide()

func _killEnemy():
	Debug.log("Passthrough. HP: " + str(getHealth()))

## Leap sequence begins when player enters this area.
func _on_player_detector_body_entered(player: Player) -> void:
	pass # Replace with function body.
