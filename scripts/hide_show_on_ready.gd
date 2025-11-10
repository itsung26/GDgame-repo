@tool
class_name HideShowOnReady extends Node

@export var nodes_to_hide_editor:Array[Node]
@export var nodes_to_show_editor:Array[Node]
@export var nodes_to_hide_on_ready:Array[Node]
@export var nodes_to_show_on_ready:Array[Node]

@export_tool_button("Show Nodes") var a = nodes_to_show_editor
@export_tool_button("Hide Nodes") var b = nodes_to_hide_editor

func hideNodesEditor():
	for node:Node in nodes_to_hide_editor:
		if node.visible == null:
			push_error("ERROR: node did not posses property node.visible")
		else:
			node.visible = false

func showNodesEditor():
	for node:Node in nodes_to_show_editor:
		if node.visible == null:
			push_error("ERROR: node did not posses property node.visible")
		else:
			node.visible = true
			
func hideNodesOnReady():
	for node:Node in nodes_to_hide_on_ready:
		if node.visible == null:
			push_error("ERROR: node did not posses property node.visible")
		else:
			node.visible = false
			
func showNodesOnReady():
	for node:Node in nodes_to_show_on_ready:
		if node.visible == null:
			push_error("ERROR: node did not posses property node.visible")
		else:
			node.visible = true

func _ready() -> void:
	if not Engine.is_editor_hint():
		hideNodesOnReady()
		showNodesOnReady()
