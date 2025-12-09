extends Node3D

const explosion3d_SCENE:PackedScene = preload("res://scenes/explosion_3d.tscn")

@onready var explosion_spawn_pos: Marker3D = $explosionSpawnPos

@export_group("Force explosion")
@export var test_explosion_curve:Curve
@export var test_alpha_curve:Curve
@export var test_color:Color
@export var shockwave_knockback:float
@export var test_emission:float

@export_group("Damage explosion")
@export var damage_explosion_curve:Curve
@export var damage_explosion_alpha_curve:Curve
@export var damage_explosion_color:Color
@export var damage_explosion_knockback:float
@export var damage_explosion_emission:float
@export var damage_explosion_unshaded:bool
@export var damage_explosion_damage:float

func spawnExplosion():
	var explosion3d = explosion3d_SCENE.instantiate()
	add_child(explosion3d)
	explosion3d.setup(explosion_spawn_pos.global_position, 0.0, shockwave_knockback, 0.66, 2.0,
	test_color, test_emission, test_explosion_curve, test_alpha_curve, true)
	
func spawnDamageExplosion():
	var explosion3d = explosion3d_SCENE.instantiate()
	add_child(explosion3d)
	explosion3d.setup(explosion_spawn_pos.global_position, damage_explosion_damage, damage_explosion_knockback,
	0.0, 0.0, damage_explosion_color, damage_explosion_emission, damage_explosion_curve, damage_explosion_alpha_curve,
	damage_explosion_unshaded)

func clearExplosions():
	var explosions = get_tree().get_nodes_in_group("explosions")
	for explosion:Explosion3D in explosions:
		explosion.queue_free()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("debug func"):
		spawnExplosion()
		spawnDamageExplosion()
