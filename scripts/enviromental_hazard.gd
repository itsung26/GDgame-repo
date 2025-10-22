class_name EnviromentalHazard extends Area3D

@export var damage:float
@export var enviroment_death_cause:String
@export var bounce_direction:Vector3
@export var bounce_speed:float

# connect signals
func _ready() -> void:
	print("initialized env_hazard at address " + str(self))
	connect("body_entered", _on_hazard_area_body_entered)
	if not bounce_direction.is_normalized():
		print("Parameter bounce direction was not a normalized vector, auto-normalizing.")
		bounce_direction = bounce_direction.normalized()
	elif bounce_direction.is_normalized():
		pass # passed check

func _on_hazard_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("players"):
		var player:Player = body
		player.damagePlayer(damage, enviroment_death_cause)
		# check if player in slamming state, check for floor and set to falling or grounded
		if player.player_state == player.player_states.SLAMMING:
			if player.is_on_floor():
				player.player_state = player.player_states.GROUNDED
			elif not player.is_on_floor():
				player.player_state = player.player_states.FALLING
		player.velocity = Vector3.ZERO
		player.velocity += bounce_direction * bounce_speed

	elif body.is_in_group("enemy"):
		var enemy:Enemy = body
		enemy.damageEnemy(damage, enemy.damage_types.NORMAL)
		print("hurt enemy")
		enemy.velocity = Vector3.ZERO
		enemy.velocity += bounce_direction * bounce_speed
