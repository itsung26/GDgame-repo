@tool
class_name Shockwave
extends Node3D

#region @onready vars
@onready var main_ring_mesh: MeshInstance3D = $MainRingMesh
#endregion

#region @export vars
@export var shockwave_config:ShockwaveConfig
@export_tool_button("test activate") var a:Callable = explode
#endregion

#region regular vars
@export var size:float:
	set = setSize
var exploding:bool = false:
	set = setExploding
#endregion


func _process(delta: float) -> void:
	if exploding:
		size = move_toward(size, size * 2.0, shockwave_config.expand_speed * delta)


func setSize(size_new:float) -> void:
	size = size_new
	
	main_ring_mesh.mesh.set("inner_radius", size_new / 2.0)
	main_ring_mesh.mesh.set("outer_radius", size_new)


func setExploding(exploding_new:bool) -> void:
	exploding = exploding_new


func setup() -> void:
	explode()


func explode() -> void:
	exploding = !exploding
