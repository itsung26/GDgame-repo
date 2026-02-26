class_name StateDebugText
extends Node3D

@onready var state_readout: Label3D = $StateReadout

@export var enabled:bool = true

func _ready() -> void:
	if not get_tree().debug_navigation_hint:
		enabled = false

func updateStateReadout(state_var:int, state_machine:Dictionary):
	if not enabled:
		return
	var state_string:String = state_machine.keys()[state_var]
	state_readout.text = state_string
