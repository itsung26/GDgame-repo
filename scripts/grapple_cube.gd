extends Node3D
@onready var cube_animator: AnimationPlayer = $cube_animator
@onready var cube_hit_animator: AnimationPlayer = $cube_hit_animator
@onready var player: CharacterBody3D = $"../../Player"


func _on_grapple_detect_block_body_entered(body: RigidBody3D) -> void:
	if body.name == "hook":
		print("grapple hook entered the box")
		cube_hit_animator.play("cube_open")


func _on_grapple_detect_block_body_exited(body: RigidBody3D) -> void:
	if body.name == "hook":
		print("grapple hook left the box")
		cube_hit_animator.play("cube_close")
		
	
