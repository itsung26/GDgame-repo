@tool
extends Node3D

const explosion3d_SCENE:PackedScene = preload("res://scenes/explosion_3d.tscn")

@onready var explosion_spawn_pos: Marker3D = $explosionSpawnPos

@export var final_explosion_scale:float
@export var explosion_time:float
@export var color_of_boom:Color
@export var boom_expand_speed:float

@export_tool_button("Test Explosion") var a = spawnExplosion
@export_tool_button("Clear Explosions") var b = clearExplosions

func spawnExplosion():
	var explosion3d = explosion3d_SCENE.instantiate()
	add_child(explosion3d)
	explosion3d.setup(explosion_spawn_pos.global_position, final_explosion_scale, explosion_time, 1.0, 1.0, color_of_boom)

func clearExplosions():
	var explosions = get_tree().get_nodes_in_group("explosions")
	for explosion:Explosion3D in explosions:
		explosion.queue_free()
