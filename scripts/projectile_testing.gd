class_name ProjectileTesting
extends Level


func _onLevelReady() -> void:
	Debug.log(global_position)


func _onLevelTick(_delta: float) -> void:
	return
	var g = EnemyPopulationHandler.getClosestVisibleEnemy(player.global_position)
	Debug.log(g)
