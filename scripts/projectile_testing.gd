extends Level


func _onLevelReady() -> void:
	pass


func _onLevelTick(_delta: float) -> void:
	return
	#Debug.log(EnemyPopulationHandler.getAllEnemies())
	#Debug.log(EnemyPopulationHandler.getClosestVisibleEnemy(player.global_position))
	var g = EnemyPopulationHandler.getClosestVisibleEnemy(player.global_position)
	Debug.log(g)
