@tool
extends Node3D

const explosion3d_SCENE:PackedScene = preload("res://scenes/explosion_3d.tscn")

@onready var explosion_spawn_pos: Marker3D = $explosionSpawnPos

@export var test_explosion_curve:Curve
@export var test_alpha_curve:Curve
@export var test_color:Color
@export var shockwave_knockback:float

@export var red_explosion_curve:Curve
@export var red_alpha_curve:Curve
@export var red_color:Color
@export var red_emission:float

@export_tool_button("Test Explosion") var a = spawnExplosion
@export_tool_button("Clear Explosions") var b = clearExplosions

func spawnRedExplosion():
	var explosion3d = explosion3d_SCENE.instantiate()
	add_child(explosion3d)
	explosion3d.setup(
		explosion_spawn_pos.global_position, # spawn position
		12.0, # damage
		0.0, # knockback
		0.66, # screen shake duration
		2.0, # screen shake strength
		red_color, # color
		red_emission, # emission
		red_explosion_curve, # scaling curve
		red_alpha_curve, # alpha curve
		)

func spawnExplosion():
	var explosion3d = explosion3d_SCENE.instantiate()
	add_child(explosion3d)
	explosion3d.setup(
		explosion_spawn_pos.global_position,
		0.0,
		shockwave_knockback,
		0.66,
		2.0,
		test_color,
		0.0,
		test_explosion_curve,
		test_alpha_curve)

func clearExplosions():
	var explosions = get_tree().get_nodes_in_group("explosions")
	for explosion:Explosion3D in explosions:
		explosion.queue_free()

func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_P):
		spawnExplosion()
		spawnRedExplosion()
