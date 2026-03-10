class_name EnemySpawnHandler
extends Node

## Instances assigned enemy scene and spawns instances at positions of marker3d nodes.
##
## Looks for marker3d nodes as children. Note that this class is only capable of spawning one 
## type of enemy, but can do so at many different places. For spawning multiple types of enemies,
## use multiple [code]EnemySpawnHandlers[/code].
##
## HOW TO USE: position marker3ds at the desired spawn point(s), assign the scene to be spawned at
## the marker locations, call spawnEnemies() to spawn an enemy at each marker. [br]
## 
## This object is instanceable mid-runtime and [code]spawnEnemies[/code] can be called several times.

## If true, calls spawnEnemies() at time of being loaded.
@export var spawn_enemies_on_ready:bool = false
## This is the scene that is instantiated. It does not strictly have to be an enemy, but it is strongly reccomended to use EnemySpawnHandler for exclusively enemies.
@export var enemy_to_spawn_SCENE:PackedScene

## The children of this node. They should only be a marker3d.
@onready var spawn_points:Array = get_children()


func _ready() -> void:
	
	assert(enemy_to_spawn_SCENE != null)
	
	# children type check
	for spawn_point in spawn_points:
		if not spawn_point is Marker3D:
			print("ERROR: Children of this node should only be of the type marker3d")
	
	# spawn on ready
	if not spawn_points.is_empty():
		if spawn_enemies_on_ready:
			spawnEnemies()
	else:
		print("ERROR: No children detected")

## Instances the scene and spawns an instance at each child marker3d node.
func spawnEnemies():
	
	for spawn_point:Marker3D in spawn_points:
		var enemy_to_spawn_INSTANCE:Enemy = enemy_to_spawn_SCENE.instantiate()
		enemy_to_spawn_INSTANCE.global_position = spawn_point.global_position
		get_tree().current_scene.add_child.call_deferred(enemy_to_spawn_INSTANCE)
		
		
