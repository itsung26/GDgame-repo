extends Node3D

const explosion3d_SCENE:PackedScene = preload("res://scenes/explosion_3d.tscn")

@onready var explosion_spawn_pos: Marker3D = $explosionSpawnPos

@export var test_explosion_curve:Curve
@export var test_alpha_curve:Curve
@export var test_color:Color
@export var shockwave_knockback:float
@export var test_emission:float

@export var gray_explosion_curve:Curve
@export var gray_alpha_curve:Curve
@export var gray_color:Color
@export var gray_explosion_shockwave_knockback:float
@export var gray_emission:float

func spawnShockwaveExplosion():
	var explosion3d = explosion3d_SCENE.instantiate()
	add_child(explosion3d)
	explosion3d.setup(
		explosion_spawn_pos.global_position, # spawn position
		0.0, # damage
		gray_explosion_shockwave_knockback, # knockback
		0.0, # screen shake duration
		0.0, # screen shake strength
		gray_color, # color
		gray_emission, # emission
		gray_explosion_curve, # scaling curve
		gray_alpha_curve, # alpha curve
		true # shading mode: unshaded
		)

func spawnExplosion():
	var explosion3d = explosion3d_SCENE.instantiate()
	add_child(explosion3d)
	explosion3d.setup(
		explosion_spawn_pos.global_position,
		12.0,
		shockwave_knockback,
		0.66,
		2.0,
		test_color,
		test_emission,
		test_explosion_curve,
		test_alpha_curve,
		false # shading mode: shaded
		)

func clearExplosions():
	var explosions = get_tree().get_nodes_in_group("explosions")
	for explosion:Explosion3D in explosions:
		explosion.queue_free()

func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_P):
		spawnExplosion()
		spawnShockwaveExplosion()
