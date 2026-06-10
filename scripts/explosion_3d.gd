@tool
@icon("res://explosionIcon.png")
class_name Explosion3D
extends Node3D

signal on_setup

@export var explosion_config: ExplosionConfig
@export var size: float = 1.0:
	set = setSize
@export_tool_button("test setup") var a: Callable = setup

var expanding: bool = false:
	set = setExpanding

## Contains an immidateMesh.
@onready var icosphere_generator: IcosphereGenerator = $IcosphereGenerator
@onready var shader_driver: ShaderDriver = $ShaderDriver
@onready var explosion_hurtbox: Area3D = $ExplosionHurtbox
@onready var explosion_collider: CollisionShape3D = $ExplosionHurtbox/ExplosionCollider


func _physics_process(delta: float) -> void:
	if not Engine.is_editor_hint():
		if Input.is_action_just_pressed("debug func"):
			setup()
	
	if expanding:
		size = move_toward(size, explosion_config.end_size, explosion_config.expand_speed * delta)
		if size == explosion_config.end_size:
			expanding = false


func setExpanding(expanding_new: bool) -> void:
	expanding = expanding_new

	if expanding_new == true:
		explosion_collider.disabled = false
	elif expanding_new == false:
		explosion_collider.disabled = true


func setSize(size_new: float) -> void:
	size = size_new

	# update mesh
	icosphere_generator.radius = size_new
	# update alpha
	shader_driver.setShaderParameter(
		&"alpha",
		explosion_config.alpha_curve.sample_baked(getNormalizedSize()),
	)
	# update collider radius
	explosion_collider.shape.radius = size_new


func setup() -> void:
	size = explosion_config.start_size
	expanding = true
	on_setup.emit()


func getNormalizedSize() -> float:
	return remap(
		size,
		explosion_config.start_size,
		explosion_config.end_size,
		0.0,
		1.0,
	)


func _on_explosion_hurtbox_body_entered(body: Node3D) -> void:
	_handle_hit(body)


func _handle_hit(body: Node3D) -> void:
	if body is Player:
		var center_point: Vector3 = global_position # get the center of the sphere
		var dir_to_player_head: Vector3 = (body.camera_3d.global_position - center_point).normalized()

		# apply a force to the player
		if explosion_config.knockback_force > 0:
			body.killVelocity()
			body.global_position.y += 0.1
			if not body.is_on_floor():
				body.set_player_state(Player.player_states.FALLING)
			body.velocity += dir_to_player_head * explosion_config.knockback_force

			body.setHealth(body.health - explosion_config.damage)
			body.cause_of_death = "Explosion."
			body.camera_3d.shakeCamera(
				explosion_config.screen_shake_duration,
				explosion_config.screen_shake_strength,
			)
	elif body is Enemy:
		var center_point: Vector3 = global_position
		var vertical_offset: float = 1.0
		var dir_to_enemy: Vector3 = (
			(body.global_position + Vector3(0, vertical_offset, 0)) - center_point
		).normalized()

		if explosion_config.knockback_force > 0:
			body.velocity = Vector3.ZERO
			body.global_position.y += 0.001
			body.velocity += dir_to_enemy * explosion_config.knockback_force

		body.setHealth(
			body.health - explosion_config.damage,
			Enemy.damage_types.EXPLOSIVE,
		)
	elif body is PhysicalBone3D:
		var center_point: Vector3 = global_position
		var dir_out: Vector3 = (body.global_position - center_point).normalized()
		var force_to_bone: float = 10.0

		body.linear_velocity = Vector3.ZERO
		body.apply_impulse(dir_out * force_to_bone)
