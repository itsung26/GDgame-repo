class_name Level
extends Node
## Class representing game levels. Note that [LoadHandler] handles level transitions,
## not the levels themselves.


@onready var player:Player = get_tree().get_first_node_in_group("players")


func _ready() -> void:
	_connectAllSignals()


func _process(delta: float) -> void:
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
