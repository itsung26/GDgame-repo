## Helper class intended only to reduce verbosity in base method calls. Should ideally not store very much data. Note that any attributes do NOT clear their values when the game is restarted or the scene is changed.
extends Node

## Gets the first node with a string name matching node_pattern.
func getFirstInScene(node_pattern:String):
	var x:Node = get_tree().current_scene.find_child(node_pattern)
	if x == null:
		assert(false, "ERROR: node with name " + node_pattern + " not found in scene.")
	else:
		return x

## Gets the first node in the scene named "checkpoint"
func getCheckPoint():
	return getFirstInScene("checkpoint")

## Gets a refrence to the player by using a group's refrence. More safe than getting
## a referance to the player by name.
func getPlayerFromTree() -> Player:
	return get_tree().get_first_node_in_group("players")
