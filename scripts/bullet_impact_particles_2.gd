extends Node3D

@onready var particle_group:Array[Node] = get_tree().get_nodes_in_group("particle group")
@onready var despawn_timer: Timer = $despawn_timer

@onready var has_been_setup:bool = false

## Called after instancing to scene
func setup(world_position:Vector3, look_dir:Vector3, despawn_time:float = 1.5):
	global_position = world_position
	look_at(global_position + look_dir + Vector3(0.0001, 0.0001, 0.0001)) # slight offset to prevent colinearity
	for particle:GPUParticles3D in particle_group:
		particle.emitting = true
	despawn_timer.start(despawn_time)
	has_been_setup = true


func _on_despawn_timer_timeout() -> void:
	queue_free()
