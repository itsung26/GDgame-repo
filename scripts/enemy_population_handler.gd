## Manages enemy populations in the entire scene.
extends Node


var enemies:Array[Enemy] = []
var _los_raycast:RayCast3D


func _ready() -> void:
	_los_raycast = RayCast3D.new()
	_los_raycast.enabled = false
	_los_raycast.collide_with_areas = false
	_los_raycast.collide_with_bodies = true
	_los_raycast.set_collision_mask_value(0, false)
	_los_raycast.set_collision_mask_value(1, true)
	add_child(_los_raycast)


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


func hasLineOfSightToEnemy(from_pos:Vector3, enemy:Enemy) -> bool:
	if enemy == null or not is_instance_valid(enemy) or _los_raycast == null:
		return false

	_los_raycast.clear_exceptions()
	_los_raycast.global_position = from_pos
	_los_raycast.target_position = enemy.global_position - from_pos
	_los_raycast.force_raycast_update()

	if not _los_raycast.is_colliding():
		return false

	var collider := _los_raycast.get_collider() as Node
	if collider == null:
		return false

	return collider == enemy or enemy.is_ancestor_of(collider)


func getClosestVisibleEnemy(from_pos:Vector3) -> Enemy:
	var closest_enemy:Enemy = null
	var closest_dist_sq:float = INF

	for enemy:Enemy in getAllEnemies():
		if not hasLineOfSightToEnemy(from_pos, enemy):
			continue

		var dist_sq := from_pos.distance_squared_to(enemy.global_position)
		if dist_sq < closest_dist_sq:
			closest_dist_sq = dist_sq
			closest_enemy = enemy

	return closest_enemy
