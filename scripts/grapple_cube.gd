extends Node3D
@onready var cube_animator: AnimationPlayer = $cube_animator
@onready var cube_hit_animator: AnimationPlayer = $cube_hit_animator
@onready var player: CharacterBody3D = $"../../Player"
@onready var yank_delay_timer: Timer = $YankDelayTimer
@onready var wind_rings: GPUParticles3D = $Pivot/Camera3D/WindRings

@export_category("Settings")
@export var time_before_yank := 1.0
@export var yank_speed := 5.0
@export var boost_speed := 15.0

var direction := Vector3.ZERO

# when the hook enters the cube
func _on_grapple_detect_block_body_entered(body: RigidBody3D) -> void:
	if body.name == "hook" and body.get_parent() == get_tree().root:
		print("grapple hook entered the box")
		body.global_position = position
		body.freeze = true
		direction = (player.camera_3d.global_position - global_position).normalized()
		player.reel_vector = direction * -yank_speed
		player.player_state = player.player_states.REELINGTO
		cube_hit_animator.play("cube_open")

# when the hook leaves the cube
func _on_grapple_detect_block_body_exited(body: RigidBody3D) -> void:
	if body.name == "hook":
		print("grapple hook left the box")
		cube_hit_animator.play("cube_close")
		

# when the timer runs out, put the hook back
func _on_yank_delay_timer_timeout() -> void:
	player.action_state = player.action_states.IDLE

# when the player enters the speed block
func _on_speed_boost_block_body_entered(body: CharacterBody3D) -> void:
	player.wind_rings.emitting = true
	player.velocity += direction * -boost_speed
	player.player_state = player.player_states.FALLING
	player.action_state = player.action_states.IDLE
