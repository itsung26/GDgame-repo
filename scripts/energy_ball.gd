class_name EnergyBall extends RigidBody3D

@export var damage_to_player:float
@export var damage_to_enemies:float
@export var travel_speed:float = 12: set = setthis

func setthis(new_travel_speed:float):
	travel_speed = new_travel_speed
	print("changed travel speed to " + str(travel_speed))
	
func beginTravel(look_at_direction:Vector3):
	look_at(look_at_direction)
	var foward_dir:Vector3 = -transform.basis.z
	linear_velocity = foward_dir * travel_speed

## Dismantles the projectile, freeing it when done.
func destroySelf():
	queue_free()

func _on_body_entered(body: Node) -> void:
	
	if body is Player:
		var player:Player = body
		player.damagePlayer(damage_to_player, "Melted by energy projectile")
		destroySelf()
	
	elif body is Enemy:
		var enemy:Enemy = body
		enemy.damageEnemy(damage_to_enemies, enemy.damage_types.NORMAL)
		destroySelf()
	
	else:
		print("projectile collided with world " + body.to_string() + ", presumably")
		destroySelf()
		
