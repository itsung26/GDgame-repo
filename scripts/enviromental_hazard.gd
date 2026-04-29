class_name EnviromentalHazard extends Area3D
## Generic hazard volume that damages and knocks back players and enemies.
##
## When a body enters this `Area3D`, it:
## - applies damage
## - optionally marks the player death cause
## - applies knockback using `bounce_direction * bounce_speed`

## Damage done to entities
@export var damage_to_enemies: float = 2.5
@export var damage_to_player: float = 10.0
@export var enviromental_death_cause: String
## Direction used for knockback. Normalized in `_ready()`.
@export var bounce_direction: Vector3
## Knockback strength multiplier.
@export var bounce_speed: float


## Connects body-enter logic and normalizes configured knockback direction.
func _ready() -> void:
	connect("body_entered", _on_hazard_area_body_entered)
	if not bounce_direction.is_normalized():
		bounce_direction = bounce_direction.normalized()


## Handles collision with supported target types (`Player`, `Enemy`).
##
## Player behavior:
## - deals `damage_to_player` with `enviromental_death_cause`
## - if currently slamming, returns to grounded/falling based on floor contact
## - resets velocity and applies knockback
##
## Enemy behavior:
## - deals `damage_to_enemies` as normal damage
## - resets velocity and applies knockback
func _on_hazard_area_body_entered(body: Node3D) -> void:
	if body is Player:
		_onHazardPlayerEnter(body)
		var player: Player = body
		player.setHealth(player.HEALTH - damage_to_player)
		player.cause_of_death = enviromental_death_cause
		# Preserve movement state consistency when a slam is interrupted by hazard hit.
		if player.player_state == player.player_states.SLAMMING:
			if player.is_on_floor():
				player.set_player_state(player.player_states.GROUNDED)
			elif not player.is_on_floor():
				player.set_player_state(player.player_states.FALLING)
		player.killVelocity()
		player.applyForceImpulse(bounce_speed, bounce_direction)

	elif body is Enemy:
		_onHazardEnemyEnter(body)
		var enemy: Enemy = body
		enemy.setHealth(enemy.HEALTH - damage_to_enemies, enemy.damage_types.NORMAL)
		enemy.velocity = Vector3.ZERO
		enemy.velocity += bounce_direction * bounce_speed


#region Overridables
func _onHazardReady() -> void:
	pass


func _onHazardTick() -> void:
	pass


func _onHazardPlayerEnter(player:Player) -> void:
	pass


func _onHazardEnemyEnter(enemy:Enemy) -> void:
	pass
#endregion
