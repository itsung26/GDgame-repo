class_name outOfBoundsHazard extends EnviromentalHazard

func _ready() -> void:
	connect("body_entered", _on_body_entered)


func _on_body_entered(body: CharacterBody3D) -> void:
	
	if body.is_in_group("players"):
		var player:Player = body
		player.damagePlayer(damage, enviroment_death_cause)
		player.respawnCheckPoint()
	
	elif body.is_in_group("enemy"):
		var enemy:Enemy = body
		enemy.damageEnemy(damage, enemy.damage_types.NORMAL)
		enemy.queue_free()
