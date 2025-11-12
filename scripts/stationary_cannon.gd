class_name CannonStationary extends Enemy

@export var bullet_spawn_marker:Marker3D
@onready var bullet_spawn_pos:Vector3 = Vector3(bullet_spawn_marker.global_position)
const bullet_scene:PackedScene = preload("res://scenes/energy_ball.tscn")

var fired_bullets:Array[EnergyBall]

func fire():
	var bullet:EnergyBall = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = bullet_spawn_pos
	bullet.beginTravel($"Bullet Spawn Position/BulletLookPosition".global_position)

func _process(delta: float) -> void:
	pass

func _on_bullet_fire_interval_timeout() -> void:
	fire()
