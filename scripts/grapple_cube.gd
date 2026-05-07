class_name GrappleCube
extends Node3D

@onready var shader_driver: ShaderDriver = $ShaderDriver
@onready var grapple_cube_procedural_animator: GrappleCubeProceduralAnimator = $grapple_cube/Skeleton3D/GrappleCubeProceduralAnimator

@export var initial_state:states
@export var active_color:Color = Color(0.231, 0.604, 0.827)
@export var inactive_color:Color = Color(0.38, 0.38, 0.38)

## Represents the global behavior state.
var state:states:
	set=set_state
var color:Color:
	set=set_color

enum states {
	INACTIVE,
	ACTIVE,
	GRAPPLED
}


#region setters and getters
func set_state(new_state:states) -> void:
	var previous_state:states = state
	state = new_state
	
	match new_state:
		
		states.INACTIVE:
			color = inactive_color
			grapple_cube_procedural_animator.active = false
		
		states.ACTIVE:
			color = active_color
			grapple_cube_procedural_animator.active = true
		
		states.GRAPPLED:
			grapple_cube_procedural_animator.master_speed_multiplier = 7.0
	
	match previous_state:
		
		states.INACTIVE:
			pass
		
		states.ACTIVE:
			pass
		
		states.GRAPPLED:
			grapple_cube_procedural_animator.master_speed_multiplier = 1.0


func set_color(new_color:Color) -> void:
	color = new_color
	
	shader_driver.setShaderParameter(&"fresnel_color", new_color)
#endregion


func _ready() -> void:
	set_state(initial_state)


func _process(delta: float) -> void:	
	var debug_text:StateDebugText = $StateDebugText
	debug_text.updateStateReadout(state, states)
	
	process_state_logic(delta)


func process_state_logic(delta:float) -> void:
	pass


func _on_grappleable_agent_3d_became_hooked_grappleable(grapple_arm: GrappleArm) -> void:
	set_state(states.GRAPPLED)


func _on_grappleable_agent_3d_stopped_being_hooked_grappleable(grapple_arm: GrappleArm) -> void:
	set_state(states.ACTIVE)
