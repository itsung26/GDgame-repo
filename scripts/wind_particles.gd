extends GPUParticles3D
@onready var player: CharacterBody3D = $"../../.."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	look_at(player.velocity.normalized())
