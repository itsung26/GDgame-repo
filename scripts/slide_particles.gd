extends Node3D

@onready var player: CharacterBody3D = $".."

func _process(delta: float) -> void:
	var direction = player.velocity.normalized()
	look_at(global_position + direction, Vector3.UP)
