extends Node3D
@onready var cube_animator: AnimationPlayer = $cube_animator
@onready var cube_hit_animator: AnimationPlayer = $cube_hit_animator
@onready var player: CharacterBody3D = $"../../Player"
@onready var yank_delay_timer: Timer = $YankDelayTimer

@export_category("Settings")
@export var time_before_yank := 1.0

func _on_grapple_detect_block_body_entered(body: RigidBody3D) -> void:
	if body.name == "hook" and body.get_parent() == get_tree().root:
		print("grapple hook entered the box")
		body.global_position = position
		body.freeze = true
		cube_hit_animator.play("cube_open")
		yank_delay_timer.start(time_before_yank)


func _on_grapple_detect_block_body_exited(body: RigidBody3D) -> void:
	if body.name == "hook":
		print("grapple hook left the box")
		cube_hit_animator.play("cube_close")
		


func _on_yank_delay_timer_timeout() -> void:
	player.action_state = player.action_states.IDLE
