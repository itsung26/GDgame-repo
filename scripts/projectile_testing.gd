extends Node3D
@onready var enemy_spawn_handler: EnemySpawnHandler = $EnemySpawnHandler

func _on_area_3d_body_entered(body: Player) -> void:
	enemy_spawn_handler.spawnEnemies()
