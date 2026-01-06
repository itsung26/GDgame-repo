extends RigidBody3D

@onready var player:Player = get_tree().get_first_node_in_group("players")

func _ready() -> void:
	add_collision_exception_with(player)

## Reparent to world and enable physics simulation.
func drop() -> void:
	# If not a child of the current scene's root node, reparent to be so.
	if get_parent() != get_tree().current_scene:
		reparent(get_tree().current_scene)
	freeze = false
