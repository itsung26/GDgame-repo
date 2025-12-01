class_name GrappleCubeBoost
extends Node3D

## How much the player's speed is multiplied by upon entering the boost area.
@export var speed_boost_factor:float

func _on_speed_boost_block_body_entered(player: Player) -> void:
	player.set_action_state(player.action_states.IDLE)
	if not player.is_on_floor():
		player.set_player_state(player.player_states.FALLING)
	elif player.is_on_floor():
		player.set_player_state(player.player_states.GROUNDED)
	player.velocity = player.velocity * speed_boost_factor
	player.wind_rings.emitting = true
