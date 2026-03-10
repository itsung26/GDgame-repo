## Spawns instances of a single enemy scene at the positions of child Marker3D nodes.
## Supports optional delays between each individual spawn, measured in seconds and
## independent of framerate.
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

## If true, calls spawnEnemies() when this node enters the scene tree.
@export var spawn_enemies_on_ready:bool = false
## Scene to instantiate for each spawn point. Intended to be an Enemy-derived scene.
@export var enemy_to_spawn_SCENE:PackedScene
## Optional delay (in seconds) between spawning each individual enemy. 0.0 spawns all at once.
@export var spawn_delay_between_enemies:float = 0.1

## Cached list of child spawn points. These should only be Marker3D nodes.
@onready var spawn_points:Array = get_children()


## Validates configuration and optionally spawns enemies immediately if enabled.
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

## Instances the configured scene and spawns an instance at each child Marker3D spawn point.
## Returns an array of the spawned enemies. If [member spawn_delay_between_enemies] is > 0.0,
## this function asynchronously waits in seconds between each spawn in a framerate-independent way.
func spawnEnemies() -> Array[Enemy]:
	var ret:Array[Enemy] = []
	for i in spawn_points.size():
		var spawn_point:Marker3D = spawn_points[i]
		var enemy_to_spawn_INSTANCE:Enemy = enemy_to_spawn_SCENE.instantiate()
		enemy_to_spawn_INSTANCE.global_position = spawn_point.global_position
		get_tree().current_scene.add_child.call_deferred(enemy_to_spawn_INSTANCE)
		ret.append(enemy_to_spawn_INSTANCE)
		# Optional delay between each spawn, measured in seconds and framerate-independent.
		# SceneTreeTimer created by create_timer() is one-shot and cleans itself up.
		if spawn_delay_between_enemies > 0.0 and i < spawn_points.size() - 1:
			await get_tree().create_timer(spawn_delay_between_enemies).timeout
	return ret
		
		
