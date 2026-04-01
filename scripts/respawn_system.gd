extends Node

## Singleton that stores the active checkpoint and coordinates player respawns.
## Add this script as an Autoload to make it globally accessible.

signal checkpoint_changed(new_checkpoint:Checkpoint, previous_checkpoint:Checkpoint)
signal respawn_requested(player:Player, checkpoint:Checkpoint)

var current_checkpoint:Checkpoint


func set_current_checkpoint(new_checkpoint:Checkpoint) -> void:	
	var previous_checkpoint:Checkpoint = current_checkpoint
	current_checkpoint = new_checkpoint
	
	checkpoint_changed.emit(current_checkpoint, previous_checkpoint)


func get_current_checkpoint() -> Checkpoint:
	return current_checkpoint


func request_respawn(player:Player) -> void:
	assert(player != null)
	assert(current_checkpoint != null)
	
	player.global_position = current_checkpoint.respawn_location
	player.HEALTH = 100.0
	player.STAMINA = 300.0
	
	respawn_requested.emit(player, current_checkpoint)
