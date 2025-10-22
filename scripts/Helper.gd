## Helper class intended only to reduce verbosity in base method calls. Should ideally not store very much data. Note that any attributes do NOT clear their values when the game is restarted or the scene is changed.
extends Node

## Gets the first node with a string name matching node_pattern.
func getFirstInScene(node_pattern:String):
	return get_tree().current_scene.find_child(node_pattern)
