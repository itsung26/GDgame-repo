class_name DeathCamera
extends Node3D
## A scene that is instanced upon the player death. Serves as a kind of "outro cinematic"
## should the death of the player occur.

@onready var rigid_body_3d: RigidBody3D = $RigidBody3D
@onready var camera_3d: Camera3D = $RigidBody3D/Camera3D
@onready var death_shader_animator: AnimationPlayer = $DeathShaderAnimator
@onready var death_screen: Control = $DeathScreen
@onready var death_outro_shader: Control = $DeathOutroShader
@onready var death_screen_text_animator: AnimationPlayer = $DeathScreenTextAnimator


func _ready() -> void:
	death_screen.visible = false


func _input(event: InputEvent) -> void:
	if event is InputEventAction:
		pass


func setup(
player:Player,
torque_applied:float = 10.0,
velocity_applied:float = 10.0,
initial_rotation:Vector3 = Vector3.ZERO,
initial_position:Vector3 = Vector3.ZERO,
initial_velocity:Vector3 = Vector3.ZERO
) -> void:
	name = "DeathCamera"
	var angular_vector:Vector3
	var fling_dir:Vector3
	
	global_position = initial_position
	global_rotation = initial_rotation
	
	fling_dir = getRandomVector(-1.0, 1.0).normalized()
	angular_vector = getRandomVector(-1.0, 1.0).normalized()
	angular_vector = angular_vector * torque_applied
	
	rigid_body_3d.linear_velocity = initial_velocity + (fling_dir * velocity_applied)
	rigid_body_3d.angular_velocity = angular_vector
	
	camera_3d.make_current()
	death_shader_animator.play("fade_to_death")


## Returns a random vector with each component independently in [range_min, range_max].
func getRandomVector(range_min: float, range_max: float) -> Vector3:
	return Vector3(
		randf_range(range_min, range_max),
		randf_range(range_min, range_max),
		randf_range(range_min, range_max),
	)


# Coroutine - single thread, time based
func _onEndDeathTweenTransition() -> void:
	var player:Player = (get_tree().get_first_node_in_group("players")) as Player
	player.can_lerp_time_in_death = false
	TimeFlowSystem.setTimeScale(1.0)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	death_screen.visible = true
	death_outro_shader.visible = false
	await get_tree().create_timer(0.75, true, false, true).timeout
	death_screen_text_animator.play("connection_lost_text_1")


func _onDeathScreenFxTransitionDone() -> void:
	Debug.log("foo")


## When the tween/slowdown anim finishes
func _on_death_shader_animator_current_animation_changed(name: String) -> void:
	if name == "":
		_onEndDeathTweenTransition()


## When [code]connection_lost_text_1[/code] finishes on [member death_screen_text_animator], wait 0.5s then play [code]connection_lost_text_2[/code].
func _on_death_screen_text_animator_animation_finished(anim_name: StringName) -> void:
	if anim_name == "connection_lost_text_2":
		_onDeathScreenFxTransitionDone()
		return
	if anim_name != "connection_lost_text_1":
		return
	await get_tree().create_timer(0.50, true, false, true).timeout
	death_screen_text_animator.play("connection_lost_text_2")
