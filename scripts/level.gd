class_name Level
extends Node
## Class representing game levels. Note that [LoadHandler] handles level transitions,
## not the levels themselves.


@onready var player:Player = get_tree().get_first_node_in_group("players")


func _enter_tree() -> void:
	_connectAllSignals()
	_onLevelEnterTree()


func _ready() -> void:
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
	
	_onLevelReady()


func _process(delta: float) -> void:
	_onLevelTick(delta)


func _onLevelReady() -> void:
	pass


func _onLevelEnterTree() -> void:
	pass


func _onLevelTick(_delta: float) -> void:
	pass


func _connectAllSignals() -> void:
	connect("child_entered_tree", _on_child_entered_tree)
	connect("child_exiting_tree", _on_child_exiting_tree)


func _on_child_entered_tree(node: Node) -> void:
	if node is Enemy:
		EnemyPopulationHandler.addEnemyToPopulation(node)


func _on_child_exiting_tree(node: Node) -> void:
	if node is Enemy:
		EnemyPopulationHandler.removeEnemyFromPopulation(node)
