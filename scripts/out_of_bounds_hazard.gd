class_name outOfBoundsHazard extends EnviromentalHazard

@export var sendBackNode:Node

func _ready() -> void:
	connect("body_entered", _on_body_entered)


func _on_body_entered(body: CharacterBody3D) -> void:
	var sendBackPosition:Vector3 = sendBackNode.global_position
	
	if body.is_in_group("players"):
		var player:Player = body
		player.damagePlayer(damage, enviroment_death_cause)
		player.global_position = sendBackPosition
		print("idiot")
	
	elif body.is_in_group("enemy"):
		var enemy:Enemy = body
		enemy.damageEnemy(damage, enemy.damage_types.NORMAL)
		enemy.queue_free()
		print("Enemy fell outside of map. This should not have happened as the game checks for collisions over three times faster than it runs logic. Honestly, how did you manage this?")
