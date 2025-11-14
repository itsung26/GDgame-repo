@tool
extends Node3D

@onready var origin: Marker3D = $origin
@onready var target: Marker3D = $target
@onready var camera_3d: Camera3D = $Camera3D

@export_tool_button("spawn bullet trail") var a = spawnBulletTrail
@export_tool_button(("delete bullet trails")) var b = clearBulletTrails
const bullet_trail_scene:PackedScene = preload("res://scenes/bullet_trail.tscn")

func _process(delta: float) -> void:
	pass

func spawnBulletTrail():
	var bullet_trail_instance:BulletTrail = bullet_trail_scene.instantiate()
	$".".add_child(bullet_trail_instance)
	bullet_trail_instance.setup(origin.global_position, target.global_position)

func clearBulletTrails():
	var trails:Array[Node] = get_tree().get_nodes_in_group("bullet trails")
	for trail:Node in trails:
		trail.queue_free()
