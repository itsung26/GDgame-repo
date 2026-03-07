class_name StateDebugText
extends Node3D

@onready var state_readout: Label3D = $StateReadout

@export var enabled:bool = true

func _ready() -> void:
	if not get_tree().debug_collisions_hint:
		enabled = false
		visible = false

## Updates the label with the name of the current state.
## [param state_var] is the current enum value (int). [param state_enum] is the enum type (e.g. enemy_states) or a Dictionary with .keys().
func updateStateReadout(state_var: int, state_enum: Variant) -> void:
	if not enabled:
		return
	var keys: Array = state_enum.keys()
	if state_var < 0 or state_var >= keys.size():
		state_readout.text = "?"
		return
	state_readout.text = keys[state_var]
