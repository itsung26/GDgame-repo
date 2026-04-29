class_name outOfBoundsHazard extends EnviromentalHazard

func _ready() -> void:
	connect("body_entered", _on_body_entered)


func _on_body_entered(body: CharacterBody3D) -> void:
	
	if body.is_in_group("players"):
		var player:Player = body
		player.setHealth(player.HEALTH - damage_to_player)
		player.respawnCheckPoint()
	
	elif body.is_in_group("enemy"):
		var enemy:Enemy = body
		enemy.setHealth(enemy.HEALTH - damage_to_enemies, enemy.damage_types.NORMAL)
		enemy.queue_free()
