extends Node

func getFirstInScene(node_pattern:String):
	return get_tree().current_scene.find_child(node_pattern)
