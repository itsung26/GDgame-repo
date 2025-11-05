## Manages enemy populations in the entire scene.
extends Node


## Gets all nodes in the "enemy" group.
func getAllEnemies() -> Array[Node]:
	return get_tree().get_nodes_in_group("enemy")

## Kills all enemies in the group
func killAllEnemies() -> void:
	for enemy:Enemy in get_tree().get_nodes_in_group("enemy"):
		pass # call damageEnemy 99999

func killEnemiesInGroup(group:String) -> void:
	for enemy in get_tree().get_nodes_in_group(group):
		pass # call damageEnemy 9999

func getEnemiesInGroup(group:String) -> Array[Node]:
	return get_tree().get_nodes_in_group(group)

func deleteAllEnemies() -> void:
	for enemy:Enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.queue_free()

func deleteEnemiesInGroup(group:String) -> void:
	for enemy in get_tree().get_nodes_in_group(group):
		enemy.queue_free()
