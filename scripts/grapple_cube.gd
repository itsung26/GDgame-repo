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
var setting_player_reel_vector:bool = false

func _process(delta: float) -> void:
	direction = (player.camera_3d.global_position - global_position).normalized()
	if setting_player_reel_vector:
		player.reel_vector = direction * -yank_speed

# when the hook enters the cube
func _on_grapple_detect_block_body_entered(body: RigidBody3D) -> void:
	# if the hook was the body that entered and it's parent is the root node
	if body.name == "hook" and body.get_parent() == get_tree().root:
		body.global_position = position # move to cube origin
		body.freeze = true # disable physics
		setting_player_reel_vector = true
		player.player_state = player.player_states.REELINGTO
		cube_hit_animator.play("cube_open")
	elif body.name == "hook" and not body.get_parent() == get_tree().root:
		print("ERROR: expected hook to be a child of the world")
	elif body.name != "hook":
		print("WARNING: expected RigidBody entering to be a hook")

# when the hook leaves the cube
func _on_grapple_detect_block_body_exited(body: RigidBody3D) -> void:
	if body.name == "hook":
		setting_player_reel_vector = false
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
