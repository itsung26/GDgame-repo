class_name StateDebugText
extends Node3D

@onready var state_readout: Label3D = $StateReadout

func updateStateReadout(state_var:int, state_machine:Dictionary):
	var state_string:String = state_machine.keys()[state_var]
	state_readout.text = state_string
