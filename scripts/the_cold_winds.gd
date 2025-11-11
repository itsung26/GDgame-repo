extends Node3D
@onready var enemy_spawn_handler: EnemySpawnHandler = $spawn1/EnemySpawnHandler


func _on_spawn_1_body_entered(body: Player) -> void:
	enemy_spawn_handler.spawnEnemies()
