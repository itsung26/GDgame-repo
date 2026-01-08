extends RigidBody3D

@onready var player:Player = get_tree().get_first_node_in_group("players")

func _ready() -> void:
	var player_colliders = get_tree().get_nodes_in_group("player collision detectors")
	for listener:Node3D in player_colliders:
		add_collision_exception_with(listener)

## Reparent to world and enable physics simulation.
func drop() -> void:
	# If not a child of the current scene's root node, reparent to be so.
	if get_parent() != get_tree().current_scene:
		reparent(get_tree().current_scene)
	freeze = false
