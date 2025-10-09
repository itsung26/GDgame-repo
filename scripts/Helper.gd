## Class_name Helper
extends Node
## Helper class intended only to reduce verbosity in base method calls.
## Should ideally not store very much data.

func getFirstInScene(node_pattern:String):
	return get_tree().current_scene.find_child(node_pattern)
