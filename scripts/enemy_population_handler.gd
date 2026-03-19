## Manages enemy populations in the entire scene.
extends Node


var enemies:Array[Enemy] = []


func addEnemyToPopulation(enemy:Enemy) -> Enemy:
	if enemy and is_instance_valid(enemy) and not enemies.has(enemy):
		enemies.append(enemy)
		return enemy
	else:
		return null


func removeEnemyFromPopulation(enemy:Enemy) -> void:
	enemies.erase(enemy)


## Gets all currently tracked enemies.
func getAllEnemies() -> Array[Enemy]:
	return enemies.duplicate()


## Kills all tracked enemies.
func killAllEnemies() -> void:
	for enemy:Enemy in getAllEnemies():
		pass # call damageEnemy 99999


func killEnemiesInGroup(group:String) -> void:
	for enemy:Enemy in getEnemiesInGroup(group):
		pass # call damageEnemy 9999


func getEnemiesInGroup(group:String) -> Array[Enemy]:
	return enemies.filter(func(enemy:Enemy) -> bool:
		return enemy.is_in_group(group)
	)


func deleteAllEnemies() -> void:
	for enemy:Enemy in getAllEnemies():
		enemy.queue_free()
	enemies.clear()


func deleteEnemiesInGroup(group:String) -> void:
	var enemies_to_delete:Array[Enemy] = getEnemiesInGroup(group)
	for enemy:Enemy in enemies_to_delete:
		enemy.queue_free()
		removeEnemyFromPopulation(enemy)


func getClosestEnemy(pos:Vector3) -> Enemy:
	var closest_enemy:Enemy = null
	var closest_dist_sq:float = INF

	for enemy:Enemy in getAllEnemies():
		var dist_sq := pos.distance_squared_to(enemy.global_position)
		if dist_sq < closest_dist_sq:
			closest_dist_sq = dist_sq
			closest_enemy = enemy

	return closest_enemy

func getClosestVisibleEnemy(from_pos:Vector3) -> Enemy:
	return
