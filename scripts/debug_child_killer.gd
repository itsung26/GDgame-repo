class_name DebugChildKiller
extends Node3D
## Immidiately frees itself upon entering the tree, preventing both it and it's children 
## from ever initializing. Intended for quick debugging purposes.

@export var enabled:bool = false


func _enter_tree() -> void:
	if enabled:
		free()
