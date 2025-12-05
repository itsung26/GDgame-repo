@tool
extends Node3D

const explosion3d_SCENE:PackedScene = preload("res://scenes/explosion_3d.tscn")

@onready var explosion_spawn_pos: Marker3D = $explosionSpawnPos

#@export var explosion_time:float
#@export var color_of_boom:Color
#@export var boom_expand_speed:float
@export var test_explosion_curve:Curve

@export_tool_button("Test Explosion") var a = spawnExplosion
@export_tool_button("Clear Explosions") var b = clearExplosions

func spawnExplosion():
	var explosion3d = explosion3d_SCENE.instantiate()
	add_child(explosion3d)
	explosion3d.setup(explosion_spawn_pos.global_position, 0.0, 5.0, Color.GRAY, test_explosion_curve)

func clearExplosions():
	var explosions = get_tree().get_nodes_in_group("explosions")
	for explosion:Explosion3D in explosions:
		explosion.queue_free()
