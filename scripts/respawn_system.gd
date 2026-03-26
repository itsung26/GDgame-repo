extends Node

## Singleton that stores the active checkpoint and coordinates player respawns.
## Add this script as an Autoload to make it globally accessible.

signal checkpoint_changed(new_checkpoint:checkPoint, previous_checkpoint:checkPoint)
signal respawn_requested(player:Player, checkpoint:checkPoint)

var current_checkpoint:checkPoint


func set_current_checkpoint(new_checkpoint:checkPoint) -> void:
	if new_checkpoint == null:
		return
	if current_checkpoint == new_checkpoint:
		return
	
	var previous_checkpoint:checkPoint = current_checkpoint
	current_checkpoint = new_checkpoint
	checkpoint_changed.emit(current_checkpoint, previous_checkpoint)


func get_current_checkpoint() -> checkPoint:
	return current_checkpoint


func request_respawn(player:Player) -> void:
	assert(player != null)
	if current_checkpoint == null:
		push_warning("Respawn requested but no active checkpoint is set.")
		return
	
	respawn_requested.emit(player, current_checkpoint)
