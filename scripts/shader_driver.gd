@tool
class_name ShaderDriver
extends Node
## Node that allows easily setting shader parameters through a public api.

@export var mesh_node:MeshInstance3D
## When true, material_slot_index is ignored and only the shader in the geometry override slot is modified.
@export var material_is_geometry_override:bool = false
@export var material_slot_index:int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func setShaderParameter(param:StringName, value:Variant) -> void:
	pass


func getShaderParameter(param:StringName) -> Variant:
	pass
