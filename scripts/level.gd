class_name Level
extends Node3D
## Abstract base class representing game levels. Note that [LoadHandler] handles level transitions,
## not the levels themselves. Levels are the objects that watch for ragdolls or enemies
## being added to the scene and update the databases/managers accordingly.

@onready var player:Player = get_tree().get_first_node_in_group("players")


func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE:
		if not is_connected(&"child_entered_tree", _on_child_entered_tree):
			child_entered_tree.connect(_on_child_entered_tree)
		if not is_connected(&"child_exiting_tree", _on_child_exiting_tree):
			child_exiting_tree.connect(_on_child_exiting_tree)
	elif what == NOTIFICATION_READY:
		var current_scene: Node = get_tree().current_scene
		assert(
			current_scene == self,
			"Level must be the current scene root. Found current_scene=%s, self=%s" % [current_scene, self]
		)

		var level_count: int = 0
		if current_scene is Level:
			level_count += 1
		for node: Node in current_scene.find_children("*", "", true, false):
			if node is Level:
				level_count += 1
		assert(level_count == 1, "Expected exactly one Level in scene tree, found %d" % level_count)


func _on_child_entered_tree(node: Node) -> void:
	if node is Enemy:
		EnemyPopulationHandler.addEnemyToPopulation(node)
	elif node is Skeleton3D:
		RagdollManager.addRagdollRig(node)


func _on_child_exiting_tree(node: Node) -> void:
	if node is Enemy:
		EnemyPopulationHandler.removeEnemyFromPopulation(node)
	elif node is Skeleton3D:
		if RagdollManager.ragdoll_rigs.has(node):
			RagdollManager.removeRagdollRig(node)
