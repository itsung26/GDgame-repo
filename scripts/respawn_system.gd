extends Node

## Singleton that stores the active checkpoint and coordinates player respawns.
## Add this script as an Autoload to make it globally accessible.

signal checkpoint_changed(new_checkpoint:Checkpoint, previous_checkpoint:Checkpoint)
signal respawn_requested(player:Player, checkpoint:Checkpoint, reload_queued:bool)

var current_checkpoint:Checkpoint:
	set = set_current_checkpoint


func set_current_checkpoint(new_checkpoint:Checkpoint) -> void:	
	var previous_checkpoint:Checkpoint = current_checkpoint
	current_checkpoint = new_checkpoint
	
	checkpoint_changed.emit(current_checkpoint, previous_checkpoint)


func get_current_checkpoint() -> Checkpoint:
	return current_checkpoint


func request_respawn(player:Player) -> void:
	assert(player != null)
	
	# if a checkpoint is not set, fallback to going to the level start position.
	if current_checkpoint == null:
		# re-confine the mouse
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
		# send the player back to where they were, revert properties
		player.global_position = player.global_initial_player_position
		player.global_rotation.y = player.global_initial_player_rotation.y
		player.pivot.global_rotation.x = player.global_initial_pivot_roation.x
		player.health = 100.0
		player.STAMINA = 300.0
		
		# emit the signal
		respawn_requested.emit(player, current_checkpoint, true)
	else:
		# re-confine the mouse
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
		# send the player back to where they were, revert properties
		player.global_position = current_checkpoint.respawn_position
		player.global_rotation.y = current_checkpoint.player_rotation_y
		player.pivot.rotation.x = current_checkpoint.pivot_rotation_x
		player.health = 100.0
		player.STAMINA = 300.0
		
		
		# emit the signal
		respawn_requested.emit(player, current_checkpoint, false)
