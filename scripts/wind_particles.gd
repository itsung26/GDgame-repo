extends GPUParticles3D
@onready var player: CharacterBody3D = $"../../.."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# show the particles
	visible = true


# Looks in the direction of the player's velocity vector
# emits if magnitude is greater than 15.0
func _process(_delta: float) -> void:
	if player.velocity.length() > 15.0:
		var direction = player.velocity.normalized()
		look_at(global_position + direction, Vector3.UP)
		emitting = true
	else:
		emitting = false
