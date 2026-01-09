extends Node3D

@onready var explosion_spawn_pos: Marker3D = $explosionSpawnPos

@export_group("Explosion Parameters")
@export var test_explosion_curve:Curve
@export var test_alpha_curve:Curve
@export var test_color:Color
@export var shockwave_knockback:float
@export var test_emission:float

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("debug func"):
		spawnExplosion() # test explosion
	
	if Input.is_key_pressed(KEY_O):
		spawnSword()

func spawnExplosion():
	var explosion3d_SCENE:PackedScene = load("res://scenes/explosion_3d.tscn")
	var explosion3d:Explosion3D = explosion3d_SCENE.instantiate()
	add_child(explosion3d)
	explosion3d.setup_preset(explosion_spawn_pos.global_position, explosion3d.explosion_presets.SHOCKWAVE_SMALL)
	
	var explosion_yellow:Explosion3D = explosion3d_SCENE.instantiate()
	add_child(explosion_yellow)
	explosion_yellow.setup_preset(explosion_spawn_pos.global_position, explosion_yellow.explosion_presets.YELLOW_SMALL)
	
func clearExplosions():
	var explosions = get_tree().get_nodes_in_group("explosions")
	for explosion:Explosion3D in explosions:
		explosion.queue_free()

func spawnSword():
	var sword_scene:PackedScene = load("res://scenes/big_sword.tscn")
	var sword:RigidBody3D = sword_scene.instantiate()
	sword.global_position = explosion_spawn_pos.global_position + Vector3(0, 10, 0)
	sword.freeze = false
	get_tree().current_scene.add_child(sword)
