extends GPUParticles3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position.y = 1.109 # move to center of enemy


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	look_at(get_viewport().get_camera_3d().global_position)
	rotation.x = 0
	rotation.z = 0
