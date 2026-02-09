extends Node3D
@onready var enemy_spawn_handler: EnemySpawnHandler = $EnemySpawnHandler

func _on_area_3d_area_entered(area: Area3D) -> void:
	enemy_spawn_handler.spawnEnemies()
