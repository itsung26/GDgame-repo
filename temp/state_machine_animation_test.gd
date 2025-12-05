extends Node2D

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var state_machine:AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")

func _on_goup_pressed() -> void:
	state_machine.travel("goUp")


func _on_circle_pressed() -> void:
	state_machine.travel("circle")
