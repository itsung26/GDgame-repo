extends Node3D

const explosion3d_SCENE:PackedScene = preload("res://scenes/explosion_3d.tscn")

@onready var explosion_spawn_pos: Marker3D = $explosionSpawnPos

@export_group("Explosion Parameters")
@export var test_explosion_curve:Curve
@export var test_alpha_curve:Curve
@export var test_color:Color
@export var shockwave_knockback:float
@export var test_emission:float

func spawnExplosion():
	var explosion3d:Explosion3D = explosion3d_SCENE.instantiate()
	add_child(explosion3d)
	explosion3d.setup(explosion_spawn_pos.global_position, 0.0, 5.0, 0.66, 2.0, Color.GRAY, 0.0,)

func clearExplosions():
	var explosions = get_tree().get_nodes_in_group("explosions")
	for explosion:Explosion3D in explosions:
		explosion.queue_free()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("debug func"):
		spawnExplosion() # test explosion
